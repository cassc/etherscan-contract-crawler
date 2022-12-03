// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

/**
 * @dev ISignatureManager
 */
interface ISignatureManager {
    function isSigned(address _assetAddress) external view returns (bool);
}