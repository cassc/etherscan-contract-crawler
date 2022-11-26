/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITokenUriHelperFeature {

    struct TokenUriParam {
        // 32bits(methodId) + 64bits(unused) + 160bits(tokenAddress)
        uint256 methodIdAndAddress;
        uint256 tokenId;
    }
    function tokenURIs(TokenUriParam[] calldata params) external view returns(string[] memory uris);
}