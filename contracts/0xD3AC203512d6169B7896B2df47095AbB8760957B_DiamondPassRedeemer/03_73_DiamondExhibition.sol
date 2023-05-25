// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.15;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {GenArt721CoreV3_Engine_Flex_PROOF} from "artblocks-contracts/GenArt721CoreV3_Engine_Flex_PROOF.sol";

import {ERC721A, ERC721ACommon, BaseTokenURI, ERC721ACommonBaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";

import {artblocksTokenID} from "proof/artblocks/TokenIDMapping.sol";
import {IGenArt721CoreContractV3_Mintable} from "proof/artblocks/IGenArt721CoreContractV3_Mintable.sol";
import {SellableERC721ACommon} from "proof/sellers/sellable/SellableERC721ACommon.sol";

import {ProjectsConfig} from "./ProjectsConfig.sol";
import {TokenInfoManager} from "./TokenInfoManager.sol";

/**
 * @notice Library for encoding and decoding purchase data for the Diamond Exhibition sellers.
 */
library DiamondExhibitionLib {
    function encodePurchaseData(uint8[] memory projectIds) internal pure returns (bytes memory) {
        return abi.encode(projectIds);
    }

    function dencodePurchaseData(bytes memory data) internal pure returns (uint8[] memory) {
        return abi.decode(data, (uint8[]));
    }
}

/**
 * @notice Diamond Exhibition
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract DiamondExhibition is
    ERC721ACommonBaseTokenURI,
    OperatorFilterOS,
    SellableERC721ACommon,
    ProjectsConfig,
    TokenInfoManager
{
    // =================================================================================================================
    //                          Errors
    // =================================================================================================================

    /**
     * @notice Thrown if the number of requested purchases exceeds the number of remaining tokens.
     */
    error ExceedingMaxTotalSupply(uint256 num, uint256 numLeft);

    /**
     * @notice Thrown if a user attempts to purchase tokens from an exhausted project.
     */
    error ProjectExhausted(uint8 projectId);

    /**
     * @notice Thrown if a user attempts to purchase tokens from an invalid project.
     */
    error InvalidProject(uint8 projectId);

    // =================================================================================================================
    //                          Constants
    // =================================================================================================================

    /**
     * @notice The ArtBlocks engine flex contract.
     */
    GenArt721CoreV3_Engine_Flex_PROOF public immutable flex;

    /**
     * @notice The ArtBlocks engine flex contract or a minter multiplexer.
     */
    IGenArt721CoreContractV3_Mintable public immutable flexMintGateway;

    /**
     * @notice The maximum total number of tokens that can be minted.
     * @dev This is intentionally not a compile-time constant for the sake of testing.
     */
    uint256 public immutable maxTotalSupply;

    // =========================================================================
    //                          Storage
    // =================================================================================================================

    /**
     * @notice The number of tokens minted per project.
     */
    uint16[NUM_PROJECTS] internal _numPurchasedPerProject;

    // =================================================================================================================
    //                          Storage
    // =================================================================================================================

    struct ConstructorParams {
        address admin;
        address steerer;
        address payable secondaryReceiver;
        GenArt721CoreV3_Engine_Flex_PROOF flex;
        IGenArt721CoreContractV3_Mintable flexMintGateway;
    }

    constructor(ConstructorParams memory params)
        ERC721ACommon(params.admin, params.steerer, "Diamond Exhibition", "DIAMOND", params.secondaryReceiver, 500)
        BaseTokenURI("https://metadata.proof.xyz/diamond-exhibition/")
    {
        uint256 total;
        uint256[NUM_PROJECTS] memory maxNumPerProject_ = _maxNumPerProject();
        for (uint256 i = 0; i < NUM_PROJECTS; i++) {
            total += maxNumPerProject_[i];
        }
        maxTotalSupply = total;

        flex = params.flex;
        flexMintGateway = params.flexMintGateway;
    }

    // =================================================================================================================
    //                          Selling
    // =================================================================================================================

    /**
     * @notice Assigns a project to a token.
     * @dev Mints from the associated ArtBlocks project if the project is a longform project.
     */
    function _assignProject(uint256 tokenId, uint8 projectId, uint256[NUM_PROJECTS] memory maxNumPerProject_)
        internal
    {
        if (projectId >= NUM_PROJECTS) {
            revert InvalidProject(projectId);
        }

        uint16 numPurchased = _numPurchasedPerProject[projectId];
        if (numPurchased >= maxNumPerProject_[projectId]) {
            revert ProjectExhausted(projectId);
        }
        _numPurchasedPerProject[projectId] = numPurchased + 1;

        if (_isLongformProject(projectId)) {
            flexMintGateway.mint_Ecf(address(this), _artblocksProjectId(projectId), address(this));
        }
        _setTokenInfo(tokenId, projectId, numPurchased /* edition */ );
    }

    /**
     * @inheritdoc SellableERC721ACommon
     */
    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual override {
        if (num + _totalMinted() > maxTotalSupply) {
            revert ExceedingMaxTotalSupply(num, maxTotalSupply - _totalMinted());
        }

        uint8[] memory projectIds = DiamondExhibitionLib.dencodePurchaseData(data);
        assert(projectIds.length == num);

        uint256 tokenId = _nextTokenId();
        uint256[NUM_PROJECTS] memory maxNumPerProject_ = _maxNumPerProject();
        for (uint256 i = 0; i < num; ++i) {
            _assignProject(tokenId++, projectIds[i], maxNumPerProject_);
        }

        SellableERC721ACommon._handleSale(to, num, data);
    }

    /**
     * @inheritdoc ERC721A
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        TokenInfo memory info = _tokenInfo(tokenId);

        if (projectType(info.projectId) == ProjectType.Curated) {
            return string.concat(_baseURI(), Strings.toString(tokenId));
        }

        return flex.tokenURI(artblocksTokenID(_artblocksProjectId(info.projectId), info.edition));
    }

    /**
     * @notice Returns all tokenIds for a given project.
     * @dev Intended for front-end consumption and not optimised for gas.
     */
    function tokenIdsByProjectId(uint8 projectId) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](_numPurchasedPerProject[projectId]);

        uint256 cursor;
        uint256 supply = totalSupply();
        for (uint256 tokenId = 0; tokenId < supply; ++tokenId) {
            if (_tokenInfo(tokenId).projectId == projectId) {
                tokenIds[cursor++] = tokenId;
            }
        }

        return tokenIds;
    }

    /**
     * @notice Returns the number of tokens purchased for each project.
     * @dev Intended for front-end consumption and not optimised for gas.
     */
    function numPurchasedPerProject() external view returns (uint16[NUM_PROJECTS] memory) {
        return _numPurchasedPerProject;
    }

    // =================================================================================================================
    //                          Inheritance resolution
    // =================================================================================================================

    /**
     * @notice Helper function that returns true if the token belongs to a longform project.
     */
    function _isLongformToken(uint256 tokenId) internal view virtual returns (bool) {
        return _isLongformProject(_tokenInfo(tokenId).projectId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, ERC721ACommonBaseTokenURI, SellableERC721ACommon)
        returns (bool)
    {
        return ERC721ACommonBaseTokenURI.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override(ERC721A, ERC721ACommonBaseTokenURI) returns (string memory) {
        return ERC721ACommonBaseTokenURI._baseURI();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, OperatorFilterOS) {
        ERC721A.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721A, OperatorFilterOS) {
        if (_isLongformToken(tokenId)) {
            ERC721A.approve(operator, tokenId);
        } else {
            OperatorFilterOS.approve(operator, tokenId);
        }
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        if (_isLongformToken(tokenId)) {
            ERC721A.transferFrom(from, to, tokenId);
        } else {
            OperatorFilterOS.transferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        if (_isLongformToken(tokenId)) {
            ERC721A.safeTransferFrom(from, to, tokenId);
        } else {
            OperatorFilterOS.safeTransferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        virtual
        override(ERC721A, OperatorFilterOS)
    {
        if (_isLongformToken(tokenId)) {
            ERC721A.safeTransferFrom(from, to, tokenId, data);
        } else {
            OperatorFilterOS.safeTransferFrom(from, to, tokenId, data);
        }
    }
}