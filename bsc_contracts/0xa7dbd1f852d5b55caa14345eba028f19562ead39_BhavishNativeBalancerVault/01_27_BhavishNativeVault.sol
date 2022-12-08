// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import {
    BaseVault,
    IBhavishAdministrator,
    IBhavishPrediction,
    IBhavishSDKImpl,
    IVaultProtector
} from "./BaseVault.sol";
import { IBhavishPredictionNative, IBhavishNativeSDK, IBhavishSDK } from "../Interface/IBhavishNativeSDK.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Bhavish Native Vault
 * This works on native currency only
 */
contract BhavishNativeBalancerVault is AccessControl, BaseVault {
    IBhavishNativeSDK public bhavishSDK;

    constructor(
        IBhavishAdministrator _bhavishAdmin, // Bhavish Admin Address
        IBhavishNativeSDK _bhavishSDK, // Bhavish SDK Address
        bytes32 _underlying,
        bytes32 _strike,
        string memory _supportedCurrency,
        IVaultProtector _protector
    ) BaseVault(_bhavishAdmin, _supportedCurrency, _underlying, _strike, _protector) {
        bhavishSDK = _bhavishSDK;
    }

    function totalAssets() public view override returns (uint256) {
        return address(this).balance;
    }

    function getPredictionMarketAddr() internal override returns (address) {
        return IBhavishSDKImpl(address(bhavishSDK)).predictionMap(assetPair.underlying, assetPair.strike);
    }

    function _performPrediction(
        uint256 _roundId,
        bool _nextPredictionUp,
        uint256 _predictAmount
    ) internal override {
        bhavishSDK.predict{ value: _predictAmount/2 }(
            IBhavishSDK.PredictionStruct(assetPair.underlying, assetPair.strike, _roundId, _nextPredictionUp),
            address(this),
            address(this)
        );

        bhavishSDK.predict{ value: _predictAmount/2 }(
            IBhavishSDK.PredictionStruct(assetPair.underlying, assetPair.strike, _roundId, !_nextPredictionUp),
            address(this),
            address(this)
        );
    }

    function performClaim(uint256[] memory _roundIds) external override {
        uint256 totalBetAmount = 0;
        uint256 beforeBalance = address(this).balance;

        for (uint256 i = 0; i < _roundIds.length; i++) {
            if (!claimRefundMap[_roundIds[i]] && (!isClaimable(_roundIds[i]) || isClaimPending(_roundIds[i]))) {
                totalBetAmount += getRoundBetAmount(_roundIds[i]);
                claimRefundMap[_roundIds[i]] = true;
            }
        }

        IBhavishPredictionNative.SwapParams memory swapParams;

        bhavishSDK.claim(
            IBhavishSDK.PredictionStruct(assetPair.underlying, assetPair.strike, 0, false),
            _roundIds,
            swapParams
        );

        uint256 claimedAmount = address(this).balance - beforeBalance;
        // win or loss
        vaultDeposit.totalDeposit = vaultDeposit.totalDeposit + claimedAmount - totalBetAmount;
    }

    function performRefund(uint256[] memory _roundIds) external override {
        uint256 totalBetAmount = 0;
        uint256 beforeBalance = address(this).balance;

        for (uint256 i = 0; i < _roundIds.length; i++) {
            if (!claimRefundMap[_roundIds[i]] && (!isClaimable(_roundIds[i]) || isClaimPending(_roundIds[i]))) {
                totalBetAmount += getRoundBetAmount(_roundIds[i]);
                bhavishSDK.refundUsers(
                    IBhavishSDK.PredictionStruct(assetPair.underlying, assetPair.strike, 0, false),
                    _roundIds[i]
                );
                claimRefundMap[_roundIds[i]] = true;
            }
        }

        uint256 totalRefundAmount = address(this).balance - beforeBalance;
        vaultDeposit.totalDeposit = vaultDeposit.totalDeposit + totalRefundAmount - totalBetAmount;
    }

    function _safeTransfer(address _to, uint256 _value) internal override {
        (bool success, ) = _to.call{ value: _value }("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    function deposit(address _user, address _provider) external payable whenNotPaused nonReentrant {
        _depositToVault(_user, msg.value, _provider);
    }

    function withdraw(address _user, uint256 _shares) external nonReentrant {
        uint256 assetAmount = _withdrawFromVault(_user, _shares);
        _safeTransfer(_user, assetAmount);
        vaultDeposit.userDeposits[_user] = convertToAssets(vaultDeposit.userShares[_user]);
    }
}