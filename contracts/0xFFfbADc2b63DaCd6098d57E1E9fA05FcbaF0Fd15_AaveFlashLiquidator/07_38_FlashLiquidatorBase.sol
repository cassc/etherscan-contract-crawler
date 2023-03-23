// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {NotionalProxy} from "../../interfaces/notional/NotionalProxy.sol";
import {IStrategyVault} from "../../interfaces/notional/IStrategyVault.sol";
import {CErc20Interface} from "../../interfaces/compound/CErc20Interface.sol";
import {CEtherInterface} from "../../interfaces/compound/CEtherInterface.sol";
import {WETH9} from "../../interfaces/WETH9.sol";
import {TokenUtils, IERC20} from "../utils/TokenUtils.sol";
import {Constants} from "../global/Constants.sol";
import {Token} from "../global/Types.sol";
import {BoringOwnable} from "./BoringOwnable.sol";
import {Deployments} from "../global/Deployments.sol";

abstract contract FlashLiquidatorBase is BoringOwnable {
    using TokenUtils for IERC20;

    NotionalProxy public immutable NOTIONAL;
    address internal immutable FLASH_LENDER;
    mapping(address => address) internal underlyingToAsset;

    struct LiquidationParams {
        uint16 currencyId;
        address account;
        address vault;
        bool useVaultDeleverage;
        bytes redeemData;
    }

    constructor(NotionalProxy notional_, address flashLender_) {
        NOTIONAL = notional_;
        FLASH_LENDER = flashLender_;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function enableCurrencies(uint16[] calldata currencies) external onlyOwner {
        for (uint256 i; i < currencies.length; i++) {
            (Token memory assetToken, Token memory underlyingToken) = NOTIONAL.getCurrency(currencies[i]);
            IERC20(assetToken.tokenAddress).checkApprove(address(NOTIONAL), type(uint256).max);
            if (underlyingToken.tokenAddress == Constants.ETH_ADDRESS) {
                IERC20(address(Deployments.WETH)).checkApprove(address(FLASH_LENDER), type(uint256).max);
                underlyingToAsset[address(Deployments.WETH)] = assetToken.tokenAddress;
            } else {
                IERC20(underlyingToken.tokenAddress).checkApprove(address(FLASH_LENDER), type(uint256).max);
                IERC20(underlyingToken.tokenAddress).checkApprove(assetToken.tokenAddress, type(uint256).max);
                underlyingToAsset[underlyingToken.tokenAddress] = assetToken.tokenAddress;
            }
        }
    }

    function estimateProfit(
        address asset,
        uint256 amount,
        LiquidationParams calldata params
    ) external onlyOwner returns (uint256) {
        uint256 balance = IERC20(asset).balanceOf(address(this));
        _flashLiquidate(asset, amount, false, params);
        return IERC20(asset).balanceOf(address(this)) - balance;
    }

    function flashLiquidate(
        address asset,
        uint256 amount,
        LiquidationParams calldata params
    ) external {
        _flashLiquidate(asset, amount, true, params);
    }

    function _flashLiquidate(
        address asset,
        uint256 amount,
        bool withdraw,
        LiquidationParams calldata params
    ) internal virtual;

    function handleLiquidation(uint256 fee, bool repay, bytes memory data) internal {
        require(msg.sender == address(FLASH_LENDER));

        (
            address asset, 
            uint256 amount, 
            bool withdraw,
            LiquidationParams memory params
        ) = abi.decode(data, (address, uint256, bool, LiquidationParams));

        address assetToken = underlyingToAsset[asset];

        // Mint CToken
        if (params.currencyId == Constants.ETH_CURRENCY_ID) {
            Deployments.WETH.withdraw(amount);
            CEtherInterface(assetToken).mint{value: amount}();
        } else {
            CErc20Interface(assetToken).mint(amount);
        }

        {
            (
                /* int256 collateralRatio */,
                /* int256 minCollateralRatio */,
                int256 maxLiquidatorDepositAssetCash,
                /* uint256 vaultSharesToLiquidator */
            ) = NOTIONAL.getVaultAccountCollateralRatio(params.account, params.vault);
            
            require(maxLiquidatorDepositAssetCash > 0);

            if (params.useVaultDeleverage) {
                IStrategyVault(params.vault).deleverageAccount(
                    params.account, 
                    params.vault, 
                    address(this), 
                    uint256(maxLiquidatorDepositAssetCash), 
                    false, 
                    params.redeemData
                );
            } else {
                NOTIONAL.deleverageAccount(
                    params.account, 
                    params.vault,
                    address(this), 
                    uint256(maxLiquidatorDepositAssetCash), 
                    false, 
                    params.redeemData
                );
            }
        }

        // Redeem CToken
        {
            uint256 balance = IERC20(assetToken).balanceOf(address(this));
            if (balance > 0) {
                CErc20Interface(assetToken).redeem(balance);
                if (params.currencyId == Constants.ETH_CURRENCY_ID) {
                    _wrapETH();
                }
            }
        }

        if (withdraw) {
            _withdrawToOwner(asset, IERC20(asset).balanceOf(address(this)) - amount - fee);
        }

        if (repay) {
            IERC20(asset).transfer(msg.sender, amount + fee);
        }
    }

    function _withdrawToOwner(address token, uint256 amount) private {
        if (amount == type(uint256).max) {
            amount = IERC20(token).balanceOf(address(this));
        }
        if (amount > 0) {
            IERC20(token).checkTransfer(owner, amount);
        }
    }

    function _wrapETH() private {
        Deployments.WETH.deposit{value: address(this).balance}();
    }

    function withdrawToOwner(address token, uint256 amount) external onlyOwner {
        _withdrawToOwner(token, amount);
    }

    function wrapETH() external onlyOwner {
        _wrapETH();
    }

    receive() external payable {} 
}