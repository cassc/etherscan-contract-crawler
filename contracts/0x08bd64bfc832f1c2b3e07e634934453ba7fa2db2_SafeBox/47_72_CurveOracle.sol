pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './UsingBaseOracle.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/ICurvePool.sol';
import '../../interfaces/ICurveRegistry.sol';

interface IERC20Decimal {
  function decimals() external view returns (uint8);
}

contract CurveOracle is UsingBaseOracle, IBaseOracle {
  using SafeMath for uint;

  ICurveRegistry public immutable registry;

  struct UnderlyingToken {
    uint8 decimals; // token decimals
    address token; // token address
  }

  mapping(address => UnderlyingToken[]) public ulTokens; // lpToken -> underlying tokens array
  mapping(address => address) public poolOf; // lpToken -> pool

  constructor(IBaseOracle _base, ICurveRegistry _registry) public UsingBaseOracle(_base) {
    registry = _registry;
  }

  /// @dev Register the pool given LP token address and set the pool info.
  /// @param lp LP token to find the corresponding pool.
  function registerPool(address lp) external {
    address pool = poolOf[lp];
    require(pool == address(0), 'lp is already registered');
    pool = registry.get_pool_from_lp_token(lp);
    require(pool != address(0), 'no corresponding pool for lp token');
    poolOf[lp] = pool;
    uint n = registry.get_n_coins(pool);
    address[8] memory tokens = registry.get_coins(pool);
    for (uint i = 0; i < n; i++) {
      ulTokens[lp].push(
        UnderlyingToken({token: tokens[i], decimals: IERC20Decimal(tokens[i]).decimals()})
      );
    }
  }

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param lp The ERC-20 LP token to check the value.
  function getETHPx(address lp) external view override returns (uint) {
    address pool = poolOf[lp];
    require(pool != address(0), 'lp is not registered');
    UnderlyingToken[] memory tokens = ulTokens[lp];
    uint minPx = uint(-1);
    uint n = tokens.length;
    for (uint idx = 0; idx < n; idx++) {
      UnderlyingToken memory ulToken = tokens[idx];
      uint tokenPx = base.getETHPx(ulToken.token);
      if (ulToken.decimals < 18) tokenPx = tokenPx.div(10**(18 - uint(ulToken.decimals)));
      if (ulToken.decimals > 18) tokenPx = tokenPx.mul(10**(uint(ulToken.decimals) - 18));
      if (tokenPx < minPx) minPx = tokenPx;
    }
    require(minPx != uint(-1), 'no min px');
    return minPx.mul(ICurvePool(pool).get_virtual_price()).div(1e18);
  }
}