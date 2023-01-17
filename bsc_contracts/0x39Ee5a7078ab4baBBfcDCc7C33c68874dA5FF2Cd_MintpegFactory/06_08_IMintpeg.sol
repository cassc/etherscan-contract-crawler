//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title IMintpeg
/// @author Trader Joe
/// @notice Defines the interface of Mintpeg
interface IMintpeg {
    function initialize(
        string memory _collectionName,
        string memory _collectionSymbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint96 _feePercent
    ) external;
}