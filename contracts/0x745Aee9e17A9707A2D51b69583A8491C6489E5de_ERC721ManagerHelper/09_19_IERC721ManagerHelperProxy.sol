// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC721ManagerHelperProxy {
    function setSporkProxy(address payable _sporkProxy) external;

    function safeTransferERC20From(address token, address from, address to, uint256 value) external;

    function emitMintFee(
        address collectionProxy,
        address minter,
        uint256 quantity,
        address mintFeeRecipient,
        address mintFeeAsset,
        uint256 mintFee
    ) external;
}