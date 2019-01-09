# erb-hiera-generator

Ruby script to use Puppets erb/hiera features without the need to have puppet installed.

## Preparation
We suggest to use erb-hiera-generator with docker to avoid dependency problem on your local maschine.

```
docker -t build erb-hiera-generator .
```

## Usage

a) Usage with docker
```
docker run -v $(pwd)/hiera.yaml:/params/hiera.yaml -v $(pwd)/test.erb:/params/template -v $(pwd)/test.result:/params/outputfile --rm erb-hiera-generator
```

Attention: Make sure the file `$(pwd)/test.result` exists **before** running the docker command as it otherwise will became a folder that can not be used by erb-hiera-generator.

b) Native usage
You can of cource use erb-hiera-generator without docker when all dependencies are installed.

```
./erb-hiera-generator.rb path/to/hiera.yaml path/to/template path/to/output
```

Be aware of the fact that erb-hiera-generator will overwrite the outputfile.