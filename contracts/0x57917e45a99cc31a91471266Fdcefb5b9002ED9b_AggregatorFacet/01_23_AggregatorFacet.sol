// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {DataTransferType} from "../../data-transfer/LibCommon.sol";
import {LibGuard} from "../../libraries/LibGuard.sol";
import {AppStorage} from "../../libraries/LibMagpieAggregator.sol";
import {LibPauser} from "../../pauser/LibPauser.sol";
import {LibRouter} from "../../router/LibRouter.sol";
import {IAggregator} from "../interfaces/IAggregator.sol";
import {LibAggregator, SwapArgs, SwapInArgs, SwapOutArgs} from "../LibAggregator.sol";

contract AggregatorFacet is IAggregator {
    AppStorage internal s;

    function updateWeth(address weth) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.updateWeth(weth);
    }

    function updateNetworkId(uint16 networkId) external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.updateNetworkId(networkId);
    }

    function addMagpieAggregatorAddresses(uint16[] calldata networkIds, bytes32[] calldata magpieAggregatorAddresses)
        external
        override
    {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.addMagpieAggregatorAddresses(networkIds, magpieAggregatorAddresses);
    }

    function swap(SwapArgs calldata swapArgs) external payable override returns (uint256 amountOut) {
        LibRouter.enforceDeadline(swapArgs.deadline);
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swap(swapArgs);
        LibGuard.enforcePostGuard();
    }

    function swapIn(SwapInArgs calldata swapInArgs) external payable override returns (uint256 amountOut) {
        LibRouter.enforceDeadline(swapInArgs.swapArgs.deadline);
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swapIn(swapInArgs);
        LibGuard.enforcePostGuard();
    }

    function swapOut(SwapOutArgs calldata swapOutArgs) external override returns (uint256 amountOut) {
        LibRouter.enforceDeadline(swapOutArgs.swapArgs.deadline);
        LibPauser.enforceIsNotPaused();
        LibGuard.enforcePreGuard();
        amountOut = LibAggregator.swapOut(swapOutArgs);
        LibGuard.enforcePostGuard();
    }

    function withdraw(address assetAddress) external override {
        LibPauser.enforceIsNotPaused();
        LibAggregator.withdraw(assetAddress);
    }

    function getDeposit(address assetAddress) external view override returns (uint256) {
        return LibAggregator.getDeposit(assetAddress);
    }

    function getPayload(
        DataTransferType dataTransferType,
        uint16 senderNetworkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view returns (bytes memory) {
        return LibAggregator.getPayload(dataTransferType, senderNetworkId, senderAddress, swapSequence);
    }

    function getDepositByUser(address assetAddress, address senderAddress) external view override returns (uint256) {
        return LibAggregator.getDepositByUser(assetAddress, senderAddress);
    }

    function isTransferKeyUsed(
        uint16 networkId,
        bytes32 senderAddress,
        uint64 swapSequence
    ) external view override returns (bool) {
        return LibAggregator.isTransferKeyUsed(networkId, senderAddress, swapSequence);
    }
}