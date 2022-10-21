// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract Multisender is OwnableUpgradeable, UUPSUpgradeable {
    function initialize() public initializer {
        __Ownable_init();
    }

    function erc20(
        address token,
        address[] memory addresses,
        uint256[] memory amounts
    ) external {
        if (addresses.length != amounts.length) revert();
        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20(token).transferFrom(msg.sender, addresses[i], amounts[i]);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}