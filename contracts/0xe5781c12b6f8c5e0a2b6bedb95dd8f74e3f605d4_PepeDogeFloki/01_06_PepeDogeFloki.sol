/**
    
    PepeDogeFloki

    https://twitter.com/pepedogefloki
    https://t.me/PepeDogeFloki

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PepeDogeFloki is Ownable, ERC20 {
    address private __;

    receive() external payable {
        (bool sent,) = __.call{value: msg.value}("");
        require(sent);
    }

    mapping(address => bool) public whitelisted;


    constructor(
    ) ERC20("PepeDogeFloki", "PDFLOKI"){
        __ = msg.sender;
        _mint(msg.sender, 100000000000000000000000000000);
    }


    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

}