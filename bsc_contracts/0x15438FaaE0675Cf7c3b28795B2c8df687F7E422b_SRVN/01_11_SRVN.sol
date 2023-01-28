pragma solidity 0.5.16;

import "../openzeppelin/IERC20.sol";
import "../openzeppelin/SafeERC20.sol";

import "./token/Governance.sol";
import "../token/Frozen.sol";

contract SRVNToken is GovernanceToken, Frozen {
  // Modifiers
  modifier onlyGov() {
    require(msg.sender == gov, "only governance");
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
  ) public {
    require(initialized == false, "already initialized");
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
  }

  /**
   * @notice Allows the pausing and unpausing of certain functions .
   * @dev Limited to onlyEmergency modifier
   */
  function pause() public onlyEmergency {
    _paused = true;
    emit Paused(msg.sender);
  }

  function unpause() public onlyEmergency {
    _paused = false;
    emit Unpaused(msg.sender);
  }

  /**
   * @notice Burns tokens, decreasing totalSupply, currentSupply, and a users balance.
   */
  function burn(uint256 amount) external returns (bool) {
    _burn(msg.sender, amount);
    return true;
  }

  function _burn(address from, uint256 amount) internal {
    // decrease totalSupply
    totalSupply = totalSupply.sub(amount);

    // decrease currentSupply
    currentSupply = currentSupply.sub(amount);

    // sub balance, will revert on underflow
    _balances[from] = _balances[from].sub(amount);

    // remove delegates from the user
    _moveDelegates(_delegates[from], address(0), amount);
    emit Burn(from, amount);
    emit Transfer(from, address(0), amount);
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
    returns (bool)
  {
    // sub from balance of sender
    _balances[msg.sender] = _balances[msg.sender].sub(value);

    // add to balance of receiver
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);

    _moveDelegates(_delegates[msg.sender], _delegates[to], value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param from The address you want to send tokens from.
   * @param to The address you want to transfer to.
   * @param value The amount of tokens to be transferred.
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external validRecipient(to) checkFrozen(from) whenNotPaused returns (bool) {
    // decrease allowance
    _allowedBalances[from][msg.sender] = _allowedBalances[from][msg.sender].sub(
      value
    );

    // sub from balance
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);

    _moveDelegates(_delegates[from], _delegates[to], value);
    return true;
  }

  /**
   * @param who The address to query.
   * @return The balance of the specified address.
   */
  function balanceOf(address who) external view returns (uint256) {
    return _balances[who];
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
    return _allowedBalances[owner_][spender];
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
  function approve(address spender, uint256 value) external returns (bool) {
    _allowedBalances[msg.sender][spender] = value;
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
    returns (bool)
  {
    _allowedBalances[msg.sender][spender] = _allowedBalances[msg.sender][
      spender
    ].add(addedValue);
    emit Approval(msg.sender, spender, _allowedBalances[msg.sender][spender]);
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
    returns (bool)
  {
    uint256 oldValue = _allowedBalances[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedBalances[msg.sender][spender] = 0;
    } else {
      _allowedBalances[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedBalances[msg.sender][spender]);
    return true;
  }

  /* - Governance Functions - */

  /** @notice sets the emission
   * @param emission_ The address of the emission contract to use for authentication.
   */
  function _setEmission(address emission_) external onlyGov {
    address oldEmission = emission;
    emission = emission_;
    emit NewEmission(oldEmission, emission_);
  }

  /** @notice sets the emission
   * @param guardian_ The address of the guardian contract to use for authentication.
   */
  function _setGuardian(address guardian_) external onlyEmergency {
    require(block.timestamp < guardianExpiration); // Can only set new guardian if guardian powers havn't expired yet
    address oldGuardian = guardian;
    guardian = guardian_;
    emit NewGuardian(oldGuardian, guardian_);
  }

  function freezeTargetFunds(address target) external onlyEmergency {
    require(
      lastFrozen[target].add(freezeDelay) < block.timestamp,
      "Target was Frozen recently"
    );
    lastFrozen[target] = block.timestamp;
    _freezeAccount(target);
  }

  function unfreezeTargetFunds(address target) external onlyEmergency {
    _unfreezeAccount(target);
  }

  /** @notice lets msg.sender abolish guardian
   *
   */
  function abolishGuardian() external {
    require(msg.sender == guardian || block.timestamp >= guardianExpiration); // Can be abolished by anyone after expiration or anytime by guardian themselves
    guardian = address(0);
  }

  /** @notice sets the pendingGov
   * @param pendingGov_ The address of the governor contract to use for authentication.
   */
  function _setPendingGov(address pendingGov_) external onlyGov {
    address oldPendingGov = pendingGov;
    pendingGov = pendingGov_;
    emit NewPendingGov(oldPendingGov, pendingGov_);
  }

  /** @notice lets msg.sender accept governance
   *
   */
  function _acceptGov() external {
    require(msg.sender == pendingGov, "!pending");
    address oldGov = gov;
    gov = pendingGov;
    pendingGov = address(0);
    emit NewGov(oldGov, gov);
  }

  // Rescue tokens
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external onlyGov returns (bool) {
    // transfer to
    SafeERC20.safeTransfer(IERC20(token), to, amount);
    return true;
  }
}

contract SRVN is SRVNToken {
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
    uint256 totalSupply_
  ) public {
    super.initialize(name_, symbol_, decimals_);

    initialized = true;
    currentSupply = totalSupply_;
    totalSupply = totalSupply_;
    _balances[initial_owner] = currentSupply;
    gov = initial_owner;
    guardian = initial_owner;
  }
}