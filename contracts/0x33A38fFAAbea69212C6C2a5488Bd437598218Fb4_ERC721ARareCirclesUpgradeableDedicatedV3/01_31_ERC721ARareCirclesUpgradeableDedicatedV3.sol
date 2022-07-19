// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721ARareCirclesUpgradeableDedicated.sol";

contract ERC721ARareCirclesUpgradeableDedicatedV3 is ERC721ARareCirclesUpgradeableDedicated {
    string public version;

    function setVersion(string memory newVersion) external {
        version = newVersion;
    }
}