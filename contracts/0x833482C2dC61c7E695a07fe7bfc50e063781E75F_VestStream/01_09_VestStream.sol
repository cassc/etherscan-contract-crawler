// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title A token vesting contract for streaming claims.
  @author SuperFarm

  This vesting contract allows users to claim vested tokens with every block.
*/
contract VestStream is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeMath for uint64;
  using SafeERC20 for IERC20;

  /// The token to disburse in vesting.
  IERC20 public token;

  // Information for a particular token claim.
  // - totalAmount: the total size of the token claim.
  // - startTime: the timestamp in seconds when the vest begins.
  // - endTime: the timestamp in seconds when the vest completely matures.
  // - lastCLaimTime: the timestamp in seconds of the last time the claim was utilized.
  // - amountClaimed: the total amount claimed from the entire claim.
  struct Claim {
    uint256 totalAmount;
    uint64 startTime;
    uint64 endTime;
    uint64 lastClaimTime;
    uint256 amountClaimed;
  }

  // A mapping of addresses to the claim received.
  mapping(address => Claim) private claims;

  /// An event for tracking the creation of a token vest claim.
  event ClaimCreated(address creator, address beneficiary);

  /// An event for tracking a user claiming some of their vested tokens.
  event Claimed(address beneficiary, uint256 amount);

  /**
    Construct a new VestStream by providing it a token to disburse.

    @param _token The token to vest to claimants in this contract.
  */
  constructor(IERC20 _token) public {
    token = _token;
    uint256 MAX_INT = 2**256 - 1;
    token.approve(address(this), MAX_INT);
  }

  /**
    A function which allows the caller to retrieve information about a specific
    claim via its beneficiary.

    @param beneficiary the beneficiary to query claims for.
  */
  function getClaim(address beneficiary) external view returns (Claim memory) {
    require(beneficiary != address(0), "The zero address may not be a claim beneficiary.");
    return claims[beneficiary];
  }

  /**
    A function which allows the caller to retrieve information about a specific
    claim's remaining claimable amount.

    @param beneficiary the beneficiary to query claims for.
  */
  function claimableAmount(address beneficiary) public view returns (uint256) {
    Claim memory claim = claims[beneficiary];

    // Early-out if the claim has not started yet.
    if (claim.startTime == 0 || block.timestamp < claim.startTime) {
      return 0;
    }

    // Calculate the current releasable token amount.
    uint64 currentTimestamp = uint64(block.timestamp) > claim.endTime ? claim.endTime : uint64(block.timestamp);
    uint256 claimPercent = currentTimestamp.sub(claim.startTime).mul(1e18).div(claim.endTime.sub(claim.startTime));
    uint256 claimAmount = claim.totalAmount.mul(claimPercent).div(1e18);

    // Reduce the unclaimed amount by the amount already claimed.
    uint256 unclaimedAmount = claimAmount.sub(claim.amountClaimed);
    return unclaimedAmount;
  }

  /**
    Sweep all of a particular ERC-20 token from the contract.

    @param _token The token to sweep the balance from.
  */
  function sweep(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.safeTransferFrom(address(this), msg.sender, balance);
  }

  /**
    A function which allows the caller to create toke vesting claims for some
    beneficiaries. The disbursement token will be taken from the claim creator.

    @param _beneficiaries an array of addresses to construct token claims for.
    @param _totalAmounts the total amount of tokens to be disbursed to each beneficiary.
    @param _startTime a timestamp when this claim is to begin vesting.
    @param _endTime a timestamp when this claim is to reach full maturity.
  */
  function createClaim(address[] memory _beneficiaries, uint256[] memory _totalAmounts, uint64 _startTime, uint64 _endTime) external onlyOwner {
    require(_beneficiaries.length > 0, "You must specify at least one beneficiary for a claim.");
    require(_beneficiaries.length == _totalAmounts.length, "Beneficiaries and their amounts may not be mismatched.");
    require(_endTime >= _startTime, "You may not create a claim which ends before it starts.");

    // After validating the details for this token claim, initialize a claim for
    // each specified beneficiary.
    for (uint i = 0; i < _beneficiaries.length; i++) {
      address _beneficiary = _beneficiaries[i];
      uint256 _totalAmount = _totalAmounts[i];
      require(_beneficiary != address(0), "The zero address may not be a beneficiary.");
      require(_totalAmount > 0, "You may not create a zero-token claim.");

      // Establish a claim for this particular beneficiary.
      Claim memory claim = Claim({
        totalAmount: _totalAmount,
        startTime: _startTime,
        endTime: _endTime,
        lastClaimTime: _startTime,
        amountClaimed: 0
      });
      claims[_beneficiary] = claim;
      emit ClaimCreated(msg.sender, _beneficiary);
    }
  }

  /**
    A function which allows the caller to send a claim's unclaimed amount to the
    beneficiary of the claim.

    @param beneficiary the beneficiary to claim for.
  */
  function claim(address beneficiary) external nonReentrant {
    Claim memory _claim = claims[beneficiary];

    // Verify that the claim is still active.
    require(_claim.lastClaimTime < _claim.endTime, "This claim has already been completely claimed.");

    // Calculate the current releasable token amount.
    uint64 currentTimestamp = uint64(block.timestamp) > _claim.endTime ? _claim.endTime : uint64(block.timestamp);
    uint256 claimPercent = currentTimestamp.sub(_claim.startTime).mul(1e18).div(_claim.endTime.sub(_claim.startTime));
    uint256 claimAmount = _claim.totalAmount.mul(claimPercent).div(1e18);

    // Reduce the unclaimed amount by the amount already claimed.
    uint256 unclaimedAmount = claimAmount.sub(_claim.amountClaimed);

    // Transfer the unclaimed tokens to the beneficiary.
    token.safeTransferFrom(address(this), beneficiary, unclaimedAmount);

    // Update the amount currently claimed by the user.
    _claim.amountClaimed = claimAmount;

    // Update the last time the claim was utilized.
    _claim.lastClaimTime = currentTimestamp;

    // Update the claim structure being tracked.
    claims[beneficiary] = _claim;

    // Emit an event for this token claim.
    emit Claimed(beneficiary, unclaimedAmount);
  }
}