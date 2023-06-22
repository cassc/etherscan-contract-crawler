// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoTekERC20 is ERC20, Ownable {

    constructor() ERC20("GPlus", "GPlus") {}

    mapping(address => Transaction[]) public transactions;

    struct Transaction {
        address from;
        address to;
        uint256 amount;
        uint256 time;
    }

    function mint(address owner, uint256 amount) public {
        _mint(owner, amount);
        Transaction memory transaction = Transaction(msg.sender, owner, amount, block.timestamp);
        transactions[owner].push(transaction);
    }

    /*function transfer(
         address from,
         address to,
         uint256 amount
     ) public {
         allowance(from, to);
         transferFrom(from, to, amount);
         Transaction memory transaction = Transaction(from, to, amount, block.timestamp);
         transactions[from].push(transaction);
         transactions[to].push(transaction);
     }*/

    function burn(address owner, uint256 amount) public {
        _burn(owner, amount);
        Transaction memory transaction = Transaction(owner, msg.sender, amount, block.timestamp);
        transactions[owner].push(transaction);
    }

    function getTransaction(address owner) public view returns (Transaction[] memory){
        return transactions[owner];
    }

}