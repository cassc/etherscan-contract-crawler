// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Staking20Plus1155Into1155 is ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public STAKE_TOKEN_ERC20;
    uint256 public STAKE_TOKEN_AMOUNT;

    IERC1155 public STAKE_TOKEN_ERC1155;
    uint256 public STAKE_TOKEN_ID;

    IERC1155 public REWARD_TOKEN;
    uint256 public REWARD_TOKEN_ID;

    uint256 public START_TIME;
    uint256[2] public DURATION;

    uint256 public numberOfUsers;

    address public creator;

    mapping(address => bool) public deposited;

    constructor(IERC20 _stakeTokenERC20, uint256 _stakeTokenAmount, IERC1155 _stakeTokenERC1155, uint256 _stakeTokenID, IERC1155 _rewardToken, uint256 _rewardTokenID, uint256 _startTime, uint256[2] memory _duration) {
        require(_startTime >= block.timestamp, "Cannot set this start time");
        STAKE_TOKEN_ERC20 = _stakeTokenERC20;
        STAKE_TOKEN_AMOUNT = _stakeTokenAmount;
        STAKE_TOKEN_ERC1155 = _stakeTokenERC1155;
        STAKE_TOKEN_ID = _stakeTokenID;
        REWARD_TOKEN = _rewardToken;
        REWARD_TOKEN_ID = _rewardTokenID;
        START_TIME = _startTime;
        DURATION = _duration;
        creator = msg.sender;
    }

    function generalInfo() external view returns(IERC20, uint256, IERC1155, uint256, IERC1155, uint256, uint256, uint256[2] memory) {
        return (STAKE_TOKEN_ERC20, STAKE_TOKEN_AMOUNT, STAKE_TOKEN_ERC1155, STAKE_TOKEN_ID, REWARD_TOKEN, REWARD_TOKEN_ID, START_TIME, DURATION);
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
        STAKE_TOKEN_ERC20.safeTransferFrom(msg.sender, address(this), STAKE_TOKEN_AMOUNT);
        STAKE_TOKEN_ERC1155.safeTransferFrom(msg.sender, address(this), STAKE_TOKEN_ID, 1, "");
    }

    function withdraw() external nonReentrant {
        require(block.timestamp >= START_TIME && block.timestamp < START_TIME + DURATION[0] || block.timestamp >= START_TIME + DURATION[0] + DURATION[1], "Cannot withdraw at this time");
        require(deposited[msg.sender], "No active deposit");
        deposited[msg.sender] = false;
        numberOfUsers--;
        STAKE_TOKEN_ERC20.safeTransfer(msg.sender, STAKE_TOKEN_AMOUNT);
        STAKE_TOKEN_ERC1155.safeTransferFrom(address(this), msg.sender, STAKE_TOKEN_ID, 1, "");
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