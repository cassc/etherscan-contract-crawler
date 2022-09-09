// SPDX-License-Identifier: USDTIFY.com
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Pausable.sol";
abstract contract ERC721Pausable is ERC721, Pausable {
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}