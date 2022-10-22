// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 
contract Token is ERC20, Ownable {
 
    constructor (uint256 initialSupply) public ERC20("Sloth Coin", "SLOTH") Ownable(){
        _mint(msg.sender, initialSupply);
    }
 
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
 
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
 
}