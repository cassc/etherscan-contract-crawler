// SPDX-License-Identifier: MIT
// Creator: Nullion Labs

pragma solidity 0.8.11;

import './ERC721A.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

abstract contract ERC721APausable is ERC721A, Pausable {
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        require(!paused(), 'ERC721Pausable: token transfer while paused');
    }
}