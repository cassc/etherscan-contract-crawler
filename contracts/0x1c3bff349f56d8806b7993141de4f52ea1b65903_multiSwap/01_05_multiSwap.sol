// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20//utils/SafeERC20.sol";

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract multiSwap is Context {

    receive() external payable {}

    function swap(
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts,
        address[] memory path,
        address tokenAddress,
        uint deadline
    ) public payable returns (bool) {

        uint amountIn = msg.value;
        IWETH(tokenAddress).deposit{value: amountIn}();

        uint checkAllowance = IERC20(tokenAddress).allowance(address(this), 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        if(checkAllowance == 0) IERC20(tokenAddress).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 115792089237316195423570985008687907853269984665640564039457584007913129639935);

        for (uint256 i = 0; i < recipients.length; i++) {
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactTokensForTokensSupportingFeeOnTransferTokens(wethAmounts[i], tokenAmounts[i], path, recipients[i], deadline);
        }

        uint amountOut = IERC20(tokenAddress).balanceOf(address(this));
        IWETH(tokenAddress).withdraw(amountOut);
        (bool sent, ) = _msgSender().call{value: amountOut}("");
        require(sent, "F t s e");

        return true;
    }

}