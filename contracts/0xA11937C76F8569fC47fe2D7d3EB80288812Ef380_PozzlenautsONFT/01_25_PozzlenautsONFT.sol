// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./tokens/extension/UniversalONFT721.sol";

contract PozzlenautsONFT is UniversalONFT721 {
    constructor(
        string memory _baseURI,
        address _layerZeroEndpoint,
        uint256 _startMintId,
        uint256 _endMintId,
        address _usdcAddress,
        address _treasuryAddress
    )
        UniversalONFT721(
            "Pozzlenauts",
            "PozNFT",
            _baseURI,
            _layerZeroEndpoint,
            _startMintId,
            _endMintId,
            _usdcAddress,
            _treasuryAddress
        )
    {}
}