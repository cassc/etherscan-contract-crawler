//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";

contract IEthRebalancerModule is Helpers {
    using SafeERC20 for IERC20;

    struct RebalanceOneVariables {
        uint256 stethBal;
        string[] targets;
        bytes[] calldatas;
        bool[] checks;
        uint256 length;
        bool isOk;
        bytes encodedFlashData;
        string[] flashTarget;
        bytes[] flashCalldata;
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
    ) external {
        if (excessDebt_ < 1e14) excessDebt_ = 0;
        if (paybackDebt_ < 1e14) paybackDebt_ = 0;
        if (totalAmountToSwap_ < 1e14) totalAmountToSwap_ = 0;
        if (extraWithdraw_ < 1e14) extraWithdraw_ = 0;

        RebalanceOneVariables memory v_;

        v_.length = amts_.length;
        require(vaults_.length == v_.length, "unequal-length");

        require(
            !(excessDebt_ > 0 && paybackDebt_ > 0),
            "cannot-borrow-and-payback-at-once"
        );
        require(
            !(totalAmountToSwap_ > 0 && paybackDebt_ > 0),
            "cannot-swap-and-payback-at-once"
        );
        require(
            !((totalAmountToSwap_ > 0 || v_.length > 0) && excessDebt_ == 0),
            "cannot-swap-and-when-zero-excess-debt"
        );

        BalVariables memory balances_ = getIdealBalances();
        v_.stethBal = balances_.stethDsaBal;
        if (balances_.wethVaultBal > 1e14)
            wethContract.safeTransfer(
                address(vaultDsa),
                balances_.wethVaultBal
            );
        if (balances_.stethVaultBal > 1e14) {
            stEthContract.safeTransfer(
                address(vaultDsa),
                balances_.stethVaultBal
            );
            v_.stethBal += balances_.stethVaultBal;
        }
        if (v_.stethBal < 1e14) v_.stethBal = 0;

        uint256 i;
        uint256 j;
        if (excessDebt_ > 0) j += 4;
        if (v_.length > 0) j += v_.length;
        if (totalAmountToSwap_ > 0) j += 1;
        if (excessDebt_ > 0 && (totalAmountToSwap_ > 0 || v_.stethBal > 0))
            j += 1;
        if (paybackDebt_ > 0) j += 1;
        if (v_.stethBal > 0 && excessDebt_ == 0) j += 1;
        if (extraWithdraw_ > 0) j += 2;
        v_.targets = new string[](j);
        v_.calldatas = new bytes[](j);
        if (excessDebt_ > 0) {
            v_.targets[0] = "AAVE-V2-A";
            v_.calldatas[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[1] = "AAVE-V2-A";
            v_.calldatas[1] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                excessDebt_,
                2,
                0,
                0
            );
            i = 2;
            // Doing swaps from different vaults using deleverage to reduce other vaults riskiness if needed.
            // It takes WETH from vault and gives astETH at 1:1
            for (uint256 k = 0; k < v_.length; k++) {
                v_.targets[i] = "LITE-A"; // Instadapp Lite vaults connector
                v_.calldatas[i] = abi.encodeWithSignature(
                    "deleverage(address,uint256,uint256,uint256)",
                    vaults_[k],
                    amts_[k],
                    0,
                    0
                );
                i++;
            }
            if (totalAmountToSwap_ > 0) {
                require(unitAmt_ > (1e18 - 10), "invalid-unit-amt");
                v_.targets[i] = "1INCH-A";
                v_.calldatas[i] = abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    stEthAddr,
                    wethAddr,
                    totalAmountToSwap_,
                    unitAmt_,
                    oneInchData_,
                    0
                );
                i++;
            }
            if (totalAmountToSwap_ > 0 || v_.stethBal > 0) {
                v_.targets[i] = "AAVE-V2-A";
                v_.calldatas[i] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    stEthAddr,
                    type(uint256).max,
                    0,
                    0
                );
                i++;
            }
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[i + 1] = "INSTAPOOL-C";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i += 2;
        }
        if (paybackDebt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                paybackDebt_,
                2,
                0,
                0
            );
            i++;
        }
        if (v_.stethBal > 0 && excessDebt_ == 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                stEthAddr,
                type(uint256).max,
                0,
                0
            );
            i++;
        }
        if (extraWithdraw_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                extraWithdraw_,
                0,
                0
            );
            v_.targets[i + 1] = "BASIC-A";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "withdraw(address,uint256,address,uint256,uint256)",
                stEthAddr,
                extraWithdraw_,
                address(this),
                0,
                0
            );
        }

        if (excessDebt_ > 0) {
            v_.encodedFlashData = abi.encode(v_.targets, v_.calldatas);

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
            require(
                getWethBorrowRate() < ratios.maxBorrowRate,
                "high-borrow-rate"
            );
        } else {
            if (j > 0) vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }

        v_.checks = new bool[](4);
        (
            v_.checks[0],
            ,
            v_.checks[1],
            v_.checks[2],
            v_.checks[3]
        ) = validateFinalRatio();
        if (excessDebt_ > 0)
            require(v_.checks[1], "position-risky-after-leverage");
        if (extraWithdraw_ > 0) require(v_.checks[0], "position-risky");
        if (excessDebt_ > 0 && extraWithdraw_ > 0)
            require(v_.checks[3], "position-hf-risky");

        emit rebalanceOneLog(
            flashTkn_,
            flashAmt_,
            route_,
            vaults_,
            amts_,
            excessDebt_,
            paybackDebt_,
            totalAmountToSwap_,
            extraWithdraw_,
            unitAmt_
        );
    }

    struct RebalanceTwoVariables {
        bool hfIsOk;
        BalVariables balances;
        uint256 wethBal;
        string[] targets;
        bytes[] calldatas;
        bytes encodedFlashData;
        string[] flashTarget;
        bytes[] flashCalldata;
        bool maxIsOk;
        bool minGapIsOk;
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
    ) external {
        RebalanceTwoVariables memory v_;
        (, , , , v_.hfIsOk) = validateFinalRatio();
        if (v_.hfIsOk) {
            require(unitAmt_ > (1e18 - (2 * 1e16)), "excess-slippage"); // Here's it's 2% slippage.
        } else {
            // Here's it's 5% slippage. Only when HF is not okay. Meaning stETH got too unstable from it's original price.
            require(unitAmt_ > (1e18 - (5 * 1e16)), "excess-slippage");
        }
        v_.balances = getIdealBalances();
        v_.wethBal = v_.balances.wethDsaBal;
        if (v_.balances.wethVaultBal > 0) {
            wethContract.safeTransfer(
                address(vaultDsa),
                v_.balances.wethVaultBal
            );
            v_.wethBal += v_.balances.wethVaultBal;
        }
        if (v_.balances.stethVaultBal > 0) {
            stEthContract.safeTransfer(
                address(vaultDsa),
                v_.balances.stethVaultBal
            );
        }
        if (v_.wethBal < 1e14) v_.wethBal = 0;

        uint256 i;
        uint256 j;
        if (flashAmt_ > 0) j += 3;
        if (withdrawAmt_ > 0) j += 1;
        if (totalAmountToSwap_ > 0) j += 1;
        if (totalAmountToSwap_ > 0 || v_.wethBal > 0) j += 1;
        v_.targets = new string[](j);
        v_.calldatas = new bytes[](j);
        if (flashAmt_ > 0) {
            v_.targets[0] = "AAVE-V2-A";
            v_.calldatas[0] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            i++;
        }
        if (withdrawAmt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                stEthAddr,
                withdrawAmt_,
                0,
                0
            );
            i++;
        }
        if (totalAmountToSwap_ > 0) {
            v_.targets[i] = "1INCH-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "sell(address,address,uint256,uint256,bytes,uint256)",
                wethAddr,
                stEthAddr,
                totalAmountToSwap_,
                unitAmt_,
                oneInchData_,
                0
            );
            i++;
        }
        if (totalAmountToSwap_ > 0 || v_.wethBal > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "payback(address,uint256,uint256,uint256,uint256)",
                wethAddr,
                type(uint256).max,
                2,
                0,
                0
            );
            i++;
        }
        if (flashAmt_ > 0) {
            v_.targets[i] = "AAVE-V2-A";
            v_.calldatas[i] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
            v_.targets[i + 1] = "INSTAPOOL-C";
            v_.calldatas[i + 1] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                flashTkn_,
                flashAmt_,
                0,
                0
            );
        }

        if (flashAmt_ > 0) {
            v_.encodedFlashData = abi.encode(v_.targets, v_.calldatas);

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
            vaultDsa.cast(v_.targets, v_.calldatas, address(this));
        }

        (v_.maxIsOk, , , v_.minGapIsOk, ) = validateFinalRatio();
        require(v_.minGapIsOk, "position-over-saved");
        require(v_.maxIsOk, "position-under-saved");

        emit rebalanceTwoLog(
            withdrawAmt_,
            flashTkn_,
            flashAmt_,
            route_,
            totalAmountToSwap_,
            unitAmt_
        );
    }

    receive() external payable {}
}