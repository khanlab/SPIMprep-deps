# SPIMprep_deps

Container for SPIMprep dependencies (Fiji, bigstitcher, python)


Note: There doesn't seem to be an easy way to pin the version of Fiji plugins (bigstitcher), and updating to the latest version might be breaking things.. 
So we define fiji plugins and dependencies manually, by providing lists of urls for each.

The URLs were determined by going to the bigstitcher maven page (of the version to install), e.g.:
https://mvnrepository.com/artifact/net.preibisch/BigStitcher/1.2.10

Then going through the list of dependencies and grabbing the URLs for jar files. The dependency jars are added to `fiji_jars.txt`. and the plugin jars are added to `fiji_plugins.txt`. The Dockerfile downloads them and puts them in the fiji jars and plugins folder respectively. 

