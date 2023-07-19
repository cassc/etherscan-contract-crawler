// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

library SismoConnectHelper {
  error AuthTypeNotFoundInVerifiedResult(AuthType authType);

  function getUserId(
    SismoConnectVerifiedResult memory result,
    AuthType authType
  ) internal pure returns (uint256) {
    // get the first userId that matches the authType
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        return result.auths[i].userId;
      }
    }
    revert AuthTypeNotFoundInVerifiedResult(authType);
  }

  function getUserIds(
    SismoConnectVerifiedResult memory result,
    AuthType authType
  ) internal pure returns (uint256[] memory) {
    // get all userIds that match the authType
    uint256[] memory userIds = new uint256[](result.auths.length);
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        userIds[i] = result.auths[i].userId;
      }
    }
    return userIds;
  }

  function getSignedMessage(
    SismoConnectVerifiedResult memory result
  ) internal pure returns (bytes memory) {
    return result.signedMessage;
  }
}