// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

// We import the contract so truffle compiles it, and we have the ABI
// available when working from truffle console.
import "@gnosis.pm/mock-contract/contracts/MockContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol" as ISushiswapV2Router;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol" as ISushiswapV2Factory;
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2ERC20.sol" as ISushiswapV2ERC20;
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";