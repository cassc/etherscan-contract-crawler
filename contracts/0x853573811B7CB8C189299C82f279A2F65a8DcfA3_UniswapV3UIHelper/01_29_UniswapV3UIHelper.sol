// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {NFTPositionInfo} from "../utils/NFTPositionInfo.sol";
import {IGaugeUniswapV3} from "../interfaces/IGaugeUniswapV3.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";

contract UniswapV3UIHelper {
    uint256 public ratePerEpoch;
    mapping(address => address) public tokenStakingPool;

    /// @dev the uniswap v3 factory
    IUniswapV3Factory public factory;

    /// @dev the uniswap v3 nft position manager
    INonfungiblePositionManager public nonfungiblePositionManager;

    constructor(address _nonfungiblePositionManager) {
        nonfungiblePositionManager = INonfungiblePositionManager(
            _nonfungiblePositionManager
        );

        factory = IUniswapV3Factory(nonfungiblePositionManager.factory());
    }

    function isInRange(uint256 _tokenId) external view returns (bool) {
        (
            IUniswapV3Pool _pool,
            int24 _tickLower,
            int24 _tickUpper,

        ) = NFTPositionInfo.getPositionInfo(
                factory,
                nonfungiblePositionManager,
                _tokenId
            );

        (, int24 tick, , , , , ) = _pool.slot0();
        return _tickLower <= tick && tick <= _tickUpper;
    }

    function boostedFactor(
        IGaugeUniswapV3 gauge,
        uint256 tokenId,
        address who
    )
        public
        view
        returns (
            uint256 original,
            uint256 boosted,
            uint256 factor
        )
    {
        (, , , uint128 _liquidity) = NFTPositionInfo.getPositionInfo(
            factory,
            nonfungiblePositionManager,
            tokenId
        );

        original = (_liquidity * 20) / 100;
        boosted = gauge.derivedLiquidity(_liquidity, who);
        factor = (boosted * 1e18) / original;
    }
}