// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface INFTValueProvider {
    function getCreditLimitETH(
        address _owner,
        uint256 _nftIndex
    ) external view returns (uint256);

    function getLiquidationLimitETH(
        address _owner,
        uint256 _nftIndex
    ) external view returns (uint256);

    function getNFTValueETH(uint256 _nftIndex) external view returns (uint256);
}