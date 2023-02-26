// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Solderse is ERC20, Ownable {
    constructor(uint256 initial_supply) ERC20("Solderse", "SOLD") {
        _mint(msg.sender, initial_supply * 10 ** uint(decimals()));
    }

    function toMint(uint256 _amount) public onlyOwner {
        _mint(msg.sender, _amount);
    }

    function toBurn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}