// SPDX-License-Identifier: MIT
///.                                     ,--. 
///.    .--.--.   ,--,     ,--,        ,--.'| 
///.   /  /    '. |'. \   / .`|    ,--,:  : | 
///.  |  :  /`. / ; \ `\ /' / ; ,`--.'`|  ' : 
///.  ;  |  |--`  `. \  /  / .' |   :  :  | | 
///.  |  :  ;_     \  \/  / ./  :   |   \ | : 
///.   \  \    `.   \  \.'  /   |   : '  '; | 
///.    `----.   \   \  ;  ;    '   ' ;.    ; 
///     __ \  \  |  / \  \  \   |   | | \   | 
///.   /  /`--'  / ;  /\  \  \  '   : |  ; .' 
///.  '--'.     /./__;  \  ;  \ |   | '`--'   
///.    `--'---' |   : / \  \  ;'   : |       
///.             ;   |/   \  ' |;   |.'       
///.             `---'     `--` '---'   

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SXN is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 69696969 * 10 ** 18; // Community Requested Supply kek 

    constructor() ERC20("SXN", "SXN") {
        _mint(msg.sender, MAX_SUPPLY);
    }

// Block Jared fuck Jared XD
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(to!=0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13 && from!=0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13, "Blacklisted");
        require(to!=0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80 && from!=0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80, "Blacklisted");
        require(to!=0x77ad3a15b78101883AF36aD4A875e17c86AC65d1 && from!=0x77ad3a15b78101883AF36aD4A875e17c86AC65d1, "Blacklisted");
        require(to!=0x76F36d497b51e48A288f03b4C1d7461e92247d5e && from!=0x76F36d497b51e48A288f03b4C1d7461e92247d5e, "Blacklisted");
    }
}
// Stupid Simple but yo mamma love it