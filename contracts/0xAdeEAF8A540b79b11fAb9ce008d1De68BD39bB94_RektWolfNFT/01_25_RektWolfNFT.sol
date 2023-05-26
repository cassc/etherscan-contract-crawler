// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./tokens/extension/UniversalONFT721.sol";

contract RektWolfNFT is UniversalONFT721 {
    constructor(
        string memory _baseURI,
        address _layerZeroEndpoint,
        uint256 _startMintId,
        uint256 _endMintId
    )
        UniversalONFT721(
            "Rekt Wolf",
            "Rekt",
            _baseURI,
            _layerZeroEndpoint,
            _startMintId,
            _endMintId
        )
    {}
}