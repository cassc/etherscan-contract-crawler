// SPDX-License-Identifier: MIT
// Author: Club Cards
// Developed by Max J. Rux

pragma solidity ^0.8.7;

interface ICCEditions {
    event Claimed(
        address indexed _address,
        uint256 authTxNonce,
        uint256[] ids,
        uint256[] amounts
    );
    event WhitelistMinted(
        address indexed _address,
        uint256 numMints,
        uint256 waveId,
        uint256 authTxNonce
    );
    event ClaimSet(uint256 indexed tokenIndex, uint256 indexed claimId);

    event WaveStartIndexBlockSet(
        uint256 indexed waveId,
        uint256 startIndexBlock
    );
    event WaveStartIndexSet(uint256 indexed waveId, uint256 startIndex);

    function setWaveStartIndex(uint256 waveId) external;

    function getClaim(uint256 claimId)
        external
        view
        returns (
            uint256 CLAIM_INDEX,
            uint256 TOKEN_INDEX,
            bool status,
            uint256 supply,
            string memory uri
        );

    function authTxNonce(address _address) external view returns (uint256);

    function getToken(uint256 id)
        external
        view
        returns (
            bool isClaim,
            uint256 editionId,
            uint256 tokenIdOfEdition
        );

    function totalSupply() external view returns (uint256);

    function getWave(uint256 waveId)
        external
        view
        returns (
            uint256 WAVE_INDEX,
            uint256 MAX_SUPPLY,
            uint256 REVEAL_TIMESTAMP,
            uint256 price,
            uint256 startIndex,
            uint256 startIndexBlock,
            bool status,
            bool whitelistStatus,
            uint256 supply,
            string memory provHash,
            string memory _waveURI
        );
}