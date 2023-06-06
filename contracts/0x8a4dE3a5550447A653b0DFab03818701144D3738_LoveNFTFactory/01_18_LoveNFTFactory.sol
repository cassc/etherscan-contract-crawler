// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import './LoveNFT.sol';

contract LoveNFTFactory {
  mapping(address => address[]) private nfts;

  mapping(address => bool) private loveNFT;

  event CreatedNFTCollection(address creator, address nft, string name, string symbol, string properties);

  function createNFTCollection(
    string memory _name,
    string memory _symbol,
    string memory _propertiesURL,
    uint96 _royaltyFeeFraction,
    address _royaltyRecipient
  ) external {
    LoveNFT nft = new LoveNFT(_name, _symbol, _propertiesURL, msg.sender, _royaltyFeeFraction, _royaltyRecipient);
    nfts[msg.sender].push(address(nft));
    loveNFT[address(nft)] = true;
    emit CreatedNFTCollection(msg.sender, address(nft), _name, _symbol, _propertiesURL);
  }

  function getOwnCollections() external view returns (address[] memory) {
    return nfts[msg.sender];
  }

  function isLoveNFT(address _nft) external view returns (bool) {
    return loveNFT[_nft];
  }
}