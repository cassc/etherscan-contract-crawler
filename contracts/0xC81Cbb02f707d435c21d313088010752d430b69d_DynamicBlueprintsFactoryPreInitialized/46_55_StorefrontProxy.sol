// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

/**
 * @title Modifying OpenZeppelin's ERC1967Proxy to use UUPS
 * @author Ohimire Labs and OpenZeppelin Labs
 * @notice Implements an upgradeable proxy. OpenZeppelin template edited by Ohimire Labs
 */
contract StorefrontProxy is Proxy, ERC1967Upgrade {
    /**
     * @notice Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCallUUPS(_logic, _data, false);
    }

    /**
     * @notice Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}