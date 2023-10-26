// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

/**
 * @dev Allows accounts to be banlisted by a "banlister" role.
 */
abstract contract BanlistableUpgradeable is Initializable, AccessControlEnumerableUpgradeable {
  bytes32 public constant BANLISTER_ROLE = keccak256('BANLISTER_ROLE');
  mapping(address => bool) internal _banlisted;

  event Banlisted(address indexed _account);
  event UnBanlisted(address indexed _account);

  function __Banlistable_init() internal onlyInitializing {
    __AccessControlEnumerable_init_unchained();
  }

  /**
   * @dev Throws if argument account is banlisted.
   * @param _account The address to check.
   */
  modifier notBanlisted(address _account) {
    require(!_banlisted[_account], 'Banlistable: account is banlisted');
    _;
  }

  /**
   * @dev Throws if argument account is not banlisted.
   * @param _account The address to check.
   */
  modifier banlisted(address _account) {
    require(_banlisted[_account], 'Banlistable: account is not banlisted');
    _;
  }

  /**
   * @dev Checks if account is banlisted.
   * @param _account The address to check.
   */
  function isBanlisted(address _account) external view returns (bool) {
    return _banlisted[_account];
  }

  /**
   * @dev Adds account to banlist.
   * @param _account The address to banlist.
   * @return True if successful.
   *
   * Requirements:
   *
   * - only BANLISTER_ROLE can call this function.
   * - address is not already banlisted.
   */
  function banlist(
    address _account
  ) external notBanlisted(_account) onlyRole(BANLISTER_ROLE) returns (bool) {
    return _banlist(_account);
  }

  /**
   * @dev Adds account to banlist.
   * Internal function without access restriction.
   * @return True if successful.
   *
   * @param _account The address to banlist.
   */
  function _banlist(address _account) internal returns (bool) {
    _banlisted[_account] = true;
    emit Banlisted(_account);
    return true;
  }

  /**
   * @dev Removes account from banlist.
   * @param _account The address to remove from the banlist.
   * @return True if successful.
   *
   * Requirements:
   *
   * - only BANLISTER_ROLE can call this function.
   * - address is banlisted.
   */
  function unBanlist(
    address _account
  ) external banlisted(_account) onlyRole(BANLISTER_ROLE) returns (bool) {
    _banlisted[_account] = false;
    emit UnBanlisted(_account);
    return true;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

/**
 * @dev ERC20 with banlist and pause functionalities.
 *
 * Banlisted accounts can't change the ERC20 token state by any means.
 * Banlisting an account will change what will be possible to do with
 * that account, this varies according to the role.
 *
 * Normal account (no roles):
 * - Can't call functions: transfer, transferFrom, approve, increaseAllowance and decreaseAllowance.
 * - Is eligible to be clawbacked (funds withdraw).
 * - Is not eligible to be the receiving end from a mint or a transfer.
 * Account with mint role:
 * - All normal account restrictions.
 * - Can't call functions: mint and burn.
 * - Can't receive more allowance to mint tokens (receiving end from increaseMinterAllowance).
 * Account with pauser role:
 * - All normal account restrictions.
 * Account with banlister role:
 * - All normal account restrictions.
 */
abstract contract ERC20BanlistableUpgradable is
  Initializable,
  ERC20Upgradeable,
  BanlistableUpgradeable,
  PausableUpgradeable
{
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

  /**
   * @dev Triggers stopped state.
   * @return True if successful.
   *
   * Requirements:
   *
   * - only PAUSER_ROLE can call this function.
   */
  function pause() public onlyRole(PAUSER_ROLE) returns (bool) {
    _pause();
    return true;
  }

  /**
   * @dev Returns to normal state.
   * @return True if successful.
   *
   * Requirements:
   *
   * - only PAUSER_ROLE can call this function.
   */
  function unpause() public onlyRole(PAUSER_ROLE) returns (bool) {
    _unpause();
    return true;
  }

  function __ERC20Banlistable_init(
    string memory name_,
    string memory symbol_
  ) internal onlyInitializing {
    __ERC20_init_unchained(name_, symbol_);
    __Banlistable_init();
    __Pausable_init_unchained();
  }

  /**
   * @dev Override ERC20Upgradeable's transfer implementation.
   * @param _to The address that will receive the tokens.
   * @param _amount The amount of tokens to be transfered.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - `msg.sender` is not banlisted.
   * - `_to` is not banlisted.
   */
  function transfer(
    address _to,
    uint256 _amount
  ) public override whenNotPaused notBanlisted(msg.sender) notBanlisted(_to) returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  /**
   * @dev Override ERC20Upgradeable's increaseAllowance implementation.
   * @param _spender Spender's address.
   * @param _addedValue value that will be added.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - `_spender` is not banlisted.
   * - `msg.sender` is not banlisted.
   */
  function increaseAllowance(
    address _spender,
    uint256 _addedValue
  ) public override whenNotPaused notBanlisted(msg.sender) notBanlisted(_spender) returns (bool) {
    address owner = msg.sender;
    _approve(owner, _spender, allowance(owner, _spender) + _addedValue);
    return true;
  }

  /**
   * @dev Override ERC20Upgradeable's decreaseAllowance implementation.
   * @param _spender Spender's address.
   * @param _subtractedValue value that will be subtracted.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - `_spender` is not banlisted.
   * - `msg.sender` is not banlisted.
   */
  function decreaseAllowance(
    address _spender,
    uint256 _subtractedValue
  ) public override whenNotPaused notBanlisted(msg.sender) notBanlisted(_spender) returns (bool) {
    address owner = msg.sender;
    uint256 currentAllowance = allowance(owner, _spender);
    require(currentAllowance >= _subtractedValue, 'ERC20: decreased allowance below zero');
    unchecked {
      _approve(owner, _spender, currentAllowance - _subtractedValue);
    }
    return true;
  }

  /**
   * @dev Override ERC20Upgradeable's approve implementation.
   * @param _spender Spender's address.
   * @param _value Allowance amount.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - `_spender` is not banlisted.
   * - `msg.sender` is not banlisted.
   */
  function approve(
    address _spender,
    uint256 _value
  ) public override whenNotPaused notBanlisted(msg.sender) notBanlisted(_spender) returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Override ERC20Upgradeable's transferFrom implementation.
   * @param _from The address that will send the tokens.
   * @param _to The address that will receive the tokens.
   * @param _amount uint256 the amount of tokens to be transfered.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - `msg.sender` is not banlisted.
   * - `_from` is not banlisted.
   * - `_to` is not banlisted.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  )
    public
    override
    whenNotPaused
    notBanlisted(msg.sender)
    notBanlisted(_from)
    notBanlisted(_to)
    returns (bool)
  {
    _spendAllowance(_from, msg.sender, _amount);
    _transfer(_from, _to, _amount);
    return true;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

/**
 * @dev ERC20 with minter, banlist and pause functionalities.
 */
abstract contract MintableERC20Upgradable is Initializable, ERC20BanlistableUpgradable {
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  mapping(address => uint256) private _minterAllowances;

  event MinterApproval(address indexed minter, uint256 value);

  function __MintableERC20_init(
    string memory name_,
    string memory symbol_
  ) internal onlyInitializing {
    __ERC20Banlistable_init(name_, symbol_);
  }

  /**
   * @dev Function to mint tokens.
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint. Must be less than or equal
   * to the minterAllowance of the caller.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - only MINTER_ROLE can call this function.
   * - `msg.sender` is not banlisted.
   * - `_to` is not banlisted.
   * - `_amount` should be greater than 0.
   * - the caller must have allowance to mint tokens of at least `amount`.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    external
    whenNotPaused
    onlyRole(MINTER_ROLE)
    notBanlisted(msg.sender)
    notBanlisted(_to)
    returns (bool)
  {
    require(_amount > 0, 'MintableERC20: mint amount not greater than 0');

    if (hasRole(getRoleAdmin(MINTER_ROLE), msg.sender)) {
      _mint(_to, _amount);
    } else {
      require(
        _amount <= _minterAllowances[msg.sender],
        'MintableERC20: mint amount exceeds minterAllowance'
      );
      _mint(_to, _amount);
      unchecked {
        _minterAllowances[msg.sender] = _minterAllowances[msg.sender] - _amount;
      }
    }
    return true;
  }

  /**
   * @dev Allows a minter to burn some of its own tokens.
   * @param _amount uint256 the amount of tokens to be burned.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - only MINTER_ROLE can call this function.
   * - `msg.sender` is not banlisted.
   */
  function burn(
    uint256 _amount
  ) external whenNotPaused onlyRole(MINTER_ROLE) notBanlisted(msg.sender) returns (bool) {
    _burn(msg.sender, _amount);
    return true;
  }

  /**
   * @dev Returns the allowance of a minter address.
   */
  function minterAllowance(address _minter) public view returns (uint256) {
    return _minterAllowances[_minter];
  }

  /**
   * @dev Atomically increase `_minter`'s allowance.
   * @param _minter the minter address.
   * @param _addedValue the amount that will be added.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - only ADMIN of MINTER_ROLE can call this function.
   * - `_minter` is not banlisted.
   * - `_minter` is not the ADMIN of MINTER_ROLE.
   * - `_minter` has the role MINTER_ROLE.
   */
  function increaseMinterAllowance(
    address _minter,
    uint256 _addedValue
  )
    external
    whenNotPaused
    onlyRole(getRoleAdmin(MINTER_ROLE))
    notBanlisted(_minter)
    returns (bool)
  {
    require(
      !hasRole(getRoleAdmin(MINTER_ROLE), _minter),
      'MintableERC20: Not possible to increase allowance to the ADMIN of MINTER_ROLE'
    );
    _checkRole(MINTER_ROLE, _minter);
    _minterAllowances[_minter] += _addedValue;

    emit MinterApproval(_minter, _minterAllowances[_minter]);
    return true;
  }

  /**
   * @dev Atomically decrease `_minter`'s allowance.
   * @param _minter the minter address.
   * @param _subtractedValue the amount that will be subtracted.
   * @return True if successful.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   * - only ADMIN of MINTER_ROLE can call this function.
   * - `_minter` is not the ADMIN of MINTER_ROLE.
   * - `_minter` has the role MINTER_ROLE.
   */
  function decreaseMinterAllowance(
    address _minter,
    uint256 _subtractedValue
  ) external whenNotPaused onlyRole(getRoleAdmin(MINTER_ROLE)) returns (bool) {
    require(
      !hasRole(getRoleAdmin(MINTER_ROLE), _minter),
      'MintableERC20: Not possible to decrease allowance to MINTER ROLE ADMIN'
    );
    _checkRole(MINTER_ROLE, _minter);
    require(
      _minterAllowances[_minter] >= _subtractedValue,
      'MintableERC20: decreased minter allowance below zero'
    );
    _minterAllowances[_minter] -= _subtractedValue;

    emit MinterApproval(_minter, _minterAllowances[_minter]);
    return true;
  }

  /**
   * @dev Revoke MINTER_ROLE from an address, also removes it's minter's allowance.
   * @param _minter the minter that will be revoked.
   * @return True if successful.
   *
   * Requirements:
   *
   * - only ADMIN of MINTER_ROLE can call this function.
   * - `_minter` has the role MINTER_ROLE.
   */
  function revokeMinter(
    address _minter
  ) external onlyRole(getRoleAdmin(MINTER_ROLE)) returns (bool) {
    revokeRole(MINTER_ROLE, _minter);
    _minterAllowances[_minter] = 0;
    return true;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

/**
 * @dev ERC20 with clawback, minter, banlist and pause functionalities.
 */
abstract contract FiatTokenUpgradable is Initializable, MintableERC20Upgradable {
  function __FiatToken_init(string memory name_, string memory symbol_) internal onlyInitializing {
    __MintableERC20_init(name_, symbol_);
  }

  /**
   * @dev Allows a banlister to transfer all tokens from an banlisted address to a minter.
   * @param _banlisted the banlisted address where the tokens will be removed.
   * @param _minter the minter address that will recieve the tokens.
   * @return True if successful.
   *
   * Requirements:
   *
   * - only BANLISTER_ROLE can call this function.
   * - `_banlisted` is banlisted.
   * - `_minter` is not banlisted.
   * - `_minter` has the role MINTER_ROLE.
   */
  function clawback(
    address _banlisted,
    address _minter
  ) external onlyRole(BANLISTER_ROLE) banlisted(_banlisted) notBanlisted(_minter) returns (bool) {
    _checkRole(MINTER_ROLE, _minter);
    uint256 _banlistedBalance = balanceOf(_banlisted);
    _transfer(_banlisted, _minter, _banlistedBalance);
    return true;
  }

  /**
   * @dev Sets `adminRole` as `role`'s admin role.
   * @param _role the role's admin that will be changed.
   * @param _adminRole the new admin role.
   *
   * Requirements:
   *
   * - only ADMIN of `role` can call this function.
   */
  function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external onlyRole(getRoleAdmin(_role)) {
    _setRoleAdmin(_role, _adminRole);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

/**
 * @dev MBRL stable coin pegged to Brazilian Real.
 * This contract is the implementation contract based on the UUPS proxy pattern,
 * thus should not be called directly.
 */
contract MBRL is Initializable, FiatTokenUpgradable, UUPSUpgradeable {
  string public constant CURRENCY = 'BRL';
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

  /**
   * @dev Prevent the contract from being initialized or reinitialized to any version.
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Sets the name and symbol for the token. These values are immutable.
   * Sets the DEFAULT_ADMIN_ROLE to the msg.sender, and also grants all roles to it.
   * Banlist the contract address thus no ERC20 transaction to this address is allowed.
   */
  function initialize() public initializer {
    __FiatToken_init('Mercado Bitcoin BRL', 'MBRL');
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(BANLISTER_ROLE, msg.sender);
    _grantRole(UPGRADER_ROLE, msg.sender);
    _banlist(address(this));
  }

  /**
   * @dev Override ERC20Upgradeable's decimals implementation.
   */
  function decimals() public pure override returns (uint8) {
    return 6;
  }

  /**
   * @dev Override UUPSUpgradeable's _authorizeUpgrade implementation.
   *
   * Requirements:
   *
   * - only UPGRADER_ROLE can call this function.
   */
  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}