//SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/IOneInch.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDEFactory {
    function isAllowedOneInchCaller(address) external view returns (bool);
}

library OneInchHelper {
    /**
     * @dev Function decodeds srcToken, dstToken and source swap amount from the given data
     * @param factory DefiEdge factory address
     * @param token0 token0 address of strategy
     * @param token1 token1 address of strategy
     * @param data bytes data to decode
     */
    function decodeData(
        address factory,
        IERC20 token0,
        IERC20 token1,
        bytes calldata data
    )
        public
        view
        returns (
            IERC20 srcToken,
            IERC20 dstToken,
            uint256 amount
        )
    {
        IOneInch.SwapDescription memory description;

        bytes memory _data = data;

        bytes4 selector;
        assembly {
            selector := mload(add(_data, 0x20))
        }

        if (selector == 0x7c025200) {
            address caller;
            // call swap() method
            (caller, description, ) = abi.decode(data[4:], (address, IOneInch.SwapDescription, bytes));

            require(IDEFactory(factory).isAllowedOneInchCaller(caller), "IC");

            srcToken = IERC20(description.srcToken);
            dstToken = IERC20(description.dstToken);
            amount = description.amount;
        } else if (selector == 0x2e95b6c8) {
            // call unoswap() method
            address tokenIn;
            (tokenIn, amount, , ) = abi.decode(data[4:], (address, uint256, uint256, bytes32[]));

            srcToken = IERC20(tokenIn);
            dstToken = srcToken == token0 ? token1 : token0;
        } else if (selector == 0xe449022e) {
            // call uniswapV3Swap() method
            uint256[] memory pools;
            (amount, , pools) = abi.decode(data[4:], (uint256, uint256, uint256[]));

            uint256 _pool = pools[0];
            bool zeroForOne = _pool >> 255 == 0;

            address tokenIn = zeroForOne ? IUniswapV3Pool(_pool).token0() : IUniswapV3Pool(_pool).token1();
            srcToken = IERC20(tokenIn);
            dstToken = srcToken == token0 ? token1 : token0;
        } else {
            revert("IM");
        }
    }
}