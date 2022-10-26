// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakeWCF is Ownable, IERC721Receiver, ReentrancyGuard {
    IERC721 public immutable wcf;
    constructor(address wcf_) {
        wcf = IERC721(wcf_);
    }

    event StakeWCFEvent(address indexed owner, uint256[] tokenIds);

    function stake(uint[] calldata tokenIds)
        public
        nonReentrant
    {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                wcf.ownerOf(tokenId) == msg.sender,
                "StakeWCF: Not owner of token"
            );
            wcf.safeTransferFrom(msg.sender, address(this), tokenId);
        }

        emit StakeWCFEvent(msg.sender,tokenIds);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}