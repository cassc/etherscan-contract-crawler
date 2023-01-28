// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.16;

import "./interfaces/IRebaser.sol";
import "./interfaces/INFT.sol";
import "./interfaces/INFTFactoryOld.sol";
import "./openzeppelin/SafeMath.sol";
import "./openzeppelin/SafeERC20.sol";
import "./openzeppelin/Address.sol";
import "./token/BalanceManagement.sol";
import "./token/Frozen.sol";
import "./token/Whitelistable.sol";
import "./token/TradePair.sol";

contract ETFToken is BalanceManagement, Frozen, Whitelistable, TradePair {

  // Modifiers
  modifier onlyGov() {
    require(msg.sender == gov, "only governance");
    _;
  }

  modifier onlyRebaser() {
    require(msg.sender == rebaser);
    _;
  }

  modifier rebaseAtTheEnd() {
    _;
    if (msg.sender == tx.origin && rebaser != address(0)) {
      IRebaser(rebaser).checkRebase();
    }
  }

  modifier _beforeTokenTransfer(address from, address to, uint256 value) {
    updateTransferLimit(from, to, value);
    _;
  }

  modifier onlyMinter() {
    require(
      msg.sender == rebaser || msg.sender == gov,
      "not minter"
    );
    _;
  }

  modifier onlyHandlers() {
    require(
      INFTFactory(factory).isHandler(msg.sender) == true,
      "not Handler"
    );
    _;
  }

  modifier onlyEmergency() {
    require(
      msg.sender == guardian || msg.sender == gov,
      "not guardian or governor"
    );
    _;
  }

  modifier whenNotPaused() {
    require(_paused == false, "Pausable: paused");
    _;
  }
  modifier validRecipient(address to) {
    require(to != address(0x0));
    require(to != address(this));
    _;
  }

  function initialize(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  )
  internal
  {
    require(etfsScalingFactor == 0, "already initialized");
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
  }


  /**
  * @notice Computes the current max scaling factor
  */
  function maxScalingFactor()
  external
  view
  returns (uint256)
  {
    return _maxScalingFactor();
  }

  function _maxScalingFactor()
  internal
  view
  returns (uint256)
  {
    // scaling factor can only go up to 2**256-1 = initSupply * etfsScalingFactor
    // this is used to check if etfsScalingFactor will be too high to compute balances when rebasing.
    return uint256(- 1) / initSupply;
  }

  /**
  * @notice Allows the pausing and unpausing of certain functions .
  * @dev Limited to onlyEmergency modifier
  */
  function pause()
  public
  onlyEmergency
  {
    _paused = true;
    emit Paused(msg.sender);
  }

  function unpause()
  public
  onlyEmergency
  {
    _paused = false;
    emit Unpaused(msg.sender);
  }

  /**
  * @notice Mints new tokens, increasing totalSupply, initSupply, and a users balance.
  * @dev Limited to onlyMinter modifier
  */
  function mint(address to, uint256 amount)
  external
  onlyMinter
  whenNotPaused
  returns (bool)
  {
    _mint(to, amount);
    return true;
  }

  function _mint(address to, uint256 amount)
  internal
  {
    // increase totalSupply
    totalSupply = totalSupply.add(amount);

    // get underlying value
    uint256 etfValue = fragmentToETF(amount);

    // increase initSupply
    initSupply = initSupply.add(etfValue);

    // make sure the mint didnt push maxScalingFactor too low
    require(etfsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

    // add balance
    _etfBalances[to] = _etfBalances[to].add(etfValue);

    // add delegates to the minter
    _moveDelegates(address(0), _delegates[to], etfValue);
    _delegate(to, to);
    emit Mint(to, amount);
    emit Transfer(address(0), to, amount);
  }

  function mintForReferral(address to, uint256 amount)
  external
  onlyHandlers
  whenNotPaused
  returns (bool)
  {
    _mint(to, amount);
    return true;
  }
  /**
  * @notice Burns tokens, decreasing totalSupply, initSupply, and a users balance.
  */
  function burn(uint256 amount)
  external
  returns (bool)
  {
    _burn(msg.sender, amount);
    return true;
  }

  function _burn(address from, uint256 amount)
  internal
  {
    // increase totalSupply
    totalSupply = totalSupply.sub(amount);

    // get underlying value
    uint256 etfValue = fragmentToETF(amount);

    // increase initSupply
    initSupply = initSupply.sub(etfValue);

    // make sure the burn didnt push maxScalingFactor too low
    require(etfsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

    // sub balance, will revert on underflow
    _etfBalances[from] = _etfBalances[from].sub(etfValue);

    // remove delegates from the minter
    _moveDelegates(_delegates[from], address(0), etfValue);
    emit Burn(from, amount);
    emit Transfer(from, address(0), amount);
  }

  /**
  * @notice Burns tokens, decreasing totalSupply, initSupply, and a users balance.
  */

  function _writeBalanceCheckpoint(
    address sender,
    uint256 amount,
    uint256 balance
  )
  internal
  {
    if(_checkForStaleData(sender, block.timestamp)) {
      balanceDuringCheckpoint[sender] = balance;
      lastTransferTime[sender] = block.timestamp;
      totalTrackedTransfer[sender] = amount;
    }
    else
      totalTrackedTransfer[sender] = totalTrackedTransfer[sender].add(amount);
  }

  function _checkForStaleData(address sender, uint256 timestamp) public view returns (bool) {
    if((lastTransferTime[sender] + 24 hours) < timestamp) {
      return true;
    }
    return false;
  }

  function updateTransferLimit(address sender, address to, uint256 amount) internal {
    uint256 previousTransfers;
    uint256 balanceOnFirstTransfer;
    // TODO: Remove this logic on full release
    // require(to != dexPair,"Cannot trade on DEX for this release"); // This is logic is only for the temporary release
    // require(sender != dexPair,"Cannot trade on DEX for this release"); // This is logic is only for the temporary release

    if(_checkForStaleData(sender, block.timestamp)) {
      previousTransfers = 0;
      balanceOnFirstTransfer = 0;
    }
    else {
      balanceOnFirstTransfer = balanceDuringCheckpoint[sender];
      previousTransfers = totalTrackedTransfer[sender];
    }
    uint256 transferLimitPercent = 0;
    if (isTradePair(sender)) {
      // This is to allow users to Add, Remove Liquidity to Uniswap/Quickswap pools without limit
      // Buying the token also has no limit, Selling is based on other conditions below
      // No case where both are true
      // On Add liquidity, msg.sender is router
      // On Remove liquidity sender is Trading pair
      // On Buy Token Sender is Trading pair
      // On Sell Token Sender is User wallet and msg.sender is Trading pair, since it moves to other checks below
    }
    else if(isWhitelisted(sender) || isWhitelisted(to) ) {
      // transferLimitPercent = 100;  Statement unrequired, only here for documentation
      // No need to record checkpoint if the transfer was made to or from a whitelisted address
    } else {
      INFT NFTContract = INFT(NFT);
      uint256 ownedNFT = NFTContract.belongsTo(sender);
      if(ownedNFT == 0) // Incase they don't own any NFTs
        transferLimitPercent = 20;
      else {
        transferLimitPercent = NFTContract.getTransferLimit(ownedNFT);
      }
      if(balanceOnFirstTransfer == 0)
        balanceOnFirstTransfer = _etfBalances[sender];
      uint256 etfValueBalance =  balanceOnFirstTransfer;
      uint256 totalTransferLimit = etfValueBalance.mul(transferLimitPercent).div(100);
      uint256 etfValueAmount = fragmentToETF(amount);
      require(previousTransfers.add(etfValueAmount) <= totalTransferLimit, "Transfer above daily limit");
      _writeBalanceCheckpoint(sender, etfValueAmount, _etfBalances[sender]);
    }
  }

  /* - ERC20 functionality - */

  /**
  * @dev Transfer tokens to a specified address.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @return True on success, false otherwise.
  */
  function transfer(address to, uint256 value)
  external
  validRecipient(to)
  checkFrozen(msg.sender)
  whenNotPaused
  _beforeTokenTransfer(msg.sender, to, value)
  rebaseAtTheEnd
  returns (bool)
  {
    // underlying balance is stored in etfs, so divide by current scaling factor

    // note, this means as scaling factor grows, dust will be untransferrable.
    // minimum transfer value == etfsScalingFactor / 1e24;

    // get amount in underlying
    uint256 etfValue = fragmentToETF(value);

    // sub from balance of sender
    _etfBalances[msg.sender] = _etfBalances[msg.sender].sub(etfValue);

    // add to balance of receiver
    _etfBalances[to] = _etfBalances[to].add(etfValue);
    emit Transfer(msg.sender, to, value);

    _moveDelegates(_delegates[msg.sender], _delegates[to], etfValue);
    _delegate(to, to);
    return true;
  }

  // Transfer call that is only usable by handlers to distribute rewards
  function transferForRewards(address to, uint256 value)
  external
  validRecipient(to)
  checkFrozen(msg.sender)
  whenNotPaused
  rebaseAtTheEnd
  onlyHandlers
  returns (bool)
  {
    // underlying balance is stored in etfs, so divide by current scaling factor

    // note, this means as scaling factor grows, dust will be untransferrable.
    // minimum transfer value == etfsScalingFactor / 1e24;

    // get amount in underlying
    uint256 etfValue = fragmentToETF(value);

    // sub from balance of sender
    _etfBalances[msg.sender] = _etfBalances[msg.sender].sub(etfValue);

    // add to balance of receiver
    _etfBalances[to] = _etfBalances[to].add(etfValue);
    emit Transfer(msg.sender, to, value);

    _moveDelegates(_delegates[msg.sender], _delegates[to], etfValue);
    _delegate(to, to);
    return true;
  }

  /**
  * @dev Transfer tokens from one address to another.
  * @param from The address you want to send tokens from.
  * @param to The address you want to transfer to.
  * @param value The amount of tokens to be transferred.
  */
  function transferFrom(address from, address to, uint256 value)
  external
  rebaseAtTheEnd
  validRecipient(to)
  checkFrozen(from)
  _beforeTokenTransfer(from, to, value)
  whenNotPaused
  returns (bool)
  {
    // decrease allowance
    _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

    // get value in etfs
    uint256 etfValue = fragmentToETF(value);

    // sub from from
    _etfBalances[from] = _etfBalances[from].sub(etfValue);
    _etfBalances[to] = _etfBalances[to].add(etfValue);
    emit Transfer(from, to, value);

    _moveDelegates(_delegates[from], _delegates[to], etfValue);
    _delegate(to, to);
    return true;
  }

  /**
  * @param who The address to query.
  * @return The balance of the specified address.
  */
  function balanceOf(address who)
  external
  view
  returns (uint256)
  {
    return etfToFragment(_etfBalances[who]);
  }

  /** @notice Currently returns the internal storage amount
  * @param who The address to query.
  * @return The underlying balance of the specified address.
  */
  function balanceOfUnderlying(address who)
  external
  view
  returns (uint256)
  {
    return _etfBalances[who];
  }

  /**
   * @dev Function to check the amount of tokens that an owner has allowed to a spender.
   * @param owner_ The address which owns the funds.
   * @param spender The address which will spend the funds.
   * @return The number of tokens still available for the spender.
   */
  function allowance(address owner_, address spender)
  external
  view
  returns (uint256)
  {
    return _allowedFragments[owner_][spender];
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of
   * msg.sender. This method is included for ERC20 compatibility.
   * increaseAllowance and decreaseAllowance should be used instead.
   * Changing an allowance with this method brings the risk that someone may transfer both
   * the old and the new allowance - if they are both greater than zero - if a transfer
   * transaction is mined before the later approve() call is mined.
   *
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value)
  external
  rebaseAtTheEnd
  returns (bool)
  {
    _allowedFragments[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner has allowed to a spender.
   * This method should be used instead of approve() to avoid the double approval vulnerability
   * described above.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue)
  external
  rebaseAtTheEnd
  returns (bool)
  {
    _allowedFragments[msg.sender][spender] =
    _allowedFragments[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner has allowed to a spender.
   *
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
  external
  rebaseAtTheEnd
  returns (bool)
  {
    uint256 oldValue = _allowedFragments[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedFragments[msg.sender][spender] = 0;
    } else {
      _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  /* - Governance Functions - */

  /** @notice sets the rebaser
   * @param rebaser_ The address of the rebaser contract to use for authentication.
   */
  function _setRebaser(address rebaser_)
  external
  onlyEmergency
  {
    address oldRebaser = rebaser;
    rebaser = rebaser_;
    emit NewRebaser(oldRebaser, rebaser_);
  }

  /** @notice sets the emission
   * @param guardian_ The address of the guardian contract to use for authentication.
   */
  function _setGuardian(address guardian_)
  external
  onlyEmergency
  {
    require(block.timestamp < guardianExpiration); // Can only set new guardian if guardian powers havn't expired yet
    address oldGuardian = guardian;
    guardian = guardian_;
    emit NewGuardian(oldGuardian, guardian_);
  }

  function _setRouter(address _router)
  external
  onlyEmergency
  {
    router = _router;
  }

  function _setPair(address _dexPair)
  external
  onlyEmergency
  {
    dexPair = _dexPair;
  }

  function _setFactory(address _factory)
  external
  onlyEmergency
  {
    factory = _factory;
  }

  function _setNFT(address _NFT)
  external
  onlyEmergency
  {
    NFT = _NFT;
  }

  function freezeTargetFunds(address target)
  external
  onlyEmergency
  {
    require(lastFrozen[target].add(freezeDelay) < block.timestamp, "Target was Frozen recently");
    lastFrozen[target] = block.timestamp;
    _freezeAccount(target);
  }

  function unfreezeTargetFunds(address target)
  external
  onlyEmergency
  {
    _unfreezeAccount(target);
  }

  function whitelistAddress(address target)
  external
  onlyEmergency
  {
    _whitelistAccount(target);
  }

  function delistAddress(address target)
  external
  onlyEmergency
  {
    _delistAccount(target);
  }

  function addTradePair(address target)
  external
  onlyEmergency
  {
    _addPair(target);
  }

  function removeTradePair(address target)
  external
  onlyEmergency
  {
    _removePair(target);
  }

  /** @notice lets msg.sender abolish guardian
   *
   */
  function abolishGuardian()
  external
  {
    require(msg.sender == guardian || block.timestamp >= guardianExpiration); // Can be abolished by anyone after expiration or anytime by guardian themselves
    guardian = address(0);
  }

  /** @notice sets the pendingGov
   * @param pendingGov_ The address of the rebaser contract to use for authentication.
   */
  function _setPendingGov(address pendingGov_)
  external
  onlyGov
  {
    address oldPendingGov = pendingGov;
    pendingGov = pendingGov_;
    emit NewPendingGov(oldPendingGov, pendingGov_);
  }

  /** @notice lets msg.sender accept governance
   *
   */
  function _acceptGov()
  external
  {
    require(msg.sender == pendingGov, "!pending");
    address oldGov = gov;
    gov = pendingGov;
    pendingGov = address(0);
    emit NewGov(oldGov, gov);
  }

  /* - Extras - */

  /**
  * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
  *
  * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
  *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
  *      and targetRate is CpiOracleRate / baseCpi
  */
  function rebase(
    uint256 epoch,
    uint256 indexDelta,
    bool positive
  )
  external
  onlyRebaser
  returns (uint256)
  {
    // no change
    if (indexDelta == 0) {
      emit Rebase(epoch, etfsScalingFactor, etfsScalingFactor);
      return totalSupply;
    }

    // for events
    uint256 prevETFsScalingFactor = etfsScalingFactor;


    if (!positive) {
      // negative rebase, decrease scaling factor
      etfsScalingFactor = etfsScalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
    } else {
      // positive reabse, increase scaling factor
      uint256 newScalingFactor = etfsScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
      if (newScalingFactor < _maxScalingFactor()) {
        etfsScalingFactor = newScalingFactor;
      } else {
        etfsScalingFactor = _maxScalingFactor();
      }
    }

    // update total supply, correctly
    totalSupply = etfToFragment(initSupply);

    emit Rebase(epoch, prevETFsScalingFactor, etfsScalingFactor);
    return totalSupply;
  }

  function etfToFragment(uint256 etf)
  public
  view
  returns (uint256)
  {
    return etf.mul(etfsScalingFactor).div(internalDecimals);
  }

  function fragmentToETF(uint256 value)
  public
  view
  returns (uint256)
  {
    return value.mul(internalDecimals).div(etfsScalingFactor);
  }

  // Rescue tokens
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  )
  external
  onlyEmergency
  returns (bool)
  {
    // transfer to
    SafeERC20.safeTransfer(IERC20(token), to, amount);
    return true;
  }
}

contract ETF is ETFToken {

  constructor() public {}

  /**
   * @notice Initialize the new money market
   * @param name_ ERC-20 name of this token
   * @param symbol_ ERC-20 symbol of this token
   * @param decimals_ ERC-20 decimal precision of this token
   */
  function initialize(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    address initial_owner,
    uint256 initTotalSupply_
  )
  public
  {
    super.initialize(name_, symbol_, decimals_);
    etfsScalingFactor = BASE;
    initSupply = fragmentToETF(initTotalSupply_);
    totalSupply = initTotalSupply_;
    _etfBalances[initial_owner] = initSupply;
    _delegate(initial_owner, initial_owner);
    gov = initial_owner;
  }
}