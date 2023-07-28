// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @title Proxy admin of the protocol
 */
contract UnitasProxyAdmin is ProxyAdmin {
    /**
     * @notice Initializes the contract with changing owner
     * @dev The constructor of `Ownable` will transfer ownership to `msg.sender` first,
     *      transfers ownership to `owner_` when it is not the same as the caller.
     */
    constructor(address owner_) {
        if (owner_ != owner()) {
            _transferOwnership(owner_);
        }
    }
}