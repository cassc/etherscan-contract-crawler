//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MGYERC721A.sol";

contract FLSERC721A is MGYERC721A{
  constructor (
      string memory _name,
      string memory _symbol
  ) MGYERC721A (_name,_symbol) {
  }
  //widraw ETH from this contract.only owner. 
  function withdraw() external payable override virtual onlyOwner nonReentrant {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    address wallet = payable(0xb6d2c79B1A65b9e20E8EEfd2B4eFB9b5F9Caae14);
    bool os;
    (os, ) = payable(wallet).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }


}