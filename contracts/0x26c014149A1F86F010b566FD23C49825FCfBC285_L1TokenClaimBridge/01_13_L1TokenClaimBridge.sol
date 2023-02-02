// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import "../L2/interface/IL2TokenClaimBridge.sol";
import "./interface/IL1EventLogger.sol";
import "./interface/IL1TokenClaimBridge.sol";
import "../lib/storage/L1TokenClaimBridgeStorage.sol";
import "./interface/IRoyaltyEngineV1.sol";
import "../lib/crosschain/CrosschainOrigin.sol";

contract L1TokenClaimBridge is IL1TokenClaimBridge {
    modifier onlyNftOwner(address canonicalNft_, uint256 tokenId_) {
        require(
            IERC721(canonicalNft_).ownerOf(tokenId_) == msg.sender,
            "Message sender does not own NFT"
        );
        _;
    }

    modifier onlyNftsOwner(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    ) {
        require(
            canonicalNfts_.length > 0 &&
                tokenIds_.length > 0 &&
                canonicalNfts_.length == tokenIds_.length,
            "NFT inputs are malformed"
        );

        for (uint8 i = 0; i < canonicalNfts_.length; i++) {
            require(
                IERC721(canonicalNfts_[i]).ownerOf(tokenIds_[i]) == msg.sender,
                "Message sender does not own at least one given NFT"
            );
        }
        _;
    }

    constructor(
        address l1EventLogger_,
        address l2TokenClaimBridge_,
        address royaltyEngine_
    ) {
        L1TokenClaimBridgeStorage.get().l1EventLogger = l1EventLogger_;
        L1TokenClaimBridgeStorage
            .get()
            .l2TokenClaimBridge = l2TokenClaimBridge_;
        L1TokenClaimBridgeStorage.get().royaltyEngine = royaltyEngine_;
    }

    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_,
        uint256[] calldata amounts_
    ) external override onlyNftsOwner(canonicalNfts_, tokenIds_) {
        require(
            amounts_.length == canonicalNfts_.length,
            "canonicalNfts_, tokenIds_, and amounts_ must be same length"
        );

        (
            address payable[][] memory royaltyRecipientsArray,
            uint256[][] memory royaltyAmountsArray
        ) = _getRoyaltyRecipientsArrayAndRoyaltyAmountsArray(
                canonicalNfts_,
                tokenIds_,
                amounts_
            );

        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).claimEtherForMultipleNfts,
            (
                canonicalNfts_,
                tokenIds_,
                beneficiary_,
                amounts_,
                royaltyRecipientsArray,
                royaltyAmountsArray
            )
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1920000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitClaimEtherForMultipleNftsMessageSent(
                keccak256(abi.encodePacked(canonicalNfts_)),
                keccak256(abi.encodePacked(tokenIds_)),
                beneficiary_
            );
    }

    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external
        override
        onlyNftOwner(canonicalNft_, tokenId_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).markReplicasAsAuthentic,
            (canonicalNft_, tokenId_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1000000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitMarkReplicasAsAuthenticMessageSent(canonicalNft_, tokenId_);
    }

    function l2TokenClaimBridge() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().l2TokenClaimBridge;
    }

    function l1EventLogger() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().l1EventLogger;
    }

    function royaltyEngine() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().royaltyEngine;
    }

    function _getRoyaltyRecipientsArrayAndRoyaltyAmountsArray(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) internal view returns (address payable[][] memory, uint256[][] memory) {
        address payable[][]
            memory royaltyRecipientsArray = new address payable[][](
                canonicalNfts_.length
            );
        uint256[][] memory royaltyAmountsArray = new uint256[][](
            canonicalNfts_.length
        );

        for (uint256 i = 0; i < canonicalNfts_.length; i++) {
            (
                address payable[] memory royaltyRecipients,
                uint256[] memory royaltyAmounts
            ) = IRoyaltyEngineV1(L1TokenClaimBridgeStorage.get().royaltyEngine)
                    .getRoyaltyView(
                        canonicalNfts_[i],
                        tokenIds_[i],
                        amounts_[i]
                    );

            royaltyRecipientsArray[i] = royaltyRecipients;
            royaltyAmountsArray[i] = royaltyAmounts;
        }

        return (royaltyRecipientsArray, royaltyAmountsArray);
    }
}