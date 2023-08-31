// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IOracle} from "splits-oracle/interfaces/IOracle.sol";
import {OracleParams} from "splits-oracle/peripherals/OracleParams.sol";
import {LibClone} from "splits-utils/LibClone.sol";

import {SwapperImpl} from "./SwapperImpl.sol";

/// @title Swapper Factory
/// @author 0xSplits
/// @notice Factory for creating Swappers
/// @dev This contract uses token = address(0) to refer to ETH.
contract SwapperFactory {
    using LibClone for address;

    event CreateSwapper(SwapperImpl indexed swapper, SwapperImpl.InitParams params);

    struct CreateSwapperParams {
        address owner;
        bool paused;
        address beneficiary;
        address tokenToBeneficiary;
        OracleParams oracleParams;
        uint32 defaultScaledOfferFactor;
        SwapperImpl.SetPairScaledOfferFactorParams[] pairScaledOfferFactors;
    }

    SwapperImpl public immutable swapperImpl;

    constructor() {
        swapperImpl = new SwapperImpl();
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    function createSwapper(CreateSwapperParams calldata params_) external returns (SwapperImpl swapper) {
        IOracle oracle = params_.oracleParams._parseIntoOracle();

        swapper = SwapperImpl(payable(address(swapperImpl).clone()));
        SwapperImpl.InitParams memory swapperInitParams = SwapperImpl.InitParams({
            owner: params_.owner,
            paused: params_.paused,
            beneficiary: params_.beneficiary,
            tokenToBeneficiary: params_.tokenToBeneficiary,
            oracle: oracle,
            defaultScaledOfferFactor: params_.defaultScaledOfferFactor,
            pairScaledOfferFactors: params_.pairScaledOfferFactors
        });
        swapper.initializer(swapperInitParams);

        emit CreateSwapper({swapper: swapper, params: swapperInitParams});
    }
}