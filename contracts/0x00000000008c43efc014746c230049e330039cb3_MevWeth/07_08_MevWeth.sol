// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.6;

import {WETH10} from "./WETH10Mod.sol";
import {IMevWeth} from "./IMevWeth.sol";

contract MevWeth is WETH10, IMevWeth {
    uint256 public override mev;

    function addMev(uint256 value) external override {
        // _burnFrom(msg.sender, value);
        uint256 balance = balanceOf[msg.sender];
        require(balance >= value, "WETH: burn amount exceeds balance");
        balanceOf[msg.sender] = balance - value;
        emit Transfer(msg.sender, address(this), value);
        // add mev
        mev += value;
    }

    function addMev(address from, uint256 value) external override {
        if (from != msg.sender) {
            // _decreaseAllowance(from, msg.sender, value);
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(allowed >= value, "WETH: request exceeds allowance");
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }
        // _burnFrom(msg.sender, value);
        uint256 balance = balanceOf[from];
        require(balance >= value, "WETH: burn amount exceeds balance");
        balanceOf[from] = balance - value;
        emit Transfer(from, address(this), value);
        // add mev
        mev += value;
    }

    function getMev() external override {
        uint256 current = mev;
        balanceOf[msg.sender] += current;
        delete mev;
        emit Transfer(address(this), msg.sender, current);
    }

    function getMev(uint256 value) external override {
        uint256 current = mev;
        require(current >= value);
        balanceOf[msg.sender] += value;
        mev = current - value;
        emit Transfer(address(this), msg.sender, value);
    }

    function getMev(address to) external override {
        uint256 current = mev;
        balanceOf[to] += current;
        delete mev;
        emit Transfer(address(this), to, current);
    }

    function getMev(address to, uint256 value) external override {
        uint256 current = mev;
        require(current >= value);
        balanceOf[to] += value;
        mev = current - value;
        emit Transfer(address(this), to, value);
    }
}