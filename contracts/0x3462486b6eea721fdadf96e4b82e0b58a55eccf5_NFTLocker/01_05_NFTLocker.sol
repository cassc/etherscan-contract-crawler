// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTLocker is IERC721Receiver, ReentrancyGuard {

    struct LockedNFT {
        address tokenAddress;
        uint256 tokenId;
        uint256 unlockTime;
    }

    event NFTLocked(address indexed owner, address indexed tokenAddress, uint256 tokenId, uint256 unlockTime);
    event NFTUnlocked(address indexed owner, address indexed tokenAddress, uint256 tokenId);

    mapping (address => LockedNFT[]) private _lockedNFTs;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function lockNFT(address tokenAddress, uint256 tokenId, uint256 unlockTime) external nonReentrant {
        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(unlockTime > block.timestamp, "Unlock time must be in the future");
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        _lockedNFTs[msg.sender].push(LockedNFT(tokenAddress, tokenId, unlockTime));

        emit NFTLocked(msg.sender, tokenAddress, tokenId, unlockTime);
    }

    function unlockNFT(uint256 index) external nonReentrant {
        require(index < _lockedNFTs[msg.sender].length, "Invalid index");
        LockedNFT storage lockedNFT = _lockedNFTs[msg.sender][index];
        require(block.timestamp >= lockedNFT.unlockTime, "NFT still locked");

        IERC721 token = IERC721(lockedNFT.tokenAddress);
        token.safeTransferFrom(address(this), msg.sender, lockedNFT.tokenId);

        emit NFTUnlocked(msg.sender, lockedNFT.tokenAddress, lockedNFT.tokenId);

        _removeLockedNFT(msg.sender, index);
    }

    function getLockedNFTs(address owner) external view returns (LockedNFT[] memory) {
        return _lockedNFTs[owner];
    }

    function _removeLockedNFT(address owner, uint256 index) private {
        uint256 lastIndex = _lockedNFTs[owner].length - 1;
        if (index != lastIndex) {
            _lockedNFTs[owner][index] = _lockedNFTs[owner][lastIndex];
        }
        _lockedNFTs[owner].pop();
    }
}