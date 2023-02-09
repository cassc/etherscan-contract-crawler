// SDPX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VestingVault is AccessControl {
  using SafeMath for uint256;
  using SafeMath for uint16;
  using SafeERC20 for IERC20;

  struct Grant {
    uint256 startTime;
    uint256 amount;
    uint16 vestingDuration;
    uint16 daysClaimed;
    uint256 totalClaimed;
    address recipient;
  }

  IERC20 public token;

  address private _adminReceiver;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  uint256 public totalVestingCount;

  mapping(address => Grant) private tokenGrants;

  event GrantAdded(address indexed recipient);
  event GrantTokensClaimed(address indexed recipient, uint256 amountClaimed);
  event GrantRevoked(address recipient, uint256 amountVested, uint256 amountNotVested);

  constructor(address _token) {
    require(address(_token) != address(0));
    token = IERC20(_token);

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(ADMIN_ROLE, _msgSender());
    _grantRole(ADMIN_ROLE, 0xf7fa6A0642E2593F7BDd7b2E0A2673600d53BBE9);

    _adminReceiver = _msgSender();
  }

  function addGrants(
    address[] memory _recipients,
    uint256[] memory _amounts,
    uint16[] memory _vestingDurationInDays,
    uint256[] memory _startTimes
  ) external onlyRole(ADMIN_ROLE) {
    uint256 count = _recipients.length;
    require(count <= 100, "Too many grants provided");
    require(
      _amounts.length == count &&
        _startTimes.length == count &&
        _vestingDurationInDays.length == count,
      "Array length mismatch"
    );

    address currenGrantee;
    uint256 currentAmount;
    uint16 currentVestingDuration;
    uint256 currentStartTime;

    for (uint256 i; i < count; ) {
      currenGrantee = _recipients[i];
      currentAmount = _amounts[i];
      currentStartTime = _startTimes[i];
      currentVestingDuration = _vestingDurationInDays[i];

      addTokenGrant(currenGrantee, currentAmount, currentVestingDuration, 0, currentStartTime);

      unchecked {
        ++i;
      }
    }
  }

  function addTokenGrant(
    address _recipient,
    uint256 _amount,
    uint16 _vestingDurationInDays,
    uint16 _vestingCliffInDays,
    uint256 _startTime
  ) public onlyRole(ADMIN_ROLE) {
    require(tokenGrants[_recipient].amount == 0, "Grant already exists, must revoke first.");
    require(_vestingCliffInDays <= 10 * 365, "Cliff greater than 10 years");
    require(_vestingDurationInDays <= 25 * 365, "Duration greater than 25 years");

    uint256 amountVestedPerDay = _amount.div(_vestingDurationInDays);
    require(amountVestedPerDay > 0, "amountVestedPerDay > 0");

    Grant memory grant = Grant({
      startTime: _startTime + _vestingCliffInDays * 1 days,
      amount: _amount,
      vestingDuration: _vestingDurationInDays,
      daysClaimed: 0,
      totalClaimed: 0,
      recipient: _recipient
    });

    tokenGrants[_recipient] = grant;

    emit GrantAdded(_recipient);
  }

  function setToken(address _token) external onlyRole(ADMIN_ROLE) {
    require(address(_token) != address(0));
    token = IERC20(_token);
  }

  /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
  function claimVestedTokens() external {
    uint16 daysVested;
    uint256 amountVested;
    (daysVested, amountVested) = calculateGrantClaim(msg.sender);
    require(amountVested > 0, "Vested is 0");
    require(token.balanceOf(address(this)) >= amountVested, "Contract Aalto balance too low");

    Grant storage tokenGrant = tokenGrants[msg.sender];
    tokenGrant.daysClaimed = uint16(tokenGrant.daysClaimed.add(daysVested));
    tokenGrant.totalClaimed = uint256(tokenGrant.totalClaimed.add(amountVested));

    token.safeTransfer(tokenGrant.recipient, amountVested);
    emit GrantTokensClaimed(tokenGrant.recipient, amountVested);
  }

  /// @notice Terminate token grant transferring all vested tokens to the `_recipient`
  /// and returning all non-vested tokens to the contract owner
  /// Secured to the contract owner only
  /// @param _recipient address of the token grant recipient
  function revokeTokenGrant(address _recipient) external onlyRole(ADMIN_ROLE) {
    Grant storage tokenGrant = tokenGrants[_recipient];
    uint16 daysVested;
    uint256 amountVested;
    (daysVested, amountVested) = calculateGrantClaim(_recipient);

    uint256 amountNotVested = (tokenGrant.amount.sub(tokenGrant.totalClaimed)).sub(amountVested);

    token.safeTransfer(_adminReceiver, amountNotVested);
    token.safeTransfer(_recipient, amountVested);

    tokenGrant.startTime = 0;
    tokenGrant.amount = 0;
    tokenGrant.vestingDuration = 0;
    tokenGrant.daysClaimed = 0;
    tokenGrant.totalClaimed = 0;
    tokenGrant.recipient = address(0);

    emit GrantRevoked(_recipient, amountVested, amountNotVested);
  }

  function getGrantStartTime(address _recipient) public view returns (uint256) {
    Grant storage tokenGrant = tokenGrants[_recipient];
    return tokenGrant.startTime;
  }

  function getGrantAmount(address _recipient) public view returns (uint256) {
    Grant storage tokenGrant = tokenGrants[_recipient];
    return tokenGrant.amount;
  }

  function getTotalClaimed(address _recipient) public view returns (uint256) {
    Grant storage tokenGrant = tokenGrants[_recipient];
    return tokenGrant.totalClaimed;
  }

  function getTokenAmount() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function getVestedTokens(address _recipient) public view returns (uint256) {
    uint16 daysVested;
    uint256 amountVested;
    (daysVested, amountVested) = calculateGrantClaim(_recipient);

    return amountVested;
  }

  /// @notice Calculate the vested and unclaimed months and tokens available for `_grantId` to claim
  /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
  /// Returns (0, 0) if cliff has not been reached
  function calculateGrantClaim(address _recipient) private view returns (uint16, uint256) {
    Grant storage tokenGrant = tokenGrants[_recipient];

    if (tokenGrant.totalClaimed == tokenGrant.amount) {
      return (0, 0);
    }

    // For grants created with a future start date, that hasn't been reached, return 0, 0
    if (currentTime() < tokenGrant.startTime) {
      return (0, 0);
    }

    // Check cliff was reached
    uint elapsedDays = currentTime().sub(tokenGrant.startTime - 1 days).div(1 days);

    // If over vesting duration, all tokens vested
    if (elapsedDays >= tokenGrant.vestingDuration) {
      uint256 remainingGrant = tokenGrant.amount.sub(tokenGrant.totalClaimed);
      return (tokenGrant.vestingDuration, remainingGrant);
    } else {
      uint16 daysVested = uint16(elapsedDays.sub(tokenGrant.daysClaimed));
      uint256 amountVestedPerDay = tokenGrant.amount.div(uint256(tokenGrant.vestingDuration));
      uint256 amountVested = uint256(daysVested.mul(amountVestedPerDay));
      return (daysVested, amountVested);
    }
  }

  function currentTime() private view returns (uint256) {
    return block.timestamp;
  }

  function emergencyWithdraw(address _tokenAddress, uint256 _amount) external onlyRole(ADMIN_ROLE) {
    // Would fail anyway, but still
    require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "Contract balance too low");

    IERC20(_tokenAddress).safeTransfer(_adminReceiver, _amount);
  }

  function setAdminReceiver(address _admin) external onlyRole(ADMIN_ROLE) {
    require(_admin != address(0), "0x0 admin");

    _adminReceiver = _admin;
  }
}