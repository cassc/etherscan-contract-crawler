// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BWCRouter is IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        bytes memory addr = data;
        require(addr.length == 20, "the data only supports address type");
        address to;
        assembly {
            to := mload(add(addr, 20))
        }
        ERC721(msg.sender).transferFrom(address(this), to, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }
}