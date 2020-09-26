# AVADO package template

This is a template for creating AVADO packages yourself.

## Prerequisites
 
 - A WiFi or VPN connection to your AVADO box 
 - IPFS client installed

## Installation

AVADO uses the DappNode SDK to build packages.

First install the SDK - we need the 0.2.11 version (higher version are not compatible with AVADO)

`npm i -g @dappnode/dappnodesdk@0.2.11`

## Testing locally

you can modify the Dockerfile in the `build` folder and test it locally using `docker-compose build` and `docker-compose up` until it works as expected.

## Building

`dappnodesdk build` will build the package and upload to your AVADO box's IPFS server.

it will output the IPFS hash that you can use in your package

` Manifest hash : /ipfs/QmNf8sEHdzD5EbBDxd3HBFpq5zBW2PziJ4vqfa8G7xgVJm`

## Installing and testing 

Go to your avado DappStore page at http://my.avado/#/installer

enter the above hash in the input field and press enter.

You will see the package detail screen - where you can install the package on your box and test it out.

## Renaming your package

You want to change the package name you need to change the package name in the following locations
`dappnode_package.json` --> modify the `name` field.
`docker-compose.yml` --> modify the `service` name and the `image` field accordingly.

## Publishing

You can distribute the IPFS hash of your package to other AVADO users - or if you want to have your package added to the DappStore - contact the AVADO team in the Telegram chat.

## Some random tips

- the docker-compose file creates a mount point `/data` where you can store data that has to be saved on a seperate volume to be retained after a package restart.
- you can bump the package version number using `dappnodesdk patch`
- upon installing - the AVADO will create a DNS entry called `my.<packagename>` that resolvves to the docker container's IP address. This is convenient if you want to open a web UI from the package. If you install this package - the hostname `my.avado-dnp-template.public.dappnode.eth` will resolve to its IP address.
- in the AVADO repo - there are several packages published that you can take a look at to get inspired on how to fiddle with parameters












