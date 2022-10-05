// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICharity.sol";

contract Staking is Ownable, Pausable, ReentrancyGuard {

    uint256 public constant DENOMINATOR = 1000;

    IERC20 public immutable GWD;

    ICharity public charity;

    uint256 public totalStaked;
    uint256 public totalRewardDebt;
    uint256 public feePercentage = 10;

    mapping(address => Stake) public stakeInfo;

    struct Stake {
        uint256 amount;
        uint256 enteredAt;
        uint256 updatedAt;
        uint256 rewardDebt;
        uint256 totalRewardGot;
    }

    constructor(IERC20 _gwd, ICharity _charity) {
        GWD = _gwd;
        charity = _charity;
    }

    function deposit(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0 && amount % 1000000 == 0, "Wrong amount");
        GWD.transferFrom(_msgSender(), address(this), amount);
        totalStaked += amount;
        _manageReward(_msgSender());
        stakeInfo[_msgSender()].enteredAt = block.timestamp;
        stakeInfo[_msgSender()].amount += amount;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(stakeInfo[_msgSender()].amount >= amount, "Cannot withdraw this much");
        require(block.timestamp >= stakeInfo[_msgSender()].enteredAt + 604800, "Cannot unstake yet");
        _manageReward(_msgSender());
        totalStaked -= amount;
        stakeInfo[_msgSender()].amount -= amount;
        GWD.transfer(_msgSender(), amount);
    }

    function getReward() external nonReentrant {
        _manageReward(_msgSender());
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setCharity(ICharity _charity) external onlyOwner {
        charity = _charity;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage < 200, "Too high fee percentage");
        feePercentage = _feePercentage;
    }

    function pendingReward(address account) public view returns(uint256) {
        return ((stakeInfo[account].amount * 15 * (block.timestamp - stakeInfo[account].updatedAt)) / 3153600000);
    }

    function _manageReward(address account) private {
        uint256 pending = pendingReward(account);
        stakeInfo[account].updatedAt = block.timestamp;
        uint256 debt = stakeInfo[_msgSender()].rewardDebt;
        if (debt > 0) {
            stakeInfo[_msgSender()].rewardDebt = 0;
            totalRewardDebt -= debt;
            pending += debt;
        }
        if (pending > 0) {
            _giveReward(account, pending);
        }
    }

    function _giveReward(address account, uint256 amount) private {
        uint256 toTransfer;
        if (GWD.balanceOf(address(this)) >= totalStaked + amount) {
            toTransfer = amount;
        }
        else {
            toTransfer = GWD.balanceOf(address(this)) - totalStaked;
            uint256 debt = amount - toTransfer;
            totalRewardDebt += debt;
            stakeInfo[account].rewardDebt += debt;
        }
        if (toTransfer > 0) {
            uint256 fee = (toTransfer * feePercentage) / DENOMINATOR;
            toTransfer -= fee;
            GWD.transfer(address(charity), fee);
            charity.addToCharity(fee, account);
            GWD.transfer(account, toTransfer);
            stakeInfo[account].totalRewardGot += toTransfer;
        }
    }
}