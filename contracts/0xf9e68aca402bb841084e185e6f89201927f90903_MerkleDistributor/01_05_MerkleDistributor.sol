//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
  using SafeMath for uint256;
  address public immutable override token;
  bytes32 public immutable override merkleRoot;
  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  // Opium Bonus
  uint256 public constant MAX_BONUS = 0.999e18;
  uint256 public constant PERCENTAGE_BASE = 1e18;

  uint256 public totalClaims;
  uint256 public initialPoolSize;
  uint256 public currentPoolSize;
  uint256 public bonusSum;
  uint256 public claimed;
  uint256 public percentageIndex;
  uint256 public bonusStart;
  uint256 public bonusEnd;
  uint256 public emergencyTimeout;
  address public emergencyReceiver;

  constructor(
    address token_,
    bytes32 merkleRoot_,
    uint256 _totalClaims,
    uint256 _initialPoolSize,
    uint256 _bonusStart,
    uint256 _bonusEnd,
    uint256 _emergencyTimeout,
    address _emergencyReceiver
  ) {
    token = token_;
    merkleRoot = merkleRoot_;
    // Opium Bonus
    totalClaims = _totalClaims;
    initialPoolSize = _initialPoolSize;
    currentPoolSize = _initialPoolSize;
    percentageIndex = PERCENTAGE_BASE;
    bonusStart = _bonusStart;
    bonusEnd = _bonusEnd;
    emergencyTimeout = _emergencyTimeout;
    emergencyReceiver = _emergencyReceiver;
    require(bonusStart < bonusEnd, "WRONG_BONUS_TIME");
    require(emergencyTimeout > bonusEnd, "WRONG_EMERGENCY_TIMEOUT");
  }

  function isClaimed(uint256 index) public view override returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] =
      claimedBitMap[claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  function claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");
    require(msg.sender == account, "Only owner can claim");
    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(
      MerkleProof.verify(merkleProof, merkleRoot, node),
      "MerkleDistributor: Invalid proof."
    );
    // Mark it claimed and send the token.
    _setClaimed(index);
    uint256 adjustedAmount = _applyAdjustment(amount);
    require(
      IERC20(token).transfer(account, adjustedAmount),
      "MerkleDistributor: Transfer failed."
    );
    emit Claimed(index, account, amount, adjustedAmount);
  }

  function getBonus() public view returns (uint256) {
    // timeRemaining = bonusEnd - now, or 0 if bonus ended
    uint256 timeRemaining =
      block.timestamp > bonusEnd ? 0 : bonusEnd.sub(block.timestamp);
    // bonus = maxBonus * timeRemaining / (bonusEnd - bonusStart)
    return MAX_BONUS.mul(timeRemaining).div(bonusEnd.sub(bonusStart));
  }

  function calculateAdjustedAmount(uint256 amount)
    public
    view
    returns (
      uint256 adjustedAmount,
      uint256 bonus,
      uint256 bonusPart
    )
  {
    // If last claims, return full amount + full bonus
    if (claimed + 1 == totalClaims) {
      return (amount.add(bonusSum), 0, 0);
    }
    // adjustedPercentage = amount / initialPoolSize * percentageIndex
    uint256 adjustedPercentage =
      amount.mul(PERCENTAGE_BASE).div(initialPoolSize).mul(percentageIndex).div(
        PERCENTAGE_BASE
      );
    // bonusPart = adjustedPercentage * bonusSum
    bonusPart = adjustedPercentage.mul(bonusSum).div(PERCENTAGE_BASE);
    // totalToClaim = amount + bonusPart
    uint256 totalToClaim = amount.add(bonusPart);
    // bonus = totalToClaim * getBonus()
    bonus = totalToClaim.mul(getBonus()).div(PERCENTAGE_BASE);
    // adjustedAmount = totalToClaim - bonus
    adjustedAmount = totalToClaim.sub(bonus);
  }

  function _applyAdjustment(uint256 amount) private returns (uint256) {
    (uint256 adjustedAmount, uint256 bonus, uint256 bonusPart) =
      calculateAdjustedAmount(amount);
    // Increment claim index
    claimed += 1;

    // If last claims, return full amount, don't update anything
    if (claimed == totalClaims) {
      return adjustedAmount;
    }
    // newPoolSize = currentPoolSize - amount
    uint256 newPoolSize = currentPoolSize.sub(amount);
    // percentageIndex = percentageIndex * currentPoolSize / newPoolSize
    percentageIndex = percentageIndex
      .mul(currentPoolSize.mul(PERCENTAGE_BASE).div(newPoolSize))
      .div(PERCENTAGE_BASE);
    // currentPoolSize = newPoolSize
    currentPoolSize = newPoolSize;
    // bonusSum = bonusSum - bonusPart + bonus
    bonusSum = bonusSum.sub(bonusPart).add(bonus);
    return adjustedAmount;
  }

  function emergencyWithdrawal() public {
    require(block.timestamp > emergencyTimeout, "TIMEOUT_NOT_EXPIRED");
    IERC20(token).transfer(
      emergencyReceiver,
      IERC20(token).balanceOf(address(this))
    );
  }
}