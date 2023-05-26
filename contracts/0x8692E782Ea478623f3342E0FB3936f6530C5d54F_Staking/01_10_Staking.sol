// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IStakingContract.sol";
import "./StakeToken.sol";

contract Staking is Ownable, IStakingContract {
  using SafeMath for uint256;
  using SafeERC20 for StakeToken;

  uint256 private INTEREST_MUL_FACTOR = 10**6; // equals number of decimals in the interest rate
  uint256 private MAX_DAYS_INTEREST_ACCRUE = 10; // limits the exponent for one interest calc iteration to avoid overflows


  mapping (address => uint256) private _ownershipShares;

  uint256 private _totalStaked;
  uint256 private _totalShares;

  uint256 private _maxInterestRateDaily;
  uint256 private _interestRateDaily;
  uint256 private _lastInterestAccruedTimestamp;

  StakeToken private _stakeToken;

  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);
  event InterestPaid(uint256 amount, uint256 lastDayPaidTimestamp);

  /**
  * @param stakeTokenAddress: address of the staking token (need minting rights on it)
  * @param startingTimestamp: timestamp at launch (not trusting the miners to put it there)
  * @param maxInterestRate: hard cap on the interest rate set in the contract
  * @param startingInterestRate: interest rate at launch, represents 1e-6 daily percent (1/100 of a basis point)
  */
  constructor(
    address stakeTokenAddress,
    uint256 startingTimestamp,
    uint256 maxInterestRate,
    uint256 startingInterestRate
  ) {
    require(stakeTokenAddress != address(0), "Staking: Trying to set a zero address token");
    require(startingInterestRate <= maxInterestRate, "Staking: Initial interest rate is higher than maximum");
    require(maxInterestRate != 0, "Staking: Max interest rate cannot be zero");
    require(startingInterestRate != 0, "Staking: Starting interest rate cannot be zero");
    require(startingTimestamp >= block.timestamp.sub(1 days), "Staking: Setting the start of staking more than 1 day in the past");
    _stakeToken = StakeToken(stakeTokenAddress);
    _lastInterestAccruedTimestamp = startingTimestamp;
    _maxInterestRateDaily = maxInterestRate;
    _interestRateDaily = startingInterestRate;
  }

  /**
  * Stakes tokens for the user by pulling them, needs allowance. Accrues interest first.
  *
  * @param amount: how many tokens the contract will attempt to pull
  * @param data: required by ERC-900 for potential usage in signaling
  */
  function stake(uint256 amount, bytes calldata data) external {
    _accrueInterest();
    _stake(amount, msg.sender, msg.sender);
    emit Staked(msg.sender, amount, _totalStaked, data);
  }


  /**
  * Stakes tokens of the caller in favour of the user. Pulls from the caller, needs allowance.
  * Accrues interest first.
  *
  * @param user: beneficiary whose balance the pulled tokens will be added to
  * @param amount: how many tokens the contract will attempt to pull
  * @param data: required by ERC-900 for potential usage in signaling
  */
  function stakeFor(address user, uint256 amount, bytes calldata data) external {
    _accrueInterest();
    _stake(amount, msg.sender, user);
    emit Staked(user, amount, _totalStaked, data);
  }

  /**
  * Unstakes tokens of the caller and pushes them.
  * Accrues interest first.
  *
  * @param amount: how many tokens the contract will attempt to unstake & send
  * @param data: required by ERC-900 for potential usage in signaling
  */
  function unstake(uint256 amount, bytes calldata data) external {
    _accrueInterest();
    _unstake(amount, msg.sender);
    emit Unstaked(msg.sender, amount, _totalStaked, data);
  }

  /**
  * Accrues interest to date. It is also accrued by most operations.
  */
  function accrueInterest() external {
    _accrueInterest();
  }

  /**
  * Viewer for the total stake of the user, including tokens not yet minted, but virtually
  * accrued to date. Doesn't change state.
  *
  * @param addr: the user the balance is checked for
  */
  function totalStakedFor(address addr) public view returns (uint256) {
    return _totalShares == 0 ? 0 : _totalStakedWithInterest().mul(_ownershipShares[addr]).div(_totalShares);
  }

  /**
  * Viewer for the total amount of all stakes, including interest to date even if it's still virtual.
  */
  function totalStaked() public view returns (uint256) {
    return _totalStakedWithInterest();
  }

  /**
  * Viewer for the virtual interest to date that hasn't been minted yet.
  */
  function totalUnmintedInterest() public view override returns (uint256) {
    (uint256 unmintedInterest, ) = _calculateAccruedInterest();
    return unmintedInterest;
  }

  /**
  * Viewer for the interest rate.
  */
  function interestRate() public view returns (uint256) {
    return _interestRateDaily;
  }

  /**
  * Viewer for the address of the staking token.
  */
  function token() public view returns (address) {
    return address(_stakeToken);
  }

  /**
  * ERC-900: MUST return true if the optional history functions are implemented, otherwise false.
  */
  function supportsHistory() public pure returns (bool) {
    return false;
  }

  /**
  * Sets the interest rate, reverts if it exceeds the maximum which was set at launch.
  *
  * @param newInterestRate: daily interest rate in 1e-6 (1/100 of a basis point)
  */
  function setInterestRate(uint256 newInterestRate) external onlyOwner {
    require(newInterestRate <= _maxInterestRateDaily, "Staking: Interest rate is higher than allowed maximum");
    _accrueInterest();
    _interestRateDaily = newInterestRate;
  }

  /**
  * Internal implementation of stake.
  *
  * @param amount: how many tokens the contract will attempt to pull
  * @param sender: who is the contract pulling from
  * @param receiver: beneficiary whose balance and shares will be increased
  */
  function _stake(uint256 amount, address sender, address receiver) internal {
    require(amount > 0, "Staking: Trying to stake zero tokens");
    require(receiver != address(0), "Staking: Trying to stake to zero address");
    require(_stakeToken.balanceOf(sender) >= amount, "Staking: user balance is less than staked amount");
    require(_stakeToken.allowance(sender, address(this)) >= amount, "Staking: insufficient allowance to stake");


    uint256 amountBefore = _stakeToken.balanceOf(address(this));
    _stakeToken.safeTransferFrom(sender, address(this), amount);
    require(_stakeToken.balanceOf(address(this)) == amountBefore.add(amount), "Staking: Incorrect number of pulled tokens");

    uint256 newShares = _totalShares == 0 ? amount : _totalShares.mul(amount).div(_totalStaked);

    _totalStaked = _totalStaked.add(amount);

    _ownershipShares[receiver] = _ownershipShares[receiver].add(newShares);
    _totalShares = _totalShares.add(newShares);

  }

  /**
  * Internal implementation of unstake.
  *
  * @param amount: how many tokens the contract will attempt to unstake & return
  * @param user: whose balance of staked tokens and shares is being changed
  */
  function _unstake(uint256 amount, address user) internal {
    uint256 sharesToBurn = _totalShares.mul(amount).div(_totalStaked);

    require(sharesToBurn > 0, "Staking: User tries to unstake 0 or there are no stakers");
    require(_ownershipShares[user] >= sharesToBurn, "Staking: User tries to unstake more than their balance");

    _ownershipShares[user] = _ownershipShares[user].sub(sharesToBurn);
    _totalShares = _totalShares.sub(sharesToBurn);
    _totalStaked = _totalStaked.sub(amount);

    uint256 amountBefore = _stakeToken.balanceOf(address(this));
    _stakeToken.safeTransfer(user, amount);
    require(_stakeToken.balanceOf(address(this)) == amountBefore.sub(amount), "Staking: Incorrect number of refunded tokens");
  }

  /**
  * Accrues interest to date.
  */
  function _accrueInterest() internal {
    (uint256 tokensToMint, uint256 newTimestamp) = _calculateAccruedInterest();

    _lastInterestAccruedTimestamp = newTimestamp;

    if (tokensToMint > 0) {
      _mintStakeToken(tokensToMint);
      _totalStaked = _totalStaked.add(tokensToMint);

      emit InterestPaid(tokensToMint, newTimestamp);
    }
  }

  function _mintStakeToken(uint256 amount) internal {
    _stakeToken.mint(address(this), amount);
  }

  /**
  * Calculates the interest that should be accrued to date and the timestamp this accrual happened at.
  * Performs exponentiation iteratively (limited by MAX_DAYS_INTEREST_ACCRUE) to avoid overflows.
  */
  function _calculateAccruedInterest() internal view returns (uint256 interestAccrued, uint256 newTimestamp) {
    if (block.timestamp.sub(_lastInterestAccruedTimestamp) > 1 days) {
      uint256 daysElapsed = (block.timestamp.sub(_lastInterestAccruedTimestamp)).div(1 days);
      uint256 newBalance = _totalStaked;
      uint256 daysRemain = daysElapsed;

      while (daysRemain > 0) {
        if (daysRemain < MAX_DAYS_INTEREST_ACCRUE) {
          newBalance = newBalance.mul((uint256(INTEREST_MUL_FACTOR).add(_interestRateDaily))**daysRemain).div(INTEREST_MUL_FACTOR**daysRemain);
          daysRemain = 0;
        } else {
          newBalance = newBalance.mul((uint256(INTEREST_MUL_FACTOR).add(_interestRateDaily))**MAX_DAYS_INTEREST_ACCRUE).div(INTEREST_MUL_FACTOR**MAX_DAYS_INTEREST_ACCRUE);
          daysRemain = daysRemain.sub(MAX_DAYS_INTEREST_ACCRUE);
        }
      }

      uint256 interest = newBalance.sub(_totalStaked);
      uint256 timestamp = _lastInterestAccruedTimestamp.add(daysElapsed.mul(1 days));

      return (interest, timestamp);
    } else {
      return (0, _lastInterestAccruedTimestamp);
    }
  }

  /**
  * Viewer for the unminted interest.
  */
  function _totalStakedWithInterest() internal view returns (uint256) {
    (uint256 unmintedInterest, ) = _calculateAccruedInterest();
    return _totalStaked.add(unmintedInterest);
  }
}