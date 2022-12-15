// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import "../L2/interface/IL2TokenClaimBridge.sol";
import "./interface/IL1EventLogger.sol";
import "../lib/UUPSCrosschainPausableUpgradeable.sol";
import "./interface/IL1TokenClaimBridge.sol";
import "../lib/storage/L1TokenClaimBridgeStorage.sol";

contract L1TokenClaimBridge is
    IL1TokenClaimBridge,
    UUPSCrosschainPausableUpgradeable
{
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

    modifier requireL2TokenClaimBridgeSet() {
        require(
            L1TokenClaimBridgeStorage.get().l2TokenClaimBridge != address(0),
            "L2TokenClaimBridge is not yet set"
        );
        _;
    }

    function initialize(address l1EventLogger_) external override initializer {
        __UUPSCrosschainPausableUpgradeable_init();
        L1TokenClaimBridgeStorage.get().l1EventLogger = l1EventLogger_;
    }

    function initializeContractReferences(
        address crossChainOwner_,
        address l2TokenClaimBridge_
    ) external override onlyDeployer {
        // Set up state
        _setCrossChainOwner(crossChainOwner_);
        L1TokenClaimBridgeStorage
            .get()
            .l2TokenClaimBridge = l2TokenClaimBridge_;

        // Set deployer to 0x00
        _revokeDeployer();
    }

    function setL2TokenClaimBridge(address l2TokenClaimBridge_)
        external
        override
        onlyCrossChainOwner
    {
        L1TokenClaimBridgeStorage
            .get()
            .l2TokenClaimBridge = l2TokenClaimBridge_;
    }

    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_
    )
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftsOwner(canonicalNfts_, tokenIds_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).claimEtherForMultipleNfts,
            (canonicalNfts_, tokenIds_, beneficiary_)
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

    function claimEther(
        address canonicalNft_,
        uint256 tokenId_,
        address payable beneficiary_
    )
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftOwner(canonicalNft_, tokenId_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).claimEther,
            (canonicalNft_, tokenId_, beneficiary_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1000000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitClaimEtherMessageSent(canonicalNft_, tokenId_, beneficiary_);
    }

    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
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

    function markReplicasAsAuthenticMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    )
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftsOwner(canonicalNfts_, tokenIds_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).markReplicasAsAuthenticMultiple,
            (canonicalNfts_, tokenIds_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1920000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitMarkReplicasAsAuthenticMultipleMessageSent(
                keccak256(abi.encodePacked(canonicalNfts_)),
                keccak256(abi.encodePacked(tokenIds_))
            );
    }

    function burnReplicasAndDisableRemints(
        address canonicalNft_,
        uint256 tokenId_
    )
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftOwner(canonicalNft_, tokenId_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).burnReplicasAndDisableRemints,
            (canonicalNft_, tokenId_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1000000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitBurnReplicasAndDisableRemintsMessageSent(
                canonicalNft_,
                tokenId_
            );
    }

    function burnReplicasAndDisableRemintsMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    )
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftsOwner(canonicalNfts_, tokenIds_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0))
                .burnReplicasAndDisableRemintsMultiple,
            (canonicalNfts_, tokenIds_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1920000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitBurnReplicasAndDisableRemintsMultipleMessageSent(
                keccak256(abi.encodePacked(canonicalNfts_)),
                keccak256(abi.encodePacked(tokenIds_))
            );
    }

    function enableRemints(address canonicalNft_, uint256 tokenId_)
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftOwner(canonicalNft_, tokenId_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).enableRemints,
            (canonicalNft_, tokenId_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1000000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitEnableRemintsMessageSent(canonicalNft_, tokenId_);
    }

    function enableRemintsMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    )
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftsOwner(canonicalNfts_, tokenIds_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).enableRemintsMultiple,
            (canonicalNfts_, tokenIds_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1920000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitEnableRemintsMultipleMessageSent(
                keccak256(abi.encodePacked(canonicalNfts_)),
                keccak256(abi.encodePacked(tokenIds_))
            );
    }

    function disableRemints(address canonicalNft_, uint256 tokenId_)
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftOwner(canonicalNft_, tokenId_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).disableRemints,
            (canonicalNft_, tokenId_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1000000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitDisableRemintsMessageSent(canonicalNft_, tokenId_);
    }

    function disableRemintsMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    )
        external
        override
        whenNotPaused
        requireL2TokenClaimBridgeSet
        onlyNftsOwner(canonicalNfts_, tokenIds_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).disableRemintsMultiple,
            (canonicalNfts_, tokenIds_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1920000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitDisableRemintsMultipleMessageSent(
                keccak256(abi.encodePacked(canonicalNfts_)),
                keccak256(abi.encodePacked(tokenIds_))
            );
    }

    function l2TokenClaimBridge() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().l2TokenClaimBridge;
    }

    function l1EventLogger() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().l1EventLogger;
    }
}