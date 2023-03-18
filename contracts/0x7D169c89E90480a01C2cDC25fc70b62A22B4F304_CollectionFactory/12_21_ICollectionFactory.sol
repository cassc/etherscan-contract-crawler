// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionFactory {
    function deploy(
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        address mintFeeERC20Asset,
        uint256 mintFeeERC20,
        uint256[4] calldata mintFeeETH
    ) external;

    function getCollectionProxyAddress(uint256 _i) external view returns (address);

    function getCollectionManagerProxy() external view returns (address);
}