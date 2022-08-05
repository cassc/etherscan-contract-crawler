// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface MonfterPass {
    function safeMint(address, uint256) external;
    function safeBurn(uint256) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

contract Wrapper is IERC721Receiver, ReentrancyGuard {
    IERC721 mToken;
    MonfterPass pToken;

    constructor(IERC721 _mToken, MonfterPass _pToken) {
        mToken = _mToken;
        pToken = _pToken;
    }

    function wrap(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            mToken.safeTransferFrom(msg.sender, address(this), tokenId);
            pToken.safeMint(msg.sender, tokenId);
        }
    }

    function unwrap(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(pToken.ownerOf(tokenId) == msg.sender, "invalid ownership");
            mToken.safeTransferFrom(address(this), msg.sender, tokenId);
            pToken.safeBurn(tokenId);
        }
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}