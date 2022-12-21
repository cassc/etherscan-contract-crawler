// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DuetTransparentUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

    /**
     * @dev override parent behavior to manage bonds fully in Factory
     *
     */
    function _beforeFallback() internal virtual override {}
}