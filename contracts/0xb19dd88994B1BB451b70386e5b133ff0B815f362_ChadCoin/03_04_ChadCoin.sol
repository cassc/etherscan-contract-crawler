// SPDX-License-Identifier: MIT
/**
 *
 * _________ .__                .___           .__
 * \_   ___ \|  |__ _____     __| _/____  ____ |__| ____
 * /    \  \/|  |  \\__  \   / __ |/ ___\/  _ \|  |/    \
 * \     \___|   Y  \/ __ \_/ /_/ \  \__(  <_> )  |   |  \
 *  \______  /___|  (____  /\____ |\___  >____/|__|___|  /
 *         \/     \/     \/      \/    \/              \/
 */

pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IRouter} from "./interfaces/IRouter.sol";

/// @notice The chaddest of all coins
contract ChadCoin is ERC20, Owned {
    ///@notice Flag to check if first time liqudiity is added to all dexes
    bool public initialized = false;
    uint256 public marketing_share = 10;

    constructor() payable ERC20("ChadCoin", "CHAD", 18) Owned(msg.sender) {
        uint256 total_supply = 694206942069420 ether;
        uint256 marketing = total_supply * marketing_share / 100;
        _mint(address(this), total_supply - marketing);
        _mint(address(msg.sender), marketing);
    }

    ///@notice This function lists all tokens owned by this contract equally into all pools for an equal amount of ETH
    ///@dev Registers the exchange address registry. All transfers to that address will burn 5% to the burn address;
    function addLiquidityETHToAllV2(address[] memory addresses) public payable onlyOwner {
        require(!initialized, "Can only call when not initialized");
        uint256 amount = balanceOf[address(this)] / addresses.length;
        for (uint8 i = 0; i < addresses.length; i++) {
            allowance[address(this)][addresses[i]] = amount;
            IRouter router = IRouter(addresses[i]);
            router.addLiquidityETH{value: msg.value / addresses.length}(
                address(this), amount, amount, msg.value / addresses.length, msg.sender, block.timestamp + 15
            );
            initialized = true;
        }
    }
}