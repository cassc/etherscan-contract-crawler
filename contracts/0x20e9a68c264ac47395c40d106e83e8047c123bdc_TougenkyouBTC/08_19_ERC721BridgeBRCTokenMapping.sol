// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {ERC721BridgeBRC} from "./ERC721BridgeBRC.sol";

contract ERC721BridgeBRCTokenMapping is ERC721BridgeBRC {
    mapping(uint256 => uint256) private originalNFTTokenId;
    uint256 public registCount = _startId();

    function _startId() internal pure virtual returns (uint256) {
        return 0;
    }

    function _updateMapping(
        uint256 tokenId,
        uint256 _originalTokenId
    ) internal virtual {
        originalNFTTokenId[tokenId] = _originalTokenId;
    }

    function originalTokenId(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        return originalNFTTokenId[tokenId];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        registCount++;
        originalNFTTokenId[registCount] = tokenId;
        return super.onERC721Received(operator, from, tokenId, data);
    }
}