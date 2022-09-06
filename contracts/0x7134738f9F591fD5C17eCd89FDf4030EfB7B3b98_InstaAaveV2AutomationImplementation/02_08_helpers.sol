// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./events.sol";

contract Helpers is Events {
    constructor(address aavePoolAddressesProvider_, address instaList_)
        Variables(aavePoolAddressesProvider_, instaList_)
    {}

    function _buildSpell(ExecutionParams memory params_)
        internal
        view
        returns (Spell memory spells)
    {
        bool isSameToken_ = params_.collateralToken == params_.debtToken;
        uint256 id_ = 7128943279;
        uint256 index_;

        /**
            The packing of route will be like as follows:
                - param.route = (flashloanFeeInBps_ << 9) | route_
            The unpacking will be as follows: 
                - route_ = params_.route % (2**8);
                - flashloanFeeInBps_ = params_.route >> 9
         */
        uint256 route_ = params_.route % (2**8);
        uint256 flashloanFeeInBps_ = params_.route >> 9;
        uint256 loanAmtWithFee_ = params_.collateralAmount +
            ((params_.collateralAmount * flashloanFeeInBps_) / 1e4);
        uint256 totalFee_ = params_.collateralAmountWithTotalFee -
            loanAmtWithFee_;

        if (route_ > 0) {
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
                    flashloanSpell_._targets[index_],
                    flashloanSpell_._datas[index_++]
                ) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        params_.swap.buyToken, // debt token
                        params_.swap.sellToken, // collateral token
                        params_.swap.sellAmt, // amount of collateral withdrawn to swap
                        params_.swap.unitAmt,
                        params_.swap.callData,
                        id_
                    )
                );
            } else id_ = 0;

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    params_.debtToken, // debt
                    params_.debtAmount,
                    params_.rateMode,
                    id_,
                    0
                )
            );

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    params_.collateralToken, // withdraw the collateral now
                    params_.collateralAmountWithTotalFee, // the amount of collateral token to withdraw
                    0,
                    0
                )
            );

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "INSTAPOOL-C",
                abi.encodeWithSignature(
                    "flashPayback(address,uint256,uint256,uint256)",
                    params_.collateralToken, // collateral token
                    loanAmtWithFee_,
                    0,
                    0
                )
            );

            (
                flashloanSpell_._targets[index_],
                flashloanSpell_._datas[index_++]
            ) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    params_.collateralToken, // transfer the collateral
                    totalFee_, // the automation fee,
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
                    params_.collateralToken,
                    params_.collateralAmount,
                    route_,
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
            (spells._targets[index_], spells._datas[index_++]) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,uint256,uint256)",
                    params_.collateralToken, // collateral token to withdraw
                    params_.collateralAmountWithTotalFee, // amount to withdraw
                    0,
                    0
                )
            );

            if (!isSameToken_) {
                (spells._targets[index_], spells._datas[index_++]) = (
                    "1INCH-A",
                    abi.encodeWithSignature(
                        "sell(address,address,uint256,uint256,bytes,uint256)",
                        params_.swap.buyToken, // debt token
                        params_.swap.sellToken, // collateral that we withdrawn
                        params_.swap.sellAmt, // amount of collateral withdrawn to swap
                        params_.swap.unitAmt,
                        params_.swap.callData,
                        id_
                    )
                );
            } else id_ = 0;

            (spells._targets[index_], spells._datas[index_++]) = (
                "AAVE-V2-A",
                abi.encodeWithSignature(
                    "payback(address,uint256,uint256,uint256,uint256)",
                    params_.debtToken,
                    params_.debtAmount,
                    params_.rateMode,
                    id_,
                    0
                )
            );

            (spells._targets[index_], spells._datas[index_++]) = (
                "BASIC-A",
                abi.encodeWithSignature(
                    "withdraw(address,uint256,address,uint256,uint256)",
                    params_.collateralToken, // transfer the collateral
                    totalFee_, // the automation fee,
                    address(this),
                    0,
                    0
                )
            );
        }
    }

    function cast(AccountInterface dsa_, Spell memory spells_)
        internal
        returns (bool success_)
    {
        (success_, ) = address(dsa_).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                spells_._targets,
                spells_._datas,
                address(this)
            )
        );
    }


    function getHealthFactor(address user_)
        public
        view
        returns (uint256 healthFactor_)
    {
        (, , , , , healthFactor_) = aave.getUserAccountData(user_);
    }
}