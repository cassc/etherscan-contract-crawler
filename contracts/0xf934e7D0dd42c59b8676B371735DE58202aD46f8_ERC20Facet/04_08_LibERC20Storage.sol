// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library LibERC20Storage {
  bytes32 constant ERC_20_STORAGE_POSITION = keccak256(
    // Compatible with pie-smart-pools
    "com.voxelville.erc20.storage"
  );

  struct ERC20Storage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
  }

  function erc20Storage() internal pure returns (ERC20Storage storage es) {
    bytes32 position = ERC_20_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}