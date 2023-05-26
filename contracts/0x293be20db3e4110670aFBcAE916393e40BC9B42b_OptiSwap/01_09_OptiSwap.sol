//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OptiSwap is Context, Ownable {
    /*  Uniswap wrapper for optimal swaps */
    using SafeMath for uint256;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    receive() external payable {}

    function buyToken(address token, uint amountOutMin, uint deadline) public payable {
        require(block.timestamp < deadline, "OptiSwap: Expired");
        uint amountIn = msg.value.mul(995).div(1000);
        IWETH(WETH).deposit{value: amountIn}();
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, WETH));
        assert(IWETH(WETH).transfer(address(pair), amountIn));
        uint balanceBefore = IERC20(token).balanceOf(_msgSender());
        uint amountInput;
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = WETH < token ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(WETH).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = WETH < token ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, _msgSender(), new bytes(0));
        require(
            IERC20(token).balanceOf(_msgSender()).sub(balanceBefore) >= amountOutMin,
            'OptiSwap: Slippage tolerance exceeded.'
        );
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'OptiSwap: Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'OptiSwap: Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function sellToken(address token, uint amountIn, uint amountOutMin, uint deadline) public {
        require(block.timestamp < deadline, "OptiSwap: Expired");
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, WETH));
        IERC20(token).transferFrom(_msgSender(), address(pair), amountIn);
        uint amountInput;
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveInput, uint reserveOutput) = WETH > token ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(token).balanceOf(address(pair)).sub(reserveInput);
        amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = WETH > token ? (uint(0), amountOutput) : (amountOutput, uint(0));
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'OptiSwap: Slippage tolerance exceeded.');
        IWETH(WETH).withdraw(amountOut);
        payable(_msgSender()).transfer(amountOut.mul(995).div(1000));
    }

    function collectFees() public onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

}