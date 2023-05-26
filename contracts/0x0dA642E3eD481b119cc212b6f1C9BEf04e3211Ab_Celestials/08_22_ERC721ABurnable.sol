// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../ERC721A.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ERC721ABurnable is Context, ERC721A {
    function burn(uint256 tokenId) public virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        _burn(tokenId);
    }
}