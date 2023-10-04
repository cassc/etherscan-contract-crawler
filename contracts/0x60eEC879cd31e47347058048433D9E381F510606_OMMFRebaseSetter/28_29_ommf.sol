/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/external/openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/token/ERC20/IERC20MetadataUpgradeable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "contracts/kyc/KYCRegistryClientUpgradeable.sol";

/**
 * @title Interest-bearing ERC20-like token for OMMF.
 *
 * OMMF balances are dynamic and represent the holder's share in the total amount
 * of Cash controlled by the protocol. Account shares aren't normalized, so the
 * contract also stores the sum of all shares to calculate each account's token balance
 * which equals to:
 *
 *   shares[account] * depositedCash() / _getTotalShares()
 *
 * For example, assume that we have:
 *
 *   depositedCash() -> 10 USDC underlying OMMF
 *   sharesOf(user1) -> 100
 *   sharesOf(user2) -> 400
 *
 * Therefore:
 *
 *   balanceOf(user1) -> 2 tokens which corresponds 2 OMMF
 *   balanceOf(user2) -> 8 tokens which corresponds 8 OMMF
 *
 * Since balances of all token holders change when the amount of total pooled Cash
 * changes, this token cannot fully implement ERC20 standard: it only emits `Transfer`
 * events upon explicit transfer between holders. In contrast, when total amount of
 * pooled Cash increases, no `Transfer` events are generated: doing so would require
 * emitting an event for each token holder and thus running an unbounded loop.
 *
 */

