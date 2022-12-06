// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

bytes32 constant UpgradeableProxyCodeHash = 0xfc1ea81db44e2de921b958dc92da921a18968ff3f3465bd475fb86dd1af03986;

library UpgradeableProxyChecker {
    function isProxy() internal view returns (bool) {
        return keccak256(address(this).code) == UpgradeableProxyCodeHash;
    }
}