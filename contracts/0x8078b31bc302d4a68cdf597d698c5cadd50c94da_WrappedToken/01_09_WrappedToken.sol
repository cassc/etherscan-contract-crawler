// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

abstract contract WrappedTokenStorage {
    // --------- IMMUTABLE ---------
}

contract WrappedToken is
    OwnableUpgradeable,
    ERC20BurnableUpgradeable,
    WrappedTokenStorage
{
    function initialize(
        address bridgeContract,
        string calldata name,
        string calldata symbol
    ) external initializer {
        _transferOwnership(bridgeContract);
        __ERC20_init(name, symbol);
    }

    function mint(address account, uint amount) external onlyOwner {
        _mint(account, amount);
    }

    function permitBurnFrom(address account, uint amount) external onlyOwner {
        _burn(account, amount);
    }
}