export DOMAIN=${TRAVIS_BRANCH::${#TRAVIS_BRANCH}-5}
git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_NAME
echo -e "machine github.com\nlogin $GITHUB_NAME\npassword $GITHUB_TOKEN" >> ~/.netrc
mkdir ~/.config || true
echo -e "---\ngithub.com:\n- oauth_token: $GITHUB_TOKEN\n  user: $GITHUB_NAME" >> ~/.config/hub

wget https://github.com/galeksandrp/https-everywhere/archive/check-sublist3r.tar.gz -O - | tar xz
mv https-everywhere-check-sublist3r ~/workspace
wget https://github.com/aboul3la/Sublist3r/archive/master.tar.gz -O - | tar xz
mv Sublist3r-master ~/workspace/Sublist3r
git remote add upstream https://github.com/EFForg/https-everywhere.git
git remote set-url origin https://github.com/$GITHUB_NAME/https-everywhere.git
git fetch upstream master
git checkout -b master upstream/master
wget https://github.com/github/hub/releases/download/v2.2.8/hub-linux-amd64-2.2.8.tgz -O - | tar xz --strip=1 -C ~ hub-linux-amd64-2.2.8
export PATH=~/bin:$PATH
chmod +x ~/workspace/Sublist3r/sublist3r.py ~/workspace/*.sh

cd src/chrome/content/rules
~/workspace/generate.sh $DOMAIN
git add $DOMAIN.xml
git commit -m $DOMAIN
git push -u origin $DOMAIN
