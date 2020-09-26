# AVADO package template

This is a template for creating AVADO packages yourself.

## Prerequisites
 
 - A WiFi or VPN connection to your AVADO box 
 - IPFS client installed

## Installation

AVADO uses the DappNode SDK to build packages.

First install the SDK - we need the 0.2.11 version (higher version are not compatible with AVADO)

`npm i -g @dappnode/dappnodesdk@0.2.11`

## Building

`dappnodesdk build` will build the package and upload to your AVADO box's IPFS server.

it will output the IPFS hash that you can use in your package

` Manifest hash : /ipfs/QmNf8sEHdzD5EbBDxd3HBFpq5zBW2PziJ4vqfa8G7xgVJm`

## Installing and testing 

Go to your avado DappStore page at http://my.avado/#/installer

enter the above hash in the input field and press enter.

You will see the package 



