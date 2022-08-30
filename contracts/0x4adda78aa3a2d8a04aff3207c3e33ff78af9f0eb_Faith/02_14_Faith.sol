// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Faith is Ownable, ERC20 {
    bool public transferable = false;

    uint256 private constant MAX_INT = type(uint256).max;

    mapping(address => bool) private __faithBanks;

    constructor() ERC20('Faith', 'FAITH') {}

    function mint(address to, uint256 quantity) public onlyFaithBank {
        _mint(to, quantity);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        if (__faithBanks[spender]) {
            return MAX_INT;
        }

        return super.allowance(owner, spender);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (!__faithBanks[_msgSender()]) {
            uint256 currentAllowance = allowance(sender, _msgSender());
            require(currentAllowance >= amount, 'Transfer amount exceeds allowance');
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (_msgSender() != owner() && !__faithBanks[_msgSender()]) {
            require(transferable, 'Cannot transfer if false');
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function addFaithBank(address faithBankAddress) public onlyOwner {
        __faithBanks[faithBankAddress] = true;
    }

    function removeFaithBank(address faithBankAddress) public onlyOwner {
        __faithBanks[faithBankAddress] = false;
    }

    function setTransferable(bool transferable_) public onlyOwner {
        transferable = transferable_;
    }

    modifier onlyFaithBank() {
        require(__faithBanks[_msgSender()], 'Caller is not an approved faith bank');
        _;
    }
}