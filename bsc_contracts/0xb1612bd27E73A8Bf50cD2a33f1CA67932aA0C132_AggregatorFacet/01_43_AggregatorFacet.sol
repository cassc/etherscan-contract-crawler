// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {LibDiamond} from "../../diamond/LibDiamond.sol";
import {AppStorage} from "../../libraries/LibMagpieAggregator.sol";
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
        LibAggregator.enforceDeadline(swapArgs.deadline);
        LibAggregator.enforceIsNotPaused();
        LibAggregator.enforcePreGuard();
        amountOut = LibAggregator.swap(swapArgs);
        LibAggregator.enforcePostGuard();
    }

    function swapIn(SwapInArgs calldata swapInArgs) external payable override returns (uint256 amountOut) {
        LibAggregator.enforceDeadline(swapInArgs.swapArgs.deadline);
        LibAggregator.enforceIsNotPaused();
        LibAggregator.enforcePreGuard();
        amountOut = LibAggregator.swapIn(swapInArgs);
        LibAggregator.enforcePostGuard();
    }

    function swapOut(SwapOutArgs calldata swapOutArgs) external override returns (uint256 amountOut) {
        LibAggregator.enforceDeadline(swapOutArgs.swapArgs.deadline);
        LibAggregator.enforceIsNotPaused();
        LibAggregator.enforcePreGuard();
        amountOut = LibAggregator.swapOut(swapOutArgs);
        LibAggregator.enforcePostGuard();
    }

    function withdraw(address assetAddress) external override {
        LibAggregator.enforceIsNotPaused();
        LibAggregator.withdraw(assetAddress);
    }

    function simulateSwap(SwapArgs calldata swapArgs) external override returns (uint256 amountOut) {
        LibAggregator.enforceDeadline(swapArgs.deadline);
        LibAggregator.enforceIsNotPaused();
        LibAggregator.enforcePreGuard();
        amountOut = LibAggregator.simulateSwap(swapArgs);
        LibAggregator.enforcePostGuard();
    }

    function simulateTransfer(
        SwapArgs calldata swapArgs,
        bool shouldTransfer,
        bool useTransferFrom
    ) external override returns (uint256 amountOut) {
        LibAggregator.enforceDeadline(swapArgs.deadline);
        LibAggregator.enforceIsNotPaused();
        LibAggregator.enforcePreGuard();
        amountOut = LibAggregator.simulateTransfer(swapArgs, shouldTransfer, useTransferFrom);
        LibAggregator.enforcePostGuard();
    }

    function pause() external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.pause();
    }

    function unpause() external override {
        LibDiamond.enforceIsContractOwner();
        LibAggregator.unpause();
    }
}