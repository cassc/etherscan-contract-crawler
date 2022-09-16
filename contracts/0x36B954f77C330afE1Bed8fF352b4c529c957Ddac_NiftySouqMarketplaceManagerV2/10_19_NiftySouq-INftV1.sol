// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface NiftySouqINftV1 {
    struct TokenData {
        uint256[] royalties;
        address[] creators;
        uint256 quantity;
        string uri;
        string name;
    }

    function getTokenData(uint256 tokenId)
        external
        view
        returns (TokenData memory);
}