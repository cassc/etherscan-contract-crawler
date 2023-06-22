// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IterableMapping.sol";
import "./SafeERC20.sol";
struct Claimers {
    address claimer;
    uint256 amount;
}

contract BigeyesClaim is Ownable {
    using IterableMapping for IterableMapping.Map;
    using SafeERC20 for IERC20;
    IERC20 public projectToken;
    IterableMapping.Map private claimers;
    uint256 public totalAmount;
    uint256 public totalClaimedAmount;
    uint256 public startTime;
    uint256 public endTime;

    event Claimed(address indexed claimer, uint256 amount);

    constructor(address _token, uint256 _startTime, uint256 _endTime) {
        projectToken = IERC20(_token);
        startTime = _startTime;
        endTime = _endTime;
    }

    function addClaimers(Claimers[] memory _claimers) external onlyOwner {
        for (uint256 i = 0; i < _claimers.length; i++) {
            claimers.set(_claimers[i].claimer, _claimers[i].amount);
            totalAmount += _claimers[i].amount;
        }
    }

    function removeClaimers(address[] memory _claimers) external onlyOwner {
        for (uint256 i = 0; i < _claimers.length; i++) {
            (uint256 amount, ) = claimers.get(_claimers[i]);
            totalAmount -= amount;
            claimers.remove(_claimers[i]);
        }
    }

    function updateTimer(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        endTime = _endTime;
        startTime = _startTime;
    }

    function claim() external {
        (uint256 amount, bool isClaimed) = claimers.get(msg.sender);
        require(amount > 0, "not bought");
        require(!isClaimed, "already claimed");
        require(startTime <= block.timestamp, "not started");
        require(endTime >= block.timestamp, "ended");
        totalClaimedAmount += amount;
        claimers.claim(msg.sender);
        projectToken.safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function deposit() external onlyOwner {
        uint256 amountRequired = totalAmount -
            totalClaimedAmount -
            projectToken.balanceOf(address(this));
        if (amountRequired > 0)
            projectToken.safeTransferFrom(
                owner(),
                address(this),
                amountRequired
            );
    }

    function withdrawRest() external onlyOwner {
        uint256 amountRequired = totalAmount - totalClaimedAmount;
        uint256 amountRest = projectToken.balanceOf(address(this)) -
            amountRequired;
        if (amountRest > 0) projectToken.safeTransfer(owner(), amountRest);
    }

    function withdrawOtherToken(address token) external onlyOwner {
        require(token != address(projectToken), "no Project Token");
        IERC20(token).safeTransfer(
            owner(),
            IERC20(token).balanceOf(address(this))
        );
    }

    function forceWithdraw() external onlyOwner {
        projectToken.safeTransfer(
            owner(),
            projectToken.balanceOf(address(this))
        );
    }

    function getAllClaimersLength() external view returns (uint256) {
        return claimers.size();
    }

    function getClaimerAddress(uint256 index) external view returns (address) {
        return claimers.getKeyAtIndex(index);
    }

    function getAllClaimers() external view returns (address[] memory) {
        return claimers.getAllKeys();
    }

    function getClaimerInfo(
        address _claimer
    ) external view returns (uint256 amount, bool isClaimed) {
        (amount, isClaimed) = claimers.get(_claimer);
    }
}