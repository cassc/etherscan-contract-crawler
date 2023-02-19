//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title InstaLite.
 * @dev InstaLite Vault 1.
 */

import "./helpers.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AdminModule is Helpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(auth == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Only rebalancer gaurd.
     */
    modifier onlyRebalancer() {
        require(
            isRebalancer[msg.sender] || auth == msg.sender,
            "only rebalancer"
        );
        _;
    }

    /**
     * @dev Update auth.
     * @param auth_ address of new auth.
     */
    function updateAuth(address auth_) external onlyAuth {
        auth = auth_;
        emit updateAuthLog(auth_);
    }

    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
        onlyAuth
    {
        isRebalancer[rebalancer_] = isRebalancer_;
        emit updateRebalancerLog(rebalancer_, isRebalancer_);
    }

    /**
     * @dev Update all fees.
     * @param revenueFee_ new revenue fee.
     * @param withdrawalFee_ new withdrawal fee.
     * @param swapFee_ new swap fee or leverage fee.
     * @param deleverageFee_ new deleverage fee.
     */
    function updateFees(
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 swapFee_,
        uint256 deleverageFee_
    ) external onlyAuth {
        require(revenueFee_ < 10000, "fees-not-valid");
        require(withdrawalFee_ < 10000, "fees-not-valid");
        require(swapFee_ < 10000, "fees-not-valid");
        require(deleverageFee_ < 10000, "fees-not-valid");
        revenueFee = revenueFee_;
        withdrawalFee = withdrawalFee_;
        swapFee = swapFee_;
        deleverageFee = deleverageFee_;
        emit updateFeesLog(
            revenueFee_,
            withdrawalFee_,
            swapFee_,
            deleverageFee_
        );
    }

    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external onlyAuth {
        ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            uint128(ratios_[3]) * 1e23
        );
        emit updateRatiosLog(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            uint128(ratios_[3]) * 1e23
        );
    }

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external onlyAuth {
        _status = status_;
        emit changeStatusLog(status_);
    }

    /**
     * @dev Admin function to supply any token as collateral to save aave position from liquidation in case of adverse market conditions.
     * @param token_ token to supply
     * @param amount_ amount to supply
     */
    // function supplyToken(address token_, uint256 amount_) external onlyAuth {
    //     IERC20(token_).safeTransferFrom(msg.sender, address(vaultDsa), amount_);
    //     string[] memory targets_ = new string[](1);
    //     bytes[] memory calldata_ = new bytes[](1);
    //     targets_[0] = "AAVE-V2-A";
    //     calldata_[0] = abi.encodeWithSignature(
    //         "deposit(address,uint256,uint256,uint256)",
    //         token_,
    //         amount_,
    //         0,
    //         0
    //     );
    //     vaultDsa.cast(targets_, calldata_, address(this));
    // }

    /**
     * @dev Admin function to withdraw token from aave
     * @param token_ token to withdraw
     * @param amount_ amount to withdraw
     */
    // function withdrawToken(address token_, uint256 amount_) external onlyAuth {
    //     string[] memory targets_ = new string[](2);
    //     bytes[] memory calldata_ = new bytes[](2);
    //     targets_[0] = "AAVE-V2-A";
    //     calldata_[0] = abi.encodeWithSignature(
    //         "withdraw(address,uint256,uint256,uint256)",
    //         token_,
    //         amount_,
    //         0,
    //         0
    //     );
    //     targets_[1] = "BASIC-A";
    //     calldata_[1] = abi.encodeWithSignature(
    //         "withdraw(address,uint256,address,uint256,uint256)",
    //         token_,
    //         amount_,
    //         auth,
    //         0,
    //         0
    //     );
    //     vaultDsa.cast(targets_, calldata_, address(this));
    // }

    /**
     * @dev Admin Spell function
     * @param to_ target address
     * @param calldata_ function calldata
     * @param value_ function msg.value
     * @param operation_ .call or .delegate. (0 => .call, 1 => .delegateCall)
     */
    function spell(
        address to_,
        bytes memory calldata_,
        uint256 value_,
        uint256 operation_
    ) external payable onlyAuth {
        if (operation_ == 0) {
            // .call
            Address.functionCallWithValue(
                to_,
                calldata_,
                value_,
                "spell: .call failed"
            );
        } else if (operation_ == 1) {
            // .delegateCall
            Address.functionDelegateCall(
                to_,
                calldata_,
                "spell: .delegateCall failed"
            );
        } else {
            revert("no operation");
        }
    }

    /**
     * @dev Admin function to add auth on DSA
     * @param auth_ new auth address for DSA
     */
    function addDSAAuth(address auth_) external onlyAuth {
        string[] memory targets_ = new string[](1);
        bytes[] memory calldata_ = new bytes[](1);
        targets_[0] = "AUTHORITY-A";
        calldata_[0] = abi.encodeWithSignature("add(address)", auth_);
        vaultDsa.cast(targets_, calldata_, address(this));
    }
}

