// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import "./interfaces/IWooRebateManager.sol";
import "./interfaces/IWooFeeManager.sol";
import "./interfaces/IWooVaultManager.sol";
import "./interfaces/IWooAccessManager.sol";

import "./libraries/TransferHelper.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Contract to collect transaction fee of WooPPV2.
contract WooFeeManager is Ownable, ReentrancyGuard, IWooFeeManager {
    /* ----- State variables ----- */

    mapping(address => uint256) public override feeRate; // decimal: 18; 1e16 = 1%, 1e15 = 0.1%, 1e14 = 0.01%
    uint256 public vaultRewardRate; // decimal: 18; 1e16 = 1%, 1e15 = 0.1%, 1e14 = 0.01%

    uint256 public rebateAmount;

    address public immutable override quoteToken;
    IWooRebateManager public rebateManager;
    IWooVaultManager public vaultManager;
    IWooAccessManager public accessManager;

    address public treasury;

    /* ----- Modifiers ----- */

    modifier onlyAdmin() {
        require(msg.sender == owner() || accessManager.isFeeAdmin(msg.sender), "WooFeeManager: !admin");
        _;
    }

    constructor(
        address _quoteToken,
        address _rebateManager,
        address _vaultManager,
        address _accessManager,
        address _treasury
    ) {
        quoteToken = _quoteToken;
        rebateManager = IWooRebateManager(_rebateManager);
        vaultManager = IWooVaultManager(_vaultManager);
        vaultRewardRate = 1e18;
        accessManager = IWooAccessManager(_accessManager);
        treasury = _treasury;
    }

    /* ----- Public Functions ----- */

    function collectFee(uint256 amount, address brokerAddr) external override nonReentrant {
        TransferHelper.safeTransferFrom(quoteToken, msg.sender, address(this), amount);
        uint256 rebateRate = rebateManager.rebateRate(brokerAddr);
        if (rebateRate > 0) {
            uint256 curRebateAmount = (amount * rebateRate) / 1e18;
            rebateManager.addRebate(brokerAddr, curRebateAmount);
            rebateAmount = rebateAmount + curRebateAmount;
        }
    }

    /* ----- Admin Functions ----- */

    function addRebates(address[] memory brokerAddrs, uint256[] memory amounts)
        external
        override
        nonReentrant
        onlyAdmin
    {
        require(amounts.length == brokerAddrs.length, "WooFeeManager: !length");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < brokerAddrs.length; ++i) {
            rebateManager.addRebate(brokerAddrs[i], amounts[i]);
            totalAmount = totalAmount + amounts[i];
        }

        rebateAmount = rebateAmount + totalAmount;
    }

    function distributeFees() external override nonReentrant onlyAdmin {
        uint256 balance = IERC20(quoteToken).balanceOf(address(this));
        require(balance > 0, "WooFeeManager: balance_ZERO");

        // Step 1: distribute the vault balance. Currently, 80% of fee (2 bps) goes to vault manager.
        uint256 vaultAmount = (balance * vaultRewardRate) / 1e18;
        if (vaultAmount > 0) {
            TransferHelper.safeTransfer(quoteToken, address(vaultManager), vaultAmount);
            balance = balance - vaultAmount;
        }

        // Step 2: distribute the rebate balance.
        if (rebateAmount > 0) {
            TransferHelper.safeTransfer(quoteToken, address(rebateManager), rebateAmount);

            // NOTE: if balance not enought: certain rebate rates are set incorrectly.
            balance = balance - rebateAmount;
            rebateAmount = 0;
        }

        // Step 3: balance left for treasury
        TransferHelper.safeTransfer(quoteToken, treasury, balance);
    }

    function setFeeRate(address token, uint256 newFeeRate) external override onlyAdmin {
        require(newFeeRate <= 1e16, "WooFeeManager: FEE_RATE>1%");
        feeRate[token] = newFeeRate;
        emit FeeRateUpdated(token, newFeeRate);
    }

    function setRebateManager(address newRebateManager) external onlyAdmin {
        require(newRebateManager != address(0), "WooFeeManager: rebateManager_ZERO_ADDR");
        rebateManager = IWooRebateManager(newRebateManager);
    }

    function setVaultManager(address newVaultManager) external onlyAdmin {
        require(newVaultManager != address(0), "WooFeeManager: newVaultManager_ZERO_ADDR");
        vaultManager = IWooVaultManager(newVaultManager);
    }

    function setVaultRewardRate(uint256 newVaultRewardRate) external onlyAdmin {
        require(newVaultRewardRate <= 1e18, "WooFeeManager: vaultRewardRate_INVALID");
        vaultRewardRate = newVaultRewardRate;
    }

    function setAccessManager(address newAccessManager) external onlyOwner {
        require(newAccessManager != address(0), "WooFeeManager: newAccessManager_ZERO_ADDR");
        accessManager = IWooAccessManager(newAccessManager);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "WooFeeManager: newTreasury_ZERO_ADDR");
        treasury = newTreasury;
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyOwner {
        if (stuckToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            uint256 amount = IERC20(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, msg.sender, amount);
        }
    }
}