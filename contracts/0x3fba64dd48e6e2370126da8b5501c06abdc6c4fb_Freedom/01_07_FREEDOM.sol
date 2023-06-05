/**

░░░░░░░░░░░░░░░░░░░░░░░░██░░░░██░░░░░██████░░░░░░░░███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░██░░░░██░░░░██░░░░░░░░░░░░██░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░██░░░░██░░░░░██████░░░░░░██░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░██░░░░██░░░░░░░░░░██░░░░██████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░██████░░░░██░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░███████░░░░███████░░░░██████░░░░██████░░░░███████░░░░░░░░████░░░░░░███░░░░░░░░███░░░░
░░░░██░░░░░░░░░██░░░░██░░░██░░░░░░░░██░░░░░░░░██░░░░░██░░░░██░░░░██░░░░██░█░░░░░░█░██░░░░
░░░░███████░░░░███████░░░░██████░░░░██████░░░░██░░░░░██░░░░██░░░░██░░░░██░░█░░░░█░░██░░░░
░░░░██░░░░░░░░░██░██░░░░░░██░░░░░░░░██░░░░░░░░██░░░░░██░░░░██░░░░██░░░░██░░░█░░█░░░██░░░░
░░░░██░░░░░░░░░██░░░██░░░░██████░░░░██████░░░░███████░░░░░░░░████░░░░░░██░░░░██░░░░██░░░░

Telegram :t.me/FREEDOMEUSA

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Freedom is ERC20, Ownable, ERC20Burnable {
    uint256 private constant MAX_SUPPLY = 1000000000000 * 10**18;
    uint256 private constant TAX_THRESHOLD = 15;
    uint256 private constant TAX_PERCENTAGE = 15;

    mapping(address => uint256) private _trades;

    constructor() ERC20("Freedom", "USA") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_trades[msg.sender] < TAX_THRESHOLD) {
            uint256 tax = (amount * TAX_PERCENTAGE) / 100;
            _transfer(msg.sender, owner(), tax);
            amount -= tax;
        }
        _trades[msg.sender]++;
        if (_trades[msg.sender] == TAX_THRESHOLD) {
            _trades[msg.sender] = 0;
        }
        _transfer(msg.sender, recipient, amount);
        return true;
    }
}