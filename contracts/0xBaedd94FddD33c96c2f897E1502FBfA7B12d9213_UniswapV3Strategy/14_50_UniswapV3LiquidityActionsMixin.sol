// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import "../AssetHelpers.sol";
import "./../../external/uniswapV3/INonfungiblePositionManager.sol";

/// @title UniswapV3LiquidityActionsMixin Contract
/// @notice Mixin contract for interacting with Uniswap v3
abstract contract UniswapV3LiquidityActionsMixin is AssetHelpers {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event UniV3Initialized(address _token0, address _token1, uint24 _fee);
    event UniV3NFTPositionAdded(uint256 indexed _tokenId, uint128 _liquidity, uint256 _amount0, uint256 _amount1);
    event UniV3NFTPositionRemoved(uint256 indexed _tokenId);
    event UniV3NFTCollect(uint256 _nftId, uint256 _amount0, uint256 _amount1);

    INonfungiblePositionManager internal constant nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IUniswapV3Pool public pool;

    address internal token0;
    address internal token1;
    uint24 internal fee;

    function _initializeUniswapV3Liquidity(address _pool) internal {
        pool = IUniswapV3Pool(_pool);
        token0 = pool.token0();
        token1 = pool.token1();
        fee = pool.fee();

        // Approve the NFT manager once for the max of each token
        IERC20Upgradeable(token0).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        IERC20Upgradeable(token1).safeApprove(address(nonfungiblePositionManager), type(uint256).max);
        emit UniV3Initialized(token0, token1, fee);
    }

    function __collectAll(uint256 _nftId) internal returns (uint256, uint256){
        return __collect(_nftId, type(uint128).max, type(uint128).max);
    }

    /// @dev Collects all uncollected amounts from the nft position and sends it to the vaultProxy
    function __collect(uint256 _nftId, uint128 _amount0, uint128 _amount1) internal returns (uint256 __amount0, uint256 __amount1){
        (__amount0, __amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams({
            tokenId : _nftId,
            recipient : address(this),
            amount0Max : _amount0,
            amount1Max : _amount1
            })
        );
        emit UniV3NFTCollect(_nftId, __amount0, __amount1);
    }

    /// @dev Helper to get the total _liquidity of an nft position.
    /// Uses a low-level staticcall() and truncated decoding of `.positions()`
    /// in order to avoid compilation error.
    function __getLiquidityForNFT(uint256 _nftId) internal view returns (uint128 _liquidity) {
        (bool _success, bytes memory _returnData) = address(nonfungiblePositionManager).staticcall(
            abi.encodeWithSelector(INonfungiblePositionManager.positions.selector, _nftId)
        );
        require(_success, string(_returnData));

        (,,,,,,, _liquidity) = abi.decode(
            _returnData,
            (uint96, address, address, address, uint24, int24, int24, uint128)
        );

        return _liquidity;
    }

    /// @dev Mints a new uniswap position, receiving an nft as a receipt
    function __mint(INonfungiblePositionManager.MintParams memory _params) internal returns (
        uint256 _tokenId,
        uint128 _liquidity,
        uint256 _amount0,
        uint256 _amount1
    ){
        (_tokenId, _liquidity, _amount0, _amount1) = nonfungiblePositionManager.mint(_params);
        emit UniV3NFTPositionAdded(_tokenId, _liquidity, _amount0, _amount1);
    }

    /// @dev Purges a position by removing all _liquidity, collecting and transferring all tokens owed to the vault, and burning the nft.
    /// _liquidity == 0 signifies no _liquidity to be removed (i.e., only collect and burn).
    /// 0 < _liquidity 0 < max uint128 signifies the full amount of _liquidity is known (more gas-efficient).
    /// _liquidity == max uint128 signifies the full amount of _liquidity is unknown.
    function __purge(
        uint256 _nftId,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) internal {
        if (_liquidity == type(uint128).max) {
            // This consumes a lot of unnecessary gas because of all the SLOAD operations,
            // when we only care about `_liquidity`.
            // Should ideally only be used in the rare case where a griefing attack
            // (i.e., frontrunning the tx and adding extra _liquidity dust) is a concern.
            _liquidity = __getLiquidityForNFT(_nftId);
        }

        if (_liquidity > 0) {
            nonfungiblePositionManager.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId : _nftId,
                liquidity : _liquidity,
                amount0Min : _amount0Min,
                amount1Min : _amount1Min,
                deadline : block.timestamp
            }));
        }

        __collectAll(_nftId);

        // Reverts if _liquidity or uncollected tokens are remaining
        nonfungiblePositionManager.burn(_nftId);

        emit UniV3NFTPositionRemoved(_nftId);
    }
}