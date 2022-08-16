// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721ALib} from "../ERC721A/ERC721ALib.sol";
import {BaseNFTLib} from "../BaseNFTLib.sol";

error InsufficientFunds();
error ExceededMaxMintsPerTxn();
error ExceededMaxMintsPerWallet();
error ReachedMaxMintableAtCurrentStage();

library LazyMintLib {
    bytes32 constant LAZY_MINT_STORAGE_POSITION =
        keccak256("lazy.mint.storage");

    struct LazyMintStorage {
        uint256 publicMintPrice;
        uint256 maxMintsPerTxn;
        uint256 maxMintsPerWallet;
        uint256 maxMintableAtCurrentStage;
    }

    function lazyMintStorage()
        internal
        pure
        returns (LazyMintStorage storage s)
    {
        bytes32 position = LAZY_MINT_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function setPublicMintPrice(uint256 _mintPrice) internal {
        lazyMintStorage().publicMintPrice = _mintPrice;
    }

    function setMaxMintsPerTransaction(uint256 _numPerTransaction) internal {
        lazyMintStorage().maxMintsPerTxn = _numPerTransaction;
    }

    function setMaxMintsPerWallet(uint256 _numPerWallet) internal {
        lazyMintStorage().maxMintsPerWallet = _numPerWallet;
    }

    function publicMintPrice() internal view returns (uint256) {
        return lazyMintStorage().publicMintPrice;
    }

    function setMaxMintableAtCurrentStage(uint256 _maxAtCurrentStage) internal {
        lazyMintStorage().maxMintableAtCurrentStage = _maxAtCurrentStage;
    }

    function publicMint(uint256 quantity) internal returns (uint256) {
        LazyMintStorage storage s = lazyMintStorage();
        if (msg.value < quantity * publicMintPrice()) {
            revert InsufficientFunds();
        }

        if (s.maxMintsPerTxn > 0 && quantity > s.maxMintsPerTxn) {
            revert ExceededMaxMintsPerTxn();
        }

        if (
            s.maxMintsPerWallet > 0 &&
            (ERC721ALib._numberMinted(msg.sender) + quantity) >
            s.maxMintsPerWallet
        ) {
            revert ExceededMaxMintsPerWallet();
        }

        if (
            s.maxMintableAtCurrentStage > 0 &&
            (ERC721ALib.totalMinted() + quantity) > s.maxMintableAtCurrentStage
        ) {
            revert ReachedMaxMintableAtCurrentStage();
        }

        return BaseNFTLib._safeMint(msg.sender, quantity);
    }
}