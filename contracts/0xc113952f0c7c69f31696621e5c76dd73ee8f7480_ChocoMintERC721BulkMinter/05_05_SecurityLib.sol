// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SecurityLib {
  struct SecurityData {
    uint256 validFrom;
    uint256 validTo;
    uint256 salt;
  }

  bytes32 private constant _SECURITY_TYPEHASH =
    keccak256(abi.encodePacked("SecurityData(uint256 validFrom,uint256 validTo,uint256 salt)"));

  function validate(SecurityData memory securityData) internal view returns (bool, string memory) {
    if (securityData.validFrom > block.timestamp) {
      return (false, "SecurityLib: valid from verification failed");
    }

    if (securityData.validTo < block.timestamp) {
      return (false, "SecurityLib: valid to verification failed");
    }
    return (true, "");
  }

  function hashStruct(SecurityData memory securityData) internal pure returns (bytes32) {
    return keccak256(abi.encode(_SECURITY_TYPEHASH, securityData.validFrom, securityData.validTo, securityData.salt));
  }
}