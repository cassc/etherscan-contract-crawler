// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IPoolFactory.sol";
import "./interfaces/ITokenFactory.sol";
import "./interfaces/ILogic.sol";
import "./interfaces/IPool.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract Router {
    IPoolFactory public immutable POOL_FACTORY;
    ITokenFactory public immutable TOKEN_FACTORY;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "DDLV1Router: EXPIRED");
        _;
    }

    constructor(
        address poolFactory,
        address tokenFactory
    ) {
        POOL_FACTORY = IPoolFactory(poolFactory);
        TOKEN_FACTORY = ITokenFactory(tokenFactory);
    }

    function creatPool(address logic) public {
        POOL_FACTORY.createPool(logic);
        for (uint256 index = 0; index < ILogic(logic).N_TOKENS(); index++) {
            TOKEN_FACTORY.createDToken(logic, index);
        }
    }

    struct Step {
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOutMin;
    }

    function multiSwap(
        address pool,
        Step[] calldata steps,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint[] memory amountOuts, uint gasLeft) {
        amountOuts = new uint[](steps.length);
        for (uint i = 0; i < steps.length; ++i) {
            Step memory step = steps[i];
            if (step.tokenIn == address(0)) {
                uint start = step.amountIn;
                uint end = step.amountOutMin;
                ILogic(IPool(pool).LOGIC()).deleverage(uint224(start), uint224(end));
                continue;
            }
            TransferHelper.safeTransferFrom(step.tokenIn, msg.sender, pool, step.amountIn);
            (amountOuts[i], ) = IPool(pool).swap(step.tokenIn, step.tokenOut, to);
            require(amountOuts[i] >= step.amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        }
        gasLeft = gasleft();
    }
}