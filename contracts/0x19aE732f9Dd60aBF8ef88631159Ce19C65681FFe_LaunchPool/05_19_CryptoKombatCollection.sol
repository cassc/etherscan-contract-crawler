// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import './ERC1155Tradable.sol';

contract CryptoKombatCollection is ERC1155Tradable {
    constructor(string memory _baseUri, address _proxyRegistryAddress)
        public
        ERC1155Tradable('Crypto Kombat Collection', 'CKC', _proxyRegistryAddress)
    {
        _setBaseMetadataURI(_baseUri);
    }

    function contractURI() public pure returns (string memory) {
        return 'https://api.cryptokombat.com/contract/cryptokombat-erc1155';
    }
}