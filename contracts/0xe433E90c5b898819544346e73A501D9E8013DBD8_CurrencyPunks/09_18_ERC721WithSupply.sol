// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721WithSupply is ERC721 {
    uint256 internal _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /*
     * Hook that's called before minting, burning and transferring.
     * Updates _totalSupply when token is minted or burned.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _totalSupply++;
        }
        if (to == address(0)) {
            _totalSupply--;
        }
    }
}