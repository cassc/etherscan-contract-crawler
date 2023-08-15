// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IProtoDAOSettingsReadable {
    function getCanvasCreatorERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getNftMinterERC20Ratio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatio(bytes32 daoId) external view returns (uint256);

    function getDaoFeePoolETHRatioFlatPrice(bytes32 daoId) external view returns (uint256);
}