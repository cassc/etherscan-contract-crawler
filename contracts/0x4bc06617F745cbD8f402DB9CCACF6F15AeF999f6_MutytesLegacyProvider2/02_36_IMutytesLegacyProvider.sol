// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Mutytes legacy token URI provider interface
 */
interface IMutytesLegacyProvider {
    struct TokenData {
        uint256 id;
        string name;
        string info;
        uint256[] dna;
    }

    struct MutationData {
        uint256 id;
        string name;
        string info;
        uint256 count;
    }

    /**
     * @notice Get the URI of a token
     * @param token The token data
     * @param mutation The mutation data
     * @param externalURL External token URL
     * @return tokenURI The token URI
     */
    function tokenURI(
        TokenData calldata token,
        MutationData calldata mutation,
        string calldata externalURL
    ) external view returns (string memory);
}