contract CoreHelpers is AdminModule {
    using SafeERC20 for IERC20;

    /**
     * @dev Update storage.
     * @notice Internal function to update storage.
     */
    function updateStorage(uint256 exchangePrice_, uint256 newRevenue_)
        internal
    {
        if (exchangePrice_ > lastRevenueExchangePrice) {
            lastRevenueExchangePrice = exchangePrice_;
            revenue = revenue + newRevenue_;
        }
    }

    /**
     * @dev internal function which handles supplies.
     */
    function supplyInternal(
        address token_,
        uint256 amount_,
        address to_,
        bool isEth_
    ) internal returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");
        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);
        if (isEth_) {
            wethCoreContract.deposit{value: amount_}();
        } else {
            require(token_ == stEthAddr || token_ == wethAddr, "wrong-token");
            IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        }
        vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);
    }

    /**
     * @dev Withdraw helper.
     */
    function withdrawHelper(uint256 amount_, uint256 limit_)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 transferAmt_;
        if (limit_ > amount_) {
            transferAmt_ = amount_;
            amount_ = 0;
        } else {
            transferAmt_ = limit_;
            amount_ = amount_ - limit_;
        }
        return (amount_, transferAmt_);
    }

    /**
     * @dev Withdraw final.
     */
    function withdrawFinal(uint256 amount_, bool afterDeleverage_)
        public
        view
        returns (uint256[] memory transferAmts_)
    {
        require(amount_ > 0, "amount-invalid");

        (
            uint256 netCollateral_,
            uint256 netBorrow_,
            BalVariables memory balances_,
            ,

        ) = netAssets();

        uint256 margin_ = afterDeleverage_ ? 5 : 10; // 0.05% margin or  0.1% margin
        uint256 colCoveringDebt_ = ((netBorrow_ * 10000) /
            (ratios.maxLimit - margin_));
        uint256 netColLimit_ = netCollateral_ > colCoveringDebt_
            ? netCollateral_ - colCoveringDebt_
            : 0;

        require(
            amount_ < (balances_.totalBal + netColLimit_),
            "excess-withdrawal"
        );

        transferAmts_ = new uint256[](5);
        if (balances_.wethVaultBal > 10) {
            (amount_, transferAmts_[0]) = withdrawHelper(
                amount_,
                balances_.wethVaultBal
            );
        }
        if (balances_.wethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[1]) = withdrawHelper(
                amount_,
                balances_.wethDsaBal
            );
        }
        if (balances_.stethVaultBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[2]) = withdrawHelper(
                amount_,
                balances_.stethVaultBal
            );
        }
        if (balances_.stethDsaBal > 10 && amount_ > 0) {
            (amount_, transferAmts_[3]) = withdrawHelper(
                amount_,
                balances_.stethDsaBal
            );
        }
        if (netColLimit_ > 10 && amount_ > 0) {
            (amount_, transferAmts_[4]) = withdrawHelper(amount_, netColLimit_);
        }
    }

    /**
     * @dev Function to handle withdraw related transfers.
     */
    function withdrawTransfers(uint256 amount_, uint256[] memory transferAmts_)
        internal
        returns (uint256 wethAmt_, uint256 stEthAmt_)
    {
        wethAmt_ = transferAmts_[0] + transferAmts_[1];
        stEthAmt_ = transferAmts_[2] + transferAmts_[3] + transferAmts_[4];
        uint256 totalTransferAmount_ = wethAmt_ + stEthAmt_;
        require(amount_ == totalTransferAmount_, "transfers-not-valid");
        // batching up spells and withdrawing all the required asset from DSA to vault at once
        uint256 i;
        uint256 j;
        if (transferAmts_[4] > 0) j += 1;
        if (transferAmts_[1] > 0) j += 1;
        if (transferAmts_[3] > 0 || transferAmts_[4] > 0) j += 1;
        if (j == 0) return (wethAmt_, stEthAmt_);
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (transferAmts_[4] > 0) {
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                transferAmts_[4],
                0,
                0
            );
            i++;
        }
        if (transferAmts_[1] > 0) {
            targets_[i] = "BASIC-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                wethAddr,
                transferAmts_[1],
                address(this),
                0,
                0
            );
            i++;
        }
        if (transferAmts_[3] > 0 || transferAmts_[4] > 0) {
            targets_[i] = "BASIC-A";
            calldata_[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                stEthAddr,
                transferAmts_[3] + transferAmts_[4],
                address(this),
                0,
                0
            );
            i++;
        }
        if (j > 0) vaultDsa.cast(targets_, calldata_, address(this));
    }

    /**
     * @dev Internal functions to handle withdrawals.
     */
    function withdrawInternal(
        uint256 amount_,
        address to_,
        bool afterDeleverage_
    ) internal returns (uint256 vtokenAmount_) {
        require(amount_ != 0, "amount cannot be zero");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        if (amount_ == type(uint256).max) {
            vtokenAmount_ = balanceOf(msg.sender); // vToken amount would be the net asset(steth inital deposited)
            amount_ = (vtokenAmount_ * exchangePrice_) / 1e18;
        } else {
            vtokenAmount_ = (amount_ * 1e18) / exchangePrice_;
        }

        _burn(msg.sender, vtokenAmount_);
        uint256 fee_ = (amount_ * withdrawalFee) / 10000;
        uint256 amountAfterFee_ = amount_ - fee_;

        uint256[] memory transferAmts_ = withdrawFinal(
            amountAfterFee_,
            afterDeleverage_
        );

        (uint256 wethAmt_, uint256 stEthAmt_) = withdrawTransfers(
            amountAfterFee_,
            transferAmts_
        );
        (bool maxIsOk_, , , , bool hfIsOk_) = validateFinalRatio();

        require(maxIsOk_ && hfIsOk_, "Aave-position-risky");

        if (wethAmt_ > 0) {
            // withdraw weth and sending ETH to user
            wethCoreContract.withdraw(wethAmt_);
            Address.sendValue(payable(to_), wethAmt_);
        }
        if (stEthAmt_ > 0) stEthContract.safeTransfer(to_, stEthAmt_);

        if (afterDeleverage_) {
            (, , , bool minGapIsOk_, ) = validateFinalRatio();
            require(minGapIsOk_, "Aave-position-risky");
        }
    }

    /**
     * @dev Internal functions for deleverge logics.
     */
    function deleverageInternal(uint256 amt_)
        internal
        returns (uint256 transferAmt_)
    {
        require(amt_ > 0, "not-valid-amount");
        wethContract.safeTransferFrom(msg.sender, address(vaultDsa), amt_);

        bool isDsa_ = instaList.accountID(msg.sender) > 0;

        uint256 i;
        uint256 j = isDsa_ ? 2 : 3;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        targets_[0] = "AAVE-V2-A";
        calldata_[0] = abi.encodeWithSignature(
            "payback(address,uint256,uint256,uint256,uint256)",
            wethAddr,
            amt_,
            2,
            0,
            0
        );
        if (!isDsa_) {
            transferAmt_ = amt_ + ((amt_ * deleverageFee) / 10000);
            targets_[1] = "AAVE-V2-A";
            calldata_[1] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                transferAmt_,
                0,
                0
            );
            i = 2;
        } else {
            transferAmt_ = amt_;
            i = 1;
        }
        targets_[i] = "BASIC-A";
        calldata_[i] = abi.encodeWithSignature(
            "withdraw(address,uint256,address,uint256,uint256)",
            isDsa_ ? address(astethToken) : stEthAddr,
            transferAmt_,
            msg.sender,
            0,
            0
        );
        vaultDsa.cast(targets_, calldata_, address(this));
    }
}

