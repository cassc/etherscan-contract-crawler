// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./MintingMachine.sol";
import "../finance/Coinbox.sol";

abstract contract Token is IERC2981, MintingMachine, Coinbox {
  
  // ## Metadata configuration
  string public baseUri;
  string public PROVENANCE = "";

  constructor(
    string memory _baseUri,
    address[] memory _payees, 
    uint256[] memory _shares,
    uint64 _totalSupply, 
    uint64 _maxTokensPerMint,
    uint256 _salePrice, 
    uint256 _presalePrice,
    bool _saleActive,
    bool _presaleActive,
    address[] memory _presaleAddresses, 
    uint256[] memory _presaleClaims
  ) 
  Coinbox(_payees, _shares)
  MintingMachine(
    _totalSupply, 
    _maxTokensPerMint,
    _salePrice, 
    _presalePrice,
    _saleActive,
    _presaleActive,
    _presaleAddresses, 
    _presaleClaims
  ) {
    baseUri = _baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseUri;
  }

  function royaltyInfo(uint256, uint256) external view virtual override returns (address receiver, uint256 royaltyAmount) {
      return (address(this), 0);
  }

  function baseTokenURI() public view returns (string memory) {
    return baseUri; 
  }

  function balance() public view returns (uint256) {
    return address(this).balance;
  }

  function setProvenance(string memory _provenance) external onlyOwner {
    PROVENANCE = _provenance;
  }

  function setBaseUri(string memory baseUri_) external onlyOwner {
    baseUri = baseUri_;
  }
}