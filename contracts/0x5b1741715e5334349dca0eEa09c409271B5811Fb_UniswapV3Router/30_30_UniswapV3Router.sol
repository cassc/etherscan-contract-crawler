// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {VersionedInitializable} from "../proxy/VersionedInitializable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurveCryptoV2} from "../interfaces/ICurveCryptoV2.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

// import "hardhat/console.sol";

// collect tokens and use it to add liquidity to ARTH/ETH and ARTH/MAHA LP pairs.
contract UniswapV3Router is Ownable, VersionedInitializable, IRouter {
    using SafeMath for uint256;
    address me;

    INonfungiblePositionManager public manager;
    uint256 public poolId;
    IERC20 public token0;
    IERC20 public token1;

    // uniswap swap router
    ISwapRouter public swapRouter;

    /// @dev uniswap pool
    IUniswapV3Pool public pool;

    function initialize(
        address _treasury,
        INonfungiblePositionManager _manager,
        IUniswapV3Pool _pool,
        ISwapRouter _swapRouter,
        uint256 _poolId
    ) external initializer {
        me = address(this);

        manager = _manager;
        poolId = _poolId;

        swapRouter = ISwapRouter(_swapRouter);
        pool = IUniswapV3Pool(_pool);

        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());

        token0.approve(address(manager), type(uint256).max);
        token1.approve(address(manager), type(uint256).max);

        token0.approve(address(swapRouter), type(uint256).max);
        token1.approve(address(swapRouter), type(uint256).max);

        _transferOwnership(_treasury);
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 1;
    }

    function execute(
        uint256 token0Amount,
        uint256 token1Amount,
        bytes calldata extraData
    ) external override {
        // take tokens from the user
        if (token0Amount > 0) token0.transferFrom(msg.sender, me, token0Amount);
        if (token1Amount > 0) token1.transferFrom(msg.sender, me, token1Amount);

        (uint256 amount0Min, uint256 amount1Min) = abi.decode(
            extraData,
            (uint256, uint256)
        );

        uint256 price = _getPrice();
        uint256 amount1ByExchangeRate = (token1Amount * price) / 1e18;

        // in most cases we are only feeding the contract with ETH, so we feed in
        // half for maha
        if (amount1ByExchangeRate > token0Amount) {
            _swapExactInputSingle(
                address(token1),
                address(token0),
                token1Amount / 2, // TODO: need to calculate this to understand how much we should efficiently swap
                10000
            );

            token0Amount = token0.balanceOf(me);
            token1Amount = token1.balanceOf(me);
        }

        // attempt to add liquidity
        _addLiquidity(token0Amount, token1Amount, amount0Min, amount1Min);

        // send balance back to the contract
        _flush(msg.sender);
    }

    function checkUpkeep(
        bytes calldata checkData
    )
        external
        pure
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (checkData.length > 0) {
            (uint256 token0Amount, uint256 token1Amount) = abi.decode(
                checkData,
                (uint256, uint256)
            );

            // uint256 minLptokens = pool.calc_token_amount([tokenArthAmount, 0]);
            return (true, abi.encode(token0Amount, token1Amount, 0, 0));
        }

        return (
            false,
            abi.encode(uint256(0), uint256(0), uint256(0), uint256(0))
        );
    }

    function performUpkeep(bytes calldata performData) external {
        (
            uint256 token0Amount,
            uint256 token1Amount,
            uint256 amount0Min,
            uint256 amount1Min
        ) = abi.decode(performData, (uint256, uint256, uint256, uint256));

        if (token0Amount > 0) token0.transferFrom(msg.sender, me, token0Amount);
        if (token1Amount > 0) token1.transferFrom(msg.sender, me, token1Amount);

        _addLiquidity(token0Amount, token1Amount, amount0Min, amount1Min);
        _flush(owner());

        emit PerformUpkeep(msg.sender, performData);
    }

    function tokens() external view override returns (address, address) {
        return (address(token0), address(token1));
    }

    function refundPosition(uint256 nftId) external onlyOwner {
        manager.transferFrom(me, owner(), nftId);
    }

    function setPoolId(uint256 nftId) external onlyOwner {
        poolId = nftId;
    }

    /// @dev swaps two tokens
    function _swapExactInputSingle(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint24 fee_
    ) internal returns (uint256 amountOut) {
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn_,
                tokenOut: tokenOut_,
                fee: fee_,
                recipient: me,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @dev adds liquidity to the nft id
    function _addLiquidity(
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal {
        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .IncreaseLiquidityParams({
                    tokenId: poolId,
                    amount0Desired: token0Amount,
                    amount1Desired: token1Amount,
                    amount0Min: amount0Min,
                    amount1Min: amount1Min,
                    deadline: block.timestamp
                });

        manager.increaseLiquidity(params);
    }

    /// @dev gets price from uniswap
    function _getPrice() internal view returns (uint256 price) {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        assembly {
            price := shr(
                192,
                mul(mul(sqrtPriceX96, sqrtPriceX96), 1000000000000000000)
            )
        }
    }

    /// @dev send balance tokens back to user
    function _flush(address to) internal {
        uint256 token0Amount = token0.balanceOf(me);
        uint256 token1Amount = token1.balanceOf(me);
        if (token0Amount > 0) token0.transfer(to, token0Amount);
        if (token1Amount > 0) token1.transfer(to, token1Amount);
    }
}