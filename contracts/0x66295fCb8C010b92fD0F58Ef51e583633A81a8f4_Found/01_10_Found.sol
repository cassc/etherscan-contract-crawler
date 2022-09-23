// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./Brachistochrone.sol";
import "./Token.sol";

contract Found is Brachistochrone, Token {
    event Mint(address indexed to, uint value, uint found);

    function mint(address to) external payable {
        require(msg.value > 0, "Send more than 0");
        uint amount = consume(msg.value);
        
        _addValue(msg.value);
        _mintToken(to, amount);
 
        emit Mint(to, msg.value, amount);
    }

    constructor(address origin_, uint lightning_) 
    Token("FOUND", "FOUND", origin_)
    Brachistochrone(lightning_) {}
}