contract OMMF is
  Initializable,
  ContextUpgradeable,
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable,
  KYCRegistryClientUpgradeable,
  IERC20Upgradeable,
  IERC20MetadataUpgradeable
{
  /**
   * @dev OMMF balances are dynamic and are calculated based on the accounts' shares
   * and the total amount of Cash controlled by the protocol. Account shares aren't
   * normalized, so the contract also stores the sum of all shares to calculate
   * each account's token balance which equals to:
   *
   *   shares[account] * depositedCash() / _getTotalShares()
   */
  mapping(address => uint256) private shares;

  /// @dev Allowances are nominated in tokens, not token shares.
  mapping(address => mapping(address => uint256)) private allowances;

  // Total shares in existence
  uint256 private totalShares;

  // Total cash in fund
  uint256 public depositedCash;

  // Address of the oracle that updates `depositedCash`
  address public oracle;

  /// @dev Role based access control roles
  bytes32 public constant OMMF_MANAGER_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURN_ROLE");
  bytes32 public constant KYC_CONFIGURER_ROLE =
    keccak256("KYC_CONFIGURER_ROLE");

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address admin,
    address kycRegistry,
    uint256 requirementGroup
  ) public virtual initializer {
    __OMMF_init(admin, kycRegistry, requirementGroup);
  }

  function __OMMF_init(
    address admin,
    address kycRegistry,
    uint256 requirementGroup
  ) internal onlyInitializing {
    __Pausable_init_unchained();
    __KYCRegistryClientInitializable_init_unchained(
      kycRegistry,
      requirementGroup
    );
    __OMMF_init_unchained(admin);
  }

  function __OMMF_init_unchained(address admin) internal onlyInitializing {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(OMMF_MANAGER_ROLE, admin);
    _grantRole(PAUSER_ROLE, admin);
    _grantRole(MINTER_ROLE, admin);
    _grantRole(BURNER_ROLE, admin);
    _grantRole(KYC_CONFIGURER_ROLE, admin);
  }

  /**
   * @notice An executed shares transfer from `sender` to `recipient`.
   *
   * @dev emitted in pair with an ERC20-defined `Transfer` event.
   */
  event TransferShares(
    address indexed from,
    address indexed to,
    uint256 sharesValue
  );

  /**
   * @notice Emitted when an oracle report (rebase) is executed
   *
   * @param oldDepositedCash The old NAV value.
   * @param newDepositedCash The new NAV value.
   */
  event OracleReportHandled(uint256 oldDepositedCash, uint256 newDepositedCash);

  /**
   * @return the name of the token.
   */
  function name() public pure returns (string memory) {
    return "Ondo Money Market Fund Token";
  }

  /**
   * @return the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public pure returns (string memory) {
    return "OMMF";
  }

  /**
   * @return the number of decimals for getting user representation of a token amount.
   */
  function decimals() public pure returns (uint8) {
    return 18;
  }

  /**
   * @return the amount of tokens in existence.
   *
   * @dev Always equals to `depositedCash()` since token amount
   * is pegged to the total amount of OMMF controlled by the protocol.
   */
  function totalSupply() public view returns (uint256) {
    return depositedCash;
  }

  /**
   * @return the amount of tokens owned by the `_account`.
   *
   * @dev Balances are dynamic and equal the `_account`'s share in the amount of the
   * total Cash controlled by the protocol. See `sharesOf`.
   */
  function balanceOf(address _account) public view returns (uint256) {
    return getBalanceOfByShares(_sharesOf(_account));
  }

  /**
   * @notice Moves `_amount` tokens from the caller's account to the `_recipient` account.
   *
   * @return a boolean value indicating whether the operation succeeded.
   * Emits a `Transfer` event.
   * Emits a `TransferShares` event.
   *
   * Requirements:
   *
   * - `_recipient` cannot be the zero address.
   * - the caller must have a balance of at least `_amount`.
   * - the contract must not be paused.
   *
   * @dev The `_amount` argument is the amount of tokens, not shares.
   */
  function transfer(address _recipient, uint256 _amount) public returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  /**
   * @return the remaining number of tokens that `_spender` is allowed to spend
   * on behalf of `_owner` through `transferFrom`. This is zero by default.
   *
   * @dev This value changes when `approve` or `transferFrom` is called.
   */
  function allowance(
    address _owner,
    address _spender
  ) public view returns (uint256) {
    return allowances[_owner][_spender];
  }

  /**
   * @notice Sets `_amount` as the allowance of `_spender` over the caller's tokens.
   *
   * @return a boolean value indicating whether the operation succeeded.
   * Emits an `Approval` event.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   * - the contract must not be paused.
   *
   * @dev The `_amount` argument is the amount of tokens, not shares.
   */
  function approve(address _spender, uint256 _amount) public returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  /**
   * @notice Moves `_amount` tokens from `_sender` to `_recipient` using the
   * allowance mechanism. `_amount` is then deducted from the caller's
   * allowance.
   *
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a `Transfer` event.
   * Emits a `TransferShares` event.
   * Emits an `Approval` event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `_sender` and `_recipient` cannot be the zero addresses.
   * - `_sender` must have a balance of at least `_amount`.
   * - the caller must have allowance for `_sender`'s tokens of at least `_amount`.
   * - the contract must not be paused.
   *
   * @dev The `_amount` argument is the amount of tokens, not shares.
   */
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) public returns (bool) {
    uint256 currentAllowance = allowances[_sender][msg.sender];
    require(currentAllowance >= _amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

    _transfer(_sender, _recipient, _amount);
    _approve(_sender, msg.sender, currentAllowance - _amount);
    return true;
  }

  /**
   * @notice Atomically increases the allowance granted to `_spender` by the caller by `_addedValue`.
   *
   * This is an alternative to `approve` that can be used as a mitigation for
   * problems described in:
   * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
   * Emits an `Approval` event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `_spender` cannot be the the zero address.
   * - the contract must not be paused.
   */
  function increaseAllowance(
    address _spender,
    uint256 _addedValue
  ) public returns (bool) {
    _approve(
      msg.sender,
      _spender,
      allowances[msg.sender][_spender] + _addedValue
    );
    return true;
  }

  /**
   * @notice Atomically decreases the allowance granted to `_spender` by the caller by `_subtractedValue`.
   *
   * This is an alternative to `approve` that can be used as a mitigation for
   * problems described in:
   * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol#L42
   * Emits an `Approval` event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `_spender` cannot be the zero address.
   * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
   * - the contract must not be paused.
   */
  function decreaseAllowance(
    address _spender,
    uint256 _subtractedValue
  ) public returns (bool) {
    uint256 currentAllowance = allowances[msg.sender][_spender];
    require(
      currentAllowance >= _subtractedValue,
      "DECREASED_ALLOWANCE_BELOW_ZERO"
    );
    _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
    return true;
  }

  /**
   * @return the total amount of shares in existence.
   *
   * @dev The sum of all accounts' shares can be an arbitrary number, therefore
   * it is necessary to store it in order to calculate each account's relative share.
   */
  function getTotalShares() public view returns (uint256) {
    return totalShares;
  }

  /**
   * @return the amount of shares owned by `_account`.
   */
  function sharesOf(address _account) public view returns (uint256) {
    return _sharesOf(_account);
  }

  /**
   * @return the amount of shares that corresponds to `cashAmount` protocol-controlled Cash.
   */
  function getSharesByPooledCash(
    uint256 _cashAmount
  ) public view returns (uint256) {
    uint256 totalPooledCash = depositedCash;
    if (totalPooledCash == 0) {
      return 0;
    } else {
      return (_cashAmount * totalShares) / totalPooledCash;
    }
  }

  /**
   * @return the amount of OMMF that corresponds to `_sharesAmount` token shares.
   */
  function getBalanceOfByShares(
    uint256 _sharesAmount
  ) public view returns (uint256) {
    if (totalShares == 0) {
      return 0;
    } else {
      return (_sharesAmount * depositedCash) / totalShares;
    }
  }

  /**
   * @notice Moves `_amount` tokens from `_sender` to `_recipient`.
   * Emits a `Transfer` event.
   * Emits a `TransferShares` event.
   */
  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal {
    uint256 _sharesToTransfer = getSharesByPooledCash(_amount);
    _transferShares(_sender, _recipient, _sharesToTransfer);
    emit Transfer(_sender, _recipient, _amount);
  }

  /**
   * @notice Sets `_amount` as the allowance of `_spender` over the `_owner` s tokens.
   *
   * Emits an `Approval` event.
   *
   * Requirements:
   *
   * - `_owner` cannot be the zero address.
   * - `_spender` cannot be the zero address.
   * - the contract must not be paused.
   */
  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) internal whenNotPaused {
    require(_owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
    require(_spender != address(0), "APPROVE_TO_ZERO_ADDRESS");

    allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  /**
   * @return the amount of shares owned by `_account`.
   */
  function _sharesOf(address _account) internal view returns (uint256) {
    return shares[_account];
  }

  /**
   * @notice Moves `_sharesAmount` shares from `_sender` to `_recipient`.
   *
   * Requirements:
   *
   * - `_sender` cannot be the zero address.
   * - `_recipient` cannot be the zero address.
   * - `_sender` must hold at least `_sharesAmount` shares.
   * - the contract must not be paused.
   */
  function _transferShares(
    address _sender,
    address _recipient,
    uint256 _sharesAmount
  ) internal whenNotPaused {
    require(_sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
    require(_recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");

    _beforeTokenTransfer(_sender, _recipient, _sharesAmount);

    uint256 currentSenderShares = shares[_sender];
    require(
      _sharesAmount <= currentSenderShares,
      "TRANSFER_AMOUNT_EXCEEDS_BALANCE"
    );

    shares[_sender] = currentSenderShares - _sharesAmount;
    shares[_recipient] = shares[_recipient] + _sharesAmount;
    emit TransferShares(_sender, _recipient, _sharesAmount);
  }

  /**
   * @notice Creates `_sharesAmount` shares and assigns them to `_recipient`, increasing the total amount of shares.
   * @dev This doesn't increase the token total supply.
   *
   * Requirements:
   *
   * - `_recipient` cannot be the zero address.
   * - the contract must not be paused.
   */
  function _mintShares(
    address _recipient,
    uint256 _sharesAmount
  ) internal whenNotPaused returns (uint256) {
    require(_recipient != address(0), "MINT_TO_THE_ZERO_ADDRESS");

    _beforeTokenTransfer(address(0), _recipient, _sharesAmount);

    totalShares += _sharesAmount;

    shares[_recipient] = shares[_recipient] + _sharesAmount;

    return totalShares;
  }

  /**
   * @notice Destroys `_sharesAmount` shares from `_account`'s holdings, decreasing the total amount of shares.
   * @dev This doesn't decrease the token total supply.
   *
   * Requirements:
   *
   * - `_account` cannot be the zero address.
   * - `_account` must hold at least `_sharesAmount` shares.
   * - the contract must not be paused.
   */
  function _burnShares(
    address _account,
    uint256 _sharesAmount
  ) internal whenNotPaused returns (uint256) {
    require(_account != address(0), "BURN_FROM_THE_ZERO_ADDRESS");

    _beforeTokenTransfer(_account, address(0), _sharesAmount);

    uint256 accountShares = shares[_account];
    require(_sharesAmount <= accountShares, "BURN_AMOUNT_EXCEEDS_BALANCE");

    totalShares -= _sharesAmount;

    shares[_account] = accountShares - _sharesAmount;

    return totalShares;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256
  ) internal virtual {
    if (from != _msgSender() && to != _msgSender()) {
      require(
        _getKYCStatus(_msgSender()),
        "OMMF: must be KYC'd to initiate transfer"
      );
    }

    if (from != address(0)) {
      // Only check KYC if not minting
      require(
        _getKYCStatus(from),
        "OMMF: `from` address must be KYC'd to send tokens"
      );
    }

    if (to != address(0)) {
      // Only check KYC if not burning
      require(
        _getKYCStatus(to),
        "OMMF: `to` address must be KYC'd to receive tokens"
      );
    }
  }

  /**
   * @notice Updates underlying cash in fund
   * @dev periodically called by the Oracle contract
   * @param _depositedCash Total cash in fund
   */
  function handleOracleReport(uint256 _depositedCash) external whenNotPaused {
    require(msg.sender == oracle, "OMMF: not oracle");
    uint256 oldDepositedCash = depositedCash;
    depositedCash = _depositedCash;
    emit OracleReportHandled(oldDepositedCash, _depositedCash);
  }

  /**
   * @notice Sets the Oracle address
   * @dev The new oracle can call `handleOracleReport` for rebases
   * @param _oracle Address of the new oracle
   */
  function setOracle(address _oracle) external onlyRole(OMMF_MANAGER_ROLE) {
    oracle = _oracle;
  }

  /**
   * @notice Send funds to the pool
   * @return Amount of OMMF shares generated
   */
  function mint(
    address user,
    uint256 depositAmount
  ) external onlyRole(MINTER_ROLE) returns (uint256) {
    require(depositAmount > 0, "OMMF: zero deposit amount");

    uint256 sharesAmount = getSharesByPooledCash(depositAmount);
    if (sharesAmount == 0) {
      // totalControlledCash is 0: first-ever deposit
      // assume that shares correspond to Cash 1-to-1
      sharesAmount = depositAmount;
    }

    _mintShares(user, sharesAmount);

    depositedCash += depositAmount;

    emit TransferShares(address(0), user, sharesAmount);
    emit Transfer(address(0), user, getBalanceOfByShares(sharesAmount));
    return sharesAmount;
  }

  /**
   * @notice Admin burn function to burn OMMF tokens from any account
   * @param _account The account to burn tokens from
   * @param _amount  The amount of OMMF tokens to burn
   */
  function adminBurn(
    address _account,
    uint256 _amount
  ) external onlyRole(BURNER_ROLE) {
    uint256 sharesAmount = getSharesByPooledCash(_amount);

    _burnShares(_account, sharesAmount);
    depositedCash -= _amount; // OMMF corresponds to deposited collateral 1:1
    emit TransferShares(_account, address(0), sharesAmount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @notice Burns `_amount` of OMMF tokens from msg.sender's holdings
   * @param _amount The amount of OMMF tokens to burn
   */
  function burn(uint256 _amount) external {
    require(
      getBalanceOfByShares(_sharesOf(msg.sender)) >= _amount,
      "BURN_AMOUNT_EXCEEDS_BALANCE"
    );
    uint256 sharesAmount = getSharesByPooledCash(_amount);
    _burnShares(msg.sender, sharesAmount);
    depositedCash -= _amount;

    emit TransferShares(msg.sender, address(0), sharesAmount);
    emit Transfer(msg.sender, address(0), _amount);
  }

  /**
   * @notice Burns `_amount` of OMMF tokens from `_account`'s holdings,
   *         deducting from the caller's allowance
   * @param _account Account to burn tokens from
   * @param _amount  Amount of tokens to burn
   * @dev Decrements shares as well as `depositedAmount`
   */
  function burnFrom(address _account, uint256 _amount) external {
    uint256 currentAllowance = allowances[_account][msg.sender];
    require(currentAllowance >= _amount, "BURN_AMOUNT_EXCEEDS_ALLOWANCE");

    uint256 sharesAmount = getSharesByPooledCash(_amount);

    _burnShares(_account, sharesAmount);
    depositedCash -= _amount; // OMMF corresponds to deposited collateral 1:1

    _approve(_account, msg.sender, currentAllowance - _amount);

    emit TransferShares(_account, address(0), sharesAmount);
    emit Transfer(_account, address(0), _amount);
  }

  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(OMMF_MANAGER_ROLE) {
    _unpause();
  }

  function setKYCRequirementGroup(
    uint256 group
  ) external override onlyRole(KYC_CONFIGURER_ROLE) {
    _setKYCRequirementGroup(group);
  }

  function setKYCRegistry(
    address registry
  ) external override onlyRole(KYC_CONFIGURER_ROLE) {
    _setKYCRegistry(registry);
  }
}