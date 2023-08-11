// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract CedenClaimer {
    using BitMaps for BitMaps.BitMap;

    event Claimed(uint256 indexed tokenId);

    IERC721 private immutable _NFT;
    uint256 private immutable _MAX_TOKEN_ID;
    BitMaps.BitMap private _claimed;

    constructor(address nftAddress, uint256 maxTokenId) {
        _NFT = IERC721(nftAddress);
        _MAX_TOKEN_ID = maxTokenId;
    }

    function isClaimed(uint256 tokenId) external view returns (bool) {
        require(tokenId <= _MAX_TOKEN_ID, "CedenClaimer: Invalid token ID");
        return _claimed.get(tokenId);
    }

    function _canClaim(uint256 _tokenId) internal view returns (bool) {
        return _NFT.ownerOf(_tokenId) == msg.sender && !_claimed.get(_tokenId);
    }

    function _setClaimed(uint256 tokenId) internal {
        _claimed.set(tokenId);
        emit Claimed(tokenId);
    }
}