// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RollBitPepe is ERC20 ,ERC20Burnable, Ownable {

      constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(0x02D345Aadc4e355664cF67d640a0C9f457931100, initialSupply);
        transferOwnership(initialOwner);
    }
      function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }


       function changeOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }
}