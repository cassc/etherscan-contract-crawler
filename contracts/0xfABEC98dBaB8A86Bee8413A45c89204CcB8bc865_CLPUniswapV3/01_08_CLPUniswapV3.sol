// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "CLPBase.sol";
import "IUniswapV3Pool.sol";
import "INonfungiblePositionManager.sol";
import "ICLPUniswapV3.sol";

contract CLPUniswapV3 is CLPBase, ICLPUniswapV3 {
    function _getContractName() internal pure override returns (string memory) {
        return "CLPUniswapV3";
    }

    function _getReceiver(address _inputRecipient) internal view returns (address receiver) {
        receiver = _inputRecipient == address(0) ? address(this) : _inputRecipient;
    }

    function _isValidUser(uint256 tokenId, address router) internal view returns (bool) {
        address owner = INonfungiblePositionManager(router).ownerOf(tokenId);
        return owner == msg.sender;
    }

    modifier isValidUser(uint256 tokenId, address router) {
        _requireMsg(_isValidUser(tokenId, router), "not your position");
        _;
    }

    /**
        @dev PositionManager ensures NFT not minted to zero address
     **/
    function deposit(
        uint256 tokenId,
        uint256 amountA,
        uint256 amountB,
        UniswapV3LPDepositParams calldata params
    ) external payable isValidUser(tokenId, params.router) {
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(
            params.router
        ).positions(tokenId);

        _approveToken(IERC20(token0), params.router, amountA);
        _approveToken(IERC20(token1), params.router, amountB);

        INonfungiblePositionManager(params.router).increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams(
                tokenId,
                amountA,
                amountB,
                params.amountAMin,
                params.amountBMin,
                params.deadline
            )
        );
    }

    /**
        @dev PositionManager ensures NFT not minted to zero address
     **/
    function depositNew(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint256 amountA,
        uint256 amountB,
        UniswapV3LPDepositParams calldata params
    ) external payable {
        address receiver = _getReceiver(params.receiver);
        address token0 = pool.token0();
        address token1 = pool.token1();

        _approveToken(IERC20(token0), params.router, amountA);
        _approveToken(IERC20(token1), params.router, amountB);

        // receiver needs to be able to receive NFT
        INonfungiblePositionManager(params.router).mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: pool.fee(),
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amountA,
                amount1Desired: amountB,
                amount0Min: params.amountAMin,
                amount1Min: params.amountBMin,
                recipient: receiver,
                deadline: params.deadline
            })
        );
    }

    function withdraw(
        uint256 tokenId,
        uint128 liquidity,
        UniswapV3LPWithdrawParams calldata params
    ) external payable isValidUser(tokenId, params.router) {
        address receiver = _getReceiver(params.receiver);
        INonfungiblePositionManager(params.router).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: params.amountAMin,
                amount1Min: params.amountBMin,
                deadline: params.deadline
            })
        );
        INonfungiblePositionManager(params.router).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: receiver,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function withdrawAll(uint256 tokenId, UniswapV3LPWithdrawParams calldata params)
        external
        payable
        isValidUser(tokenId, params.router)
    {
        address receiver = _getReceiver(params.receiver);

        (, , , , , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(params.router)
            .positions(tokenId);

        INonfungiblePositionManager(params.router).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: params.amountAMin,
                amount1Min: params.amountBMin,
                deadline: params.deadline
            })
        );

        INonfungiblePositionManager(params.router).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: receiver,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        INonfungiblePositionManager(params.router).burn(tokenId);
    }

    function collectAll(
        address router,
        uint256 tokenId,
        address recipient
    ) external payable isValidUser(tokenId, router) {
        address receiver = _getReceiver(recipient);
        INonfungiblePositionManager(router).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: receiver,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }
}