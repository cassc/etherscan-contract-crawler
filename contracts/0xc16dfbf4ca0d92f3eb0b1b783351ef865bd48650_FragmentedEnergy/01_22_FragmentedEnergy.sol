// https://fragmentedenergy.com (ENERGY)
// https://twitter.com/EnergyERC
//
// Experimental decentralized protocol capitalizing on the incredibly powerful tools available
// to manage and control liquidity to create positive chart technicals with memetics to
// capitalize on virality. We're integrating classic full price range liquidity as is present
// using UniswapV2 with fragmented & concentrated liquidity supported in UniswapV3.
//
// Success is not guaranteed through our efforts alone, but through strategic levers pulled at
// appropriate times and a passionate and broad community that gets built and spreads ENERGY everywhere!
// Markets run on psychology, and we will do our part to manufacture the psychology
// needed for continuous bullishness.
//
// COMMUNITY MANAGEMENT
//
// Our goal is upon identifying the power of what we're building that appropriate community leaders
// will step up, organize, and mobilize a community of people that spread positive ENERGY everywhere.
// We are passionate devs looking to create optimal strategies on clustering and fragmenting
// ENERGY liquidity in order to absorb sell pressure and encourage continued upward momentum, but
// communities created will be run by community leaders who step up. We will support them and update
// website links to point to community managed links/channels, but will be focusing our time on technicals.
//
// All communication with ENERGY devs should occur through twitter & on-chain messages.
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import './LiquidityLocker.sol';

contract FragmentedEnergy is ERC20, Ownable {
  LiquidityLocker public liquidityLocker;
  address public v2Pool;
  mapping(uint24 => address) public v3Pools;

  IUniswapV2Router02 _v2Router;
  INonfungiblePositionManager _v3Manager;

  constructor() ERC20('Fragmented Energy', 'ENERGY') {
    _v2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    _v3Manager = INonfungiblePositionManager(
      0xC36442b4a4522E871399CD717aBDD847Ab11FE88
    );
    v2Pool = IUniswapV2Factory(_v2Router.factory()).createPair(
      address(this),
      _v2Router.WETH()
    );
    liquidityLocker = new LiquidityLocker(_v3Manager);
    liquidityLocker.transferOwnership(msg.sender);
    _mint(msg.sender, 999_999_999 * 10 ** 18);
  }

  function createV3Pool(
    uint24 _poolFee,
    uint160 _sqrtPriceX96
  ) external onlyOwner {
    address _WETH = _v2Router.WETH();
    (address _t0, address _t1) = address(this) < _WETH
      ? (address(this), _WETH)
      : (_WETH, address(this));
    v3Pools[_poolFee] = _v3Manager.createAndInitializePoolIfNecessary(
      _t0,
      _t1,
      _poolFee,
      _sqrtPriceX96
    );
  }
}