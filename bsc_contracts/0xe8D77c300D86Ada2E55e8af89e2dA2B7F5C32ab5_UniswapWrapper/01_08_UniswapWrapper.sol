// SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.15;

import "../interfaces/IEntangleDEXWrapper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UniswapWrapper is IEntangleDEXWrapper {
    using SafeERC20 for IERC20;
    
    IUniswapV2Router01 public router;
    IUniswapV2Factory public factory;
    address public WETH;

    constructor(address _router, address _WETH) {
        router = IUniswapV2Router01(_router);
        factory = IUniswapV2Factory(router.factory());
        WETH = _WETH;
    }

    function _getSwapPath(address from, address to) internal view returns (address[] memory path){
        if (factory.getPair(from, to) != address(0)) {
            path = new address[](2);
            path[0] = from;
            path[1] = to;
        }
        else {
            path = new address[](3);
            path[0] = from;
            path[1] = WETH;
            path[2] = to;
        }
    }

    function convert(address from, address to, uint256 amount) external returns(uint256 receivedAmount) {
        IERC20(from).safeTransferFrom(msg.sender, address(this), amount);
        if (IERC20(from).allowance(address(this), address(router)) < amount) {
            IERC20(from).safeIncreaseAllowance(address(router), type(uint256).max);
        }
        uint256[] memory amounts = router.swapExactTokensForTokens(amount, 1, _getSwapPath(from, to), msg.sender, block.timestamp);
        receivedAmount = amounts[amounts.length - 1];
    }

    function previewConvert(address from, address to, uint256 amount) external view returns(uint256 amountToReceive) {
        uint256[] memory amounts = router.getAmountsOut(amount, _getSwapPath(from, to));
        amountToReceive = amounts[amounts.length - 1];
    }
}