// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Shroom is Ownable, ERC20 {
    bool public transferable = false;
    uint256 public constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    mapping(address => bool) private _shroomBanks;

    constructor() ERC20('Shroom', 'SHRM') {}

    function mint(address to, uint256 quantity) public onlyShroomBank {
        _mint(to, quantity);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        if (_shroomBanks[spender]) {
            return MAX_INT;
        }

        return super.allowance(owner, spender);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (!_shroomBanks[_msgSender()]) {
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
        if (_msgSender() != owner() && !_shroomBanks[_msgSender()]) {
            require(transferable, 'Cannot transfer if false');
        }
        super._beforeTokenTransfer(from, to, amount);  
    }

    function addShroomBank(address shroomBank) public onlyOwner {
        _shroomBanks[shroomBank] = true;
    }

    function removeShroomBank(address shroomBank) public onlyOwner {
        _shroomBanks[shroomBank] = false;
    }

    function setTransferable(bool _transferable) public onlyOwner {
        transferable = _transferable;
    }

    modifier onlyShroomBank() {
        require(_shroomBanks[_msgSender()], 'Caller is not an approved shroom bank');
        _;
    }
}