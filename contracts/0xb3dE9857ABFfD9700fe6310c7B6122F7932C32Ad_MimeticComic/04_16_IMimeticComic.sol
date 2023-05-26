// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IMimeticComic {
    function loadSeries(
          uint8 _series
        , string memory _description
        , string memory _ipfsHash
        , uint256 _issuanceEnd
    )
        external;

    function lock()
        external;

    function seriesImage(
        uint8 _series
    )
        external
        view
        returns (
            string memory ipfsString
        );

    function seriesMetadata(
          uint8 _series
        , uint256 _tokenId
        , bool redeemed
        , bool exists
        , bool wildcard
        , uint256 votes
    )
        external
        view
        returns (
            string memory metadataString
        );

    function tokenSeries(
        uint256 _tokenId
    )
        external
        view
        returns (
            uint8 series
        );

    function tokenImage(
        uint256 _tokenId
    )
        external
        view
        returns (
            string memory
        );

    function tokenMetadata(
        uint256 _tokenId
    )
        external
        view
        returns (
            string memory
        );

    function focusSeries(
          uint8 _series
        , uint256 _tokenId
    )
        external;
}