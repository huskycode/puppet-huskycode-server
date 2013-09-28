sudo apt-get -y install git

curl -o /tmp/puppetlabs-release-precise.deb http://apt.puppetlabs.com/puppetlabs-release-precise.deb
sudo dpkg -i /tmp/puppetlabs-release-precise.deb
sudo apt-get update

sudo apt-get -y install puppet

echo "Installing librarian-puppet, this might take a while..."
sudo apt-get -y install rubygems
sudo gem install librarian-puppet
librarian-puppet install --verbose

echo "Install gpg"
sudo apt-get -y install gnupg
gem install hiera-gpg

echo "*************************************"
echo "At this point, set up pgp private key for 'Huskycode Deploy <deploy@huskycode.com>'"
echo "*************************************"

