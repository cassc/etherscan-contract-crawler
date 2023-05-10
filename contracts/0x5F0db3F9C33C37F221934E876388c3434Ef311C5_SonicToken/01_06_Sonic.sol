//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
 * Website: https://www.sonic.band
 * Telegram: https://t.me/+9JxmdnvNxLlkMTg0
 * Once upon a time, there was a blue blur with an insatiable appetite for adventure and memes. His name was Sonic, but he wasn't your typical hero. No, Sonic had a degen side that set him apart from the rest. His ultimate goal? Discovering and collecting all the glorious memes coins scattered throughout the universe.
 */
contract SonicToken is Ownable, ERC20 {
    constructor(uint256 _totalSupply) ERC20("SonicBand", "SONIC") {
        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}