// contracts/ApiProxy.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockUpdaterProxy is ERC1967Proxy, Ownable {
    constructor (address implementation, bytes memory initData) ERC1967Proxy(
        implementation,
        initData
    ) {}

    function upgradeTo(address newImplementation) external onlyOwner {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    function upgradeToAndCall(address newImplementation, bytes calldata initData) external onlyOwner {
        _upgradeToAndCall(newImplementation, initData, true);
    }

    function implementation() external view returns (address) {
        return _implementation();
    }
}