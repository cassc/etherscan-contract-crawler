// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract Presale is Ownable {
    bool public active;
    Round public currentRound;
    uint256 public constant MAX_PER_WALLET = 7e18; // 7
    uint256 public constant MIN_SEND = 5e16; // 0.05
    
    enum Round {
        ONE,
        TWO
    }

    event PresaleEntry (
        address user,
        uint256 amount,
        Round round
    );

    constructor() {
        active = true;
        currentRound = Round.ONE;
    }

    function withdrawETH() external onlyOwner {
        active = false;
        address payable to = payable(owner());
        to.transfer(address(this).balance);
    }

    function nextRound() external onlyOwner {
        currentRound = Round.TWO;
    }

    receive() external payable {
        _buy();
    }

    fallback() external payable {
        _buy();
    }

    // ฅ^•ﻌ•^ฅ
    function _buy() internal {
        require(active, "presale closed");
        require(msg.value >= MIN_SEND, "min amount is 0.05 ETH");
        require(msg.value <= MAX_PER_WALLET, "max amount is 7 ETH");

        emit PresaleEntry(msg.sender, msg.value, currentRound);
    }
}