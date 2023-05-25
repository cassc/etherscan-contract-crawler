// SPDX-License-Identifier: MIT

//@dev Greed is Good

import "./ERC20.sol";
import "./Ownable.sol";

pragma solidity ^0.8.16;

contract GordonGecko is ERC20 , Ownable {
    uint private constant _numTokens = 300000000000000;


     constructor( address _lpWallet, address _ggWallet) ERC20() {
        _mint(_lpWallet, _numTokens * 10**18 * 920 / 1000);  
        _mint(_ggWallet, _numTokens * 10**18 * 80 / 1000); 
    }

    function name() public view virtual override returns (string memory) {
        return "GordonGecko";
    }

    function symbol() public view virtual override returns (string memory) {
        return "GG";
    }


}