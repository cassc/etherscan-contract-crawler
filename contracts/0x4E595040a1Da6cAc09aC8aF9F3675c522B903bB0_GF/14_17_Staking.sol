// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solady/tokens/ERC20.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract Staking {
    ERC20 public token;

    uint256 public totalStaked;
    uint256 public totalShares;
    mapping(address => uint256) public shares;

    constructor() {
        token = ERC20(msg.sender);
    }

    function stake(uint256 amount) public {
        uint256 tokensHeld = token.balanceOf(address(this));
        uint256 _totalShares = totalShares;
        uint256 sharesToMint = amount;
        if (_totalShares != 0 && tokensHeld != 0) {
            sharesToMint += (amount * _totalShares) / tokensHeld;
        }
        totalStaked += amount;
        totalShares += sharesToMint;
        shares[msg.sender] += sharesToMint;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 share) public {
        uint256 tokenAmount = (share * token.balanceOf(address(this))) / totalShares;
        uint256 ethAmount = (share * address(this).balance) / totalShares;
        totalStaked -= tokenAmount;
        token.transfer(msg.sender, tokenAmount);
        SafeTransferLib.safeTransferETH(msg.sender, ethAmount);
    }

    receive() external payable {}
}