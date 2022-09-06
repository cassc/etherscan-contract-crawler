// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Staking20Plus20Into1155 is ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20[2] public STAKE_TOKEN;
    uint256[2] public STAKE_TOKEN_AMOUNT;

    IERC1155 public REWARD_TOKEN;
    uint256 public REWARD_TOKEN_ID;

    uint256 public START_TIME;
    uint256[2] public DURATION;

    uint256 public numberOfUsers;

    address public creator;

    mapping(address => bool) public deposited;

    constructor(IERC20[2] memory _stakeToken, uint256[2] memory _stakeTokenAmount, IERC1155 _rewardToken, uint256 _rewardTokenID, uint256 _startTime, uint256[2] memory _duration) {
        require(_startTime >= block.timestamp, "Cannot set this start time");
        STAKE_TOKEN = _stakeToken;
        STAKE_TOKEN_AMOUNT = _stakeTokenAmount;
        REWARD_TOKEN = _rewardToken;
        REWARD_TOKEN_ID = _rewardTokenID;
        START_TIME = _startTime;
        DURATION = _duration;
        creator = msg.sender;
    }

    function generalInfo() external view returns(IERC20[2] memory, uint256[2] memory, IERC1155, uint256, uint256, uint256[2] memory) {
        return (STAKE_TOKEN, STAKE_TOKEN_AMOUNT, REWARD_TOKEN, REWARD_TOKEN_ID, START_TIME, DURATION);
    }

    function setCreator(address _creator) external {
        require(msg.sender == creator, "Not a staking creator");
        creator = _creator;
    }

    function deposit() external nonReentrant {
        require(block.timestamp >= START_TIME && block.timestamp < START_TIME + DURATION[0], "Cannot deposit at this time");
        require(numberOfUsers < REWARD_TOKEN.balanceOf(address(this), REWARD_TOKEN_ID), "Exceeds number of allowed users");
        require(!deposited[msg.sender], "Already deposited");
        deposited[msg.sender] = true;
        numberOfUsers++;
        STAKE_TOKEN[0].safeTransferFrom(msg.sender, address(this), STAKE_TOKEN_AMOUNT[0]);
        STAKE_TOKEN[1].safeTransferFrom(msg.sender, address(this), STAKE_TOKEN_AMOUNT[1]);
    }

    function withdraw() external nonReentrant {
        require(block.timestamp >= START_TIME && block.timestamp < START_TIME + DURATION[0] || block.timestamp >= START_TIME + DURATION[0] + DURATION[1], "Cannot withdraw at this time");
        require(deposited[msg.sender], "No active deposit");
        deposited[msg.sender] = false;
        numberOfUsers--;
        STAKE_TOKEN[0].safeTransfer(msg.sender, STAKE_TOKEN_AMOUNT[0]);
        STAKE_TOKEN[1].safeTransfer(msg.sender, STAKE_TOKEN_AMOUNT[1]);
        if (block.timestamp >= START_TIME + DURATION[0] + DURATION[1]) {
            REWARD_TOKEN.safeTransferFrom(address(this), msg.sender, REWARD_TOKEN_ID, 1, "");
        }
    }

    function withdrawRemaining() external {
        require(msg.sender == creator, "Not a staking creator");
        require(block.timestamp >= START_TIME + DURATION[0], "Cannot withdraw remaining at this time");
        REWARD_TOKEN.safeTransferFrom(address(this), msg.sender, REWARD_TOKEN_ID, (REWARD_TOKEN.balanceOf(address(this), REWARD_TOKEN_ID) - numberOfUsers), "");
    }
}