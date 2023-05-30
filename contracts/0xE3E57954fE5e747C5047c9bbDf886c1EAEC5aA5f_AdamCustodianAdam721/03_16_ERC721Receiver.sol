// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";


abstract contract ERC721Receiver is Context, IERC721Receiver {
    event ReceiveERC721(address indexed contract_, uint256 indexed tokenId, address indexed sender, address from, bytes data);

    function onERC721Received(address sender, address from, uint256 tokenId, bytes memory data) public virtual override returns (bytes4) {
        emit ReceiveERC721(_msgSender(), tokenId, sender, from, data);
        return this.onERC721Received.selector;
    }
}