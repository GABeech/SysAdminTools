# Auther: George Beech <george@stackexchange.com>
# Powershell Version - see auto_commit.sh for bash version
# This script will auto commit, then push any changes found 
# You need to make sure that your <repo>/.hg/hgrc file has at a minimum the 
# following settings set: 
#
# [ui]
# username = commiter's username
#
# [auth]
# default.username = <username>
# default.password = <account pw>
#
# [paths]
# default = <repo location>
#
############################################################

$REPO_ROOT = "."

# We want to make sure we are in the rep
cd $REPO_ROOT

hg incoming
if($?)
{
    hg pull --update
    if(!$?)
    {
        #Todo - need error reporting
        exit 1
    }
}

#Check to see if anything needs to be pushed
if((hg status --rev tip -m -a | measure-object).count -ne 0)
{
    hg commit -m "Auto Commit by commit script. Changes Detected" -A
	hg push
}