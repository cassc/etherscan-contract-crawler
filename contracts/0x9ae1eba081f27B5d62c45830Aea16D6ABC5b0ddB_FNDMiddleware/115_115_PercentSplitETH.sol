// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/PercentSplitETH.sol";

contract $PercentSplitETH is PercentSplitETH {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_disableInitializers() external {
        return super._disableInitializers();
    }

    function $_getInitializedVersion() external view returns (uint8) {
        return super._getInitializedVersion();
    }

    function $_isInitializing() external view returns (bool) {
        return super._isInitializing();
    }
}