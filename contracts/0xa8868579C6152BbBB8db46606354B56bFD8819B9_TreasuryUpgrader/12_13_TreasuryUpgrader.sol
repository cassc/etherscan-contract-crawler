// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./UpgraderBase.sol";

contract TreasuryUpgrader is UpgraderBase {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function _calls() internal pure override returns (bytes[] memory calls) {}

    function _checkResults(bytes[] memory _beforeResults, bytes[] memory _afterResults) internal pure override {}
}