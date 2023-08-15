// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SecurityLib.sol";
import "./HashLib.sol";

library DeployLib {
  struct DeployData {
    SecurityLib.SecurityData securityData;
    address deployer;
    address implementation;
    bytes[] data;
  }

  bytes32 private constant _DEPLOY_TYPEHASH =
    keccak256(
      bytes(
        "DeployData(SecurityData securityData,address deployer,address implementation,bytes[] data)SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"
      )
    );

  function hashStruct(DeployData memory deployData) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _DEPLOY_TYPEHASH,
          SecurityLib.hashStruct(deployData.securityData),
          deployData.deployer,
          deployData.implementation,
          HashLib.hashBytesArray(deployData.data)
        )
      );
  }
}