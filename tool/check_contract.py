"""Offline request/schema and Android manifest checks; not a Flutter build."""
import json, pathlib, re, xml.etree.ElementTree as ET
root = pathlib.Path(__file__).resolve().parents[1]
spec = json.loads((root/'docs/openapi-v53.json').read_text())
schemas = spec['components']['schemas']
checked = 0

def verify(path, method, payload):
    global checked
    op = spec['paths'][path][method.lower()]
    ref = op['requestBody']['content']['application/json']['schema']['$ref'].split('/')[-1]
    schema = schemas[ref]
    assert set(payload) <= set(schema['properties']), (path, 'unknown field')
    assert set(schema.get('required', [])) <= set(payload), (path, 'required field')
    for key,value in payload.items():
        field=schema['properties'][key]
        if value is None: assert field.get('nullable'), (path,key)
        elif 'enum' in field: assert value in field['enum'],(path,key)
        elif field.get('type')=='integer': assert type(value) is int,(path,key)
        elif field.get('type')=='boolean': assert type(value) is bool,(path,key)
        elif field.get('type')=='number': assert type(value) in (int,float),(path,key)
        elif field.get('type')=='string': assert type(value) is str,(path,key)
    checked += 1

verify('/auth/login','POST',{'mobile':'09121234567','password':' secret ','device_name':'bonYe Android'})
verify('/auth/refresh','POST',{'refresh_token':'a'*64})
verify('/auth/otp/request','POST',{'mobile':'09121234567','purpose':'register'})
verify('/auth/otp/verify','POST',{'challenge_id':'a'*32,'code':'123456','device_name':'bonYe Android','name':'تست','new_password':'long password'})
verify('/pets','POST',{'name':'پت','species':'cat','breed':'','birth_date':'2020-01-01','sex':'female','weight_kg':4.2,'body_condition':5,'activity':'normal','life_stage':'adult','neutered':True,'special_conditions':[]})
verify('/pets/{id}','PATCH',{'name':'پت','species':'dog','birth_date':None,'neutered':None,'weight_kg':None})
verify('/pets/{id}/weights','POST',{'weight_kg':4.3,'measured_on':'2026-10-08'})
verify('/pets/{id}/feeding-plans','POST',{'variant_id':1,'meals_per_day':2})
verify('/club/credit/convert','POST',{'points':100})
verify('/club/referrals/join','POST',{'code':'REF-123'})
verify('/me','PATCH',{'name':'کاربر','email':None})
verify('/me/addresses','POST',{'label':'خانه','recipient_name':'کاربر','mobile':'09121234567','province':'تهران','city':'تهران','address':'آدرس','postal_code':'1234567890','is_default':True})
verify('/me/preferences','PATCH',{'sms_marketing':False,'consent_version':'bonye-app-v1'})
verify('/content/articles/{id}/state','PUT',{'favorite':True,'revision':0})
verify('/content/podcasts/{id}/state','PUT',{'favorite':True,'position_seconds':10,'completed':False,'revision':0})
# Verify all literal and interpolated API routes used in source exist in the contract.
checked_routes=set()
for file in (root/'lib').rglob('*.dart'):
    for method,path in re.findall(r"(?:request|_send)\s*\(\s*'(GET|POST|PATCH|PUT|DELETE)'\s*,\s*'([^']+)'",file.read_text()):
        if '$kind' in path or '${widget.kind}' in path: variants=[path.replace('$kind',x).replace('${widget.kind}',x) for x in ['articles','podcasts']]
        else: variants=[path]
        for route in variants:
            route=route.split('?')[0]
            route=re.sub(r'\$\{[^}]+\}', '{id}', route)
            route=re.sub(r'\$(id|challenge)', '{id}', route)
            if route in spec['paths']:
                assert method.lower() in spec['paths'][route], (file,method,route)
                checked_routes.add((method,route))
            else:
                assert '$' in route, (file,'unknown endpoint',route)
manifest=ET.parse(root/'android/app/src/main/AndroidManifest.xml').getroot()
android='{http://schemas.android.com/apk/res/android}'
app=manifest.find('application')
assert app.get(android+'usesCleartextTraffic')=='false'
assert app.get(android+'allowBackup')=='false'
permissions={p.get(android+'name') for p in manifest.findall('uses-permission')}
assert {'android.permission.INTERNET','android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK'} <= permissions
assert app.find('service').get(android+'foregroundServiceType')=='mediaPlayback'
for xml in (root/'android').rglob('*.xml'): ET.parse(xml)
print(f'PASS: {checked} request fixtures, {len(checked_routes)} endpoint/method bindings, Android XML/security/media configuration')
