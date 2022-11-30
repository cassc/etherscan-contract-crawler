// SPDX-License-Identifier: MIT
// solhint-disable

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

// contract IOneSplitConsts {
//     // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_BANCOR + ...
//     uint256 internal constant FLAG_DISABLE_UNISWAP = 0x01;
//     uint256 internal constant DEPRECATED_FLAG_DISABLE_KYBER = 0x02; // Deprecated
//     uint256 internal constant FLAG_DISABLE_BANCOR = 0x04;
//     uint256 internal constant FLAG_DISABLE_OASIS = 0x08;
//     uint256 internal constant FLAG_DISABLE_COMPOUND = 0x10;
//     uint256 internal constant FLAG_DISABLE_FULCRUM = 0x20;
//     uint256 internal constant FLAG_DISABLE_CHAI = 0x40;
//     uint256 internal constant FLAG_DISABLE_AAVE = 0x80;
//     uint256 internal constant FLAG_DISABLE_SMART_TOKEN = 0x100;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_BDAI = 0x400;
//     uint256 internal constant FLAG_DISABLE_IEARN = 0x800;
//     uint256 internal constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
//     uint256 internal constant FLAG_DISABLE_CURVE_USDT = 0x2000;
//     uint256 internal constant FLAG_DISABLE_CURVE_Y = 0x4000;
//     uint256 internal constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
//     uint256 internal constant FLAG_DISABLE_WETH = 0x80000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
//     uint256 internal constant FLAG_DISABLE_IDLE = 0x800000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP = 0x1000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
//     uint256 internal constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
//     uint256 internal constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_USDT = 0x400000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_WBTC = 0x800000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_TBTC = 0x1000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_RENBTC = 0x2000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
//     uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
//     uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
//     uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_SBTC = 0x40000000000;
//     uint256 internal constant FLAG_DISABLE_DMM = 0x80000000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_ALL = 0x100000000000;
//     uint256 internal constant FLAG_DISABLE_CURVE_ALL = 0x200000000000;
//     uint256 internal constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x400000000000;
//     uint256 internal constant FLAG_DISABLE_SPLIT_RECALCULATION = 0x800000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_ALL = 0x1000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_1 = 0x2000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_2 = 0x4000000000000;
//     uint256 internal constant FLAG_DISABLE_BALANCER_3 = 0x8000000000000;
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x10000000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x20000000000000; // Deprecated, Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x40000000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP = 0x80000000000000; // Turned off by default
//     uint256 internal constant DEPRECATED_FLAG_ENABLE_MULTI_PATH_COMP = 0x100000000000000; // Deprecated, Turned off by default
//     uint256 internal constant FLAG_DISABLE_KYBER_ALL = 0x200000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_1 = 0x400000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_2 = 0x800000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_3 = 0x1000000000000000;
//     uint256 internal constant FLAG_DISABLE_KYBER_4 = 0x2000000000000000;
//     uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN = 0x4000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_ALL = 0x8000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_ETH = 0x10000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_DAI = 0x20000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_USDC = 0x40000000000000000;
//     uint256 internal constant FLAG_DISABLE_MOONISWAP_POOL_TOKEN = 0x80000000000000000;
// }

interface IOneSplit {
  function getExpectedReturn(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags // See constants in IOneSplit.sol
  ) external view returns (uint256 returnAmount, uint256[] memory distribution);

  function getExpectedReturnWithGas(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 parts,
    uint256 flags, // See constants in IOneSplit.sol
    uint256 destTokenEthPriceTimesGasPrice
  )
    external
    view
    returns (
      uint256 returnAmount,
      uint256 estimateGasAmount,
      uint256[] memory distribution
    );

  function swap(
    IERC20 fromToken,
    IERC20 destToken,
    uint256 amount,
    uint256 minReturn,
    uint256[] memory distribution,
    uint256 flags
  ) external payable returns (uint256 returnAmount);
}