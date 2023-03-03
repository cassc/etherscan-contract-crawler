// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IProxyBotRenderer.sol";
import "./ProxyBotConfig.sol";
import "./IProxyBot.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// This renders the Proxy Tokens, swappable as future requirements dictate.
// The metadata for a token is all on-chain so it can immediately reflect the state of a token,
// but the images are off-chain. No need to get tricky with that here.
contract ProxyBotRenderer is Ownable {

  string public baseUri;
  string public description;
  string public title;
  address proxyBotContractAddress;

  constructor(address _proxyBotContractAddress, string memory _baseUri, string memory _title, string memory _description) {
    baseUri = _baseUri;
    description = _description;
    title = _title;
    proxyBotContractAddress = _proxyBotContractAddress;
  }  

  function updateDescription(string memory _description) public onlyOwner {
    description = _description;
  }

  function updateTitle(string memory _title) public onlyOwner {
    title = _title;
  }

  // A tokenURI method that returns on-chain JSON for all the metadata, plus the off-chain image itself.
  function tokenURI(uint256 _tokenId) external view returns (string memory) {

    IProxyBot proxyBot = IProxyBot(proxyBotContractAddress);
    
    uint256 mintedBlock = proxyBot.getMintedBlock(_tokenId);
    address coldWalletAddress = proxyBot.getVaultWallet(_tokenId);
    ProxyBotConfig.Status status = proxyBot.getStatus(_tokenId);
    (bool hasSpecialEdition, string memory editionLabel) = proxyBot.getAppliedSpecialEdition(_tokenId);

    string memory editionForJson = editionLabel;
    if(!hasSpecialEdition){
      editionForJson = 'default';
    }

    string memory json = Base64.encode(
      bytes(
        string.concat('{"name": "', title, ' #', Strings.toString(_tokenId) ,'", "description": "', description ,'", "image": "',
        imageForTokenID(_tokenId, status, hasSpecialEdition, editionLabel),
        '", "attributes": [{"trait_type": "Status", "value": "',
        ProxyBotConfig.prettyStatusOf(status), '"}, {"trait_type": "Vault ID", "value": "',
        Strings.toHexString(coldWalletAddress), '"}, {"trait_type": "Edition", "value": "',
        prettifySpecialEdition(editionForJson),
        '"}, {"display_type": "number", "trait_type": "Mint Block", "value": "',
        Strings.toString(mintedBlock),
        '"}]}')
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));        
  }

  // Given an internal label, returns a prettified version for display in the metadata.
  function prettifySpecialEdition(string memory rawName) pure public returns (string memory) {
    if(ProxyBotConfig.stringsEqual(rawName, 'beta')){
      return 'Beta';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'brokemon')){
      return 'Brokemon';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'def')){
      return 'DEF';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'fite')){
      return 'Fite';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'fps')){
      return 'FPS';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'gawds')){
      return 'GAWDS';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'guardian')){
      return 'Guardian';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'icewiz')){
      return 'Ice Wiz';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'kruton')){
      return 'Kruton';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'proxyBot_b')){
      return 'Proxybot Licorice';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'proxyBot_c')){
      return 'Proxybot Crystal';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'proxyBot_g')){
      return 'Proxybot Grey Plastic';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'proxyBot_go')){
      return 'Proxybot Gold';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'proxyBot_r')){
      return 'Proxybot Ruby';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'proxyBot_s')){
      return 'Proxybot Sludge';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'proxyBot_w')){
      return 'Proxybot Wood';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'prsh')){
      return 'PRSH';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'rnbwKtty')){
      return 'Rainbow Kitty';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'sheebQuest')){
      return 'Sheeb Quest';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'starX')){
      return 'StarX';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'toads')){
      return 'Toads';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'tomo')){
      return 'TomoBOTchi';
    } else if(ProxyBotConfig.stringsEqual(rawName, 'turf')){
      return 'Turf';
    } else {
      return 'Basic';
    }
  }

  // The image URL for a given token ID.
  // It's determined by the status of the ProxyBot token and whether it's got a special edition or not.
  function imageForTokenID(uint256 _tokenId, ProxyBotConfig.Status _status, bool _hasSpecialEdition, string memory _editionLabel) public view returns (string memory) {
    string memory baseImageName;

    if (_status == ProxyBotConfig.Status.Pending) {
      baseImageName = '0';
    } else if (_status == ProxyBotConfig.Status.Connected) {
      baseImageName = '1';
    } else {
      baseImageName = '2';
    }

    // Is there a special edition? If so we need it in the filename, otherwise just use the base image name.
    // It will be a blank string if there's no edition.
    string memory specialEdition = _editionLabel;
    if(_hasSpecialEdition){
      // Concat baseImageNAme with the special edition name string
      baseImageName = string(abi.encodePacked(specialEdition, '_', baseImageName));
    } else {
      baseImageName = string(abi.encodePacked('default_', baseImageName));
    }

    return string(abi.encodePacked(baseUri, baseImageName, '.gif'));
  }


}