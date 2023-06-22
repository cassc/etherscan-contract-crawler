//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainScouts.sol";

abstract contract ChainScoutsExtension {
    IChainScouts internal chainScouts;
    bool public enabled = true;

    modifier canAccessToken(uint tokenId) {
        require(chainScouts.canAccessToken(msg.sender, tokenId), "ChainScoutsExtension: you don't own the token");
        _;
    }

    modifier onlyAdmin() {
        require(chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: admins only");
        _;
    }

    modifier whenEnabled() {
        require(enabled, "ChainScoutsExtension: currently disabled");
        _;
    }

    function adminSetEnabled(bool e) external onlyAdmin {
        enabled = e;
    }

    function extensionKey() public virtual view returns (string memory);

    function setChainScouts(IChainScouts _contract) external {
        require(address(0) == address(chainScouts) || chainScouts.isAdmin(msg.sender), "ChainScoutsExtension: The Chain Scouts contract must not be set or you must be an admin");
        chainScouts = _contract;
        chainScouts.adminSetExtension(extensionKey(), this);
    }
}