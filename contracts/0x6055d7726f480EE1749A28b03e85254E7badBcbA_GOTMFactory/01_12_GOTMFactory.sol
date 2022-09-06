// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity 0.8.15;

import "./token/ERC721OptimizedFactory.sol";

contract GOTMFactory is ERC721OptimizedFactory {
    constructor(string memory baseURI_, OptionConfig memory optionConfig_, address payable erc721OptimizedAddress_, address proxyRegistryAddress_) ERC721OptimizedFactory(
        "GOATs of the Metaverse Factory",
        "GOTMF",
        baseURI_,
        optionConfig_,
        erc721OptimizedAddress_,
        proxyRegistryAddress_
    ) {}
}