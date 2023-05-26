/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721{
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}

contract MultiTransferHelper {
    function multiTransferFrom(address address_, address[] calldata to_, uint256[] calldata tokenIds_) external {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            IERC721(address_).transferFrom(msg.sender, to_[i], tokenIds_[i]);
        } while (++i < l); }
    }
}