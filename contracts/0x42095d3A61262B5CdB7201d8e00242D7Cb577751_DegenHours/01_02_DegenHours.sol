// SPDX-License-Identifier: MIT

/*
 * ██████  ██████ ███████  ███████ ███    ██   ██   ██  ██████  ██    ██ ██████  ███████ 
 * ██   ██ ██     ██       ██      ████   ██   ██   ██ ██    ██ ██    ██ ██   ██ ██      
 * ██   ██ █████  ██   ███ █████   ██ ██  ██   ███████ ██    ██ ██    ██ ██████  ███████ 
 * ██   ██ ██     ██    ██ ██      ██  ██ ██   ██   ██ ██    ██ ██    ██ ██   ██      ██ 
 * ██████  ██████ ███████  ███████ ██   ████   ██   ██  ██████   ██████  ██   ██ ███████ 
 *
 * Don't let your bags keep you up all night
 *
 ****************************************
 * Only tradable during 22:00-04:00 UTC *
 ****************************************
 *
 * Inspired by TradFiLines 0x4d04bBA7f5eA45ac59769a1095762467B1157CC4
 *
 * Twitter - @DegenHoursCoin - don't expect anything, I have more important things to do
 *    in my life than running a twitter account for some random magic internet money.
 * Website - I could make one, but it would be ugly af and wtf am I going to put on there?
 * Telegram - No thank you very f'ing much.
 */

pragma solidity ^0.8.0;

import "solady/src/tokens/ERC20.sol";

error OutOfDegenHours();

contract DegenHours is ERC20 {
    uint256 constant TOTAL_SUPPLY = 42069000000 ether;

    constructor() {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function name() public pure override returns (string memory) {
        return "Degen Hours";
    }

    function symbol() public pure override returns (string memory) {
        return "DGHOUR";
    }

    function isWithinDegenHours() public view returns(bool) {
        uint256 hour = (block.timestamp % (24 * 60 * 60)) / (60 * 60);
        return (hour > 21 || hour < 4);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        if (!isWithinDegenHours()) revert OutOfDegenHours();
    }
}
// milady