// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '../../interfaces//adapters/IUniswapV3Adapter.sol';
import '../libraries/TokenSorting.sol';
import '../base/SimpleOracle.sol';

contract UniswapV3Adapter is AccessControl, SimpleOracle, IUniswapV3Adapter {
  using SafeCast for uint256;

  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  /// @inheritdoc IUniswapV3Adapter
  IStaticOracle public immutable UNISWAP_V3_ORACLE;
  /// @inheritdoc IUniswapV3Adapter
  uint32 public immutable MAX_PERIOD;
  /// @inheritdoc IUniswapV3Adapter
  uint32 public immutable MIN_PERIOD;
  /// @inheritdoc IUniswapV3Adapter
  uint32 public period;
  /// @inheritdoc IUniswapV3Adapter
  uint8 public cardinalityPerMinute;
  /// @inheritdoc IUniswapV3Adapter
  uint104 public gasPerCardinality = 22_250;
  /// @inheritdoc IUniswapV3Adapter
  uint112 public gasCostToSupportPool = 30_000;

  mapping(bytes32 => bool) internal _isPairDenylisted; // key(tokenA, tokenB) => is denylisted
  mapping(bytes32 => address[]) internal _poolsForPair; // key(tokenA, tokenB) => pools

  constructor(InitialConfig memory _initialConfig) {
    if (_initialConfig.superAdmin == address(0)) revert ZeroAddress();
    UNISWAP_V3_ORACLE = _initialConfig.uniswapV3Oracle;
    MAX_PERIOD = _initialConfig.maxPeriod;
    MIN_PERIOD = _initialConfig.minPeriod;
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _initialConfig.superAdmin);
    for (uint256 i; i < _initialConfig.initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialConfig.initialAdmins[i]);
    }

    // Set the period
    if (_initialConfig.initialPeriod < MIN_PERIOD || _initialConfig.initialPeriod > MAX_PERIOD)
      revert InvalidPeriod(_initialConfig.initialPeriod);
    period = _initialConfig.initialPeriod;
    emit PeriodChanged(_initialConfig.initialPeriod);

    // Set cardinality, by using the oracle's default
    uint8 _cardinality = UNISWAP_V3_ORACLE.CARDINALITY_PER_MINUTE();
    cardinalityPerMinute = _cardinality;
    emit CardinalityPerMinuteChanged(_cardinality);
  }

  /// @inheritdoc ITokenPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool) {
    if (_isPairDenylisted[_keyForPair(_tokenA, _tokenB)]) {
      return false;
    }
    try UNISWAP_V3_ORACLE.getAllPoolsForPair(_tokenA, _tokenB) returns (address[] memory _pools) {
      return _pools.length > 0;
    } catch {
      return false;
    }
  }

  /// @inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address _tokenA, address _tokenB) public view override(ITokenPriceOracle, SimpleOracle) returns (bool) {
    return _poolsForPair[_keyForPair(_tokenA, _tokenB)].length > 0;
  }

  /// @inheritdoc ITokenPriceOracle
  function quote(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    bytes calldata
  ) external view returns (uint256) {
    address[] memory _pools = _poolsForPair[_keyForPair(_tokenIn, _tokenOut)];
    if (_pools.length == 0) revert PairNotSupportedYet(_tokenIn, _tokenOut);
    return UNISWAP_V3_ORACLE.quoteSpecificPoolsWithTimePeriod(_amountIn.toUint128(), _tokenIn, _tokenOut, _pools, period);
  }

  /// @inheritdoc IUniswapV3Adapter
  function isPairDenylisted(address _tokenA, address _tokenB) external view returns (bool) {
    return _isPairDenylisted[_keyForPair(_tokenA, _tokenB)];
  }

  /// @inheritdoc IUniswapV3Adapter
  function getPoolsPreparedForPair(address _tokenA, address _tokenB) external view returns (address[] memory) {
    return _poolsForPair[_keyForPair(_tokenA, _tokenB)];
  }

  /// @inheritdoc IUniswapV3Adapter
  function setPeriod(uint32 _newPeriod) external onlyRole(ADMIN_ROLE) {
    if (_newPeriod < MIN_PERIOD || _newPeriod > MAX_PERIOD) revert InvalidPeriod(_newPeriod);
    period = _newPeriod;
    emit PeriodChanged(_newPeriod);
  }

  /// @inheritdoc IUniswapV3Adapter
  function setCardinalityPerMinute(uint8 _cardinalityPerMinute) external onlyRole(ADMIN_ROLE) {
    if (_cardinalityPerMinute == 0) revert InvalidCardinalityPerMinute();
    cardinalityPerMinute = _cardinalityPerMinute;
    emit CardinalityPerMinuteChanged(_cardinalityPerMinute);
  }

  /// @inheritdoc IUniswapV3Adapter
  function setGasPerCardinality(uint104 _gasPerCardinality) external onlyRole(ADMIN_ROLE) {
    if (_gasPerCardinality == 0) revert InvalidGasPerCardinality();
    gasPerCardinality = _gasPerCardinality;
    emit GasPerCardinalityChanged(_gasPerCardinality);
  }

  /// @inheritdoc IUniswapV3Adapter
  function setGasCostToSupportPool(uint112 _gasCostToSupportPool) external onlyRole(ADMIN_ROLE) {
    if (_gasCostToSupportPool == 0) revert InvalidGasCostToSupportPool();
    gasCostToSupportPool = _gasCostToSupportPool;
    emit GasCostToSupportPoolChanged(_gasCostToSupportPool);
  }

  /// @inheritdoc IUniswapV3Adapter
  function setDenylisted(Pair[] calldata _pairs, bool[] calldata _denylisted) external onlyRole(ADMIN_ROLE) {
    if (_pairs.length != _denylisted.length) revert InvalidDenylistParams();
    for (uint256 i; i < _pairs.length; i++) {
      bytes32 _pairKey = _keyForPair(_pairs[i].tokenA, _pairs[i].tokenB);
      _isPairDenylisted[_pairKey] = _denylisted[i];
      if (_denylisted[i] && _poolsForPair[_pairKey].length > 0) {
        delete _poolsForPair[_pairKey];
      }
    }
    emit DenylistChanged(_pairs, _denylisted);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override(AccessControl, BaseOracle) returns (bool) {
    return
      _interfaceId == type(IUniswapV3Adapter).interfaceId ||
      AccessControl.supportsInterface(_interfaceId) ||
      BaseOracle.supportsInterface(_interfaceId);
  }

  function _addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata
  ) internal override {
    bytes32 _pairKey = _keyForPair(_tokenA, _tokenB);
    if (_isPairDenylisted[_pairKey]) revert PairCannotBeSupported(_tokenA, _tokenB);

    address[] memory _pools = _getAllPoolsSortedByLiquidity(_tokenA, _tokenB);
    if (_pools.length == 0) revert PairCannotBeSupported(_tokenA, _tokenB);

    // Load to mem to avoid multiple storage reads
    address[] storage _storagePools = _poolsForPair[_pairKey];
    uint256 _poolsPreviouslyInStorage = _storagePools.length;
    uint104 _gasCostPerCardinality = gasPerCardinality;
    uint112 _gasCostToSupportPool = gasCostToSupportPool;

    uint16 _targetCardinality = uint16((period * cardinalityPerMinute) / 60) + 1;
    uint256 _preparedPools;
    for (uint256 i; i < _pools.length; i++) {
      address _pool = _pools[i];
      (, , , , uint16 _currentCardinality, , ) = IUniswapV3Pool(_pool).slot0();
      if (_currentCardinality < _targetCardinality) {
        uint112 _gasCostToIncreaseAndAddSupport = uint112(_targetCardinality - _currentCardinality) *
          _gasCostPerCardinality +
          _gasCostToSupportPool;
        if (_gasCostToIncreaseAndAddSupport > gasleft()) {
          continue;
        }
        IUniswapV3Pool(_pool).increaseObservationCardinalityNext(_targetCardinality);
      }
      if (_preparedPools < _poolsPreviouslyInStorage) {
        // Rewrite storage
        _storagePools[_preparedPools++] = _pool;
      } else {
        // If I have more pools than before, then push
        _storagePools.push(_pool);
        _preparedPools++;
      }
    }

    if (_preparedPools == 0) revert GasTooLow();

    // If I have less pools than before, then remove the extra pools
    for (uint256 i = _preparedPools; i < _poolsPreviouslyInStorage; i++) {
      _storagePools.pop();
    }

    emit UpdatedSupport(_tokenA, _tokenB, _preparedPools);
  }

  function _getAllPoolsSortedByLiquidity(address _tokenA, address _tokenB) internal view virtual returns (address[] memory _pools) {
    _pools = UNISWAP_V3_ORACLE.getAllPoolsForPair(_tokenA, _tokenB);
    if (_pools.length > 1) {
      // Store liquidity by pool
      uint128[] memory _poolLiquidity = new uint128[](_pools.length);
      for (uint256 i; i < _pools.length; i++) {
        _poolLiquidity[i] = IUniswapV3Pool(_pools[i]).liquidity();
      }

      // Sort both arrays together
      for (uint256 i; i < _pools.length - 1; i++) {
        uint256 _biggestLiquidityIndex = i;
        for (uint256 j = i + 1; j < _pools.length; j++) {
          if (_poolLiquidity[j] > _poolLiquidity[_biggestLiquidityIndex]) {
            _biggestLiquidityIndex = j;
          }
        }
        if (_biggestLiquidityIndex != i) {
          // Swap pools
          (_pools[i], _pools[_biggestLiquidityIndex]) = (_pools[_biggestLiquidityIndex], _pools[i]);

          // Don't need to swap both ways, can just move the liquidity in i to its new place
          _poolLiquidity[_biggestLiquidityIndex] = _poolLiquidity[i];
        }
      }
    }
  }

  function _keyForPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    return keccak256(abi.encodePacked(__tokenA, __tokenB));
  }
}