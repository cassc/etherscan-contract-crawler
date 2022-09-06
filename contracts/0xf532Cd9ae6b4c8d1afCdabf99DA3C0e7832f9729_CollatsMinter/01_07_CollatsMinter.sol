// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./interface/ICollatsMinter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @custom:security-contact [email protected]
contract CollatsMinter is ICollatsMinter {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 private uniswapRouter;
    address private assetAddress;
    uint256 private decimals;

    constructor(
        address uniswapRouterAddress,
        address _assetAddress,
        uint256 _decimals
    ) {
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
        assetAddress = _assetAddress;
        decimals = _decimals;
    }

    function swapEthForBackUpAsset(address to)
        public
        payable
        override
        returns (uint256)
    {
        require(msg.value > 0, "CollatsMinter: You need to send some eth");
        uint256 deadline = block.timestamp + 600; //Ten minutes
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = assetAddress;

        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: msg.value
        }(0, path, to, deadline);
        return amounts[1];
    }

    function swapTokenForBackUpAsset(
        address to,
        address token,
        uint256 amount
    ) public override returns (uint256) {
        require(amount > 0, "CollatsMinter: You need to send some wei");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 deadline = block.timestamp + 600; //Ten minutes
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = assetAddress;

        IERC20(token).safeApprove(address(uniswapRouter), amount);
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amount,
            0,
            path,
            to,
            deadline
        );
        return amounts[1];
    }

    function backUpAsset() public view override returns (address) {
        return assetAddress;
    }

    function backUpAssetDecimals() public view override returns (uint256) {
        return decimals;
    }

    //This could throw if there is not enough amountOut in the pair.
    function getAmountIn(address from, uint256 amountOut)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = assetAddress;
        return uniswapRouter.getAmountsIn(amountOut, path)[0];
    }

    //This could throw if the pair is not found
    function getAmountOut(address from, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = assetAddress;
        return uniswapRouter.getAmountsOut(amountIn, path)[1];
    }
}