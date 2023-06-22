// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBProjects.sol';
import '../interfaces/IJBOperatorStore.sol';

/**
 * @notice A struct that contains all the components needed to validate permissions using JBOperatable.
 */
struct PermissionValidationComponents {
  IJBDirectory jbxDirectory;
  IJBProjects jbxProjects;
  IJBOperatorStore jbxOperatorStore;
}

struct CommonNFTAttributes {
  string name;
  string symbol;
  string baseUri;
  bool revealed;
  string contractUri;
  uint256 maxSupply;
  uint256 unitPrice;
  uint256 mintAllowance;
}