// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../../common/helpers.sol";
import "./events.sol";

contract RefinanceModule is Helpers, Events {
    /***********************************|
    |              ERRORS               |
    |__________________________________*/
    error RefinanceModule__Unsafe();

    /***********************************|
    |           REFINANCE CORE          |
    |__________________________________*/
    struct RefinanceVariables {
        bool isFromStETHBasedProtocol;
        bool isToStETHBasedProtocol;
        uint256 spellIndex;
        uint256 spellsLength;
        string[] targets;
        bytes[] calldatas;
        uint256 withdrawIdToPaybackFlashloan;
    }

    /// @notice Core function to perform refinance.
    /// @dev Note Flashloan will always be taken in `WSTETH`.
    /// @param fromProtocolId_ Id of the protocol to refinance from.
    /// @param toProtocolId_ Id of the protocol to refinance to.
    /// @param route_ Route for flashloan.
    /// @param wstETHflashAmount_ Amount of flashloan.
    /// @param wETHBorrowAmount_ Amount of wETH to be borrowed.
    /// @param withdrawAmount_ Amount to be withdrawn. Will always be in stETH.
    function refinance(
        uint8 fromProtocolId_,
        uint8 toProtocolId_,
        uint256 route_,
        uint256 wstETHflashAmount_,
        uint256 wETHBorrowAmount_,
        uint256 withdrawAmount_
    )
        external
        nonReentrant
        onlyRebalancer
        returns (uint256 ratioFromProtocol_, uint256 ratioToProtocol_)
    {
        RefinanceVariables memory ref_;

        ref_.isFromStETHBasedProtocol =
            fromProtocolId_ == 1 ||
            fromProtocolId_ == 5;
        ref_.isToStETHBasedProtocol = toProtocolId_ == 1 || toProtocolId_ == 5;

        /// @dev `wstETHflashAmount_` does not include withdraw and deposit spells.
        /// They are considered in `withdrawAmount_` count.
        if (ref_.isFromStETHBasedProtocol && !(ref_.isToStETHBasedProtocol)) {
            // From: stETH based protocol
            // To: wstETH based protocol

            // to: deposit wstETH protocol -> 1
            // to: withdraw wstETH protocol, flashpayback -> 2
            if (wstETHflashAmount_ > 0) ref_.spellsLength += 3;

            // to: borrow wETH, from: payback wETH -> 2
            if (wETHBorrowAmount_ > 0) ref_.spellsLength += 2;

            // from: withdraw stETH protocol, steth => wsteth, to: deposit wstETH protocol -> 3
            if (withdrawAmount_ > 0) ref_.spellsLength += 3;
        } else if (
            !(ref_.isFromStETHBasedProtocol) && ref_.isToStETHBasedProtocol
        ) {
            // From: wstETH based protocol
            // To: stETH based protocol

            // wstETH flashloan to stETH, to: stETH deposit in protocol -> 2
            // stETH withdraw from protocol, stETH to wstETH, flash payback -> 3
            if (wstETHflashAmount_ > 0) ref_.spellsLength += 5;

            // to: borrow WETH, from: payback WETH -> 2
            if (wETHBorrowAmount_ > 0) ref_.spellsLength += 2;

            // from: withdraw wstETH based protocol, unwrap wsteth to steth, to: deposit stETH based protocol -> 3
            if (withdrawAmount_ > 0) ref_.spellsLength += 3;
        } else if (
            ref_.isFromStETHBasedProtocol && ref_.isToStETHBasedProtocol
        ) {
            // From: stETH based protocol
            // To: stETH based protocol

            // wstETH flashloan to stETH, to: stETH deposit protocol -> 2
            // to: withdraw stETH from protocol, stETH to wstETH, flashpayback wstETH -> 3
            if (wstETHflashAmount_ > 0) ref_.spellsLength += 5;

            // to: borrow WETH, from: payback WETH -> 2
            if (wETHBorrowAmount_ > 0) ref_.spellsLength += 2;

            // from: withdraw stETH protocol, to: deposit stETH based protocol -> 2
            if (withdrawAmount_ > 0) ref_.spellsLength += 2;
        } else if (
            !(ref_.isFromStETHBasedProtocol) && !(ref_.isToStETHBasedProtocol)
        ) {
            // From: wstETH based protocol
            // To: wstETH based protocol

            // to: deposit wstETH protocol -> 1
            // to: withdraw wstETH protocol, flashPayback wstETH -> 2
            if (wstETHflashAmount_ > 0) ref_.spellsLength += 3;

            // to: borrow wETH, from: payback wETH -> 2
            if (wETHBorrowAmount_ > 0) ref_.spellsLength += 2;

            // from: withdraw wstETH protocol, to: deposit wstETH protocol -> 2
            if (withdrawAmount_ > 0) ref_.spellsLength += 2;
        }

        // withdrawAmount_ will always be in stETH.
        // Getting wstETH values for protocols supporting wstETH.
        uint256 fromWithdrawAmount_ = ref_.isFromStETHBasedProtocol
            ? withdrawAmount_
            : WSTETH_CONTRACT.getWstETHByStETH(withdrawAmount_);

        // To get the amount of stETH deposited from wstETH flashloan.
        uint256 flashDepositAmount_ = ref_.isToStETHBasedProtocol
            ? WSTETH_CONTRACT.getStETHByWstETH(wstETHflashAmount_)
            : wstETHflashAmount_;

        ref_.targets = new string[](ref_.spellsLength);
        ref_.calldatas = new bytes[](ref_.spellsLength);

        // stETH => wstETH after withdraw for flashloan payback
        ref_.withdrawIdToPaybackFlashloan = 5236237;

        /**************************************|
        |   TAKE WSTETH FLASHLOAN AND DEPOSIT  |
        |_____________________________________*/

        if (wstETHflashAmount_ > 0) {
            if (ref_.isToStETHBasedProtocol) {
                // to: stETH based protocols
                ref_.targets[ref_.spellIndex] = "WSTETH-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,uint256,uint256)",
                    type(uint256).max, // Converting all wsteth to steth
                    0,
                    0
                );

                ref_.spellIndex++;
            }

            if (toProtocolId_ == 1) {
                // to: stETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    type(uint256).max, // stETH amount will come from below getId
                    0,
                    0
                );
            } else if (toProtocolId_ == 2) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (toProtocolId_ == 3) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "COMPOUND-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            } else if (toProtocolId_ == 4) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "EULER-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,address,uint256,bool,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    type(uint256).max,
                    true,
                    0,
                    0
                );
            } else if (toProtocolId_ == 5) {
                // to: stETH based protocol
                ref_.targets[ref_.spellIndex] = "MORPHO-AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    type(uint256).max,
                    0,
                    0
                );
            }

            ref_.spellIndex++;
        }

        /***********************************|
        |      BORROW WETH AND PAYBACK       |
        |__________________________________*/

        if (wETHBorrowAmount_ > 0) {
            if (toProtocolId_ == 1) {
                // to: stETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "borrow(address,uint256,uint256,uint256,uint256)",
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    2,
                    0,
                    0
                );
            } else if (toProtocolId_ == 2) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "borrow(address,uint256,uint256,uint256,uint256)",
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    2,
                    0,
                    0
                );
            } else if (toProtocolId_ == 3) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "COMPOUND-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "borrow(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    0,
                    0
                );
            } else if (toProtocolId_ == 4) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "EULER-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "borrow(uint256,address,uint256,uint256,uint256)",
                    0,
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    0,
                    0
                );
            } else if (toProtocolId_ == 5) {
                // to: stETH based protocol
                ref_.targets[ref_.spellIndex] = "MORPHO-AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "borrow(address,address,uint256,uint256,uint256)",
                    WETH_ADDRESS,
                    A_WETH_ADDRESS,
                    wETHBorrowAmount_,
                    0,
                    0
                );
            }
            ref_.spellIndex++;

            if (fromProtocolId_ == 1) {
                // from: stETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    2,
                    0,
                    0
                );
            } else if (fromProtocolId_ == 2) {
                // from: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    2,
                    0,
                    0
                );
            } else if (fromProtocolId_ == 3) {
                // from: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "COMPOUND-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "payback(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    0,
                    0
                );
            } else if (fromProtocolId_ == 4) {
                // from: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "EULER-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "repay(uint256,address,uint256,uint256,uint256)",
                    0,
                    WETH_ADDRESS,
                    wETHBorrowAmount_,
                    0,
                    0
                );
            } else if (fromProtocolId_ == 5) {
                // from: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "MORPHO-AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "payback(address,address,uint256,uint256,uint256)",
                    WETH_ADDRESS,
                    A_WETH_ADDRESS,
                    wETHBorrowAmount_,
                    0,
                    0
                );
            }
            ref_.spellIndex++;
        }

        /*************************************|
        |     WITHDRAW wstETH AND DEPOSIT     |
        |____________________________________*/

        if (withdrawAmount_ > 0) {
            // even in case of flashloan, this amount will be withdrawn

            if (fromProtocolId_ == 1) {
                // from: stETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    fromWithdrawAmount_, // withdrawAmount_ is stETH based
                    0,
                    0
                );
            } else if (fromProtocolId_ == 2) {
                // wstETH based protocol

                ref_.targets[ref_.spellIndex] = "AAVE-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount converted to wstETH.
                    0,
                    0
                );
            } else if (fromProtocolId_ == 3) {
                // wstETH based protocol
                ref_.targets[ref_.spellIndex] = "COMPOUND-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount converted to wstETH.
                    0,
                    0
                );
            } else if (fromProtocolId_ == 4) {
                // wstETH based protocol
                ref_.targets[ref_.spellIndex] = "EULER-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,address,uint256,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount converted to wstETH.
                    0,
                    0
                );
            } else if (fromProtocolId_ == 5) {
                // stETH based protocol
                ref_.targets[ref_.spellIndex] = "MORPHO-AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    fromWithdrawAmount_, // stETH amount
                    0,
                    0
                );
            }
            ref_.spellIndex++;

            if (ref_.isFromStETHBasedProtocol && !ref_.isToStETHBasedProtocol) {
                // from: stETH based protocols
                // to: wstETH based protocols

                ref_.targets[ref_.spellIndex] = "WSTETH-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    type(uint256).max, // Converting all the withdrawn amount
                    0,
                    0
                );

                ref_.spellIndex++;
            } else if (
                !ref_.isFromStETHBasedProtocol && ref_.isToStETHBasedProtocol
            ) {
                // from: wstETH based protocols
                // to: stETH based protocols

                ref_.targets[ref_.spellIndex] = "WSTETH-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,uint256,uint256)",
                    type(uint256).max, // Converting all the withdrawn amount
                    0,
                    0
                );

                ref_.spellIndex++;
            }

            if (toProtocolId_ == 1) {
                // to: stETH based protocol

                ref_.targets[ref_.spellIndex] = "AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    type(uint256).max, // Depositing all stETH
                    0,
                    0
                );
            } else if (toProtocolId_ == 2) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "AAVE-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    type(uint256).max, // Depositing all wstETH
                    0,
                    0
                );
            } else if (toProtocolId_ == 3) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "COMPOUND-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    type(uint256).max, // Depositing all wstETH
                    0,
                    0
                );
            } else if (toProtocolId_ == 4) {
                // to: wstETH based protocol
                ref_.targets[ref_.spellIndex] = "EULER-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,address,uint256,bool,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    type(uint256).max, // Depositing all wstETH
                    true,
                    0,
                    0
                );
            } else if (toProtocolId_ == 5) {
                // to: stETH based protocol

                ref_.targets[ref_.spellIndex] = "MORPHO-AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    type(uint256).max, // Depositing all stETH
                    0,
                    0
                );
            }

            ref_.spellIndex++;
        }

        /***************************************|
        |   WITHDRAW WSTETH AND FLASH PAYBACK   |
        |______________________________________*/

        if (wstETHflashAmount_ > 0) {
            if (toProtocolId_ == 1) {
                // stETH based protocol

                ref_.targets[ref_.spellIndex] = "AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    (flashDepositAmount_ + 10), // flash amount in stETH + 10 wei buffer for proper payback.
                    0,
                    ref_.withdrawIdToPaybackFlashloan
                );
                ref_.spellIndex++;

                ref_.targets[ref_.spellIndex] = "WSTETH-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    0,
                    ref_.withdrawIdToPaybackFlashloan, // stETH flashloan deposited + 10 wei
                    0
                );
            } else if (toProtocolId_ == 2) {
                // wstETH based protocol

                ref_.targets[ref_.spellIndex] = "AAVE-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    WSTETH_ADDRESS,
                    flashDepositAmount_, // flash amount in wstETH
                    0,
                    0
                );
            } else if (toProtocolId_ == 3) {
                // wstETH based protocol

                ref_.targets[ref_.spellIndex] = "COMPOUND-V3-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    COMP_ETH_MARKET_ADDRESS,
                    WSTETH_ADDRESS,
                    flashDepositAmount_, // flash amount in wstETH
                    0,
                    0
                );
            } else if (toProtocolId_ == 4) {
                // wstETH based protocol

                ref_.targets[ref_.spellIndex] = "EULER-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(uint256,address,uint256,uint256,uint256)",
                    0,
                    WSTETH_ADDRESS,
                    flashDepositAmount_, // flash amount in wstETH
                    0,
                    0
                );
            } else if (toProtocolId_ == 5) {
                // stETH based protocol

                ref_.targets[ref_.spellIndex] = "MORPHO-AAVE-V2-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "withdraw(address,address,uint256,uint256,uint256)",
                    STETH_ADDRESS,
                    A_STETH_ADDRESS,
                    (flashDepositAmount_ + 10), // flash amount in stETH + 10 wei buffer for proper payback.
                    0,
                    ref_.withdrawIdToPaybackFlashloan
                );

                ref_.spellIndex++;

                ref_.targets[ref_.spellIndex] = "WSTETH-A";
                ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                    "deposit(uint256,uint256,uint256)",
                    0,
                    ref_.withdrawIdToPaybackFlashloan, // stETH flashloan deposited + 10 wei
                    0
                );
            }
            ref_.spellIndex++;

            ref_.targets[ref_.spellIndex] = "INSTAPOOL-C";
            ref_.calldatas[ref_.spellIndex] = abi.encodeWithSignature(
                "flashPayback(address,uint256,uint256,uint256)",
                WSTETH_ADDRESS,
                wstETHflashAmount_,
                0,
                0
            );
            ref_.spellIndex++;

            /*********************************|
            |    CAST SPELLS WITH FLASHLOAN   |
            |________________________________*/
            bytes memory encodedFlashData_ = abi.encode(
                ref_.targets,
                ref_.calldatas
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
            /******************|
            |    CAST SPELLS   |
            |_________________*/

            vaultDSA.cast(ref_.targets, ref_.calldatas, address(this));
        }

        uint256 fromRatio_ = getProtocolRatio(fromProtocolId_);
        uint256 toRatio_ = getProtocolRatio(toProtocolId_);

        if (
            fromRatio_ < maxRiskRatio[fromProtocolId_] &&
            toRatio_ < maxRiskRatio[toProtocolId_]
        ) {
            emit LogRefinance(
                fromProtocolId_,
                toProtocolId_,
                route_,
                wstETHflashAmount_,
                wETHBorrowAmount_,
                withdrawAmount_
            );

            return (fromRatio_, toRatio_);
        } else {
            revert RefinanceModule__Unsafe();
        }
    }
}