// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IPlatformFeeConfigV0 {
    event PlatformFeesUpdated(address platformFeeReceiver, uint16 platformFeeBPS);

    function getPlatformFees() external view returns (address platformFeeReceiver, uint16 platformFeeBPS);

    function setPlatformFees(address _newPlatformFeeReceiver, uint16 _newPlatformFeeBPS) external;
}