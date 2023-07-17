// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AERC20.sol";
import "./AERC20Burnable.sol";
import "./Ownable.sol";
import "./IAntisnipe.sol";

contract SabaiToken is AERC20, AERC20Burnable, Ownable {

    constructor() AERC20("Sabai Ecoverse Token", "SABAI") {
        _mint(msg.sender, 1e18*2650000000);
    }
    
    function setAntisnipe(address value) external onlyOwner {
        _setAntisnipe(value);
    }

    function disableAntisnipe() external onlyOwner {
        _disableAntisnipe();
    }
}