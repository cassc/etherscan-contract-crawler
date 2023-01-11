// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

interface UniswapRouter {
    function WETH() external pure returns (address);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapPair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract asd123 is Ownable {
    // pancake router
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address weth = UniswapRouter(router).WETH();

    function getAmounts(address token, address lp, address token0) private view returns(uint256 amount0Out, uint256 amount1Out) {
        uint256 amountInput;
        uint256 amountOutput;
        {
            (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(lp).getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = token == token0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);
            amountInput = IERC20(token).balanceOf(lp) - reserveInput;
            uint256 amountInWithFee = amountInput * 9975;
            uint256 numerator = amountInWithFee * reserveOutput;
            uint256 denominator = reserveInput * 10000 + amountInWithFee;
            amountOutput = numerator / denominator;
        }
        (amount0Out, amount1Out) = token == token0
            ? (uint256(0), amountOutput)
            : (amountOutput, uint256(0));
    }

    function xd(
        address token,
        address lp
    ) external payable onlyOwner {
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).transfer(lp, msg.value);
        (address token0, ) = token < weth ? (token, weth) : (weth, token);

        (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(lp).getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = weth == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint amountInWithFee = msg.value * 9975;
        uint numerator = amountInWithFee * reserveOutput;
        uint denominator = reserveInput * 10000 + amountInWithFee;
        uint amountOut = numerator / denominator;

        (uint amount0Out, uint amount1Out) = weth == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IUniswapPair(lp).swap(amount0Out, amount1Out, address(this), new bytes(0));
        IERC20(token).transfer(lp, IERC20(token).balanceOf(address(this)));
        (amount0Out, amount1Out) = getAmounts(token, lp, token0);
        IUniswapPair(lp).swap(amount0Out, amount1Out, address(this), new bytes(0));
        uint256 wethReceived = IERC20(weth).balanceOf(address(this));
        IWETH(weth).withdraw(wethReceived);
        payable(msg.sender).transfer(wethReceived);
    }

    function withdrawTokens(
        address token,
        address to,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function withdrawETH(address payable to, uint amount) external onlyOwner {
        to.transfer(amount);
    }

    receive() external payable {}
}