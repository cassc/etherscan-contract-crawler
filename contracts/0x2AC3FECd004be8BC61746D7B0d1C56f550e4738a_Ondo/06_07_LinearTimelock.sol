// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "../interfaces/IOndo.sol";

abstract contract LinearTimelock {
  struct InvestorParam {
    IOndo.InvestorType investorType;
    uint96 initialBalance;
  }

  /// @notice the timestamp at which releasing is allowed
  uint256 public cliffTimestamp;
  /// @notice the linear vesting period for the first tranche
  uint256 public immutable tranche1VestingPeriod;
  /// @notice the linear vesting period for the second tranche
  uint256 public immutable tranche2VestingPeriod;
  /// @notice the linear vesting period for the Seed/Series A Tranche
  uint256 public immutable seedVestingPeriod;
  /// @dev mapping of balances for each investor
  mapping(address => InvestorParam) internal investorBalances;
  /// @notice role that allows updating of tranche balances - granted to Merkle airdrop contract
  bytes32 public constant TIMELOCK_UPDATE_ROLE =
    keccak256("TIMELOCK_UPDATE_ROLE");

  constructor(
    uint256 _cliffTimestamp,
    uint256 _tranche1VestingPeriod,
    uint256 _tranche2VestingPeriod,
    uint256 _seedVestingPeriod
  ) {
    cliffTimestamp = _cliffTimestamp;
    tranche1VestingPeriod = _tranche1VestingPeriod;
    tranche2VestingPeriod = _tranche2VestingPeriod;
    seedVestingPeriod = _seedVestingPeriod;
  }

  function passedCliff() public view returns (bool) {
    return block.timestamp > cliffTimestamp;
  }

  /// @dev the seedVestingPeriod is the longest vesting period
  function passedAllVestingPeriods() public view returns (bool) {
    return block.timestamp > cliffTimestamp + seedVestingPeriod;
  }

  /**
    @notice View function to get the user's initial balance and current amount of freed balance
   */
  function getVestedBalance(address account)
    external
    view
    returns (uint256, uint256)
  {
    if (investorBalances[account].initialBalance == 0) {
      return (0, 0);
    }
    InvestorParam memory investorParam = investorBalances[account];
    uint96 amountAvailable;
    if (passedAllVestingPeriods()) {
      amountAvailable = investorParam.initialBalance;
    } else if (passedCliff()) {
      (uint256 vestingPeriod, uint256 elapsed) = _getTrancheInfo(
        investorParam.investorType
      );
      amountAvailable = _proportionAvailable(
        elapsed,
        vestingPeriod,
        investorParam
      );
    } else {
      amountAvailable = 0;
    }
    return (investorParam.initialBalance, amountAvailable);
  }

  function _getTrancheInfo(IOndo.InvestorType investorType)
    internal
    view
    returns (uint256 vestingPeriod, uint256 elapsed)
  {
    elapsed = block.timestamp - cliffTimestamp;
    if (investorType == IOndo.InvestorType.CoinlistTranche1) {
      elapsed = elapsed > tranche1VestingPeriod
        ? tranche1VestingPeriod
        : elapsed;
      vestingPeriod = tranche1VestingPeriod;
    } else if (investorType == IOndo.InvestorType.CoinlistTranche2) {
      elapsed = elapsed > tranche2VestingPeriod
        ? tranche2VestingPeriod
        : elapsed;
      vestingPeriod = tranche2VestingPeriod;
    } else if (investorType == IOndo.InvestorType.SeedTranche) {
      elapsed = elapsed > seedVestingPeriod ? seedVestingPeriod : elapsed;
      vestingPeriod = seedVestingPeriod;
    }
  }

  function _proportionAvailable(
    uint256 elapsed,
    uint256 vestingPeriod,
    InvestorParam memory investorParam
  ) internal pure returns (uint96) {
    if (investorParam.investorType == IOndo.InvestorType.SeedTranche) {
      // Seed/Series A Tranche Balance = proportionAvail*2/3 + x/3, where x = Balance.
      // This allows 1/3 of the series A balance to be unlocked at cliff.
      uint96 vestedAmount = safe96(
        (((investorParam.initialBalance * elapsed) / vestingPeriod) * 2) / 3,
        "Ondo::_proportionAvailable: amount exceeds 96 bits"
      );
      return
        add96(
          vestedAmount,
          investorParam.initialBalance / 3,
          "Ondo::_proportionAvailable: overflow"
        );
    } else {
      return
        safe96(
          (investorParam.initialBalance * elapsed) / vestingPeriod,
          "Ondo::_proportionAvailable: amount exceeds 96 bits"
        );
    }
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint96)
  {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }
}