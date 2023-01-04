// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IAggregationRouterV4.sol";
import "./IDex.sol";

contract OneInchProvider is Ownable {
    using SafeERC20 for IERC20;
    address public OneInchRouter;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    event NativeFundsSwapped(
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event ERC20FundsSwapped(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    );

    constructor(address _OneInchRouter) {
        OneInchRouter = _OneInchRouter;
    }

    function swapERC20(
        IAggregationExecutor executor,
        SwapDescription memory desc,
        bytes memory data
    ) external returns (uint256) {
        require(address(desc.srcToken) != address(0), "Cannot be a address(0)");
        desc.srcToken.safeTransferFrom(msg.sender, address(this), desc.amount);
        desc.srcToken.safeIncreaseAllowance(OneInchRouter, desc.amount);
        (uint256 returnAmount, , ) = IAggregationRouterV4(OneInchRouter).swap(
            executor,
            desc,
            data
        );
        emit ERC20FundsSwapped(
            desc.amount,
            address(desc.srcToken),
            address(desc.dstToken),
            returnAmount
        );
        return returnAmount;
    }

    function swapNative(
        IAggregationExecutor executor,
        SwapDescription memory desc,
        bytes memory data
    ) external payable returns (uint256) {
        require(msg.value > 0, "Must pass non 0 ETH amount");
        (uint256 returnAmount, , ) = IAggregationRouterV4(OneInchRouter).swap{
            value: msg.value
        }(executor, desc, data);

        emit NativeFundsSwapped(
            address(desc.dstToken),
            msg.value,
            returnAmount
        );
        return returnAmount;
    }

    function changePool(address newPool) external onlyOwner {
        OneInchRouter = newPool;
    }

    function rescueFunds(address tokenAddr, uint256 amount) external onlyOwner {
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            IERC20(tokenAddr).transferFrom(address(this), msg.sender, amount);
        }
    }
}