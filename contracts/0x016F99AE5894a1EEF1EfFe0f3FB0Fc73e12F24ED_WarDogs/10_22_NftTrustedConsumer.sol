// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract NftTrustedConsumer is ERC721 {
    // Enable future consumption of the contract (without approvals)
    mapping(address=>bool) public _trustedConsumers;

    function _addTrustedConsumer(address trustedConsumer) internal virtual {
        require(trustedConsumer != address(0x0), "trustedConsumer Need a valid address");
        _trustedConsumers[trustedConsumer] = true;
    }

    function _removeTrustedConsumer(address trustedConsumer) internal virtual {
        require(_trustedConsumers[trustedConsumer], "Consumer is not trusted");
        delete _trustedConsumers[trustedConsumer];
    }

    // auto approve the trusted contract interactions otherwise standard approvals.
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return (_trustedConsumers[_msgSender()] ||
            super._isApprovedOrOwner(spender, tokenId));
    }
}