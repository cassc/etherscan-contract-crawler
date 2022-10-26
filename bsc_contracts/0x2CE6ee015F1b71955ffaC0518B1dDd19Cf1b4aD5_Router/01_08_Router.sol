// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IPoolFactory.sol";
import "./interfaces/ITokenFactory.sol";
import "./interfaces/ILogic.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IRouter.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract Router is IRouter {
    IPoolFactory public immutable POOL_FACTORY;
    ITokenFactory public immutable TOKEN_FACTORY;
    ILogic public immutable LOGIC;
    IPool public immutable POOL;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DDLV1Router: EXPIRED");
        _;
    }

    constructor(
        address poolFactory,
        address tokenFactory,
        address logic
    ) {
        POOL_FACTORY = IPoolFactory(poolFactory);
        TOKEN_FACTORY = ITokenFactory(tokenFactory);
        LOGIC = ILogic(logic);
        POOL = IPool(POOL_FACTORY.computePoolAddress(address(LOGIC)));
    }

    function creatPool() public {
        POOL_FACTORY.createPool(address(LOGIC));
        for (uint256 index = 0; index < LOGIC.N_TOKENS(); index++) {
            TOKEN_FACTORY.createDToken(address(LOGIC), index);
        }
    }

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        uint256 amount,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 liquidity) {
        TransferHelper.safeTransferFrom(LOGIC.COLLATERAL_TOKEN(), msg.sender, address(POOL), amount);
        (liquidity,) = POOL.swap(LOGIC.COLLATERAL_TOKEN(), address(POOL), to);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        uint liquidity,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint256 amount) {
        TransferHelper.safeTransferFrom(address(POOL), msg.sender, address(POOL), liquidity);
        (amount,) = POOL.swap(address(POOL), LOGIC.COLLATERAL_TOKEN(), to);
    }

    // **** SWAP ****
    function swap(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOutMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountOut) {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(POOL), amountIn);
        (amountOut,) = POOL.swap(tokenIn, tokenOut, to);
        require(amountOut >= amountOutMin, "DDLV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function deleverageAndSwap(
        uint224 start,
        uint224 end,
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOutMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountOut) {
        LOGIC.deleverage(start, end);
        amountOut = swap(tokenIn, amountIn, tokenOut, amountOutMin, to, deadline);
    }
}