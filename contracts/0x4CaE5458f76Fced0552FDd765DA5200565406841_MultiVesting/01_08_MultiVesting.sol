pragma solidity =0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Vesting {
    uint256 startedAt; // Timestamp in seconds
    uint256 totalAmount; // Vested amount
    uint256 releasedAmount; // Amount that beneficiary withdraw
  }

  // ===============================================================================================================
  // Constants
  // ===============================================================================================================
  uint256 public constant STEPS_AMOUNT = 20; // 20 steps, each step unlock 7% or 2% of funds after 90 days

  // ===============================================================================================================
  // Members
  // ===============================================================================================================
  uint256 public totalVestedAmount;
  uint256 public totalReleasedAmount;
  IERC20 public token;

  // Beneficiary address -> Array of Vesting params
  mapping(address => Vesting[]) public vestingMap;

  // ===============================================================================================================
  // Constructor
  // ===============================================================================================================
  /// @notice Contract constructor - sets the token address that the contract facilitates.
  /// @param _token - ERC20 token address.
  constructor(IERC20 _token) {
    token = _token;
  }

  /// @notice Creates vesting for beneficiary, with a given amount of tokens to allocate.
  /// The allocation will start when the method is called (now).
  /// @param _beneficiary - address of beneficiary.
  /// @param _amount - amount of tokens to allocate
  function addVestingFromNow(address _beneficiary, uint256 _amount)
    external
    onlyOwner
  {
    addVesting(_beneficiary, _amount, block.timestamp);
  }

  /// @notice Creates vesting for beneficiary, with a given amount of funds to allocate,
  /// and timestamp of the allocation.
  /// @param _beneficiary - address of beneficiary.
  /// @param _amount - amount of tokens to allocate
  /// @param _startedAt - timestamp (in seconds) when the allocation should start
  function addVesting(
    address _beneficiary,
    uint256 _amount,
    uint256 _startedAt
  ) public onlyOwner {
    require(_startedAt >= block.timestamp, "TIMESTAMP_CANNOT_BE_IN_THE_PAST");
    require(_amount >= STEPS_AMOUNT, "VESTING_AMOUNT_TO_LOW");
    uint256 debt = totalVestedAmount.sub(totalReleasedAmount);
    uint256 available = token.balanceOf(address(this)).sub(debt);

    require(available >= _amount, "DON_T_HAVE_ENOUGH");

    Vesting memory v = Vesting({
      startedAt: _startedAt,
      totalAmount: _amount,
      releasedAmount: 0
    });

    vestingMap[_beneficiary].push(v);
    totalVestedAmount = totalVestedAmount.add(_amount);
  }

  /// @notice Method that allows a beneficiary to withdraw their allocated funds for a specific vesting ID.
  /// @param _vestingId - The ID of the vesting the beneficiary can withdraw their funds for.
  function withdraw(uint256 _vestingId) external {
    uint256 amount = getAvailableAmount(msg.sender, _vestingId);
    require(amount > 0, "DON_T_HAVE_RELEASED_TOKENS");

    // Increased released amount in in mapping
    vestingMap[msg.sender][_vestingId].releasedAmount = vestingMap[msg.sender][
      _vestingId
    ].releasedAmount.add(amount);

    // Increased total released in contract
    totalReleasedAmount = totalReleasedAmount.add(amount);
    token.safeTransfer(msg.sender, amount);
  }

  /// @notice Method that allows a beneficiary to withdraw all their allocated funds.
  function withdrawAllAvailable() external {
    uint256 aggregatedAmount = 0;

    uint256 maxId = vestingMap[msg.sender].length;
    for (uint256 vestingId = 0; vestingId < maxId; vestingId++) {
      uint256 availableInSingleVesting = getAvailableAmount(
        msg.sender,
        vestingId
      );
      aggregatedAmount = aggregatedAmount.add(availableInSingleVesting);

      // Update released amount in specific vesting
      vestingMap[msg.sender][vestingId].releasedAmount = vestingMap[msg.sender][
        vestingId
      ].releasedAmount.add(availableInSingleVesting);
    }

    // Increase released amount
    totalReleasedAmount = totalReleasedAmount.add(aggregatedAmount);

    // Transfer
    token.safeTransfer(msg.sender, aggregatedAmount);
  }

  /// @notice Method that allows the owner to withdraw unallocated funds to a specific address
  /// @param _receiver - address where the funds will be send
  function withdrawUnallocatedFunds(address _receiver) external onlyOwner {
    uint256 amount = getUnallocatedFundsAmount();
    require(amount > 0, "DON_T_HAVE_UNALLOCATED_TOKENS");
    token.safeTransfer(_receiver, amount);
  }

  // ===============================================================================================================
  // Getters
  // ===============================================================================================================

  /// @notice Returns smallest unused VestingId (unique per beneficiary).
  /// The next vesting ID can be used by the benficiary to see how many vestings / allocations has.
  /// @param _beneficiary - address of the beneficiary to return the next vesting ID
  function getNextVestingId(address _beneficiary)
    external
    view
    returns (uint256)
  {
    return vestingMap[_beneficiary].length;
  }

  /// @notice Returns amount of funds that beneficiary can withdraw using all vesting records of given beneficiary address
  /// @param _beneficiary - address of the beneficiary
  function getAvailableAmountAggregated(address _beneficiary)
    external
    view
    returns (uint256)
  {
    uint256 available = 0;
    uint256 maxId = vestingMap[_beneficiary].length;
    //
    for (uint256 vestingId = 0; vestingId < maxId; vestingId++) {
      // Optimization for gas saving in case vesting were already released
      if (
        vestingMap[_beneficiary][vestingId].totalAmount ==
        vestingMap[_beneficiary][vestingId].releasedAmount
      ) {
        continue;
      }

      available = available.add(getAvailableAmount(_beneficiary, vestingId));
    }
    return available;
  }

  /// @notice Returns amount of funds that beneficiary can withdraw, vestingId should be specified (default is 0)
  /// @param _beneficiary - address of the beneficiary
  /// @param _vestingId - the ID of the vesting (default is 0)
  function getAvailableAmount(address _beneficiary, uint256 _vestingId)
    public
    view
    returns (uint256)
  {
    return
      getAvailableAmountAtTimestamp(_beneficiary, _vestingId, block.timestamp);
  }

  /// @notice Returns amount of funds that beneficiary will be able to withdraw at the given timestamp per vesting ID (default is 0).
  /// @param _beneficiary - address of the beneficiary
  /// @param _vestingId - the ID of the vesting (default is 0)
  /// @param _timestamp - Timestamp (in seconds) on which the beneficiary wants to check the withdrawable amount.
  function getAvailableAmountAtTimestamp(
    address _beneficiary,
    uint256 _vestingId,
    uint256 _timestamp
  ) public view returns (uint256) {
    if (_vestingId >= vestingMap[_beneficiary].length) {
      return 0;
    }

    Vesting memory vesting = vestingMap[_beneficiary][_vestingId];

    uint256 periodsPassed = _timestamp.sub(vesting.startedAt).div(90 days); // We say that 3 months are always 90 days

    uint256 alreadyReleased = vesting.releasedAmount;

    if (periodsPassed >= STEPS_AMOUNT) {
      return vesting.totalAmount.sub(alreadyReleased);
    }

    uint256 phase1Peroids = 12;
    if (periodsPassed <= phase1Peroids) {
      return
        vesting.totalAmount.mul(7).mul(periodsPassed).div(100).sub(
          alreadyReleased
        );
    } else {
      uint256 phase2PeriodsPassed = periodsPassed.sub(phase1Peroids);
      uint256 rewardPhase1 = vesting.totalAmount.mul(7).mul(phase1Peroids).div(
        100
      );
      uint256 rewardPhase2 = vesting
        .totalAmount
        .mul(2)
        .mul(phase2PeriodsPassed)
        .div(100);
      return rewardPhase1.add(rewardPhase2).sub(alreadyReleased);
    }
  }

  /// @notice Returns amount of unallocated funds that contract owner can withdraw
  function getUnallocatedFundsAmount() public view returns (uint256) {
    uint256 debt = totalVestedAmount.sub(totalReleasedAmount);
    uint256 available = token.balanceOf(address(this)).sub(debt);
    return available;
  }
}