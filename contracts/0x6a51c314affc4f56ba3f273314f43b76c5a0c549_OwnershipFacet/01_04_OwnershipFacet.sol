// 2023, ApeFathers NFT
// GSKNNFT Inc
// Contract name: OwnershipFacet.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
  function owner() external view returns (address owner_) {
    return LibDiamond.contractOwner();
  }

  function transferOwnership(address _newOwner) external {
    LibDiamond.enforceIsContractOwner();
    LibDiamond.setContractOwner(_newOwner);
  }
}