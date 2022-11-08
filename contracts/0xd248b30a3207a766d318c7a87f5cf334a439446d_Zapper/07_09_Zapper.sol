/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBatcher.sol";
import "./interfaces/IVault.sol";

/// @title Zapper
/// @author 0xAd1
/// @notice Used to zap in and out of vault with any token
contract Zapper is ReentrancyGuard {
    event ZappedIn(
        address indexed token,
        address indexed sender,
        uint256 amountIn,
        uint256 sharesOut
    );
    event ZappedOut(
        address indexed token,
        address indexed sender,
        uint256 wantTokenIn,
        uint256 amountOut
    );

    address public constant nativeETH =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct ZapData {
        address requiredToken;
        uint256 amountIn;
        uint256 minAmountOut;
        address allowanceTarget;
        address swapTarget;
        bytes callData;
    }

    IVault public vault;

    constructor(address _vault) {
        vault = IVault(_vault);
    }

    function zapIn(ZapData calldata zapCall)
        external
        payable
        nonReentrant
        isRelevant
    {
        if (zapCall.requiredToken != nativeETH) {
            IERC20(zapCall.requiredToken).transferFrom(
                msg.sender,
                address(this),
                zapCall.amountIn
            );
        }
        uint256 amountIn = zap(zapCall, true);

        IERC20(wantToken()).approve(address(vault), amountIn);
        uint256 sharesOut = vault.deposit(amountIn, msg.sender);

        emit ZappedIn(
            zapCall.requiredToken,
            msg.sender,
            zapCall.amountIn,
            sharesOut
        );
    }

    function zapOut(ZapData memory zapCall) external nonReentrant isRelevant {
        if (zapCall.requiredToken == nativeETH) zapCall.requiredToken = weth;
        batcher().completeWithdrawalWithZap(zapCall.amountIn, msg.sender);
        uint256 amountOut = zap(zapCall, false);
        IERC20(zapCall.requiredToken).transfer(msg.sender, amountOut);
        emit ZappedOut(
            zapCall.requiredToken,
            msg.sender,
            zapCall.amountIn,
            amountOut
        );
    }

    function batcher() public view returns (IBatcher) {
        return IBatcher(vault.batcher());
    }

    function wantToken() public view returns (address) {
        return vault.wantToken();
    }

    modifier isRelevant() {
        require(address(this) == vault.zapper(), "DEPRECATED");
        _;
    }

    function sweep(address token) external {
        require(msg.sender == vault.governance(), "ONY_GOV");

        if (token == nativeETH) {
            uint256 amount = address(this).balance;
            (bool success, ) = weth.call{value: amount}("");
            require(success, "WRAP_UNSUCCESSFULL");
            IERC20(weth).transfer(vault.governance(), amount);
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(vault.governance(), balance);
        }
    }

    function zap(ZapData memory zapCall, bool deposit)
        internal
        returns (uint256 tokenOut)
    {
        if (zapCall.requiredToken == wantToken()) {
            return zapCall.amountIn;
        }

        address inputToken = deposit ? zapCall.requiredToken : wantToken();
        address outputToken = deposit ? wantToken() : zapCall.requiredToken;

        uint256 oldBalance = IERC20(outputToken).balanceOf(address(this));

        if (inputToken == nativeETH) {
            require(msg.value >= zapCall.amountIn, "ETH_NOT_RECEIVED");

            (bool success, ) = zapCall.swapTarget.call{value: zapCall.amountIn}(
                zapCall.callData
            );
            require(success, "SWAP_FAILED");
        } else {
            require(
                IERC20(inputToken).balanceOf(address(this)) >= zapCall.amountIn,
                "INPUT_AMOUNT_NOT_RECEIVED"
            );

            IERC20(inputToken).approve(
                zapCall.allowanceTarget,
                zapCall.amountIn
            );

            (bool success, ) = zapCall.swapTarget.call(zapCall.callData);
            require(success, "SWAP_FAILED");
        }
        uint256 newBalance = IERC20(outputToken).balanceOf(address(this));
        tokenOut = newBalance - oldBalance;

        require(tokenOut >= zapCall.minAmountOut, "MIN_AMOUNT_NOT_RECEIVED");
    }
}