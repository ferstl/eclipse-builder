# Eclipse Builder
*- Creates Eclipse distributions for Linux (GTK), Mac OSX and Windows using the P2 Director application*

### Prerequisites
 - A Bash shell
 - A recent Eclipse distribution from http://download.eclipse.org containing the P2 Director application
 - The `eclipse-builder.sh` script from https://github.com/ferstl/eclipse-builder
 - One or more configuration files describing the content of the Eclipse distribution to be built


### The configuration file(s)
A configuration file contains the information which installable units (IUs) will be installed into the Eclipse distribution and where to download them:

    remote-url:http://download.eclipse.org/releases/juno
    local-url:file:///home/me/my-local-repository
    tag:Basic Installation
    iu:org.eclipse.sdk.ide
    iu:org.eclipse.jgit.feature.group
    iu:org.eclipse.egit.import.feature.group
    iu:...

 - `remote-url`: URL of the remote repository where the listed IUs can be downloaded. The configuration file must contain one or more `remote-url` tags.
 - `local-url`: Alternative URL where the listed IUs can be downloaded. This tag can be used to get the IUs from a locally mirrored repository or from a P2-enabled Nexus. The configuration file must contain one or more `local-url` tags in case the script is executed with the `--local` option.
 - `tag`: Name of the installation tag. The tag will be shown in the installation history of the built Eclipse distribution. This tag is optional.
 - `iu`: IU to be installed in the Eclipse distribution. The configuration file must contain one or more `iu` tags.
 
 
### How to run the eclipse-builder.sh Script
Running `eclipse-builder.sh --help` shows ho to use the script:

    Usage: $SCRIPT_NAME <options> <configs>
      <options>:
        -c --p2command    Command to start the P2 director
                          (default: $BASEDIR/eclipse/eclipse)
        -l --local        Use local (on-site) repositories to download installable
                          units.
        -p --platform     Distribution platform. The currently supported platforms
                          are "linux", "macosx", "windows" (all 64bit)
        -d --destination  Destination directory (must be a fully qualifed name!)
                          for the created distributions
        -n --name         Name of the created distribution
                          (default: custom-eclipse)
        -h --help         Print this help message
      
      <configs>: Configuration files
      
### Examples
The following examples are based on the directory structure below where the `eclipse-builder.sh` script, the P2 Director and the configuration files are located in the same directory.

    /home/me/my-eclipse-build/
      |- eclipse/
      |   |- ...
      |   |- features/
      |   |- plugins/
      |   |- ...
      |   |- eclipse
      |   |- ...
      |
      |- configuration-1.conf
      |- configuration-2.conf
      |- eclipse-builder.sh


#### Example 1: Create an eclipse distribution as described in `configuration-1.conf` for Linux:
This command will create the Eclipse distribution in `~/my-eclipse-build/distros/my-personal-eclipse-distribution-linux-gtk-x86_64`:

    cd /home/me/my-eclipse-build
    ./eclipse-builder.sh \
    --platform linux \
    --destination /home/me/my-eclipse-build/distros \
    --name my-personal-eclipse-distribution \
    configuration-1.conf
    
**Note that the `--destination` option requires a fully qualified path!** Relative paths won't work due to this [Bug](https://bugs.eclipse.org/bugs/show_bug.cgi?id=329619).


#### Example 2: Create Eclipse distributions for all supported platforms as described in both configuration files using local repositories:
This command will create Eclipse distributions for all three supported platforms in `~/my-eclipse-build/distros/my-personal-eclipse-distribution-<platform>`

    cd /home/me/my-eclipse-build
    ./eclipse-builder.sh \
    --local \
    --platform linux \
    --platform macosx \
    --platform windows \
    --destination /home/me/my-eclipse-build/distros \
    --name my-personal-eclipse-distribution \
    configuration-1.conf \
    configuration-2.conf


#### Example 3: Create an Eclipse distribution when the eclipse-builder.sh Script is in a different directory
Assuming that the `eclipse-builder.sh` script is in a different directory called `/home/me/eclipse-builder`, the `--p2command` has to be set to point to the executable of the P2 director application:

    cd /home/me/eclipse-builder
    ./eclipse-builder.sh \
    --p2command ../my-eclipse-build/eclipse/eclipse
    --platform linux \
    --destination /home/me/my-eclipse-build/distros \
    --name my-personal-eclipse-distribution \
    ../my-eclipse-build/configuration-1.conf


### Links
 - [P2 Director Documentation](http://help.eclipse.org/juno/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Fguide%2Fp2_director.html)
 - [Nexus P2 Repository Plugins](https://docs.sonatype.org/display/Nexus/Nexus+OSGi+Experimental+Features+-+P2+Repository+Plugin)