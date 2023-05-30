// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

abstract contract TunnelEnabled {
    mapping(address => bool) public whitelistTunnelAddresses;

    modifier onlyTunnel() {
        require(
            whitelistTunnelAddresses[msg.sender],
            "Not called from the tunnel"
        );
        _;
    }
}