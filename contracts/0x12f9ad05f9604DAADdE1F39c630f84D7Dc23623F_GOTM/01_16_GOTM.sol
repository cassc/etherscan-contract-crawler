// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "./token/ERC721Optimized.sol";

contract GOTM is ERC721Optimized {
    constructor(string memory baseURI_, MintConfig memory privateMintConfig_, MintConfig memory publicMintConfig_, address erc721FactoryAddress_, address proxyRegistryAddress_) ERC721Optimized(
        "GOATs of the Metaverse",
        "GOTM",
        baseURI_,
        privateMintConfig_,
        publicMintConfig_,
        erc721FactoryAddress_,
        proxyRegistryAddress_
    ) {}
}