// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC721ALib} from "./ERC721A/ERC721ALib.sol";

error ExceedsMaxMintable();
error MaxMintableTooSmall();
error MaxMintableLocked();

library BaseNFTLib {
    struct BaseNFTStorage {
        uint256 saleState;
        uint256 maxMintable; // the max number of tokens able to be minted
        bool maxMintableLocked;
    }

    function baseNFTStorage()
        internal
        pure
        returns (BaseNFTStorage storage es)
    {
        bytes32 position = keccak256("base.nft.diamond.storage");
        assembly {
            es.slot := position
        }
    }

    function saleState() internal view returns (uint256) {
        return baseNFTStorage().saleState;
    }

    function setSaleState(uint256 _saleState) internal {
        baseNFTStorage().saleState = _saleState;
    }

    function _safeMint(address to, uint256 quantity)
        internal
        returns (uint256 initialTokenId)
    {
        // if max mintable is zero, unlimited mints are allowed
        uint256 max = baseNFTStorage().maxMintable;
        if (max != 0 && max < (ERC721ALib.totalMinted() + quantity)) {
            revert ExceedsMaxMintable();
        }

        // returns the id of the first token minted!
        initialTokenId = ERC721ALib.currentIndex();
        ERC721ALib._safeMint(to, quantity);
    }

    // skips checks about sending to contract addresses
    function _unsafeMint(address to, uint256 quantity)
        internal
        returns (uint256 initialTokenId)
    {
        // if max mintable is zero, unlimited mints are allowed
        uint256 max = baseNFTStorage().maxMintable;
        if (max != 0 && max < (ERC721ALib.totalMinted() + quantity)) {
            revert ExceedsMaxMintable();
        }

        // returns the id of the first token minted!
        initialTokenId = ERC721ALib.currentIndex();
        ERC721ALib._mint(to, quantity, "", false);
    }

    function maxMintable() internal view returns (uint256) {
        return baseNFTStorage().maxMintable;
    }

    function setMaxMintable(uint256 _maxMintable) internal {
        if (_maxMintable < ERC721ALib.totalMinted()) {
            revert MaxMintableTooSmall();
        }
        if (baseNFTStorage().maxMintableLocked) {
            revert MaxMintableLocked();
        }

        baseNFTStorage().maxMintable = _maxMintable;
    }

    // NOTE: this returns an array of owner addresses for each token
    // this may return duplicate addresses if one address owns multiple
    // tokens. The client should de-doop as needed
    function allOwners() internal view returns (address[] memory) {
        uint256 currIndex = ERC721ALib.erc721AStorage()._currentIndex;

        address[] memory _allOwners = new address[](currIndex - 1);

        for (uint256 i = 0; i < currIndex - 1; i++) {
            uint256 tokenId = i + 1;
            if (ERC721ALib._exists(tokenId)) {
                address owner = ERC721ALib._ownershipOf(tokenId).addr;
                _allOwners[i] = owner;
            } else {
                _allOwners[i] = address(0x0);
            }
        }

        return _allOwners;
    }

    function allTokensForOwner(address _owner)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 balance = ERC721ALib.balanceOf(_owner);
        uint256 currIndex = ERC721ALib.erc721AStorage()._currentIndex;

        uint256[] memory tokens = new uint256[](balance);
        uint256 tokenCount = 0;

        for (uint256 i = 1; i < currIndex; i++) {
            if (ERC721ALib._exists(i)) {
                address ownerOfToken = ERC721ALib._ownershipOf(i).addr;

                if (ownerOfToken == _owner) {
                    tokens[tokenCount] = i;
                    tokenCount++;
                }
            }
        }

        return tokens;
    }
}