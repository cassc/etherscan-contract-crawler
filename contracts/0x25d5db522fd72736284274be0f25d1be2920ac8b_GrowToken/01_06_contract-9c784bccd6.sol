// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GrowToken is ERC20, Ownable {
    address[] public holders;
    mapping(address => bool) public isHolder;

    constructor() ERC20("GROW", "GROW") {
        _mint(msg.sender, 100 * (10 ** uint256(decimals())));
        isHolder[msg.sender] = true;
        holders.push(msg.sender);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _addHolder(recipient);
        _mintRandomHolder(1 * (10 ** uint256(decimals())));
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _addHolder(recipient);
        _mintRandomHolder(1 * (10 ** uint256(decimals())));
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender,_msgSender()) - amount);
        return true;
    }

    function _addHolder(address holder) private {
        if (!isHolder[holder]) {
            isHolder[holder] = true;
            holders.push(holder);
        }
    }

    function _mintRandomHolder(uint256 amount) private {
        uint256 index = _random() % holders.length;
        _mint(holders[index], amount);
    }

    function _random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
}