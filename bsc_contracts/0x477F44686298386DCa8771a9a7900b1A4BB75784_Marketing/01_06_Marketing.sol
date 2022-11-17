// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Marketing is Ownable {
    using SafeERC20 for IERC20;
    // TODO fix for mainnet
    uint256 public constant BLOCKS_PER_MONTH = 861000;
    uint256 public lockedPeriod = 6 * BLOCKS_PER_MONTH;
    uint256 public lockedAmount = 8000000 ether;
    uint256 public claimedAmount;
    uint256 public startBlock;
    uint256 public unlockedPerMonth = 200000 ether;
    IERC20 public token;

    // event
    event Claimed(uint256 amount, uint256 blockNumber);

    constructor(IERC20 token_) {
        require(address(token_) != address(0), "Marketing: Token address can't be address zero");
        token = token_;
        startBlock = block.number;
    }

    function claim(uint256 amount_) external onlyOwner {
        require(block.number >= startBlock + 7 * BLOCKS_PER_MONTH, "Marketing: Locked period didn't passed");
        uint256 unlockedAmount = getUnlockedTokenAmount();
        require(amount_ <= unlockedAmount, "Marketing: Insufficiant unlocked tokens");
        require(lockedAmount >= claimedAmount + amount_, "Marketing: Insufficient locked tokens");
        claimedAmount += amount_;
        token.safeTransfer(msg.sender, amount_);
        emit Claimed(amount_, block.number);
    }

    function getUnlockedTokenAmount() public view returns (uint256 amount) {
        if (block.number < startBlock + 7 * BLOCKS_PER_MONTH) {
            return 0;
        }
        amount = unlockedPerMonth * ((block.number - (startBlock + 6 * BLOCKS_PER_MONTH)) / BLOCKS_PER_MONTH);
        if (amount >= lockedAmount) {
            amount = lockedAmount;
        }
        amount -= claimedAmount;
        return amount;
    }
}