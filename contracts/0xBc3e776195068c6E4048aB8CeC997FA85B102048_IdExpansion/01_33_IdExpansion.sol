// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../../zone/tlds/Ape.sol";
import "../../registrar/Expansion.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IdExpansion is Expansion, Ownable {
  event CampaignAdded(bytes32 indexed _projectDomain, ERC721 _campaign);
  event CampaignRemoved(bytes32 indexed _projectDomain);

  mapping (bytes32 => ERC721) private campaigns;

  constructor(ApeZone zone) 
  Expansion(
    zone
  )
  {}

  function addCampaign(ERC721 _campaign, bytes32 _projectDomain) public onlyOwner {
    campaigns[_projectDomain] = _campaign;
    emit CampaignAdded(_projectDomain, _campaign);
  }

  function removeCampaign(bytes32 _projectDomain) public onlyOwner {
    delete campaigns[_projectDomain];
    emit CampaignRemoved(_projectDomain);
  }

  function claim(uint256 _tokenId, bytes32 _projectDomain) public returns(bytes32 namehash){
    require(address(campaigns[_projectDomain]) != address(0), "campaign must be registered");
    string memory _label = Strings.toString(_tokenId);
    namehash = _claimSubdomain(campaigns[_projectDomain].ownerOf(_tokenId), _label, _projectDomain);
  }
}