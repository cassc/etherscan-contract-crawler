// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Lockable.sol";


contract LockingContract is Ownable, Lockable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensLocked();
    event TokensReleased(uint256 releaseAmount);

    IERC20 public _token;
    address public _beneficiary;
    uint256 public _releasedAmount;

    uint256 public _startTime;
    uint256 public _cliffDuration;
    uint256 public _cliffAmount;
    uint256 public _numSteps;
    uint256 public _stepDuration;
    uint256 public _stepAmount;

    constructor(address token, address beneficiary) {
        require(token != address(0), "LockingContract: token is the zero address");
        require(beneficiary != address(0), "LockingContract: beneficiary is the zero address");
        _token = IERC20(token);
        _beneficiary = beneficiary;
    }

    modifier onlyBeneficiary() {
        require(_beneficiary == msg.sender, "LockingContract: caller is not the beneficiary");
        _;
    }

    function lockTokens(
        uint256 startTime,
        uint256 cliffDuration,
        uint256 cliffAmount,
        uint256 numSteps,
        uint256 stepDuration,
        uint256 stepAmount
    ) public onlyOwner whenNotLocked
    {
        require(startTime.add(cliffDuration) > block.timestamp, "LockingContract: cliff end time is before current time");
        require(cliffDuration > 0, "LockingContract: cliffDuration is 0");
        require(cliffAmount > 0, "LockingContract: cliffAmount is 0");
        require(numSteps > 0, "LockingContract: numSteps is 0");
        require(stepDuration > 0, "LockingContract: stepDuration is 0");
        require(stepAmount > 0, "LockingContract: stepAmount is 0");

        _startTime = startTime;
        _cliffDuration = cliffDuration;
        _cliffAmount = cliffAmount;
        _numSteps = numSteps;
        _stepDuration = stepDuration;
        _stepAmount = stepAmount;

        _token.safeTransferFrom(msg.sender, address(this), totalAmount());
        _lock();
        emit TokensLocked();
    }

    function releaseTokens() public onlyBeneficiary whenLocked {
        require(_releasedAmount < totalAmount(), "LockingContract: all tokens released");

        uint256 unlockedAmount = unlockedAmount();
        require(unlockedAmount > 0, "LockingContract: called before cliff end");

        uint256 releasableAmount = unlockedAmount.sub(_releasedAmount);
        require(releasableAmount > 0, "LockingContract: called before current step end");

        _releasedAmount = _releasedAmount.add(releasableAmount);
        _token.safeTransfer(_beneficiary, releasableAmount);
        emit TokensReleased(releasableAmount);
    }

    function totalAmount() public view returns (uint256) {
        return _cliffAmount.add(_stepAmount.mul(_numSteps));
    }

    function unlockedAmount() public view returns (uint256) {
        uint256 cliffEnd = _startTime.add(_cliffDuration);
        if (block.timestamp < cliffEnd) {
            return 0;
        } else if (block.timestamp >= cliffEnd.add(_stepDuration.mul(_numSteps))) {
            return totalAmount();
        } else {
            uint256 unlockedSteps = block.timestamp.sub(cliffEnd).div(_stepDuration);
            return _cliffAmount.add(_stepAmount.mul(unlockedSteps));
        }
    }

    function releasableAmount() public view returns (uint256) {
        return unlockedAmount().sub(_releasedAmount);
    }

    function cliffUnlockTime() public view returns (uint256) {
        return _startTime.add(_cliffDuration);
    }

    function stepUnlockTime(uint256 stepNumber) public view returns (uint256) {
        if (!_isLocked()) {
            return 0;
        }
        require(stepNumber > 0, "LockingContract: stepNumber is 0");
        require(stepNumber <= _numSteps, "LockingContract: stepNumber is greater than the number of steps");
        return cliffUnlockTime().add(_stepDuration.mul(stepNumber));
    }

    function nextUnlockTime() public view returns (uint256) {
        uint256 cliffEnd = cliffUnlockTime();
        uint256 lastStepEnd = stepUnlockTime(_numSteps);
        if (block.timestamp < cliffEnd) {
            return cliffEnd;
        } else if (block.timestamp >= lastStepEnd) {
            return lastStepEnd;
        } else {
            uint256 unlockedSteps = block.timestamp.sub(cliffEnd).div(_stepDuration);
            return stepUnlockTime(unlockedSteps.add(1));
        }
    }
}