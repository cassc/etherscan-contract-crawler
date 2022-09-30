// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@chainlink/contracts/src/v0.8/Denominations.sol';
import './base/SimpleOracle.sol';
import './libraries/TokenSorting.sol';
import '../interfaces/IStatefulChainlinkOracle.sol';

contract StatefulChainlinkOracle is AccessControl, SimpleOracle, IStatefulChainlinkOracle {
  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  /// @inheritdoc IStatefulChainlinkOracle
  uint32 public constant MAX_DELAY = 24 hours;
  /// @inheritdoc IStatefulChainlinkOracle
  FeedRegistryInterface public immutable registry;

  // solhint-disable private-vars-leading-underscore
  int8 private constant FOREX_DECIMALS = 8;
  int8 private constant ETH_DECIMALS = 18;
  // solhint-enable private-vars-leading-underscore

  mapping(address => address) internal _tokenMappings;
  mapping(bytes32 => PricingPlan) internal _planForPair;

  constructor(
    FeedRegistryInterface _registry,
    address _superAdmin,
    address[] memory _initialAdmins
  ) {
    if (address(_registry) == address(0) || _superAdmin == address(0)) revert ZeroAddress();
    registry = _registry;
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i = 0; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }
  }

  /// @inheritdoc ITokenPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool) {
    (address __tokenA, address __tokenB) = _mapAndSort(_tokenA, _tokenB);
    PricingPlan _plan = _determinePricingPlan(__tokenA, __tokenB);
    return _plan != PricingPlan.NONE;
  }

  /// @inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address _tokenA, address _tokenB) public view override(ITokenPriceOracle, SimpleOracle) returns (bool) {
    return planForPair(_tokenA, _tokenB) != PricingPlan.NONE;
  }

  /// @inheritdoc ITokenPriceOracle
  function quote(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    bytes calldata
  ) external view returns (uint256 _amountOut) {
    (address _mappedTokenIn, address _mappedTokenOut) = _mapPair(_tokenIn, _tokenOut);
    PricingPlan _plan = _planForPair[_keyForUnsortedPair(_mappedTokenIn, _mappedTokenOut)];
    if (_plan == PricingPlan.NONE) revert PairNotSupportedYet(_tokenIn, _tokenOut);
    if (_plan == PricingPlan.SAME_TOKENS) return _amountIn;

    int16 _inDecimals = _getDecimals(_tokenIn);
    int16 _outDecimals = _getDecimals(_tokenOut);

    if (_plan <= PricingPlan.TOKEN_ETH_PAIR) {
      return _getDirectPrice(_mappedTokenIn, _mappedTokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    } else if (_plan <= PricingPlan.TOKEN_TO_ETH_TO_TOKEN_PAIR) {
      return _getPriceSameBase(_mappedTokenIn, _mappedTokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    } else {
      return _getPriceDifferentBases(_mappedTokenIn, _mappedTokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    }
  }

  function _addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata
  ) internal virtual override {
    (address __tokenA, address __tokenB) = _mapAndSort(_tokenA, _tokenB);
    PricingPlan _plan = _determinePricingPlan(__tokenA, __tokenB);
    bytes32 _keyForPair = _keyForSortedPair(__tokenA, __tokenB);
    if (_plan == PricingPlan.NONE) {
      // Check if there is a current plan. If there is, it means that the pair was supported and it
      // lost support. In that case, we will remove the current plan and continue working as expected.
      // If there was no supported plan, and there still isn't, then we will fail
      PricingPlan _currentPlan = _planForPair[_keyForPair];
      if (_currentPlan == PricingPlan.NONE) {
        revert PairCannotBeSupported(_tokenA, _tokenB);
      }
    }
    _planForPair[_keyForPair] = _plan;
    emit UpdatedPlanForPair(__tokenA, __tokenB, _plan);
  }

  /// @inheritdoc IStatefulChainlinkOracle
  function planForPair(address _tokenA, address _tokenB) public view returns (PricingPlan) {
    (address __tokenA, address __tokenB) = _mapAndSort(_tokenA, _tokenB);
    return _planForPair[_keyForSortedPair(__tokenA, __tokenB)];
  }

  /// @inheritdoc IStatefulChainlinkOracle
  function addMappings(address[] calldata _addresses, address[] calldata _mappings) external onlyRole(ADMIN_ROLE) {
    if (_addresses.length != _mappings.length) revert InvalidMappingsInput();
    for (uint256 i = 0; i < _addresses.length; i++) {
      _tokenMappings[_addresses[i]] = _mappings[i];
    }
    emit MappingsAdded(_addresses, _mappings);
  }

  /// @inheritdoc IStatefulChainlinkOracle
  function mappedToken(address _token) public view returns (address) {
    address _mapping = _tokenMappings[_token];
    return _mapping != address(0) ? _mapping : _token;
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view override(AccessControl, BaseOracle) returns (bool) {
    return
      _interfaceId == type(IStatefulChainlinkOracle).interfaceId ||
      AccessControl.supportsInterface(_interfaceId) ||
      BaseOracle.supportsInterface(_interfaceId);
  }

  /** Handles prices when the pair is either ETH/USD, token/ETH or token/USD */
  function _getDirectPrice(
    address _tokenIn,
    address _tokenOut,
    int16 _inDecimals,
    int16 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    uint256 _price;
    int8 _resultDecimals = _plan == PricingPlan.TOKEN_ETH_PAIR ? ETH_DECIMALS : FOREX_DECIMALS;
    bool _needsInverting = _isUSD(_tokenIn) || (_plan == PricingPlan.TOKEN_ETH_PAIR && _isETH(_tokenIn));

    if (_plan == PricingPlan.ETH_USD_PAIR) {
      _price = _getETHUSD();
    } else if (_plan == PricingPlan.TOKEN_USD_PAIR) {
      _price = _getPriceAgainstUSD(_isUSD(_tokenOut) ? _tokenIn : _tokenOut);
    } else if (_plan == PricingPlan.TOKEN_ETH_PAIR) {
      _price = _getPriceAgainstETH(_isETH(_tokenOut) ? _tokenIn : _tokenOut);
    }
    if (!_needsInverting) {
      return _adjustDecimals(_price * _amountIn, _outDecimals - _resultDecimals - _inDecimals);
    } else {
      return _adjustDecimals(_adjustDecimals(_amountIn, _resultDecimals + _outDecimals) / _price, -_inDecimals);
    }
  }

  /** Handles prices when both tokens share the same base (either ETH or USD) */
  function _getPriceSameBase(
    address _tokenIn,
    address _tokenOut,
    int16 _inDecimals,
    int16 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    address _base = _plan == PricingPlan.TOKEN_TO_USD_TO_TOKEN_PAIR ? Denominations.USD : Denominations.ETH;
    uint256 _tokenInToBase = _callRegistry(_tokenIn, _base);
    uint256 _tokenOutToBase = _callRegistry(_tokenOut, _base);
    return _adjustDecimals((_amountIn * _tokenInToBase) / _tokenOutToBase, _outDecimals - _inDecimals);
  }

  /** Handles prices when one of the tokens uses ETH as the base, and the other USD */
  function _getPriceDifferentBases(
    address _tokenIn,
    address _tokenOut,
    int16 _inDecimals,
    int16 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    bool _isTokenInUSD = (_plan == PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B && _tokenIn < _tokenOut) ||
      (_plan == PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B && _tokenIn > _tokenOut);
    uint256 _ethToUSDPrice = _getETHUSD();
    if (_isTokenInUSD) {
      uint256 _tokenInToUSD = _getPriceAgainstUSD(_tokenIn);
      uint256 _tokenOutToETH = _getPriceAgainstETH(_tokenOut);
      uint256 _adjustedInUSDValue = _adjustDecimals(_amountIn * _tokenInToUSD, _outDecimals - _inDecimals + ETH_DECIMALS);
      return _adjustedInUSDValue / _ethToUSDPrice / _tokenOutToETH;
    } else {
      uint256 _tokenInToETH = _getPriceAgainstETH(_tokenIn);
      uint256 _tokenOutToUSD = _getPriceAgainstUSD(_tokenOut);
      return _adjustDecimals((_amountIn * _tokenInToETH * _ethToUSDPrice) / _tokenOutToUSD, _outDecimals - _inDecimals - ETH_DECIMALS);
    }
  }

  function _getPriceAgainstUSD(address _token) internal view returns (uint256) {
    return _isUSD(_token) ? 1e8 : _callRegistry(_token, Denominations.USD);
  }

  function _getPriceAgainstETH(address _token) internal view returns (uint256) {
    return _isETH(_token) ? 1e18 : _callRegistry(_token, Denominations.ETH);
  }

  /// @dev Expects `_tokenA` and `_tokenB` to be sorted
  function _determinePricingPlan(address _tokenA, address _tokenB) internal view virtual returns (PricingPlan) {
    if (_tokenA == _tokenB) {
      return PricingPlan.SAME_TOKENS;
    }
    bool _isTokenAUSD = _isUSD(_tokenA);
    bool _isTokenBUSD = _isUSD(_tokenB);
    bool _isTokenAETH = _isETH(_tokenA);
    bool _isTokenBETH = _isETH(_tokenB);
    if ((_isTokenAETH && _isTokenBUSD) || (_isTokenAUSD && _isTokenBETH)) {
      return PricingPlan.ETH_USD_PAIR;
    } else if (_isTokenBUSD) {
      return _tryWithBases(_tokenA, PricingPlan.TOKEN_USD_PAIR, PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B);
    } else if (_isTokenAUSD) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_USD_PAIR, PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B);
    } else if (_isTokenBETH) {
      return _tryWithBases(_tokenA, PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B, PricingPlan.TOKEN_ETH_PAIR);
    } else if (_isTokenAETH) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B, PricingPlan.TOKEN_ETH_PAIR);
    } else if (_exists(_tokenA, Denominations.USD)) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_TO_USD_TO_TOKEN_PAIR, PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B);
    } else if (_exists(_tokenA, Denominations.ETH)) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B, PricingPlan.TOKEN_TO_ETH_TO_TOKEN_PAIR);
    }
    return PricingPlan.NONE;
  }

  function _tryWithBases(
    address _token,
    PricingPlan _ifUSD,
    PricingPlan _ifETH
  ) internal view returns (PricingPlan) {
    // Note: we are prioritizing plans that have fewer external calls
    (address _firstBase, PricingPlan _firstResult, address _secondBaseBase, PricingPlan _secondResult) = _ifUSD < _ifETH
      ? (Denominations.USD, _ifUSD, Denominations.ETH, _ifETH)
      : (Denominations.ETH, _ifETH, Denominations.USD, _ifUSD);
    if (_exists(_token, _firstBase)) {
      return _firstResult;
    } else if (_exists(_token, _secondBaseBase)) {
      return _secondResult;
    } else {
      return PricingPlan.NONE;
    }
  }

  function _exists(address _base, address _quote) internal view returns (bool) {
    try registry.latestRoundData(_base, _quote) returns (uint80, int256 _price, uint256, uint256, uint80) {
      return _price > 0;
    } catch {
      return false;
    }
  }

  function _adjustDecimals(uint256 _amount, int256 _factor) internal pure returns (uint256) {
    if (_factor < 0) {
      return _amount / (10**uint256(-_factor));
    } else {
      return _amount * (10**uint256(_factor));
    }
  }

  function _getDecimals(address _token) internal view returns (int16) {
    if (_isETH(_token)) {
      return ETH_DECIMALS;
    } else if (!Address.isContract(_token)) {
      return FOREX_DECIMALS;
    } else {
      return int16(uint16(IERC20Metadata(_token).decimals()));
    }
  }

  function _callRegistry(address _base, address _quote) internal view returns (uint256) {
    (, int256 _price, , uint256 _updatedAt, ) = registry.latestRoundData(_base, _quote);
    if (_price <= 0) revert InvalidPrice();
    if (block.timestamp > _updatedAt + MAX_DELAY) revert LastUpdateIsTooOld();
    return uint256(_price);
  }

  function _mapAndSort(address _tokenA, address _tokenB) internal view returns (address, address) {
    (address _mappedTokenA, address _mappedTokenB) = _mapPair(_tokenA, _tokenB);
    return TokenSorting.sortTokens(_mappedTokenA, _mappedTokenB);
  }

  function _mapPair(address _tokenA, address _tokenB) internal view returns (address _mappedTokenA, address _mappedTokenB) {
    _mappedTokenA = mappedToken(_tokenA);
    _mappedTokenB = mappedToken(_tokenB);
  }

  function _keyForUnsortedPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    return _keyForSortedPair(__tokenA, __tokenB);
  }

  /// @dev Expects `_tokenA` and `_tokenB` to be sorted
  function _keyForSortedPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_tokenA, _tokenB));
  }

  function _getETHUSD() internal view returns (uint256) {
    return _callRegistry(Denominations.ETH, Denominations.USD);
  }

  function _isUSD(address _token) internal pure returns (bool) {
    return _token == Denominations.USD;
  }

  function _isETH(address _token) internal pure returns (bool) {
    return _token == Denominations.ETH;
  }
}