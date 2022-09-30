// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './base/SimpleOracle.sol';
import './libraries/TokenSorting.sol';
import '../interfaces/IOracleAggregator.sol';

contract OracleAggregator is AccessControl, SimpleOracle, IOracleAggregator {
  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  // A list of available oracles. Oracles first on the array will take precedence over those that come later
  ITokenPriceOracle[] internal _availableOracles;
  mapping(bytes32 => OracleAssignment) internal _assignedOracle; // key(tokenA, tokenB) => oracle

  constructor(
    address[] memory _initialOracles,
    address _superAdmin,
    address[] memory _initialAdmins
  ) {
    if (_superAdmin == address(0)) revert ZeroAddress();
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }

    if (_initialOracles.length > 0) {
      for (uint256 i; i < _initialOracles.length; i++) {
        _revertIfNotOracle(_initialOracles[i]);
        _availableOracles.push(ITokenPriceOracle(_initialOracles[i]));
      }
      emit OracleListUpdated(_initialOracles);
    }
  }

  /// @inheritdoc ITokenPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool) {
    uint256 _length = _availableOracles.length;
    for (uint256 i; i < _length; i++) {
      if (_availableOracles[i].canSupportPair(_tokenA, _tokenB)) {
        return true;
      }
    }
    return false;
  }

  /// @inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address _tokenA, address _tokenB) public view override(ITokenPriceOracle, SimpleOracle) returns (bool) {
    ITokenPriceOracle _oracle = assignedOracle(_tokenA, _tokenB).oracle;
    // We check if the oracle still supports the pair, since it might have lost support
    return address(_oracle) != address(0) && _oracle.isPairAlreadySupported(_tokenA, _tokenB);
  }

  /// @inheritdoc ITokenPriceOracle
  function quote(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    bytes calldata _data
  ) external view returns (uint256 _amountOut) {
    ITokenPriceOracle _oracle = assignedOracle(_tokenIn, _tokenOut).oracle;
    if (address(_oracle) == address(0)) revert PairNotSupportedYet(_tokenIn, _tokenOut);
    return _oracle.quote(_tokenIn, _amountIn, _tokenOut, _data);
  }

  /// @inheritdoc ITokenPriceOracle
  function addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) external override(ITokenPriceOracle, SimpleOracle) {
    OracleAssignment memory _assignment = assignedOracle(_tokenA, _tokenB);
    if (_canModifySupportForPair(_tokenA, _tokenB, _assignment)) {
      _addOrModifySupportForPair(_tokenA, _tokenB, _data);
    }
  }

  /// @inheritdoc IOracleAggregator
  function assignedOracle(address _tokenA, address _tokenB) public view returns (OracleAssignment memory) {
    return _assignedOracle[_keyForPair(_tokenA, _tokenB)];
  }

  /// @inheritdoc IOracleAggregator
  function availableOracles() external view returns (ITokenPriceOracle[] memory) {
    return _availableOracles;
  }

  /// @inheritdoc IOracleAggregator
  function previewAddOrModifySupportForPair(address _tokenA, address _tokenB) external view returns (ITokenPriceOracle) {
    OracleAssignment memory _assignment = assignedOracle(_tokenA, _tokenB);
    return _canModifySupportForPair(_tokenA, _tokenB, _assignment) ? _findFirstOracleThatCanSupportPair(_tokenA, _tokenB) : _assignment.oracle;
  }

  /// @inheritdoc IOracleAggregator
  function forceOracle(
    address _tokenA,
    address _tokenB,
    address _oracle,
    bytes calldata _data
  ) external onlyRole(ADMIN_ROLE) {
    _revertIfNotOracle(_oracle);
    _setOracle(_tokenA, _tokenB, ITokenPriceOracle(_oracle), _data, true);
  }

  /// @inheritdoc IOracleAggregator
  function setAvailableOracles(address[] calldata _oracles) external onlyRole(ADMIN_ROLE) {
    uint256 _currentAvailableOracles = _availableOracles.length;
    uint256 _min = _currentAvailableOracles < _oracles.length ? _currentAvailableOracles : _oracles.length;

    uint256 i;
    for (; i < _min; i++) {
      // Rewrite storage
      _revertIfNotOracle(_oracles[i]);
      _availableOracles[i] = ITokenPriceOracle(_oracles[i]);
    }
    if (_currentAvailableOracles < _oracles.length) {
      // If have more oracles than before, then push
      for (; i < _oracles.length; i++) {
        _revertIfNotOracle(_oracles[i]);
        _availableOracles.push(ITokenPriceOracle(_oracles[i]));
      }
    } else if (_currentAvailableOracles > _oracles.length) {
      // If have less oracles than before, then remove extra oracles
      for (; i < _currentAvailableOracles; i++) {
        _availableOracles.pop();
      }
    }

    emit OracleListUpdated(_oracles);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override(AccessControl, BaseOracle) returns (bool) {
    return
      _interfaceId == type(IOracleAggregator).interfaceId ||
      AccessControl.supportsInterface(_interfaceId) ||
      BaseOracle.supportsInterface(_interfaceId);
  }

  /**
   * @notice Checks all oracles again and re-assigns the first that supports the given pair.
   *         It will also reconfigure the assigned oracle
   */
  function _addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) internal virtual override {
    ITokenPriceOracle _oracle = _findFirstOracleThatCanSupportPair(_tokenA, _tokenB);
    if (address(_oracle) == address(0)) revert PairCannotBeSupported(_tokenA, _tokenB);
    _setOracle(_tokenA, _tokenB, _oracle, _data, false);
  }

  function _canModifySupportForPair(
    address _tokenA,
    address _tokenB,
    OracleAssignment memory _assignment
  ) internal view returns (bool) {
    /* 
      Only modify if one of the following is true:
        - There is no current oracle
        - The current oracle hasn't been forced by an admin
        - The current oracle has been forced but it has lost support for the pair
        - The caller is an admin
    */
    return !_assignment.forced || hasRole(ADMIN_ROLE, msg.sender) || !_assignment.oracle.isPairAlreadySupported(_tokenA, _tokenB);
  }

  function _findFirstOracleThatCanSupportPair(address _tokenA, address _tokenB) internal view returns (ITokenPriceOracle) {
    uint256 _length = _availableOracles.length;
    for (uint256 i; i < _length; i++) {
      ITokenPriceOracle _oracle = _availableOracles[i];
      if (_oracle.canSupportPair(_tokenA, _tokenB)) {
        return _oracle;
      }
    }
    return ITokenPriceOracle(address(0));
  }

  function _setOracle(
    address _tokenA,
    address _tokenB,
    ITokenPriceOracle _oracle,
    bytes calldata _data,
    bool _forced
  ) internal {
    _oracle.addOrModifySupportForPair(_tokenA, _tokenB, _data);
    _assignedOracle[_keyForPair(_tokenA, _tokenB)] = OracleAssignment({oracle: _oracle, forced: _forced});
    emit OracleAssigned(_tokenA, _tokenB, _oracle);
  }

  function _revertIfNotOracle(address _oracleToCheck) internal view {
    bool _isOracle = ERC165Checker.supportsInterface(_oracleToCheck, type(ITokenPriceOracle).interfaceId);
    if (!_isOracle) revert AddressIsNotOracle(_oracleToCheck);
  }

  function _keyForPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    return keccak256(abi.encodePacked(__tokenA, __tokenB));
  }
}