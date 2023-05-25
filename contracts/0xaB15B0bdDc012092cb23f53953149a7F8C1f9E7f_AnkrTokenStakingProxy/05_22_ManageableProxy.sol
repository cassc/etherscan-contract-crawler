// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../interfaces/IGovernable.sol";

abstract contract ManageableProxy is ERC1967Proxy {

    constructor(IGovernable governable, address defaultVersion, bytes memory inputData) ERC1967Proxy(defaultVersion, inputData) {
        _changeAdmin(address(governable));
    }

    function getCurrentVersion() public view returns (address) {
        return _implementation();
    }

    modifier onlyFromGovernance() {
        require(msg.sender == IGovernable(_getAdmin()).getGovernanceAddress(), "ManageableProxy: only governance");
        _;
    }

    function upgradeToAndCall(address impl, bytes memory data) external onlyFromGovernance {
        _upgradeToAndCall(impl, data, false);
    }
}