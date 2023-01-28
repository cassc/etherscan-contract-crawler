import "./openzeppelin/ERC20Detailed.sol";
// File: contracts/ApyOracle.sol

pragma solidity 0.5.16;

contract IUniswapRouterV2 {
  function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function totalSupply() external view returns (uint256);
}

contract ApyOracle {

  address public router;
  address public usdc;
  address public wNative; // This is address for wrapped native token of the ecosystem

  constructor (address _router, address _usdc, address _wNative) public {
    router = _router;
    usdc = _usdc;
    wNative = _wNative;
  }

  function getApy(
    address stakeToken,
    bool isUni,
    address token,
    uint256 incentive, // amount of token loaded into the contract
    uint256 howManyWeeks,
    address pool) public view returns (uint256) {
    address[] memory p = new address[](3);
    p[1] = wNative;
    p[2] = usdc;
    p[0] = token;
    uint256[] memory tokenPriceAmounts = IUniswapRouterV2(router).getAmountsOut(1e18, p);
    uint256 poolBalance = IERC20(stakeToken).balanceOf(pool);
    uint256 stakeTokenPrice = 1000000;
    p[0] = stakeToken;
    if (stakeToken != usdc) {
      if (isUni) {
        stakeTokenPrice = getUniPrice(IUniswapV2Pair(stakeToken));
      } else {
        uint256 unit = 10 ** uint256(ERC20Detailed(stakeToken).decimals());
        uint256[] memory stakePriceAmounts = IUniswapRouterV2(router).getAmountsOut(unit, p);
        stakeTokenPrice = stakePriceAmounts[2];
      }
    }
    uint256 temp = (
      1e8 * tokenPriceAmounts[2] * incentive * (52 / howManyWeeks)
    ) / (poolBalance * stakeTokenPrice);
    if (ERC20Detailed(stakeToken).decimals() == uint8(18)) {
      return temp;
    } else {
      uint256 divideBy = 10 ** uint256(18 - ERC20Detailed(stakeToken).decimals());
      return temp / divideBy;
    }
  }

  function getUniPrice(IUniswapV2Pair unipair) public view returns (uint256) {
    // find the token price that is not wNative
    (uint112 r0, uint112 r1, ) = unipair.getReserves();
    uint256 total = 0;
    if (unipair.token0() == wNative) {
      total = uint256(r0) * 2;
      uint256 singlePriceInWeth = 1e18 * total / unipair.totalSupply();
      address[] memory p = new address[](2);
    p[0] = wNative;
    p[1] = usdc;
    uint256[] memory prices = IUniswapRouterV2(router).getAmountsOut(1e18, p);
    return prices[1] * singlePriceInWeth / 1e18; // price of single token in USDC
    } else {
      total = uint256(r1) * 2;
      address t1 = unipair.token1();
      address[] memory p = new address[](3);
      p[0] = t1;
      p[1] = wNative;
      p[2] = usdc;
      uint256[] memory prices = IUniswapRouterV2(router).getAmountsOut(1e18, p);
      uint256 tokenValue = prices[2] * total;
      return tokenValue/unipair.totalSupply();
    }

  }

  function getTvl(address pool, address token, bool isUniswap) public view returns (uint256) {
    uint256 balance = IERC20(token).balanceOf(pool);
    uint256 decimals = ERC20Detailed(token).decimals();
    if (balance == 0) {
      return 0;
    }
    if (!isUniswap) {
      address[] memory p = new address[](3);
      p[1] = wNative;
      p[2] = usdc;
      p[0] = token;
      uint256 one = 10 ** decimals;
      uint256[] memory amounts = IUniswapRouterV2(router).getAmountsOut(one, p);
      return amounts[2] * balance / (10 ** decimals);
    } else {
      uint256 price = getUniPrice(IUniswapV2Pair(token));
      return price * balance / (10 ** decimals);
    }
  }
  function tokenPerLP(address pool, address token) public view returns (uint256) {
    // Incase result is too small we multiply by 1*e18 to ensure we get a more precision
    uint256 tokenBalance = IERC20(token).balanceOf(pool);
    uint256 totalLP = IERC20(pool).totalSupply();
    uint256 result = (tokenBalance * 1e18) / totalLP;
    return result;
  }

  function batchUniPrices(address[] memory tokens) public view returns (uint256[] memory) {
    uint256[] memory prices = new uint256[](tokens.length);
    for(uint256 i = 0; i < tokens.length; i++) {
      prices[i] = getUniPrice(IUniswapV2Pair(tokens[i]));
    }
    return prices;
  }

  function batchTvl(address[] memory pool, address token, bool isUniswap) public view returns (uint256[] memory) {
    uint256[] memory tvl = new uint256[](pool.length);
    for(uint256 i = 0; i < pool.length; i++) {
      tvl[i] = getTvl(pool[i], token, isUniswap);
    }
    return tvl;
  }

  function batchAPY(
    address[] memory stakeTokens,
    bool isUni,
    address token,
    uint256 incentive,
    uint256 howManyWeeks,
    address[] memory pools) public view returns (uint256[] memory) {
    uint256[] memory apy =  new uint256[](stakeTokens.length);
    for(uint256 i = 0; i < stakeTokens.length; i++) {
      apy[i] = getApy(stakeTokens[i], isUni, token, incentive, howManyWeeks, pools[i]);
    }
    return apy;
  }
}