// SPDX-License-Identifier: CC-BY-NC-ND-1.0
pragma solidity ^0.8.9;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IDogMoneyAuctionHouse} from "./interfaces/IDogMoneyAuctionHouse.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import "@uniswap/swap-router-contracts/contracts/interfaces/IV3SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IWETH.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IPeripheryPaymentsWithFeeExtended.sol";

contract UniversalPaymentReceiver is Context {
    struct PaymentSettings {
        address fundsReceiver;
        IERC20 reserveCurrency;
        address swapRouter;
        IWETH WETH9;
    }
    IERC20 public reserveCurrency;

    // https://docs.uniswap.org/contracts/v3/reference/deployments
    address public swapRouter;
    IWETH public WETH9;

    address payable public fundsReceiver;

    function _acceptReserveCurrency(
        IERC20 token,
        bytes memory swapPath,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) internal returns (uint256) {
        // Swap if not given the reserve currency.
        if (address(token) != address(reserveCurrency)) {
            if (address(token) != address(WETH9) || msg.value == 0) {
                require(
                    token.transferFrom(_msgSender(), address(this), amountIn),
                    "UniversalPaymentReceiver: !alternate currency transferrom"
                );
            } else {
                WETH9.deposit{value: msg.value}();
            }

            TransferHelper.safeApprove(
                address(token),
                address(swapRouter),
                amountIn
            );

            IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter
                .ExactInputParams({
                    path: swapPath,
                    recipient: address(this),
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMinimum
                });

            return IV3SwapRouter(swapRouter).exactInput(params);
        } else {
            require(
                token.transferFrom(_msgSender(), address(this), amountIn),
                "UniversalPaymentReceiver: !reserveCurrency's transferFrom"
            );
            return amountIn;
        }
    }

    function _configurePaymentSettings(
        PaymentSettings memory paymentSettings
    ) internal {
        fundsReceiver = payable(paymentSettings.fundsReceiver);

        reserveCurrency = paymentSettings.reserveCurrency;

        swapRouter = paymentSettings.swapRouter;
        WETH9 = paymentSettings.WETH9;
    }
}