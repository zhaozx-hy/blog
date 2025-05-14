import requests

data={
    "id":"1000",
    "name":"xxxxx"
}

header={
    "token":"3086dcc4-530d-498e-9628-da5c0bfd19f6"
}

url = "http://localhost:8080/category/list"

response = requests.get(url)

print(response.text)
# 以二进制模式打开文件
# with open(file_path, "rb") as file:
#     files = {"file": (file_path, file, "image/jpeg")}  # 显式指定文件名和MIME类型[1,4](@ref)
#     response = requests.post(url, files=files)
# print(response.text)

# with open(js_path, 'rb') as f:
    # files = {'file': (js_path, f, 'application/javascript')}
    
