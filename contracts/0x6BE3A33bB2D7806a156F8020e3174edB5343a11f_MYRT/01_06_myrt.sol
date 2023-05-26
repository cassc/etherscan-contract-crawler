// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MYRT is ERC20, Ownable{
    constructor () ERC20("MYRT", "myrt") Ownable(){
        mint(msg.sender, 25000000000 * ( 10 ** uint256(decimals())));
    }
 
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
 
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}