// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ITokeRewards.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITAssetStruct {
    struct TAssetGlobalView {
        ERC20View stakingAsset;
        address stakingAddress;
        uint256 cvgCycle;
        uint256 tokeCycle;
        uint256 previousCvgCycleTotal;
        uint256 previousTokeCycleTotal;
        uint256 actualStakedCvgCycleTotal;
        uint256 actualStakedTokeCycleTotal;
        uint256 nextStakedCvgCycleTotal;
        uint256 nextStakedTokeCycleTotal;
    }

    struct TAssetTokenView {
        uint256 previousCvgCycleToken;
        uint256 previousTokeCycleToken;
        uint256 actualStakedCvgCycleToken;
        uint256 actualStakedTokeCycleToken;
        uint256 nextStakedCvgCycleToken;
        uint256 nextStakedTokeCycleToken;
    }
    struct ERC20View {
        string token;
        address tokenAddress;
        uint256 decimals;
    }
}