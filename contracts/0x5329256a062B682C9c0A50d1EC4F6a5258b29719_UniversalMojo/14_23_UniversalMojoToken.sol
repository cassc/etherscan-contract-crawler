// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './MojosToken.sol';

/// @title Interface of the UniversalONFT standard
contract UniversalMojo is MojosToken {


    /// @notice Constructor for the UniversalNFT

    constructor(
        address _mojosDAO,
        address _minter,
        IMojosDescriptor _descriptor,
        IMojosSeeder _seeder,
        address _lzEndpoint,
        uint256 _startMintId,
        uint256 _endMintId
    ) MojosToken(_mojosDAO, _minter, _descriptor, _seeder, _lzEndpoint, _startMintId, _endMintId) {
      
    }
}