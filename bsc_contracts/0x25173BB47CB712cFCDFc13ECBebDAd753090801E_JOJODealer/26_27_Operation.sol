/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "./Types.sol";
import "../utils/Errors.sol";
import "../intf/IPerpetual.sol";
import "../intf/IDecimalERC20.sol";

library Operation {
    // ========== events ==========

    event SetFundingRateKeeper(address oldKeeper, address newKeeper);

    event SetInsurance(address oldInsurance, address newInsurance);

    event SetWithdrawTimeLock(
        uint256 oldWithdrawTimeLock,
        uint256 newWithdrawTimeLock
    );

    event SetOrderSender(address orderSender, bool isValid);

    event SetOperator(
        address indexed client,
        address indexed operator,
        bool isValid
    );

    event SetSecondaryAsset(address secondaryAsset);

    event UpdatePerpRiskParams(address indexed perp, Types.RiskParams param);

    event UpdateFundingRate(
        address indexed perp,
        int256 oldRate,
        int256 newRate
    );

    // ========== functions ==========

    function setPerpRiskParams(
        Types.State storage state,
        address perp,
        Types.RiskParams calldata param
    ) external {
        if (state.perpRiskParams[perp].isRegistered && !param.isRegistered) {
            // remove perp
            for (uint256 i; i < state.registeredPerp.length; i++) {
                if (state.registeredPerp[i] == perp) {
                    state.registeredPerp[i] = state.registeredPerp[
                        state.registeredPerp.length - 1
                    ];
                    state.registeredPerp.pop();
                }
            }
        }
        if (!state.perpRiskParams[perp].isRegistered && param.isRegistered) {
            // new perp
            state.registeredPerp.push(perp);
        }
        require(
            param.liquidationPriceOff + param.insuranceFeeRate <=
                param.liquidationThreshold,
            Errors.INVALID_RISK_PARAM
        );
        state.perpRiskParams[perp] = param;
        emit UpdatePerpRiskParams(perp, param);
    }

    function updateFundingRate(
        address[] calldata perpList,
        int256[] calldata rateList
    ) external {
        require(
            perpList.length == rateList.length,
            Errors.ARRAY_LENGTH_NOT_SAME
        );
        for (uint256 i = 0; i < perpList.length; i++) {
            int256 oldRate = IPerpetual(perpList[i]).getFundingRate();
            IPerpetual(perpList[i]).updateFundingRate(rateList[i]);
            emit UpdateFundingRate(perpList[i], oldRate, rateList[i]);
        }
    }

    function setFundingRateKeeper(Types.State storage state, address newKeeper)
        external
    {
        address oldKeeper = state.fundingRateKeeper;
        state.fundingRateKeeper = newKeeper;
        emit SetFundingRateKeeper(oldKeeper, newKeeper);
    }

    function setInsurance(Types.State storage state, address newInsurance)
        external
    {
        address oldInsurance = state.insurance;
        state.insurance = newInsurance;
        emit SetInsurance(oldInsurance, newInsurance);
    }

    function setWithdrawTimeLock(
        Types.State storage state,
        uint256 newWithdrawTimeLock
    ) external {
        uint256 oldWithdrawTimeLock = state.withdrawTimeLock;
        state.withdrawTimeLock = newWithdrawTimeLock;
        emit SetWithdrawTimeLock(oldWithdrawTimeLock, newWithdrawTimeLock);
    }

    function setOrderSender(
        Types.State storage state,
        address orderSender,
        bool isValid
    ) external {
        state.validOrderSender[orderSender] = isValid;
        emit SetOrderSender(orderSender, isValid);
    }

    function setOperator(
        Types.State storage state,
        address client,
        address operator,
        bool isValid
    ) external {
        state.operatorRegistry[client][operator] = isValid;
        emit SetOperator(client, operator, isValid);
    }

    function setSecondaryAsset(
        Types.State storage state,
        address _secondaryAsset
    ) external {
        require(
            state.secondaryAsset == address(0),
            Errors.SECONDARY_ASSET_ALREADY_EXIST
        );
        require(
            IDecimalERC20(_secondaryAsset).decimals() ==
                IDecimalERC20(state.primaryAsset).decimals(),
            Errors.SECONDARY_ASSET_DECIMAL_WRONG
        );
        state.secondaryAsset = _secondaryAsset;
        emit SetSecondaryAsset(_secondaryAsset);
    }
}