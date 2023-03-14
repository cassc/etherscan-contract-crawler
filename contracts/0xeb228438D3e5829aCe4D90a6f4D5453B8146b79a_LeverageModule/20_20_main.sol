// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../../common/helpers.sol";
import "./events.sol";

/// @title LeverageModule
/// @dev Actions are executable by allowed rebalancers only
contract LeverageModule is Helpers, Events {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    // Revert if protocol or vault overall ratio after leverage is more than max.
    error LeverageModule__UnequalLength();
    error LeverageModule__UnitAmountLess();
    error LeverageModule__AggregatedRatioExceeded();
    error LeverageModule__MaxRiskRatioExceeded();
    error LeverageModule__LessAssetsRecieved();

    struct LeverageMemoryVariables {
        bool isStETHBasedProtocol;
        uint256 spellIndex;
        uint256 spellsLength;
        uint256 vaultsLength;
        string[] targets;
        bytes[] calldatas;
        uint256 flashStETH;
        uint256 beforeNetAssets;
        uint256 afterNetAssets;
        uint256 aggregatedRatio;
    }

    /// @notice Core function to perform leverage.
    /// @dev Note Flashloan will always be taken in `WSTETH`.
    /// @param protocolId_ Id of the protocol to leverage.
    /// @param route_ Route for flashloan
    /// @param wstETHflashAmount_ Amount of flashloan.
    /// @param wETHBorrowAmount_ Amount of weth to be borrowed.
    /// @param vaults_ Addresses of old vaults to deleverage.
    /// @param vaultAmounts_ Amount of `WETH` that we will payback in old vaults.
    /// @param swapMode_ Mode of swap.(0 = no swap, 1 = 1Inch, 2 = direct Lido route)
    /// @param unitAmount_ `WSTETH` per `WETH` conversion ratio with slippage.
    /// @dev Note `WETH` will always be swapped to `WSTETH`,
    /// even if the protocol accepts STETH. (This is done to add simplicity to the vault).
    /// @param oneInchData_ Bytes calldata required for `WETH` to `WSTETH` swapping.
    function leverage(
        uint8 protocolId_,
        uint256 route_,
        uint256 wstETHflashAmount_,
        uint256 wETHBorrowAmount_,
        address[] memory vaults_,
        uint256[] memory vaultAmounts_,
        uint256 swapMode_,
        uint256 unitAmount_,
        bytes memory oneInchData_
    ) external nonReentrant onlyRebalancer {
        if (protocolId_ == 4) {
            revert Helpers__EulerDisabled();
        }

        LeverageMemoryVariables memory lev_;
        lev_.vaultsLength = vaultAmounts_.length;
        if (!(vaults_.length == lev_.vaultsLength))
            revert LeverageModule__UnequalLength();

        lev_.isStETHBasedProtocol = (protocolId_ == 1 || protocolId_ == 5);

        // Includes eth borrow + stETH deposit
        lev_.spellsLength = 2;

        if (lev_.isStETHBasedProtocol) {
            // stETH based protocol

            // Note: Below are the spells based on which spell count has been calculated.
            // If wstETHflashAmount_ > 0, unwrap wsteth, deposit stETH aavev2 -> 2
            // Borrow (no condition) -> 1
            // Deleverage, aave v2 withdraw -> lev_.vaultsLength > 0 , lev_.vaultsLength + 1
            // Swap wETH to wstETH, unwrap wstETH -> swapMode_ == 1 , 2
            // Convert wETH to ETH, ETH to stETH -> swapMode_ == 2 , 2
            // Deposit wsteth aavev2, -> no condition , 1
            // Withdraw aave v2 wstETH, unwrap wsteth, flashpayback wstETH -> wstETHflashAmount_ > 0 , 3

            // Includes flash unwrap, deposit, withdraw, wrap, and flash payback.
            if (wstETHflashAmount_ > 0) lev_.spellsLength += 5;
            // Includes deleveraging other vaults (deleveraging other vaults gives astETH in return at 1:1)
            // + 1 for withdrawing underlying stETH from astETH.
            if (lev_.vaultsLength > 0)
                lev_.spellsLength += lev_.vaultsLength + 1;

            // Includes 1Inch swap to wstETH and unwrap.
            if (swapMode_ == 1)
                lev_.spellsLength += 2;
                // Includes direct Lido route. wETH => eth => stETH.
            else if (swapMode_ == 2) lev_.spellsLength += 2;
        } else {
            // wstETH based protocol

            // Deposit wstETH aavev2, -> wstETHflashAmount_ > 0 , 1
            // Borrow, -> no condition , 1
            // Deleverage, aave v2 withdraw, wrap stETH -> lev_.vaultsLength > 0 , lev_.vaultsLength + 2
            // Swap weth to wsteth, -> swapMode_ == 1 , 1
            // Convert wETH to ETH, ETH to stETH, stETH to wstETH -> swapMode_ == 2 , 3
            // Deposit wsteth aavev2, -> no condition , 1
            // Withdraw aave v2 wstETH, flashpayback wstETH -> wstETHflashAmount_ > 0 , 2

            // Includes flash deposit, withdraw, and flash payback.
            if (wstETHflashAmount_ > 0) lev_.spellsLength += 3;
            // Includes deleveraging other vaults, converting astETH into stETH, wrapping
            // stETH into wstETH (deleveraging other vaults gives astETH in return at 1:1)
            if (lev_.vaultsLength > 0) {
                lev_.spellsLength += lev_.vaultsLength + 2;
            }

            // Includes 1Inch swap.
            if (swapMode_ == 1)
                lev_.spellsLength += 1;
                // Includes direct Lido route. wETH => eth => stETH => wstETH.
            else if (swapMode_ == 2) lev_.spellsLength += 3;
        }

        // Var to set the total amount of astETH recieved from old vault deleverage.
        // Used for swapping astETH to stETH.
        uint256 vaultSwapAmt_;
        uint256 wstethPerWeth;

        lev_.targets = new string[](lev_.spellsLength);
        lev_.calldatas = new bytes[](lev_.spellsLength);

        (, , lev_.beforeNetAssets, , ) = getNetAssets();

        /***********************************|
        |     FLASHLOAN wstETH DEPOSIT      |
        |__________________________________*/
        if (wstETHflashAmount_ > 0) {
            // Flashloan needed. Hence adding spells to deposit flashloan received.

            if (lev_.isStETHBasedProtocol) {
                // stETH based protocol
                lev_.flashStETH = WSTETH_CONTRACT.getStETHByWstETH(
                    wstETHflashAmount_
                );

                // Flashloan is in wstETH & protocol 1 & 5 only supports stETH.
                // Hence converting flash wstETH into stETH
                lev_.targets[lev_.spellIndex] = "WSTETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,uint256,uint256)", //WSTETH -> STETH
                    type(uint256).max, // Converting all wsteth to steth
                    0,
                    0
                );

                lev_.spellIndex++;
            }

            if (protocolId_ == 1) {
                lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (protocolId_ == 2) {
                lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (protocolId_ == 3) {
                lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (protocolId_ == 4) {
                lev_.targets[lev_.spellIndex] = "EULER-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,address,uint256,bool,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    true,
                    0,
                    0
                );
            } else if (protocolId_ == 5) {
                lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    type(uint256).max, // depositing max steth
                    0,
                    0
                );
            }

            lev_.spellIndex++;
        }

        /***********************************|
        |            WETH BORROW             |
        |__________________________________*/

        if (protocolId_ == 1) {
            lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                WETH_ADDRESS,
                wETHBorrowAmount_,
                2,
                0,
                0
            );
        } else if (protocolId_ == 2) {
            lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,uint256,uint256,uint256,uint256)",
                WETH_ADDRESS,
                wETHBorrowAmount_,
                2,
                0,
                0
            );
        } else if (protocolId_ == 3) {
            lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,address,uint256,uint256,uint256)",
                COMP_ETH_MARKET_ADDRESS,
                WETH_ADDRESS,
                wETHBorrowAmount_,
                0,
                0
            );
        } else if (protocolId_ == 4) {
            lev_.targets[lev_.spellIndex] = "EULER-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(uint256,address,uint256,uint256,uint256)",
                0,
                WETH_ADDRESS,
                wETHBorrowAmount_,
                0,
                0
            );
        } else if (protocolId_ == 5) {
            lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "borrow(address,address,uint256,uint256,uint256)",
                WETH_ADDRESS,
                A_WETH_ADDRESS,
                wETHBorrowAmount_,
                0,
                0
            );
        }

        lev_.spellIndex++;

        /***********************************|
        |       DELEVERAGE V1 VAULTS        |
        |__________________________________*/

        if (lev_.vaultsLength > 0) {
            for (uint256 k = 0; k < lev_.vaultsLength; k++) {
                lev_.targets[lev_.spellIndex] = "LITE-A"; // Instadapp Lite v1 vaults connector
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deleverage(address,uint256,uint256,uint256)",
                    vaults_[k],
                    vaultAmounts_[k],
                    0,
                    0
                );

                lev_.spellIndex++;

                // We'll receive astETH 1:1 for wETH payback.
                wETHBorrowAmount_ -= vaultAmounts_[k];
                vaultSwapAmt_ += vaultAmounts_[k];
            }

            lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "withdraw(address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                vaultSwapAmt_, // Not taking buffer since we will mostly have borrowed assets on aave so buffer case will be covered.
                0,
                0
            );

            lev_.spellIndex++;

            if (!(lev_.isStETHBasedProtocol)) {
                // wstETH based protocols
                lev_.targets[lev_.spellIndex] = "WSTETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    type(uint256).max, // Swap all the stETH amount recieved through Aave.
                    0,
                    0
                );

                lev_.spellIndex++;
            }
        }

        /***********************************|
        |      WETH => WSTETH 1INCH SWAP     |
        |__________________________________*/

        if (swapMode_ > 0) {
            if (swapMode_ == 1) {
                // swap via 1inch
                // wstethPerWeth will always be < 1, considering wETH is 1:1 with stETH.
                wstethPerWeth = WSTETH_CONTRACT.tokensPerStEth();
                if (unitAmount_ < (wstethPerWeth - leverageMaxUnitAmountLimit))
                    revert LeverageModule__UnitAmountLess();

                lev_.targets[lev_.spellIndex] = "1INCH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "sell(address,address,uint256,uint256,bytes,uint256)",
                    WSTETH_ADDRESS,
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    unitAmount_,
                    oneInchData_,
                    0
                );
                lev_.spellIndex++;

                // Unwrapping wstETH to stETH after 1Inch swap(wETH => wstETH)
                if (lev_.isStETHBasedProtocol) {
                    // stETH based protocols
                    lev_.targets[lev_.spellIndex] = "WSTETH-A";
                    lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                        "withdraw(uint256,uint256,uint256)",
                        type(uint256).max, // Swap all the wstETH amount recieved through 1Inch.
                        0,
                        0
                    );

                    lev_.spellIndex++;
                }
            } else if (swapMode_ == 2) {
                // convert wETH into ETH
                lev_.targets[lev_.spellIndex] = "WETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,uint256,uint256)",
                    wETHBorrowAmount_,
                    0,
                    0
                );
                lev_.spellIndex++;

                // convert ETH into stETH
                lev_.targets[lev_.spellIndex] = "LIDO-STETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    wETHBorrowAmount_,
                    0,
                    0
                );
                lev_.spellIndex++;

                // wrapping stETH to wstETH
                if (!lev_.isStETHBasedProtocol) {
                    // wstETH based protocols
                    lev_.targets[lev_.spellIndex] = "WSTETH-A";
                    lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                        "deposit(uint256,uint256,uint256)",
                        type(uint256).max,
                        0,
                        0
                    );
                    lev_.spellIndex++;
                }
            }
        }

        /***********************************|
        |         COLLATERAL DEPOSIT        |
        |__________________________________*/

        /// If protocol is 1 or 5, DSA would currently have all stETH (since we unwrapped all wstETH from 1Inch swap).
        /// If protocol is 2, 3 or 4, DSA would currently have all wstETH (since we have wrapped all the stETH to wstETH).
        if (protocolId_ == 1) {
            // stETH based protocol
            lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 2) {
            // wstETH based protocol
            lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 3) {
            // wstETH based protocol
            lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,address,uint256,uint256,uint256)",
                COMP_ETH_MARKET_ADDRESS,
                WSTETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        } else if (protocolId_ == 4) {
            // wstETH based protocol
            lev_.targets[lev_.spellIndex] = "EULER-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(uint256,address,uint256,bool,uint256,uint256)",
                0,
                WSTETH_ADDRESS,
                type(uint256).max,
                true,
                0,
                0
            );
        } else if (protocolId_ == 5) {
            // stETH based protocol
            lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "deposit(address,address,uint256,uint256,uint256)",
                STETH_ADDRESS,
                A_STETH_ADDRESS,
                type(uint256).max,
                0,
                0
            );
        }
        lev_.spellIndex++;

        /***********************************|
        |         WITHDRAW FLASHLOAN        |
        |__________________________________*/

        if (wstETHflashAmount_ > 0) {
            if (protocolId_ == 1) {
                lev_.targets[lev_.spellIndex] = "AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    (lev_.flashStETH + 10), // taking 10 wei margin as there is possibilty of 1 wei precision loss due to exchange price calculations
                    0,
                    0
                );
            } else if (protocolId_ == 2) {
                lev_.targets[lev_.spellIndex] = "AAVE-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    wstETHflashAmount_,
                    0,
                    0
                );
            } else if (protocolId_ == 3) {
                lev_.targets[lev_.spellIndex] = "COMPOUND-V3-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    wstETHflashAmount_,
                    0,
                    0
                );
            } else if (protocolId_ == 4) {
                lev_.targets[lev_.spellIndex] = "EULER-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,address,uint256,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    wstETHflashAmount_,
                    0,
                    0
                );
            } else if (protocolId_ == 5) {
                lev_.targets[lev_.spellIndex] = "MORPHO-AAVE-V2-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    (lev_.flashStETH + 10), // taking 10 wei margin as there is possibilty of 1 wei precision loss due to exchange price calculations
                    0,
                    0
                );
            }
            lev_.spellIndex++;

            if (lev_.isStETHBasedProtocol) {
                lev_.targets[lev_.spellIndex] = "WSTETH-A";
                lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    type(uint256).max,
                    0,
                    0
                );
                lev_.spellIndex++;
            }

            lev_.targets[lev_.spellIndex] = "INSTAPOOL-C";
            lev_.calldatas[lev_.spellIndex] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                wstETHflashAmount_,
                0,
                0
            );
            lev_.spellIndex++;

            bytes memory encodedFlashData_ = abi.encode(
                lev_.targets,
                lev_.calldatas
            );

            string[] memory flashTarget = new string[](1);
            bytes[] memory flashCalldata = new bytes[](1);
            flashTarget[0] = "INSTAPOOL-C";
            flashCalldata[0] = abi.encodeWithSignature(
                "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                WSTETH_ADDRESS,
                wstETHflashAmount_,
                route_,
                encodedFlashData_,
                "0x"
            );

            vaultDSA.cast(flashTarget, flashCalldata, address(this));
        } else {
            vaultDSA.cast(lev_.targets, lev_.calldatas, address(this));
        }

        // Verifying that the max risk ratio of the vault is less than the max ratio allowed.
        if (getProtocolRatio(protocolId_) > maxRiskRatio[protocolId_]) {
            revert LeverageModule__MaxRiskRatioExceeded();
        }

        // Verifying that the aggregated ratio of the vault is less than the max ratio allowed.
        (, , lev_.afterNetAssets, lev_.aggregatedRatio, ) = getNetAssets();

        if (lev_.afterNetAssets > lev_.beforeNetAssets) {
            revenue = revenue + lev_.afterNetAssets - lev_.beforeNetAssets;
        } else if ((lev_.beforeNetAssets - lev_.afterNetAssets) > 1e10) {
            revert LeverageModule__LessAssetsRecieved();
        }

        if (lev_.aggregatedRatio > aggrMaxVaultRatio) {
            revert LeverageModule__AggregatedRatioExceeded();
        }

        emit LogLeverage(
            protocolId_,
            route_,
            wstETHflashAmount_,
            wETHBorrowAmount_,
            vaults_,
            vaultAmounts_,
            swapMode_,
            unitAmount_,
            vaultSwapAmt_
        );
    }
}