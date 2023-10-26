// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title Upgradeable Proxy for StakePad
 * @author Quantum3 Labs
 * @notice Serves as entry point for all functions inside stakePad contract
 */
contract StakePadUpgradeableProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}

    /**
     * @notice Returns the current implementation address
     */
    function implementation() public view returns (address) {
        return _implementation();
    }
}