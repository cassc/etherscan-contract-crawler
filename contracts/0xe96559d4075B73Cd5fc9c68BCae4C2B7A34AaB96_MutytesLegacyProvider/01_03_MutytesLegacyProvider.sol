// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMutytesLegacyProvider } from "./IMutytesLegacyProvider.sol";
import { IERC721TokenURIProvider } from "../../core/token/ERC721/tokenURI/IERC721TokenURIProvider.sol";

/**
 * @title Mutytes legacy token URI provider implementation
 */
contract MutytesLegacyProvider is IERC721TokenURIProvider {
    address _interpreterAddress;
    string _externalURL;

    constructor(address interpreterAddress, string memory externalURL) {
        _interpreterAddress = interpreterAddress;
        _externalURL = externalURL;
    }

    /**
     * @inheritdoc IERC721TokenURIProvider
     */
    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        IMutytesLegacyProvider interpreter = IMutytesLegacyProvider(_interpreterAddress);
        IMutytesLegacyProvider.TokenData memory token;
        token.id = tokenId;
        token.dna = new uint256[](1);
        token.dna[0] = uint256(keccak256(abi.encode(tokenId)));
        token
            .info = "The Mutytes are a collection of severely mutated creatures that invaded Ethernia. Completely decentralized, every Mutyte is generated, stored and rendered 100% on-chain. Once acquired, a Mutyte grants its owner access to the lab and its facilities.";
        IMutytesLegacyProvider.MutationData memory mutation;
        mutation.count = 1;
        return interpreter.tokenURI(token, mutation, _externalURL);
    }
}