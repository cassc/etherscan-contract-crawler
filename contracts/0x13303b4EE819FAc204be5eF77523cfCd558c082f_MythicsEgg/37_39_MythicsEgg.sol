// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {ERC721A, ERC721ACommon, BaseTokenURI, ERC721ACommonBaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";
import {ERC4906} from "ethier/erc721/ERC4906.sol";

import {IEntropyOracle} from "proof/entropy/IEntropyOracle.sol";
import {RedeemableERC721ACommon} from "proof/redemption/voucher/RedeemableERC721ACommon.sol";
import {SellableERC721ACommon} from "proof/sellers/sellable/SellableERC721ACommon.sol";

import {MythicEggSampler} from "./MythicEggSampler.sol";
import {MythicEggActivator} from "./MythicEggActivator.sol";

/**
 * @title Mythics: Egg
 * @notice A redeemable token claimable by all diamond nested Moonbirds.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract MythicsEgg is
    ERC721ACommonBaseTokenURI,
    OperatorFilterOS,
    SellableERC721ACommon,
    RedeemableERC721ACommon,
    MythicEggSampler,
    MythicEggActivator
{
    constructor(address admin, address steerer, address payable secondaryReceiver, IEntropyOracle oracle)
        ERC721ACommon(admin, steerer, "Mythics: Egg", "EGG", secondaryReceiver, 500)
        BaseTokenURI("https://metadata.proof.xyz/mythics/egg/")
        MythicEggSampler(oracle)
    {
        _setEggProbabilities([uint64(0), uint64(40), uint64(60)]);
    }

    // =================================================================================================================
    //                          Information Getter
    // =================================================================================================================

    /**
     * @notice Encodes information about a token.
     * @dev Intended to be used off-chain.
     */
    struct TokenInfo {
        bool revealed;
        EggType eggType;
        bool activated;
    }

    /**
     * @notice Returns information about given egg token.
     * @dev Not optimised, intended to be used off-chain only.
     */
    function tokenInfos(uint256[] calldata tokenIds) external view returns (TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (EggType eggT, bool revealed) = eggType(tokenIds[i]);
            infos[i] = TokenInfo({revealed: revealed, eggType: eggT, activated: activated(tokenIds[i])});
        }
        return infos;
    }

    // =================================================================================================================
    //                          Steering
    // =================================================================================================================

    /**
     * @notice Sets the probability distribution for egg types.
     */
    function setEggProbabilities(uint64[NUM_EGG_TYPES] memory pdf) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setEggProbabilities(pdf);
    }

    /**
     * @notice Sets the entropy oracle.
     */
    function setEntropyOracle(IEntropyOracle newOracle) external onlyRole(DEFAULT_STEERING_ROLE) {
        entropyOracle = newOracle;
    }

    /**
     * @notice Sets the maximum number of activations per day.
     */
    function setMaxNumActivationsPerDay(uint32 maxNumActivationsPerDay) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setMaxNumActivationsPerDay(maxNumActivationsPerDay);
    }

    /**
     * @notice Activates an array of eggs.
     */
    function activate(uint256[] calldata tokenIds) external onlyRole(DEFAULT_STEERING_ROLE) {
        _activate(tokenIds);
    }

    // =================================================================================================================
    //                          Inheritance Resolution
    // =================================================================================================================

    /**
     * @inheritdoc SellableERC721ACommon
     * @dev Registers the minted tokens for sampling.
     */
    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual override {
        uint256 startTokenId = _nextTokenId();
        for (uint256 i; i < num; ++i) {
            _registerForSampling(startTokenId + i);
        }

        super._handleSale(to, num, data);
    }

    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721A, MythicEggActivator, MythicEggSampler)
        returns (bool)
    {
        return ERC721A._exists(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, ERC721ACommonBaseTokenURI, SellableERC721ACommon, RedeemableERC721ACommon, ERC4906)
        returns (bool)
    {
        return RedeemableERC721ACommon.supportsInterface(interfaceId)
            || SellableERC721ACommon.supportsInterface(interfaceId) || ERC4906.supportsInterface(interfaceId)
            || ERC721ACommonBaseTokenURI.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override(ERC721A, ERC721ACommonBaseTokenURI) returns (string memory) {
        return ERC721ACommonBaseTokenURI._baseURI();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721A, OperatorFilterOS) {
        OperatorFilterOS.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
    }
}