// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../external/IStargateRouter.sol";
import "./IMultichainPortal.sol";

contract MultichainRouter is IMultichainPortal, Pausable, Ownable {
    using SafeERC20 for IERC20;

    IMultichainPortal public Portal;
    address public usdc;

    receive() external payable {}

    constructor(address _portal, address _usdc) {
        Portal = IMultichainPortal(_portal);
        usdc = _usdc;
    }

    /// @param tokenIn input token address 
    /// @param amountIn The number of tokens to send
    /// @param swapRouter address of swap router
    /// @param swapArguments arguments to perform swap on destination chain
    /// @param calls desired functions to call after swap
    function swapERC20AndCall(
        address tokenIn,
        address[] memory tokenOuts,
        uint256 amountIn,
        address, /* user */
        address swapRouter,
        bytes calldata swapArguments,
        Types.ICall[] calldata calls
    ) external override whenNotPaused {

        IERC20 token = IERC20(tokenIn);
        uint256 balance = token.balanceOf(address(Portal));

        token.safeTransferFrom(msg.sender, address(Portal), amountIn);

        amountIn = token.balanceOf(address(Portal)) - balance;
        Portal.swapERC20AndCall(tokenIn, tokenOuts, amountIn, msg.sender, swapRouter, swapArguments, calls);
    }

    /// @param swapRouter address of swap router
    /// @param swapArguments arguments to perform swap on destination chain
    /// @param calls desired functions to call after swap
    function swapNativeAndCall(
        address[] memory tokenOuts,
        address user,
        address swapRouter,
        bytes calldata swapArguments,
        Types.ICall[] calldata calls
    ) external payable override whenNotPaused {
        Portal.swapNativeAndCall{value: msg.value}(tokenOuts, user, swapRouter, swapArguments, calls);
    }

    /// @param amountIn The number of tokens to send
    /// @param amountStargate the amount of USDC expected after swap
    /// @param tokenIn input token address 
    /// @param tokenStargate output (stargate) token address 
    /// @param swapRouter address of swap router
    /// @param swapArguments arguments to perform swap on source chain
    /// @param stargateArgs arguments to send tokens cross chain through stargate
    function swapERC20AndSend(
        uint amountIn,
        uint amountStargate,
        address, /* user */
        address tokenIn,
        address tokenStargate,
        address swapRouter,
        bytes calldata swapArguments,
        IMultichainPortal.StargateArgs memory stargateArgs
    ) external payable override {
        require(msg.value > 0, "stargate requires a msg.value to pay crosschain message"); //TODO: modifiers
        require(amountIn > 0, "error: swap() requires amountIn > 0");

        IERC20 token = IERC20(tokenIn);
        uint256 balance = token.balanceOf(address(Portal));

        token.safeTransferFrom(msg.sender, address(Portal), amountIn);

        amountIn = token.balanceOf(address(Portal)) - balance;
        Portal.swapERC20AndSend{value:msg.value}(
            amountIn,
            amountStargate,
            msg.sender,
            tokenIn,
            tokenStargate,
            swapRouter,
            swapArguments,
            stargateArgs
        );
    }

    /// @param amountIn The number of tokens to send
    /// @param amountStargate the amount of USDC expected after swap
    /// @param lzFee layerZero fee sent along with input amount to cover gas 
    /// @param tokenStargate output (stargate) token address 
    /// @param swapRouter address of swap router
    /// @param swapArguments arguments to perform swap on source chain
    /// @param stargateArgs arguments to send tokens cross chain through stargate
    function swapNativeAndSend(
        uint amountIn,
        uint amountStargate,
        uint lzFee,
        address, /* user */
        address tokenStargate,
        address swapRouter,
        bytes calldata swapArguments,
        IMultichainPortal.StargateArgs memory stargateArgs
    ) external payable override whenNotPaused {
        Portal.swapNativeAndSend{value: msg.value}(
            amountIn,
            amountStargate,
            lzFee,
            msg.sender,
            tokenStargate,
            swapRouter,
            swapArguments,
            stargateArgs
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}