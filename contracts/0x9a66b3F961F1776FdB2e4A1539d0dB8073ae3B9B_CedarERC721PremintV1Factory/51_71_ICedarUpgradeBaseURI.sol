// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

interface ICedarUpgradeBaseURIV0 {
    /**
     *  @notice Lets the owner update base URI
     */
    function upgradeBaseURI(string calldata baseURI_) external;
}