// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable {
    IERC20 public token;
    struct UserInfo {
        uint256 amount;
        uint256 startBlock;
    }
    uint256 public availablePrizeFund;
    uint256 public constant BLOCKS_PER_YEAR = 30;
    mapping(address => UserInfo[]) public userInfo;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 startBlock);
    event Unstaked(address indexed user, uint256 amount);

    constructor(IERC20 token_) {
        require(address(token_) != address(0), "Token address can't be address zero");
        token = token_;
    }

    function addPrizeFund(uint256 amount) external onlyOwner {
        availablePrizeFund += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function stake(uint256 amount_) external {
        require(availablePrizeFund > (amount_ * 1200) / 10000, "Staking: Insufficient Prize fund");
        userInfo[msg.sender].push(UserInfo({amount: amount_, startBlock: block.number}));
        availablePrizeFund -= (amount_ * 1200) / 10000;
        emit Staked(msg.sender, amount_, block.number);
    }

    function unstake(uint256 stakeIndex_) external {
        require(userInfo[msg.sender][stakeIndex_].amount > 0, "Staking: Nothing to unstake");
        require(
            userInfo[msg.sender][stakeIndex_].startBlock + BLOCKS_PER_YEAR * 3 <= block.number,
            "Staking: Locked period didn't passed"
        );
        uint256 amount = userInfo[msg.sender][stakeIndex_].amount;
        delete userInfo[msg.sender][stakeIndex_];
        token.transfer(msg.sender, amount + (amount * 1200) / 10000);
        emit Unstaked(msg.sender, amount + (amount * 1200) / 10000);
    }

    function withdraw() external onlyOwner {
        uint256 amount = availablePrizeFund;
        availablePrizeFund = 0;
        token.transfer(msg.sender, amount);
    }
}