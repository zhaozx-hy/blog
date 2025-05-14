import requests

data={
    "account":"admin",
    "password":"1"
}

header={
    "token":"0af9604d-477e-4951-9acd-b80f2933307c"
}

url = "http://localhost:8080/admin/login"

response = requests.post(url,json=data)

print(response.text)