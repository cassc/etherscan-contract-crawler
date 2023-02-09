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
    // uniswap router
    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//0x10ED43C718714eb63d5aA57B78B54704E256024E;//0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address weth = UniswapRouter(router).WETH();

    function setWeth(address _weth) external onlyOwner {
        weth = _weth;
    }

    struct Tax {
        uint16 buy;
        uint16 sell;
    }

    function xd(
        address token,
        address lp,
        Tax calldata taxes
    ) external payable {
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).transfer(lp, msg.value);
        uint amountIn = msg.value;
        (address token0, ) = token < weth ? (token, weth) : (weth, token);

        (uint256 reserve0, uint256 reserve1, ) = IUniswapPair(lp).getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = weth == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint amountInWithFee = amountIn * 9970; // 75 if pancakev2, 70 if uniswapv2
        uint numerator = amountInWithFee * reserveOutput;
        uint denominator = reserveInput * 10000 + amountInWithFee;
        uint amountOut = numerator / denominator;
        amountOut = amountOut * (10000 - taxes.buy) / 10000;
        (uint amount0Out, uint amount1Out) = weth == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IUniswapPair(lp).swap(amount0Out, amount1Out, address(this), new bytes(0));
        IERC20(token).transfer(lp, amountOut);
        // (amount0Out, amount1Out) = getAmounts(token, lp, token0);

        amountInWithFee = amountOut * 9970;
        numerator = amountInWithFee * (reserveInput + amountIn);
        denominator = (reserveOutput - amountOut) * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
        amountOut = amountOut * (10000 - taxes.sell) / 10000;
        (amount0Out, amount1Out) = amount0Out == 0 ? (amountOut, uint(0)) : (uint(0), amountOut);
        IUniswapPair(lp).swap(amount0Out, amount1Out, address(this), new bytes(0));
        uint256 wethReceived = IERC20(weth).balanceOf(address(this));
        IWETH(weth).withdraw(wethReceived);
        payable(msg.sender).transfer(wethReceived);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) private pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 9970;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
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