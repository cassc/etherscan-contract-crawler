// SPDX-License-Identifier: GPL-3.0

/*
                __                .__    .__ 
 ___.__._____  |  | ____ __  _____|  |__ |__|
<   |  |\__  \ |  |/ /  |  \/  ___/  |  \|  |
 \___  | / __ \|    <|  |  /\___ \|   Y  \  |
 / ____|(____  /__|_ \____//____  >___|  /__|
 \/          \/     \/          \/     \/    

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20{
    constructor() ERC20("Yakushi Nyorai", "YAKUSHI"){
        _mint(msg.sender,1000000000*10**18);
    }
}