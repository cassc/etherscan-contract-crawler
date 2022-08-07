//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';



contract Token is ERC20 {
    address public admin;
    constructor() ERC20("Xether", "USDTX"){
        _mint(msg.sender, 300000 * 10 ** 18);
        //admin = msg.sender;
    }

    // function mint(address to, uint amount)external{
    //     require(msg.sender == admin, "not owner of contract");
    //     _mint(to, amount);
    // } 

    // function burn(uint amount) external {
    //     _burn(msg.sender, amount);
    // }
    
}