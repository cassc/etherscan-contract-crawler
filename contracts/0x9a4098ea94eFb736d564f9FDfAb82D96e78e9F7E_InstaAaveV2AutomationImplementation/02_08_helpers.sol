// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./events.sol";

contract Helpers is Events {
    constructor(address aavePoolAddressesProvider_, address instaList_)
        Variables(aavePoolAddressesProvider_, instaList_)
    {}

    function _buildSpell(ExecutionParams memory params)
        internal
        view
        returns (Spell memory spells)
    {
        bool isSameToken_ = params.collateralToken == params.debtToken;
        uint256 id_ = 7128943279;
        uint256 index;

        uint256 automationFee_ = (params.collateralAmount * _automationFee) /
            1e4;

        if (params.route > 0) {
            /**
             * if we are taking the flashloan, then this case
             * This case if the user is doesn't have enough collateral to payback the debt
             * will be used most of the time
             * flashBorrowAndCast: Take the flashloan of collateral token
             * swap: swap the collateral token into the debt token
             * payback: payback the debt
             * withdraw: withdraw the collateral
             * flashPayback: payback the flashloan
             */
            Spell memory flashloanSpell_;
            uint256 loanAmtWithFee_ = params.collateralAmountWithTotalFee -
                automationFee_;

            (flashloanSpell_._targets, flashloanSpell_._datas) = (
                new string[](isSameToken_ ? 4 : 5),
                new bytes[](isSameToken_ ? 4 : 5)
            );

            (spells._targets, spells._datas) = (
                new string[](1),
                new bytes[](1)
            );

            if (!isSameToken_) {
                (
                    flashloanSpell_._targets[index],
                    flashloanSpell_._datas[index++]
                ) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        params.swap.buyToken, // debt token
                        params.swap.sellToken, // collateral token
                        params.swap.sellAmt, // amount of collateral withdrawn to swap
                        params.swap.unitAmt,
                        params.swap.callData,
                        id_
                    )
                );
            } else id_ = 0;

            (
                flashloanSpell_._targets[index],
                flashloanSpell_._datas[index++]
            ) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    params.debtToken, // debt
                    params.debtAmount,
                    params.rateMode,
                    id_,
                    0
                )
            );

            (
                flashloanSpell_._targets[index],
                flashloanSpell_._datas[index++]
            ) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    params.collateralToken, // withdraw the collateral now
                    params.collateralAmountWithTotalFee, // the amount of collateral token to withdraw
                    0,
                    0
                )
            );

            (
                flashloanSpell_._targets[index],
                flashloanSpell_._datas[index++]
            ) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    params.collateralToken, // collateral token
                    loanAmtWithFee_,
                    0,
                    0
                )
            );

            (
                flashloanSpell_._targets[index],
                flashloanSpell_._datas[index++]
            ) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    params.collateralToken, // transfer the collateral
                    automationFee_, // the automation fee,
                    address(this),
                    0,
                    0
                )
            );

            bytes memory encodedFlashData_ = abi.encode(
                flashloanSpell_._targets,
                flashloanSpell_._datas
            );

            (spells._targets[0], spells._datas[0]) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashBorrowAndCast(address,uint256,uint256,bytes,bytes)",
                    params.collateralToken,
                    params.collateralAmount,
                    params.route,
                    encodedFlashData_,
                    "0x"
                )
            );
        } else {
            (spells._targets, spells._datas) = (
                new string[](isSameToken_ ? 3 : 4),
                new bytes[](isSameToken_ ? 3 : 4)
            );

            /**
             * This case if the user have enough collateral to payback the debt
             */
            (spells._targets[index], spells._datas[index++]) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    params.collateralToken, // collateral token to withdraw
                    params.collateralAmountWithTotalFee, // amount to withdraw
                    0,
                    0
                )
            );

            if (!isSameToken_) {
                (spells._targets[index], spells._datas[index++]) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        params.swap.buyToken, // debt token
                        params.swap.sellToken, // collateral that we withdrawn
                        params.swap.sellAmt, // amount of collateral withdrawn to swap
                        params.swap.unitAmt,
                        params.swap.callData,
                        id_
                    )
                );
            } else id_ = 0;

            (spells._targets[index], spells._datas[index++]) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    params.debtToken,
                    params.debtAmount,
                    params.rateMode,
                    id_,
                    0
                )
            );

            (spells._targets[index], spells._datas[index++]) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    params.collateralToken, // transfer the collateral
                    automationFee_, // the automation fee,
                    address(this),
                    0,
                    0
                )
            );
        }
    }

    function cast(AccountInterface dsa, Spell memory spells)
        internal
        returns (bool success)
    {
        (success, ) = address(dsa).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                spells._targets,
                spells._datas,
                address(this)
            )
        );
    }

    function getHealthFactor(address user)
        public
        view
        returns (uint256 healthFactor)
    {
        (, , , , , healthFactor) = aave.getUserAccountData(user);
    }
}