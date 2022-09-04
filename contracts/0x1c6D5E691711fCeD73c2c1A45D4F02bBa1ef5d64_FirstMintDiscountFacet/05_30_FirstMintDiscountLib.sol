// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../LazyMint/LazyMintLib.sol";
import {ERC721ALib} from "../ERC721A/ERC721ALib.sol";
import {MerkleTreeAllowlistLibV2} from "../MerkleTreeAllowlistV2/MerkleTreeAllowlistLibV2.sol";

error IncorrectAllowlistEntries();
error ExceededAllowlistMintLimit();

library FirstMintDiscountLib {
    bytes32 constant FIRST_MINT_DISCOUNT_STORAGE_POSITION =
        keccak256("first.mint.discount.storage");

    struct FirstMintDiscountStorage {
        uint256 discountPrice;
        uint256 discountCountPerUser;
        uint256 maxMintableViaDiscount;
        uint256 totalMintedViaDiscount;
    }

    function firstMintDiscountStorage()
        internal
        pure
        returns (FirstMintDiscountStorage storage s)
    {
        bytes32 position = FIRST_MINT_DISCOUNT_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function setDiscountPrice(uint256 _discountPrice) internal {
        firstMintDiscountStorage().discountPrice = _discountPrice;
    }

    function setDiscountCountPerUser(uint256 _count) internal {
        firstMintDiscountStorage().discountCountPerUser = _count;
    }

    function setMaxMintableViaDiscount(uint256 _max) internal {
        firstMintDiscountStorage().maxMintableViaDiscount = _max;
    }

    // copied from lazyMintLib without price validation
    function _lazyMint(uint256 quantity) internal returns (uint256) {
        LazyMintLib.LazyMintStorage storage s = LazyMintLib.lazyMintStorage();
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

    // Copied from merkle-allowlistLibV2 but without price validation
    function _allowlistMint(
        uint256 _quantityToMint,
        uint256 _quantityAllowListEntries,
        bytes32[] calldata _merkleProof
    ) internal returns (uint256) {
        // merkle proof then lazy mint mint
        bytes32 leaf = keccak256(
            abi.encodePacked(msg.sender, _quantityAllowListEntries)
        );

        bool isOnAllowlist = MerkleProof.verify(
            _merkleProof,
            MerkleTreeAllowlistLibV2
                .merkleTreeAllowlistStorage()
                .allowlistMerkleRoot,
            leaf
        );

        if (!isOnAllowlist) {
            revert IncorrectAllowlistEntries();
        }

        uint256 numMintedSoFar = ERC721ALib._numberMinted(msg.sender);
        if ((numMintedSoFar + _quantityToMint) > _quantityAllowListEntries)
            revert ExceededAllowlistMintLimit();

        return _lazyMint(_quantityToMint);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function discountPriceInfo(uint256 _count, address _minter)
        internal
        view
        returns (
            uint256 numDiscounted_,
            uint256 numFullPrice_,
            uint256 price_
        )
    {
        uint256 numMintedSoFar = ERC721ALib._numberMinted(_minter);
        FirstMintDiscountStorage storage s = firstMintDiscountStorage();
        uint256 maxMintableViaDiscount = s.maxMintableViaDiscount;
        uint256 totalMintedViaDiscount = s.totalMintedViaDiscount;
        uint256 discountPrice = s.discountPrice;
        uint256 discountCountPerUser = s.discountCountPerUser;
        uint256 fullPrice = LazyMintLib.lazyMintStorage().publicMintPrice;

        uint256 numDiscountedMintsAvail = numMintedSoFar >= discountCountPerUser
            ? 0
            : discountCountPerUser - numMintedSoFar;

        // if maxMintableViaDiscount is set, enforce it
        if (maxMintableViaDiscount != 0) {
            uint256 numDiscountsLeft = maxMintableViaDiscount -
                totalMintedViaDiscount;
            numDiscountedMintsAvail = _min(
                numDiscountedMintsAvail,
                numDiscountsLeft
            );
        }

        numDiscounted_ = _min(_count, numDiscountedMintsAvail);
        numFullPrice_ = numDiscounted_ >= _count ? 0 : _count - numDiscounted_;
        price_ = numDiscounted_ * discountPrice + numFullPrice_ * fullPrice;
    }

    function discountAllowlistMint(
        uint256 _count,
        uint256 _quantityAllowListEntries,
        bytes32[] calldata _merkleProof
    ) internal {
        (uint256 numDiscounted, , uint256 price) = discountPriceInfo(
            _count,
            msg.sender
        );
        require(msg.value >= price, "FirstMintDiscount: Insufficient funds");
        _allowlistMint(_count, _quantityAllowListEntries, _merkleProof);
        firstMintDiscountStorage().totalMintedViaDiscount += numDiscounted;
    }

    function discountLazyMint(uint256 _count) internal {
        (uint256 numDiscounted, , uint256 price) = discountPriceInfo(
            _count,
            msg.sender
        );
        require(msg.value >= price, "FirstMintDiscount: Insufficient funds");
        _lazyMint(_count);
        firstMintDiscountStorage().totalMintedViaDiscount += numDiscounted;
    }

    function setFirstMintDiscountConfig(
        uint256 discountPrice,
        uint256 discountCountPerUser,
        uint256 maxMintableViaDiscount
    ) internal {
        FirstMintDiscountStorage storage s = firstMintDiscountStorage();
        s.discountPrice = discountPrice;
        s.discountCountPerUser = discountCountPerUser;
        s.maxMintableViaDiscount = maxMintableViaDiscount;
    }
}