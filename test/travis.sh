export PATH=~/bin:$PATH
USER=$(curl -H "Authorization: token $GITHUB_TOKEN" 'https://api.github.com/user')
#GITHUB_NAME=$(echo $USER | jq -r '.login')
git config --global user.email $(echo $USER | jq -e '.email' > /dev/null && echo $USER | jq -r '.email' || echo $(echo $USER | jq -r '.login')@users.noreply.github.com)
git config --global user.name "$(echo $USER | jq -e '.name' > /dev/null && echo $USER | jq -r '.name' || echo $USER | jq -r '.login')"
echo -e "machine github.com\nlogin $GITHUB_TOKEN\npassword x-oauth-basic" >> ~/.netrc
mkdir ~/.config || true
echo -e "---\ngithub.com:\n- oauth_token: $GITHUB_TOKEN\n  user: $GITHUB_NAME" >> ~/.config/hub

wget https://github.com/galeksandrp/https-everywhere/archive/check-sublist3r.tar.gz -O - | tar xz
mv https-everywhere-check-sublist3r ~/workspace
wget https://github.com/aboul3la/Sublist3r/archive/master.tar.gz -O - | tar xz
mv Sublist3r-master ~/workspace/Sublist3r
git remote add upstream https://github.com/EFForg/https-everywhere.git
git remote add fork https://github.com/$GITHUB_NAME/https-everywhere.git
checkoutBranch(){
    git show fork/$DOMAIN:test/fetch.sh > /dev/null || (git fetch --unshallow fork $DOMAIN && git fetch upstream master)
    git checkout -b $DOMAIN fork/$DOMAIN
    git show fork/$DOMAIN:test/fetch.sh > /dev/null || (git rebase upstream/master && FORCE='-f')
}
git fetch --depth=50 fork $DOMAIN && checkoutBranch || (git fetch --depth=50 upstream master && git checkout -b $DOMAIN upstream/master)
wget https://github.com/github/hub/releases/download/v2.2.8/hub-linux-amd64-2.2.8.tgz -O - | tar xz --strip=1 -C ~ hub-linux-amd64-2.2.8
chmod +x ~/workspace/Sublist3r/sublist3r.py ~/workspace/*.sh

cd src/chrome/content/rules
FILE=$(grep "<target host=\"$DOMAIN\"" -l *.xml) || FILE=$DOMAIN.xml
~/workspace/generate.sh $DOMAIN "$FILE" || exit 1
if [ $(xmllint --xpath 'count(//target)' "$FILE") -eq 0 ]; then
  exit 1
fi
git add "$FILE"
git commit -m $DOMAIN
git push $FORCE -u fork $DOMAIN
echo $DOMAIN > ~/pr.txt
echo '' >> ~/pr.txt
echo Issue author: @$(echo $USER | jq -r '.login') >> ~/pr.txt
if [ $ISSUE -ne 2 ]; then hub pull-request -h $GITHUB_NAME:$DOMAIN -F ~/pr.txt; fi