contract InstaVaultImplementation is CoreHelpers {
    using SafeERC20 for IERC20;

    /**
     * @dev Supply Eth.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supplyEth(address to_)
        external
        payable
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        uint256 amount_ = msg.value;
        vtokenAmount_ = supplyInternal(ethAddr, amount_, to_, true);
        emit supplyLog(ethAddr, amount_, to_);
    }

    /**
     * @dev User function to supply (WETH or STETH).
     * @param token_ address of token, steth or weth.
     * @param amount_ amount to supply.
     * @param to_ address to send vTokens to.
     * @return vtokenAmount_ amount of vTokens sent to the `to_` address passed
     */
    function supply(
        address token_,
        uint256 amount_,
        address to_
    ) external nonReentrant returns (uint256 vtokenAmount_) {
        vtokenAmount_ = supplyInternal(token_, amount_, to_, false);
        emit supplyLog(token_, amount_, to_);
    }

    /**
     * @dev User function to withdraw (to get ETH or STETH).
     * @param amount_ amount to withdraw.
     * @param to_ address to send tokens to.
     * @return vtokenAmount_ amount of vTokens burnt from caller
     */
    function withdraw(uint256 amount_, address to_)
        external
        nonReentrant
        returns (uint256 vtokenAmount_)
    {
        vtokenAmount_ = withdrawInternal(amount_, to_, false);
        emit withdrawLog(amount_, to_);
    }

    /**
     * @dev If ratio is below then this function will allow anyone to swap from steth -> weth.
     */
    function leverage(uint256 amt_) external nonReentrant {
        require(amt_ > 0, "not-valid-amount");
        uint256 fee_ = (amt_ * swapFee) / 10000;
        uint256 transferAmt_ = amt_ - fee_;
        revenue += fee_;

        stEthContract.safeTransferFrom(msg.sender, address(this), amt_);

        uint256 wethVaultBal_ = wethContract.balanceOf(address(this));
        uint256 stethVaultBal_ = stEthContract.balanceOf(address(this));

        if (wethVaultBal_ >= transferAmt_) {
            wethContract.safeTransfer(msg.sender, transferAmt_);
        } else {
            uint256 remainingTransferAmt_ = transferAmt_;
            if (wethVaultBal_ > 1e14) {
                remainingTransferAmt_ -= wethVaultBal_;
                wethContract.safeTransfer(msg.sender, wethVaultBal_);
            }
            uint256 i;
            uint256 j = 2;
            if (stethVaultBal_ > 1e14) {
                stEthContract.safeTransfer(address(vaultDsa), stethVaultBal_);
                j = 3;
            }
            string[] memory targets_ = new string[](j);
            bytes[] memory calldata_ = new bytes[](j);
            if (stethVaultBal_ > 1e14) {
                targets_[i] = "AAVE-V2-A";
                calldata_[i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    stEthAddr,
                    stethVaultBal_,
                    0,
                    0
                );
                i++;
            }
            targets_[i] = "AAVE-V2-A";
            calldata_[i] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                remainingTransferAmt_,
                2,
                0,
                0
            );
            targets_[i + 1] = "BASIC-A";
            calldata_[i + 1] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                wethAddr,
                remainingTransferAmt_,
                msg.sender,
                0,
                0
            );
            vaultDsa.cast(targets_, calldata_, address(this));
            (bool maxIsOk_, , bool minIsOk_, , ) = validateFinalRatio();
            require(minIsOk_ && maxIsOk_, "excess-leverage");
        }

        emit leverageLog(amt_, transferAmt_);
    }

    /**
     * @dev If ratio is above then this function will allow anyone to payback WETH and withdraw astETH to msg.sender at 1:1 ratio.
     */
    function deleverage(uint256 amt_) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(amt_);
        (, , , bool minGapIsOk_, ) = validateFinalRatio();
        require(minGapIsOk_, "excess-deleverage");

        emit deleverageLog(amt_, transferAmt_);
    }

    /**
     * @dev Function to allow max withdrawals.
     */
    function deleverageAndWithdraw(
        uint256 deleverageAmt_,
        uint256 withdrawAmount_,
        address to_
    ) external nonReentrant {
        uint256 transferAmt_ = deleverageInternal(deleverageAmt_); //transffered aSteth if DSA.
        uint256 vtokenAmt_ = withdrawInternal(withdrawAmount_, to_, true);

        emit deleverageAndWithdrawLog(
            deleverageAmt_,
            transferAmt_,
            vtokenAmt_,
            to_
        );
    }

    struct ImportPositionVariables {
        uint256 ratioLimit;
        uint256 importNetAmt;
        uint256 initialDsaAsteth;
        uint256 initialDsaWethDebt;
        uint256 finalDsaAsteth;
        uint256 finalDsaWethDebt;
        uint256 dsaDif;
        bytes encodedFlashData;
        string[] flashTarget;
        bytes[] flashCalldata;
        bool[] checks;
    }

    /**
     * @dev Function to import user's position from his/her DSA to vault.
     */
    function importPosition(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address to_,
        uint256 stEthAmt_,
        uint256 wethAmt_
    ) external nonReentrant {
        ImportPositionVariables memory v_;

        stEthAmt_ = stEthAmt_ == type(uint256).max
            ? astethToken.balanceOf(msg.sender)
            : stEthAmt_;
        wethAmt_ = wethAmt_ == type(uint256).max
            ? awethVariableDebtToken.balanceOf(msg.sender)
            : wethAmt_;

        v_.importNetAmt = stEthAmt_ - wethAmt_;
        v_.ratioLimit = (wethAmt_ * 1e4) / stEthAmt_;
        require(v_.ratioLimit <= ratios.maxLimit, "risky-import");

        (
            uint256 exchangePrice_,
            uint256 newRevenue_
        ) = getCurrentExchangePrice();
        updateStorage(exchangePrice_, newRevenue_);

        v_.initialDsaAsteth = astethToken.balanceOf(address(vaultDsa));
        v_.initialDsaWethDebt = awethVariableDebtToken.balanceOf(
            address(vaultDsa)
        );

        uint256 j = flashAmt_ > 0 ? 6 : 3;
        uint256 i;
        string[] memory targets_ = new string[](j);
        bytes[] memory calldata_ = new bytes[](j);
        if (flashAmt_ > 0) {
            require(flashTkn_ != address(0), "wrong-flash-token");
            targets_[0] = "AAVE-V2-A";
            calldata_[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i++;
        }
        targets_[i] = "AAVE-V2-A";
        calldata_[i] = abi.encodeWithSignature(
            "borrow(address,uint256,uint256,uint256)",
            wethAddr,
            wethAmt_,
            0,
            0
        );
        targets_[i + 1] = "AAVE-V2-A";
        calldata_[i + 1] = abi.encodeWithSignature(
            "paybackOnBehalfOf(address,uint256,uint256,address,uint256,uint256)",
            wethAddr,
            wethAmt_,
            2,
            msg.sender,
            0,
            0
        );
        targets_[i + 2] = "BASIC-A";
        calldata_[i + 2] = abi.encodeWithSignature(
            "depositFrom(address,uint256,address,uint256,uint256)",
            astethToken,
            stEthAmt_,
            msg.sender,
            0,
            0
        );
        if (flashAmt_ > 0) {
            targets_[i + 3] = "AAVE-V2-A";
            calldata_[i + 3] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            targets_[i + 4] = "INSTAPOOL-C";
            calldata_[i + 4] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
        }
        if (flashAmt_ > 0) {
            v_.encodedFlashData = abi.encode(targets_, calldata_);

            v_.flashTarget = new string[](1);
            v_.flashCalldata = new bytes[](1);
            v_.flashTarget[0] = "INSTAPOOL-C";
            v_.flashCalldata[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                flashTkn_,
                flashAmt_,
                route_,
                v_.encodedFlashData,
                "0x"
            );

            vaultDsa.cast(v_.flashTarget, v_.flashCalldata, address(this));
        } else {
            vaultDsa.cast(targets_, calldata_, address(this));
        }

        v_.finalDsaAsteth = astethToken.balanceOf(address(vaultDsa));
        v_.finalDsaWethDebt = awethVariableDebtToken.balanceOf(
            address(vaultDsa)
        );

        // final net balance - initial net balance
        v_.dsaDif =
            (v_.finalDsaAsteth - v_.finalDsaWethDebt) -
            (v_.initialDsaAsteth - v_.initialDsaWethDebt);
        require(v_.importNetAmt < v_.dsaDif + 1e9, "import-check-fail"); // Adding 1e9 for decimal problem that might occur due to Aave's calculation

        v_.checks = new bool[](2);

        (v_.checks[0], , , , v_.checks[1]) = validateFinalRatio();
        require(v_.checks[0] && v_.checks[1], "Import: position-is-risky");

        uint256 vtokenAmount_ = (v_.importNetAmt * 1e18) / exchangePrice_;
        _mint(to_, vtokenAmount_);

        emit importLog(flashTkn_, flashAmt_, route_, to_, stEthAmt_, wethAmt_);
    }

    /**
     * @dev Rebalancer function to leverage and rebalance the position.
     */
    function rebalanceOne(
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        address[] memory vaults_, // leverage using other vaults
        uint256[] memory amts_,
        uint256 excessDebt_,
        uint256 paybackDebt_,
        uint256 totalAmountToSwap_,
        uint256 extraWithdraw_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        Address.functionDelegateCall(rebalancerModuleAddr, msg.data);
    }

    /**
     * @dev Rebalancer function for saving. To be run in times of making position less risky or to fill up the withdraw amount for users to exit
     */
    function rebalanceTwo(
        uint256 withdrawAmt_,
        address flashTkn_,
        uint256 flashAmt_,
        uint256 route_,
        uint256 totalAmountToSwap_,
        uint256 unitAmt_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        Address.functionDelegateCall(rebalancerModuleAddr, msg.data);
    }

    /**
     * @dev Function to collect revenue.
     * @param amount_ amount to claim
     * @param to_ address to send the claimed revenue to
     */
    function collectRevenue(uint256 amount_, address to_) external onlyAuth {
        require(amount_ != 0, "amount-cannot-be-zero");
        if (amount_ == type(uint256).max) amount_ = revenue;
        require(amount_ <= revenue, "not-enough-revenue");
        revenue -= amount_;

        uint256 stethAmt_;
        uint256 wethAmt_;
        uint256 wethVaultBal_ = wethContract.balanceOf(address(this));
        uint256 stethVaultBal_ = stEthContract.balanceOf(address(this));
        if (wethVaultBal_ > 10)
            (amount_, wethAmt_) = withdrawHelper(amount_, wethVaultBal_);
        if (amount_ > 0 && stethVaultBal_ > 10)
            (amount_, stethAmt_) = withdrawHelper(amount_, stethVaultBal_);
        require(amount_ == 0, "not-enough-amount-inside-vault");
        if (wethAmt_ > 0) wethContract.safeTransfer(to_, wethAmt_);
        if (stethAmt_ > 0) stEthContract.safeTransfer(to_, stethAmt_);

        emit collectRevenueLog(stethAmt_ + wethAmt_, stethAmt_, wethAmt_, to_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure override returns (string memory) {
        return "Instadapp ETH";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure override returns (string memory) {
        return "iETH";
    }

    /* 
     Deprecated
    */
    // function initialize(
    //     string memory name_,
    //     string memory symbol_,
    //     address auth_,
    //     address rebalancer_,
    //     uint256 revenueFee_,
    //     uint16[] memory ratios_
    // ) public initializer {
    //     address vaultDsaAddr_ = instaIndex.build(address(this), 2, address(this));
    //     vaultDsa = IDSA(vaultDsaAddr_);
    //     __ERC20_init(name_, symbol_);
    //     auth = auth_;
    //     isRebalancer[rebalancer_] = true;
    //     revenueFee = revenueFee_;
    //     lastRevenueExchangePrice = 1e18;
    //     // sending borrow rate in 4 decimals eg:- 300 meaning 3% and converting into 27 decimals eg:- 3 * 1e25
    //     ratios = Ratios(ratios_[0], ratios_[1], ratios_[2], uint128(ratios_[3]) * 1e23);
    // }

    receive() external payable {}
}