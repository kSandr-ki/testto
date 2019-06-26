# testto
deploing application in aws


# requirements

You need docker installed on host machine and jq for parsing results


#usage
before all operations you need export your aws keys.
```
export AWS_ACCESS_KEY=<your access key here>
export AWS_SECRET_KEY=<your secret key key here>
```

for start deploying 
```
/bin/bash run --apply 
```
for destroy
```
/bin/bash run --destroy
```
for get actual info about hosts
```
/bin/bash run --info
```

#application

you can get fibonacci series by set "n" param in url string like:
```
curl $APP_URL/?n=10
```
you can add client "ip" with uri "path" to black list with next params:
```
curl $APP_URL/blacked?token=bigsecret&ip=10.10.10.10&path=/info&action=add
```
you can get currently blocked user list with next params:
```
curl $APP_URL/blacked?token=bigsecret&action=list
```
