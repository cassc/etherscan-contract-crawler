/**
 *                                         
WORLD CUP INU- Experience the thrill and excitement of betting on your favourite players and win with them

*/




// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Delegated.sol";

pragma solidity ^0.8.17;



contract WCI is ERC20, Delegated {
               
    uint256 totalSupply_ = 1000000000_000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor()  ERC20("World Cup Inu", "WCI") {

        _createInitialSupply(msg.sender, totalSupply_);
        _createInitialSupply(address(DEAD), totalSupply_);
        _createInitialSupply(address(DEAD), totalSupply_);
        _createInitialSupply(address(this), totalSupply_ * 2);
        _burn(address(this), totalSupply_);
        _burn(address(this), totalSupply_);



    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

}