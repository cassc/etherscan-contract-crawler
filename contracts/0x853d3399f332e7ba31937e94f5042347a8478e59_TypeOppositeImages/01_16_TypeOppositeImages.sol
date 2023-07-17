// SPDX-License-Identifier: GPL-3.0-or-later
// Author:                  Rhea Myers <[email protected]>
// Copyright:               2023 Myers Studio, Ltd.
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IERC998ERC721TopDownEnumerable.sol";

// A contract that reverses Tokens Equal Text.

contract TypeOppositeImages is ERC721, ERC721Enumerable, Pausable, Ownable {
    uint256 public constant NUM_TOKENS = 32;

    address private tet998;

    string private baseUri = "ipfs://Qmc3fsEYpuNsDsw2CJyctCq7j2KL3FDDDf3pWvCm84qoiq/";
    
    mapping(uint256 => bytes32) public citehtsea;

    constructor(address tet998Addr)
        ERC721("Type Opposite Images", "TOI")
    {
        tet998 = tet998Addr;
        for (uint256 i = 1; i <= NUM_TOKENS; i++) {
            _mint(msg.sender, i);
        }
    }

    function addCitehtsea(
        uint256[] calldata ids,
        bytes32[] calldata vals
    )
        public
        onlyOwner
    {
        require(ids.length == vals.length, "Arguments must be same length.");
        for (uint256 i = 0; i < ids.length; i++) {
            citehtsea[ids[i]] = vals[i];
        }
    }

    function reverse(uint256[] memory texts)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory reversed = new bytes32[](texts.length);
        for (uint256 i = 0; i < texts.length; i++) {
            // This will be null/the empty string for uinknown texts.
            reversed[i] = citehtsea[texts[i]];
        }
        return reversed;
    }

    function tet998TokenChildCount(uint256 tokenId)
        public
        view
        returns(uint256)
    {
        // This will actually error in the called function,
        // so this is for clarity.
        // Yes, the 998 is also a 721.
        require(ERC721(tet998).ownerOf(tokenId) != address(0), "No such token");
        ERC998ERC721TopDownEnumerable
            enumerable = ERC998ERC721TopDownEnumerable(tet998);
        // No memory dynamic arrays in Solidity.
        // So we walk the tree to calculate this.
        // It would be fantastically wasteful to ever call this onchain.
        uint256 childIdCount = 0;
        uint256 numChildContracts = enumerable.totalChildContracts(tokenId);
        for (uint256 c = 0; c < numChildContracts; c++) {
            address childContract = enumerable.childContractByIndex(
                tokenId,
                c
            );
            uint256 numChildTokens = enumerable.totalChildTokens(
                tokenId,
                childContract
            );
            for (uint256 index = 0; index < numChildTokens; index++) {
                childIdCount += 1;
            }
        }
        return childIdCount;
    }

    function tet998TokenChildIds(uint256 tokenId)
        public
        view
        returns(uint256[] memory childIds)
    {
        // No memory dynamic arrays in Solidity.
        uint256 childIdCount = tet998TokenChildCount(tokenId);
        childIds = new uint256[](childIdCount);
        if (childIdCount > 0) {
            ERC998ERC721TopDownEnumerable
                enumerable = ERC998ERC721TopDownEnumerable(tet998);
            uint256 childIdArrayIndex = 0;
            uint256 numChildContracts = enumerable.totalChildContracts(tokenId);
            for (uint256 c = 0; c < numChildContracts; c++) {
                address childContract = enumerable.childContractByIndex(
                    tokenId,
                    c
                );
                uint256 numChildTokens = enumerable.totalChildTokens(
                    tokenId,
                    childContract
                );
                for (uint256 index = 0; index < numChildTokens; index++) {
                    childIds[childIdArrayIndex] = enumerable.childTokenByIndex(
                        tokenId,
                        childContract,
                        index
                    );
                    childIdArrayIndex += 1;
                }
            }
            uint256[] memory childIdArray = new uint256[](childIdCount);
            for (uint256 i = 0; i < childIdCount; i++) {
                childIdArray[i] = childIds[i];
            }
            return childIdArray;
        }
    }

    function aestheticToCitehtsea(uint256 tokenId)
        public
        view
        returns (bytes32[] memory reversals)
    {
        uint256[] memory tetChildIds = tet998TokenChildIds(tokenId);
        reversals = new bytes32[](tetChildIds.length);
        for(uint256 i = 0; i < tetChildIds.length; i++) {
            reversals[i] = citehtsea[tetChildIds[i]];
        }
        return reversals;
    }

    function setTet998Addr(address tet998Addr)
        public
        onlyOwner
    {
        require(
            tet998Addr != address(0),
            "Cannot assign to 0x0, use burn address"
        );
        tet998 = tet998Addr;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string calldata newUri) external onlyOwner {
        baseUri = newUri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}