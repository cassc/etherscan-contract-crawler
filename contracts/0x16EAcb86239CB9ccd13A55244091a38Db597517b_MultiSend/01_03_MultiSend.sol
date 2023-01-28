// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MultiSend {
    constructor() {}

    function bulkSendERC721(
        IERC721 erc721Contract,
        address[] calldata to,
        uint256[] calldata tokenId
    ) public {
        uint256 length = to.length;
        for (uint256 i; i < length; ) {
            erc721Contract.transferFrom(msg.sender, to[i], tokenId[i]);
            unchecked {
                ++i;
            }
        }
    }
}