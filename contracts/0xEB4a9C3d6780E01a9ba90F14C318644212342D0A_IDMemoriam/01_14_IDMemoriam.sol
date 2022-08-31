// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

/*
I see you nerd! ⌐⊙_⊙
*/

contract IDMemoriam is ERC2981, ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bool public claimIsActive;
    bool public isLocked;
    string public baseURI;
    string public provenance;

    IERC721 public immutable afterlifeContract;

    uint256 public startTokenId;
    uint256 public packedOffsets;

    // errors
    error ProvenanceLocked();
    error TokenNotEligible();
    error AlreadyClaimed();
    error ClaimNotLive();
    error NotOwner();

    constructor(string memory name, string memory symbol, address afterlifeAddress) ERC721(name, symbol) {
        afterlifeContract = IERC721(afterlifeAddress);
        _setDefaultRoyalty(msg.sender, 500);
    }

    function reserveMint(uint256[] calldata tokenIds, address mintAddress) external onlyOwner {
        _mintMultiple(tokenIds, mintAddress);
    }

    function _mintMultiple(uint256[] calldata tokenIds, address mintAddress) internal {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                _tokenIdCounter.increment();
                _safeMint(mintAddress, tokenIds[i]);
            }
        }
    }

    function flipClaimState() external onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function lockProvenance() external onlyOwner {
        isLocked = true;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setClaimableTokens(uint256 baseStart, uint256 offset) external onlyOwner {
        startTokenId = baseStart;
        packedOffsets = offset;
    }

    function getOffsetFor(uint256 baseStart, uint256[] calldata tokenIds) external pure returns (uint256) {
        uint256 offset;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // We are assuming tokenIds are within a range of 256
            offset = offset | (1 << (tokenIds[i] - baseStart - 1));
        }

        return offset;
    }

    function isClaimableToken(uint256 tokenId) external view returns (bool) {
        if (tokenId <= startTokenId || tokenId > (startTokenId + 256)) {
            return false;
        }

        uint256 mask = (1 << (tokenId - startTokenId - 1));

        return packedOffsets & mask  == mask;
    }

    function claim(uint256[] calldata tokenIds) external {
        if (!claimIsActive) {
            revert ClaimNotLive();
        }

        uint256 baseStart = startTokenId;
        uint256 offsets = packedOffsets;

        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 mask = (1 << (tokenIds[i] - baseStart - 1));

            if (offsets & mask != mask) {
                revert TokenNotEligible();
            }

            if (afterlifeContract.ownerOf(tokenIds[i]) != msg.sender) {
                revert NotOwner();
            }

            unchecked {
                ++i;
            }
        }

        _mintMultiple(tokenIds, msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        if (isLocked) {
            revert ProvenanceLocked();
        }

        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        if (isLocked) {
            revert ProvenanceLocked();
        }

        provenance = provenanceHash;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}