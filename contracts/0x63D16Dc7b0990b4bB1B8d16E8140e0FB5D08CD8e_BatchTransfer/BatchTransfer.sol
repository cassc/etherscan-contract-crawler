/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    address private owner;
    constructor(){
        owner = msg.sender;
    }

    function batchTransfer(ERC721Partial tokenContract, address actualOwner,address recipient, uint256[] calldata tokenIds) external {
        require(msg.sender == owner, "Access denied");
        for (uint256 index; index < tokenIds.length; index++) {
            tokenContract.transferFrom(actualOwner, recipient, tokenIds[index]);
        }
    }
}