// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721BulkTransfer {
    function bulkTransfer(IERC721 token,address[] calldata recipients,uint256[] calldata ids) external{
        require(recipients.length == ids.length);
        for(uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], ids[i]);
        }
    }
}