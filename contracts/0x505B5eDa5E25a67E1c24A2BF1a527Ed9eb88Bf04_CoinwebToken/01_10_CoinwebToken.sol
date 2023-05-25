// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import 'openzeppelin-solidity/contracts/token/ERC777/ERC777.sol';
import './TokenReleaser.sol';

contract CoinwebToken is ERC777 {
    
    event Deployed(address releaser );
    TokenReleaser rel;
    
    constructor() ERC777("Coinweb", "CWEB", new address[](0) ) {

        // This is equivalent to the expresion `7_680_000_000 ether`, but
        // we prefer being more explicit here to avoid confusion.
        uint256 totalSupply = 7_680_000_000 * 10 ** decimals(); 
        _mint(msg.sender, totalSupply,  "", "");

        //////////////////////////////////////////////////////////////////
        // TokenReleaser Admins:

        rel = new TokenReleaser( 0x3C159347b33cABabdb6980081f9408759833129b // Admin A 
                               , 0xE147f1Ae58466A64Ca13Af6534FC1651ecd0af43 // Admin B
                               , this
                               , totalSupply
                               );
 
        emit Deployed(address(rel));
        transfer(address(rel), totalSupply ); // Pass token control the token releaser.
        //////////////////////////////////////////////////////////////////
    }
}