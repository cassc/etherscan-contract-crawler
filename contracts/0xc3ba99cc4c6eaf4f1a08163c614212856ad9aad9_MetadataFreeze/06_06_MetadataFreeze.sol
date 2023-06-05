// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IMetadataFreeze } from "./IMetadataFreeze.sol";

struct TokenFreeze {
    uint64 frozenAt;
    address frozenBy;
}

contract MetadataFreeze is Ownable, IMetadataFreeze {

    error NotOwnerOfToken();
    error TokenAlreadyFrozen();
    error FreezeNotEnabled();

    event TokenFrozen(uint256 indexed tokenId, address indexed frozenBy);

    IERC721 public subjectToChange;
    mapping(uint256 => TokenFreeze) public tokenFreezeData;
    bool public freezeEnabled;

    constructor(IERC721 thisArtwork) {
        subjectToChange = thisArtwork;
    }

    modifier canFreeze() {
        requireFreezeEnabled();
        _;
    }

    function toggleFreeze() external onlyOwner {
        freezeEnabled = !freezeEnabled;
    }

    function freeze(uint256 tokenId) external canFreeze() {
        freezeCore(tokenId);
    }

    function freeze(uint256[] calldata tokenIds) external canFreeze() {
        uint256 count = tokenIds.length;
        for (uint256 i; i < count;) {
            uint256 tokenId = tokenIds[i];
            freezeCore(tokenId);
            
            unchecked { ++i; }
        }
    }

    function freezeCore(uint256 tokenId) private {
        requireOwnerOfToken(tokenId);
        requireTokenNotFrozen(tokenId);

        tokenFreezeData[tokenId] = TokenFreeze(uint64(block.timestamp), msg.sender);

        emit TokenFrozen(tokenId, msg.sender);
    }

    function isTokenFrozen(uint256 tokenId) external view returns (bool) {   
        return tokenFreezeData[tokenId].frozenAt != 0;
    }

    function getTokenFreezeData(uint256[] memory tokenIds) external view returns (TokenFreeze[] memory) {
        uint256 length = tokenIds.length;
        TokenFreeze[] memory freezeData = new TokenFreeze[](length);

        for (uint256 i; i < length;) {
            freezeData[i] = tokenFreezeData[tokenIds[i]];

            unchecked { ++i; }
        }

        return freezeData;
    }

    function requireTokenNotFrozen(uint256 tokenId) private view {
        if (tokenFreezeData[tokenId].frozenAt != 0) {
            revert TokenAlreadyFrozen();
        }
    }

    function requireFreezeEnabled() private view {
        if (!freezeEnabled) {
            revert FreezeNotEnabled();
        }
    }

    function requireOwnerOfToken(uint256 tokenId) private view {
        if (subjectToChange.ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOfToken();
        }
    }
}