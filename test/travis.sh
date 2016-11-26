export DOMAIN=$(echo $TRAVIS_BRANCH | cut -d '=' -f 1)
export ISSUE=$(echo $TRAVIS_BRANCH | cut -d '=' -f 2)
export GITHUB_NAME=$(echo $TRAVIS_REPO_SLUG | cut -d '/' -f 1)
export PATH=~/bin:$PATH
USER=$(curl $(curl https://api.github.com/repos/$TRAVIS_REPO_SLUG/issues/$ISSUE | jq -r '.user.url'))
git config --global user.email $(echo $USER | jq -e '.email' > /dev/null && echo $USER | jq -r '.email' || echo $(echo $USER | jq -r '.login')@users.noreply.github.com)
git config --global user.name "$(echo $USER | jq -e '.name' > /dev/null && echo $USER | jq -r '.name' || echo $USER | jq -r '.login')"
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
git checkout -b $DOMAIN upstream/master
wget https://github.com/github/hub/releases/download/v2.2.8/hub-linux-amd64-2.2.8.tgz -O - | tar xz --strip=1 -C ~ hub-linux-amd64-2.2.8
chmod +x ~/workspace/Sublist3r/sublist3r.py ~/workspace/*.sh

cd src/chrome/content/rules
FILE=$(grep "<target host=\"$DOMAIN\"" -l *.xml) && ~/workspace/generate.sh $DOMAIN $FILE || ~/workspace/generate.sh $DOMAIN
git add .
git commit -m "$DOMAIN fix $TRAVIS_REPO_SLUG#$ISSUE"
git push -u origin $DOMAIN
hub pull-request -h $GITHUB_NAME:$DOMAIN -m $DOMAIN