// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NounForwarder is IERC721Receiver {
    address public immutable to;

    constructor(address _to) {
        to = _to;
    }

    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        IERC721(msg.sender).transferFrom(address(this), to, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }
}