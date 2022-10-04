// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../interface/IERC165.sol";
import "../auth/Owner.sol";
import "../token/metadata/ERC721Metadata.sol";

abstract contract ERC721Supports is IERC165, Owner, ERC721Metadata {
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}