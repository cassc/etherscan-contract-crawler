// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {IXERC20} from '../interfaces/IXERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {ERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract XERC20 is ERC20, Ownable, IXERC20, ERC20Permit {
  /**
   * @notice The duration it takes for the limits to fully replenish
   */
  uint256 private constant _DURATION = 1 days;

  /**
   * @notice The address of the factory which deployed this contract
   */
  address public immutable FACTORY;

  /**
   * @notice The address of the lockbox contract
   */
  address public lockbox;

  /**
   * @notice Maps bridge address to bridge configurations
   */
  mapping(address => Bridge) public bridges;

  /**
   * @notice Constructs the initial config of the XERC20
   *
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _factory The factory which deployed this contract
   */

  constructor(
    string memory _name,
    string memory _symbol,
    address _factory
  ) ERC20(string.concat('x', _name), string.concat('x', _symbol)) ERC20Permit(string.concat('x', _name)) {
    _transferOwnership(_factory);
    FACTORY = _factory;
  }

  /**
   * @notice Mints tokens for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens minted
   * @param _amount The amount of tokens being minted
   */

  function mint(address _user, uint256 _amount) public {
    _mintWithCaller(msg.sender, _user, _amount);
  }

  /**
   * @notice Burns tokens for a user
   * @dev Can only be called by a bridge
   * @param _user The address of the user who needs tokens burned
   * @param _amount The amount of tokens being burned
   */

  function burn(address _user, uint256 _amount) public {
    if (msg.sender != _user) {
      _spendAllowance(_user, msg.sender, _amount);
    }

    _burnWithCaller(msg.sender, _user, _amount);
  }

  /**
   * @notice Sets the lockbox address
   *
   * @param _lockbox The address of the lockbox
   */

  function setLockbox(address _lockbox) public {
    if (msg.sender != FACTORY) revert IXERC20_NotFactory();
    lockbox = _lockbox;

    emit LockboxSet(_lockbox);
  }

  /**
   * @notice Updates the limits of any bridge
   * @dev Can only be called by the owner
   * @param _mintingLimit The updated minting limit we are setting to the bridge
   * @param _burningLimit The updated burning limit we are setting to the bridge
   * @param _bridge The address of the bridge we are setting the limits too
   */
  function setLimits(address _bridge, uint256 _mintingLimit, uint256 _burningLimit) external onlyOwner {
    _changeMinterLimit(_bridge, _mintingLimit);
    _changeBurnerLimit(_bridge, _burningLimit);
    emit BridgeLimitsSet(_mintingLimit, _burningLimit, _bridge);
  }

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function mintingMaxLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = bridges[_bridge].minterParams.maxLimit;
  }

  /**
   * @notice Returns the max limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function burningMaxLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = bridges[_bridge].burnerParams.maxLimit;
  }

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function mintingCurrentLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = _getCurrentLimit(
      bridges[_bridge].minterParams.currentLimit,
      bridges[_bridge].minterParams.maxLimit,
      bridges[_bridge].minterParams.timestamp,
      bridges[_bridge].minterParams.ratePerSecond
    );
  }

  /**
   * @notice Returns the current limit of a bridge
   *
   * @param _bridge the bridge we are viewing the limits of
   * @return _limit The limit the bridge has
   */

  function burningCurrentLimitOf(address _bridge) public view returns (uint256 _limit) {
    _limit = _getCurrentLimit(
      bridges[_bridge].burnerParams.currentLimit,
      bridges[_bridge].burnerParams.maxLimit,
      bridges[_bridge].burnerParams.timestamp,
      bridges[_bridge].burnerParams.ratePerSecond
    );
  }

  /**
   * @notice Uses the limit of any bridge
   * @param _bridge The address of the bridge who is being changed
   * @param _change The change in the limit
   */

  function _useMinterLimits(address _bridge, uint256 _change) internal {
    uint256 _currentLimit = mintingCurrentLimitOf(_bridge);
    bridges[_bridge].minterParams.timestamp = block.timestamp;
    bridges[_bridge].minterParams.currentLimit = _currentLimit - _change;
  }

  /**
   * @notice Uses the limit of any bridge
   * @param _bridge The address of the bridge who is being changed
   * @param _change The change in the limit
   */

  function _useBurnerLimits(address _bridge, uint256 _change) internal {
    uint256 _currentLimit = burningCurrentLimitOf(_bridge);
    bridges[_bridge].burnerParams.timestamp = block.timestamp;
    bridges[_bridge].burnerParams.currentLimit = _currentLimit - _change;
  }

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _bridge The address of the bridge we are setting the limit too
   * @param _limit The updated limit we are setting to the bridge
   */

  function _changeMinterLimit(address _bridge, uint256 _limit) internal {
    uint256 _oldLimit = bridges[_bridge].minterParams.maxLimit;
    uint256 _currentLimit = mintingCurrentLimitOf(_bridge);
    bridges[_bridge].minterParams.maxLimit = _limit;

    bridges[_bridge].minterParams.currentLimit = _calculateNewCurrentLimit(_limit, _oldLimit, _currentLimit);

    bridges[_bridge].minterParams.ratePerSecond = _limit / _DURATION;
    bridges[_bridge].minterParams.timestamp = block.timestamp;
  }

  /**
   * @notice Updates the limit of any bridge
   * @dev Can only be called by the owner
   * @param _bridge The address of the bridge we are setting the limit too
   * @param _limit The updated limit we are setting to the bridge
   */

  function _changeBurnerLimit(address _bridge, uint256 _limit) internal {
    uint256 _oldLimit = bridges[_bridge].burnerParams.maxLimit;
    uint256 _currentLimit = burningCurrentLimitOf(_bridge);
    bridges[_bridge].burnerParams.maxLimit = _limit;

    bridges[_bridge].burnerParams.currentLimit = _calculateNewCurrentLimit(_limit, _oldLimit, _currentLimit);

    bridges[_bridge].burnerParams.ratePerSecond = _limit / _DURATION;
    bridges[_bridge].burnerParams.timestamp = block.timestamp;
  }

  /**
   * @notice Updates the current limit
   *
   * @param _limit The new limit
   * @param _oldLimit The old limit
   * @param _currentLimit The current limit
   */

  function _calculateNewCurrentLimit(
    uint256 _limit,
    uint256 _oldLimit,
    uint256 _currentLimit
  ) internal pure returns (uint256 _newCurrentLimit) {
    uint256 _difference;

    if (_oldLimit > _limit) {
      _difference = _oldLimit - _limit;
      _newCurrentLimit = _currentLimit > _difference ? _currentLimit - _difference : 0;
    } else {
      _difference = _limit - _oldLimit;
      _newCurrentLimit = _currentLimit + _difference;
    }
  }

  /**
   * @notice Gets the current limit
   *
   * @param _currentLimit The current limit
   * @param _maxLimit The max limit
   * @param _timestamp The timestamp of the last update
   * @param _ratePerSecond The rate per second
   */

  function _getCurrentLimit(
    uint256 _currentLimit,
    uint256 _maxLimit,
    uint256 _timestamp,
    uint256 _ratePerSecond
  ) internal view returns (uint256 _limit) {
    _limit = _currentLimit;
    if (_limit == _maxLimit) {
      return _limit;
    } else if (_timestamp + _DURATION <= block.timestamp) {
      _limit = _maxLimit;
    } else if (_timestamp + _DURATION > block.timestamp) {
      uint256 _timePassed = block.timestamp - _timestamp;
      uint256 _calculatedLimit = _limit + (_timePassed * _ratePerSecond);
      _limit = _calculatedLimit > _maxLimit ? _maxLimit : _calculatedLimit;
    }
  }

  /**
   * @notice Internal function for burning tokens
   *
   * @param _caller The caller address
   * @param _user The user address
   * @param _amount The amount to burn
   */

  function _burnWithCaller(address _caller, address _user, uint256 _amount) internal {
    if (_caller != lockbox) {
      uint256 _currentLimit = burningCurrentLimitOf(_caller);
      if (_currentLimit < _amount) revert IXERC20_NotHighEnoughLimits();
      _useBurnerLimits(_caller, _amount);
    }
    _burn(_user, _amount);
  }

  /**
   * @notice Internal function for minting tokens
   *
   * @param _caller The caller address
   * @param _user The user address
   * @param _amount The amount to mint
   */

  function _mintWithCaller(address _caller, address _user, uint256 _amount) internal {
    if (_caller != lockbox) {
      uint256 _currentLimit = mintingCurrentLimitOf(_caller);
      if (_currentLimit < _amount) revert IXERC20_NotHighEnoughLimits();
      _useMinterLimits(_caller, _amount);
    }
    _mint(_user, _amount);
  }
}