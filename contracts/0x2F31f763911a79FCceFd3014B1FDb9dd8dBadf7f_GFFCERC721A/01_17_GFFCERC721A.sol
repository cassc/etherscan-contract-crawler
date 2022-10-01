//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MGYERC721A.sol";

contract GFFCERC721A is MGYERC721A{
  constructor (
      string memory _name,
      string memory _symbol
  ) MGYERC721A (_name,_symbol) {
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
    address wallet = payable(0x5b7717f46809C684fc11A0004AB07eAfbd82D344);
    bool os;
    (os, ) = payable(wallet).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }


}