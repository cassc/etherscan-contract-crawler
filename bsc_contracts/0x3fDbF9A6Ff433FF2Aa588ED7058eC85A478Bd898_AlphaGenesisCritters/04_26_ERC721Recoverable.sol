// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Recoverable {
    function _recoverERC721(address tokenAddress, uint256 tokenId, address receiver)
        internal
    {
        IERC721(tokenAddress).transferFrom(
            address(this),
            receiver,
            tokenId
        );
    }
}