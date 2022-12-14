//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./MGYERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TCSERC721A is DefaultOperatorFilterer,MGYERC721A{
  constructor (
      string memory _name,
      string memory _symbol
  ) MGYERC721A (_name,_symbol) {
    _extension = ".json";
  }
  //disabled
  function setSBTMode(bool) external virtual override onlyOwner {
    isSBTEnabled = false;
  }
  //widraw ETH from this contract.only owner.  
  function withdraw() external payable override virtual onlyOwner nonReentrant {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    address wallet = payable(0xAd199DFd0D765418961a334de6337A34F2626740);
    bool os;
    (os, ) = payable(wallet).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
  //for Opensea  
  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override(ERC721A,IERC721A)
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }


}