// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./library/ExponentMath.sol";

import "./interfaces/IStakedToken.sol";
import "./interfaces/ITreasury.sol";

/// @title StakedToken
/// @author Bluejay Core Team
/// @notice StakedToken is the contract for sBLU token.
/// The token accumulates interest every second and maintains a
/// one-to-one ratio with the underlying BLU token.
contract StakedToken is Ownable, IStakedToken {
  using SafeERC20 for IERC20;

  uint256 private constant WAD = 10**18;
  uint256 private constant RAY = 10**27;

  /// @notice The name of the token
  string public constant name = "Staked BLU";

  /// @notice The symbol of the token
  string public constant symbol = "sBLU";

  /// @notice Contract address of the underlying BLU token
  IERC20 public immutable BLU;

  /// @notice Contract address of the treasury contract for minting BLU
  ITreasury public immutable treasury;

  /// @notice Interest rate per second, in RAY
  /// @dev To obtain the per second interest rate from APY:
  /// nthRoot(<APY-IN-RAY> + RAY, 365 * 24 * 60 * 60)
  uint256 public interestRate;

  /// @notice Accumulated interest rates, in RAY
  uint256 public accumulatedRates;

  /// @notice Last time the interest rate was updated, in unix epoch time
  uint256 public lastInterestRateUpdate;

  /// @notice Flag to pause staking
  bool public isStakePaused;

  /// @notice Flag to pause unstaking
  bool public isUnstakePaused;

  /// @notice Normalized total supply of token, in WAD
  uint256 public normalizedTotalSupply;

  /// @notice Minimum amount of normalized balance allowed for an address, in WAD
  /// Any account with balance lower than this number will be zeroed
  uint256 public minimumNormalizedBalance;

  /// @notice Mapping of addresses to their normalized token balances, in WAD
  mapping(address => uint256) public normalizedBalances;

  /// @notice Mapping of owners to spenders to spendable allowances, in WAD
  /// @dev Stored as allowances[owner][spender].
  /// Nore that the allowance is already denormalized
  mapping(address => mapping(address => uint256)) private allowances;

  /// @notice Constructor to initialize the contract
  /// @param _BLU Contract address of the underlying BLU token
  /// @param _treasury Contract address of the treasury contract for minting BLU
  /// @param _interestRate Interest rate per second, in RAY
  constructor(
    address _BLU,
    address _treasury,
    uint256 _interestRate
  ) {
    BLU = IERC20(_BLU);
    treasury = ITreasury(_treasury);

    lastInterestRateUpdate = block.timestamp;
    interestRate = _interestRate;
    accumulatedRates = RAY;
    minimumNormalizedBalance = WAD / 10**3; // 1/1000th of a BLU
    isStakePaused = true;

    emit UpdatedInterestRate(interestRate);
    emit UpdatedMinimumNormalizedBalance(minimumNormalizedBalance);
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to transfer token from one address to another
  /// @param sender Address of token sender
  /// @param recipient Address of token recipient
  /// @param normalizedAmount Amount of tokens to transfer, in normalized form
  function _transfer(
    address sender,
    address recipient,
    uint256 normalizedAmount
  ) internal {
    require(sender != address(0), "Transfer from the zero address");
    require(recipient != address(0), "Transfer to the zero address");

    require(
      normalizedBalances[sender] >= normalizedAmount,
      "Transfer amount exceeds balance"
    );

    _beforeTokenTransfer(sender, recipient, normalizedAmount);

    unchecked {
      normalizedBalances[sender] -= normalizedAmount;
    }
    normalizedBalances[recipient] += normalizedAmount;

    emit Transfer(sender, recipient, denormalize(normalizedAmount));

    _afterTokenTransfer(sender, recipient, normalizedAmount);
  }

  /// @notice Internal function to mint sBLU token to an address
  /// @param account Address of account to credit tokens to
  /// @param normalizedAmount Amount of tokens to mint, in normalized form
  function _mint(address account, uint256 normalizedAmount) internal {
    require(account != address(0), "Minting to the zero address");

    _beforeTokenTransfer(address(0), account, normalizedAmount);

    normalizedTotalSupply += normalizedAmount;
    normalizedBalances[account] += normalizedAmount;
    emit Transfer(address(0), account, denormalize(normalizedAmount));

    _afterTokenTransfer(address(0), account, normalizedAmount);
  }

  /// @notice Internal function to burn sBLU token from an address
  /// @param account Address of account to burn tokens from
  /// @param normalizedAmount Amount of tokens to burn, in normalized form
  function _burn(address account, uint256 normalizedAmount) internal {
    require(account != address(0), "Burn from the zero address");

    _beforeTokenTransfer(account, address(0), normalizedAmount);

    require(
      normalizedBalances[account] >= normalizedAmount,
      "Burn amount exceeds balance"
    );
    unchecked {
      normalizedBalances[account] -= normalizedAmount;
    }
    normalizedTotalSupply -= normalizedAmount;

    emit Transfer(account, address(0), denormalize(normalizedAmount));

    _afterTokenTransfer(account, address(0), normalizedAmount);
  }

  /// @notice Internal function to approve a spender to spend a certain amount of tokens
  /// @param owner Address of owner who is approving the spending
  /// @param spender Address of spender who is allowed to spend
  /// @param denormalizedAmount Amount of tokens as allowance, in denormalized form
  function _approve(
    address owner,
    address spender,
    uint256 denormalizedAmount
  ) internal {
    require(owner != address(0), "Approve from the zero address");
    require(spender != address(0), "Approve to the zero address");

    allowances[owner][spender] = denormalizedAmount;
    emit Approval(owner, spender, denormalizedAmount);
  }

  /// @notice Internal function to zero out balance on an address if the balance is too low
  /// @param account Address to check for small balances
  function _zeroMinimumBalances(address account) internal {
    if (
      normalizedBalances[account] < minimumNormalizedBalance &&
      normalizedBalances[account] != 0
    ) {
      // Cannot use _burn here because it would be recursive
      normalizedTotalSupply -= normalizedBalances[account];
      normalizedBalances[account] = 0;
    }
  }

  /// @notice Internal function to run before a token transfer occurs
  function _beforeTokenTransfer(
    address,
    address,
    uint256
  ) internal {}

  /// @notice Internal function to run after a token transfer occurs
  /// @dev A cleanup is run after every token transfer to remove accounts with negligible amount of tokens
  /// @param sender Address of token sender
  function _afterTokenTransfer(
    address sender,
    address,
    uint256
  ) internal {
    _zeroMinimumBalances(sender);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Staking function allowing users to convert BLU to sBLU at one-to-one ratio
  /// @dev The transfer may result in small rounding error due to normalization
  /// and denormalization. Dusty accounts will also be zeroed our after the process.
  /// @param amount Amount of BLU to stake, in WAD
  /// @param recipient Address of sBLU recipient
  /// @return success Whether the staking was successful
  function stake(uint256 amount, address recipient)
    public
    override
    returns (bool)
  {
    require(!isStakePaused, "Staking paused");
    require(recipient != address(0), "Staking to the zero address");
    BLU.safeTransferFrom(msg.sender, address(this), amount);
    _mint(recipient, normalize(amount));
    emit Stake(recipient, amount);
    return true;
  }

  /// @notice Unstaking function allowing users to convert sBLU to BLU at one-to-one ratio
  /// @dev The transfer may result in small rounding error due to normalization
  /// and denormalization. Dusty accounts will also be zeroed our after the process.
  /// Rebase is called each time to ensure this contact is sufficient funded with BLU
  /// tokens from the treasury.
  /// @param amount Amount of sBLU to unstake, in WAD
  /// @param recipient Address of BLU recipient
  /// @return success Whether the unstaking was successful
  function unstake(uint256 amount, address recipient)
    public
    override
    returns (bool)
  {
    require(!isUnstakePaused, "Unstaking paused");
    rebase();
    require(recipient != address(0), "Unstaking to the zero address");
    _burn(recipient, normalize(amount));
    BLU.safeTransfer(recipient, amount);
    emit Unstake(recipient, amount);
    return true;
  }

  /// @notice Transfer sBLU from one address to another
  /// @dev The transfer may result in small rounding error due to normalization
  /// and denormalization. Dusty accounts will also be zeroed our after the process.
  /// @param recipient Address of sBLU recipient
  /// @param amount Amount of sBLU to transfer, in WAD
  /// @return success Whether the transfer was successful
  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(msg.sender, recipient, normalize(amount));
    return true;
  }

  /// @notice Returns the remaining number of tokens that `spender` will be
  /// allowed to spend on behalf of `owner` through {transferFrom}. This is
  /// zero by default.
  /// @param owner Address of owner
  /// @param spender Address of spender
  /// @return allowance Amount of tokens that `spender` is allowed to spend from owner, in WAD
  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return allowances[owner][spender];
  }

  /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens
  /// @param spender Address of spender
  /// @param amount Amount of tokens that `spender` is allowed to spend, in WAD
  /// @return success Whether the allowance was set successfully
  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /// @notice Moves `amount` tokens from `from` to `to` using the
  /// allowance mechanism. `amount` is then deducted from the caller's
  /// allowance.
  /// @param sender Address of the sender of sBLU tokens
  /// @param recipient Address of the recipient of sBLU tokens
  /// @param amount Amount of sBLU tokens to transfer, in WAD
  /// @return success Whether the transfer was successful
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, normalize(amount));

    uint256 currentAllowance = allowances[sender][msg.sender];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, msg.sender, currentAllowance - amount);
    }

    return true;
  }

  /// @notice Atomically increases the allowance granted to `spender` by the caller
  /// @param spender Address of the spender to increase allowance for
  /// @param addedValue Amount of allowance to increment, in WAD
  /// @return success Whether the allowance increment was successful
  function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
  {
    _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
    return true;
  }

  /// @notice Atomically decreases the allowance granted to `spender` by the caller
  /// @param spender Address of the spender to decrease allowance for
  /// @param subtractedValue Amount of allowance to decrement, in WAD
  /// @return success Whether the allowance decrement was successful
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
  {
    uint256 currentAllowance = allowances[msg.sender][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }
    return true;
  }

  /// @notice Update the accumulated rate and the last updated timestamp
  /// @return accumulatedRates Updated accumulated interest rate
  function updateAccumulatedRate() public override returns (uint256) {
    accumulatedRates = currentAccumulatedRate();
    lastInterestRateUpdate = block.timestamp;
    return accumulatedRates;
  }

  /// @notice Rebase function that ensures the contract is funded with sufficient
  /// BLU tokens from the treasury to ensure that all unstake can be fulfilled.
  /// @return mintedTokens Amount of BLU tokens minted to this contract
  function rebase() public override returns (uint256 mintedTokens) {
    updateAccumulatedRate();
    uint256 mappedTokens = denormalize(normalizedTotalSupply);
    uint256 tokenBalance = BLU.balanceOf(address(this));
    if (tokenBalance < mappedTokens) {
      mintedTokens = mappedTokens - tokenBalance;
      treasury.mint(address(this), mintedTokens);
    }
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Sets the interest rate for the staking contract
  /// @dev The interest rate compounds per second and cannot be less than RAY to ensure
  /// balance is monotonic increasing.
  /// @param _interestRate Interest rate per second, in RAY
  function setInterestRate(uint256 _interestRate) public override onlyOwner {
    require(_interestRate >= RAY, "Interest rate less than 1");
    updateAccumulatedRate();
    interestRate = _interestRate;
    emit UpdatedInterestRate(interestRate);
  }

  /// @notice Sets the minimum amount of normalized balance on an account to prevent
  /// accounts from having extremely small amount of sBLU.
  /// @param _minimumNormalizedBalance Minimum normalized balance, in WAD
  function setMinimumNormalizedBalance(uint256 _minimumNormalizedBalance)
    public
    override
    onlyOwner
  {
    require(_minimumNormalizedBalance <= WAD, "Minimum balance greater than 1");
    minimumNormalizedBalance = _minimumNormalizedBalance;
    emit UpdatedMinimumNormalizedBalance(_minimumNormalizedBalance);
  }

  /// @notice Pause or unpause staking
  /// @param pause True to pause staking, false to unpause staking
  function setIsStakePaused(bool pause) public override onlyOwner {
    isStakePaused = pause;
    emit StakePaused(pause);
  }

  /// @notice Pause or unpause unstaking
  /// @param pause True to pause unstaking, false to unpause unstaking
  function setIsUnstakePaused(bool pause) public override onlyOwner {
    isUnstakePaused = pause;
    emit UnstakePaused(pause);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Number of decimals for sBLU token
  /// @return decimals Number of decimals for sBLU token
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /// @notice Total supply of sBLU token
  /// @return totalSupply Total supply of sBLU token
  function totalSupply() public view override returns (uint256) {
    return denormalize(normalizedTotalSupply);
  }

  /// @notice Token balance of `owner`
  /// @param account Address of account
  /// @return balance Token balance of `owner`
  function balanceOf(address account) public view override returns (uint256) {
    return denormalize(normalizedBalances[account]);
  }

  /// @notice Current compounded interest rate since the deployment of the contract
  /// @return accumulatedRates Current compounded interest rate, in RAY
  function currentAccumulatedRate() public view override returns (uint256) {
    require(block.timestamp >= lastInterestRateUpdate, "Invalid timestamp");
    return
      (compoundedInterest(block.timestamp - lastInterestRateUpdate) *
        accumulatedRates) / RAY;
  }

  /// @notice Denormalize a number by the accumulated interest rate
  /// @dev Use this to obtain the denormalized form used for presentation purposes
  /// @param amount Amount to denormalize
  /// @return denormalizedAmount Denormalized amount
  function denormalize(uint256 amount) public view override returns (uint256) {
    return (amount * currentAccumulatedRate()) / RAY;
  }

  /// @notice Normalize a number by the accumulated interest rate
  /// @dev Use this to obtain the normalized form used for storage purposes
  /// @param amount Amount to normalize
  /// @return normalizedAmount Normalized amount
  function normalize(uint256 amount) public view override returns (uint256) {
    return (amount * RAY) / currentAccumulatedRate();
  }

  /// @notice Current interest rate compounded by the timePeriod
  /// @dev Use this to obtain the interest rate over other periods of time like a year
  /// @param timePeriod Number of seconds to compound the interest rate by
  function compoundedInterest(uint256 timePeriod)
    public
    view
    override
    returns (uint256)
  {
    return ExponentMath.rpow(interestRate, timePeriod, RAY);
  }
}