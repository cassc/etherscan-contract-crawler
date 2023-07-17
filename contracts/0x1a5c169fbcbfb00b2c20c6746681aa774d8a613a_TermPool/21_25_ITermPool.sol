// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITermPool {
  enum TermStatus {
    Created,
    Cancelled,
    Repayed
  }

  struct Term {
    uint256 minSize;
    uint256 maxSize;
    uint256 size;
    uint256 startDate;
    uint256 depositWindowMaturity;
    uint256 maturityDate;
    uint256 rewardRate;
    uint256 availableReward;
    TermStatus status;
    address tpToken;
  }

  event LiquidityProvided(address indexed lender, uint256 indexed termId, uint256 amount);
  event LiquidityRedeemed(address indexed lender, uint256 indexed termId, uint256 amount);
  event Borrowed(uint256 indexed termId, uint256 amount);
  event RewardTopUp(uint256 indexed termId, uint256 amount);
  event RewardDrop(uint256 indexed termId);
  event FactoryAddressChanged(address factory);
  event TermCreated(
    uint256 indexed termId,
    uint256 minSize,
    uint256 maxSize,
    uint256 startDate,
    uint256 depositWindow,
    uint256 maturity,
    uint256 rewardRate
  );
  event TermStatusChanged(uint256 indexed termId, TermStatus status);
  event PoolListingChanged(bool isListed);
  event PartialRepaymentAllowed(uint256 indexed termId);

  error TermDoesntExist(uint256 termId);
  error TermIsNotActive(uint256 termId);
  error NotBorrower(address sender);
  error NotFactory(address sender);
  error NotInDepositWindow(uint256 from, uint256 to, uint256 current);
  error NotInMaturityWindow(uint256 from, uint256 to, uint256 current);
  error NotEndedMaturity(uint256 maturity, uint256 current);
  error WrongTermState(TermStatus expected, TermStatus actual);
  error TermSizeIsTooSmall(uint256 min, uint256 actual);
  error MaxPoolSizeOverflow(uint256 max, uint256 actual);
  error TermCancelled(uint256 termId);
  error NotListed();
  error ZeroAmount();
  error NotEnoughReward();

  //---------------- ADMIN ACTIONS --------------
  /// @notice recover the IERC20 tokens in this pool if the lender has not claimed them within x days - in case lender loses keys or whatever.
  // function recover() external returns (bool);

  function __TermPool_init(address _baseToken, address _borrower, bool _isListed) external;

  function createTerm(
    uint256 _minSize, // minimum amount of liquidity that must be provided
    uint256 _maxSize, // maximum amount of liquidity that can be provided
    uint256 _startDate, // timestamp when the deposit window opens
    uint256 _depositWindow, // duration in seconds for deposit window
    uint256 _maturity, // duration in seconds for maturity
    uint256 _rewardRate //
  ) external;

  /// @notice can be called by the borrower to destroy this TermPool before any lenders have provided liquidity
  function cancelTerm(uint256 _termId) external;

  /// @notice borrower moves IERC20 tokens into the pool so that interest can be paid to lenders
  function topupReward(uint256 _termId, uint256 _amount) external;

  /// @notice only factory owner can withdraw reward that remains unused
  function withdrawReward(uint256 _termId) external;

  /// @notice only factory owner can allow reward that to ve partially repaid
  function allowPartialRepayment(uint256 _termId) external;

  function lock(uint256 _termId, uint256 _amount) external;

  function unlock(uint256 _termId) external;

  function setListed(bool _isListed) external;

  function borrower() external view returns (address);
}