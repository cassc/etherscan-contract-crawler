// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/interfaces/IDynamics.sol";

library DynamicsErrors {
    error InvalidScheduledDate(
        uint256 scheduledDate,
        uint256 minScheduledDate,
        uint256 maxScheduledDate
    );
    error InvalidExtCodeSize(address addr, uint256 codeSize);
    error DynamicValueNotFound(uint256 epoch);
    error InvalidAliceNetNodeHash(bytes32 sentHash, bytes32 currentHash);
    error InvalidAliceNetNodeVersion(CanonicalVersion newVersion, CanonicalVersion current);
}