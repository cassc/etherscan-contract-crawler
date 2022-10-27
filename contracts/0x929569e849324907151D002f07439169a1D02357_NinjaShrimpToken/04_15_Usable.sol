// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBreedable.sol";

abstract contract Usable is Ownable {
  IBreedable public nftContract;

  function setNFTContract(address _ninjaShrimps) external onlyOwner {
    nftContract = IBreedable(_ninjaShrimps);
  }
}