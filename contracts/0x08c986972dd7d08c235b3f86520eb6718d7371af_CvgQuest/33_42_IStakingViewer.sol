// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ITAssetStruct.sol";

interface IStakingViewer {
    function getGlobalViewTokeStaking(
        address stakingContract
    ) external pure returns (ITAssetStruct.TAssetGlobalView memory);
}