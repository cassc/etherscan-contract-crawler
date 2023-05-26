// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {IERC721Metadata} from "openzeppelin-contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {GenArt721CoreV3_Engine_Flex_PROOF} from "artblocks-contracts/GenArt721CoreV3_Engine_Flex_PROOF.sol";

import {AccessControlEnumerable, ERC721ACommon} from "ethier/erc721/ERC721ACommon.sol";
import {ERC721A, BaseTokenURI, ERC721ACommonBaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";
import {OperatorFilterOS} from "ethier/erc721/OperatorFilterOS.sol";
import {ERC4906} from "ethier/erc721/ERC4906.sol";

import {SellableERC721ACommon} from "proof/sellers/sellable/SellableERC721ACommon.sol";
import {Seller} from "proof/sellers/base/Seller.sol";
import {IEntropyOracleV2} from "proof/entropy/IEntropyOracleV2.sol";
import {artblocksTokenID} from "proof/artblocks/TokenIDMapping.sol";
import {IGenArt721CoreContractV3_Mintable} from "proof/artblocks/IGenArt721CoreContractV3_Mintable.sol";

import {SettablePrimaryRevenueForwarder} from "./PrimaryRevenueForwarder.sol";
import {ProjectsConfig} from "./ProjectsConfig.sol";
import {TokenInfoManager} from "./TokenInfoManager.sol";
import {Randomiser} from "./Randomiser.sol";

/**
 * @notice PROOF Curated: Evolving Pixels.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract EvolvingPixels is
    SellableERC721ACommon,
    SettablePrimaryRevenueForwarder,
    TokenInfoManager,
    ERC721ACommonBaseTokenURI,
    OperatorFilterOS,
    Randomiser,
    ProjectsConfig
{
    // =================================================================================================================
    //                          Errors
    // =================================================================================================================

    /**
     * @notice Thrown if the number of requested purchases exceeds the number of remaining tokens.
     */
    error ExceedingMaxTotalSupply(uint256 num, uint256 numLeft);

    /**
     * @notice Thrown if the contract owner attempts to mint the reserve twice.
     */
    error DontGetGreedy();

    // =================================================================================================================
    //                          Types
    // =================================================================================================================

    /**
     * @notice Encodes a stage of the sale.
     */
    enum Stage {
        Closed,
        TokenGated,
        SignatureGated,
        Public
    }

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

    // =================================================================================================================
    //                          Storage
    // =================================================================================================================

    /**
     * @notice The stage of the sale.
     */
    Stage public stage;

    /**
     * @notice Flag indicating whether the owner reserve has been minted.
     */
    bool internal _reserveMinted;

    /**
     * @notice The number of tokens minted per project.
     */
    uint8[_NUM_PROJECTS] public numPurchasedPerProject;

    /**
     * @notice The seller contracts for different contract stages.
     */
    mapping(Stage => Seller) public stageSellers;

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    struct ConstructorParams {
        address admin;
        address steerer;
        address payable primaryReceiver;
        address payable secondaryReceiver;
        string baseTokenURI;
        IEntropyOracleV2 entropyOracle;
        GenArt721CoreV3_Engine_Flex_PROOF flex;
        IGenArt721CoreContractV3_Mintable flexMintGateway;
    }

    constructor(ConstructorParams memory params)
        ERC721ACommon(
            params.admin,
            params.steerer,
            "PROOF Curated: Evolving Pixels",
            "EVOPIX",
            params.secondaryReceiver,
            750
        )
        BaseTokenURI(params.baseTokenURI)
        Randomiser(params.entropyOracle)
    {
        flex = params.flex;
        flexMintGateway = params.flexMintGateway;
        _setPrimaryReceiver(params.primaryReceiver);
        assert(maxTotalSupply == 891);
    }

    // =================================================================================================================
    //                          Selling
    // =================================================================================================================

    /**
     * @inheritdoc SellableERC721ACommon
     */
    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual override {
        if (num + _totalMinted() > maxTotalSupply) {
            revert ExceedingMaxTotalSupply(num, maxTotalSupply - _totalMinted());
        }

        _forwardRevenue(msg.value);
        _commitAndRequestEntropy(_nextTokenId(), num);
        SellableERC721ACommon._handleSale(to, num, data);
    }

    /**
     * @inheritdoc Randomiser
     */
    function _assignProject(uint256 tokenId, uint8 projectId) internal virtual override {
        uint8 edition = numPurchasedPerProject[projectId]++;
        if (_isLongformProject(projectId)) {
            flexMintGateway.mint_Ecf(address(this), _artblocksProjectId(projectId), address(this));
        }
        _setTokenInfo(tokenId, projectId, edition);
    }

    /**
     * @inheritdoc ERC721A
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        TokenInfo memory info = _tokenInfo(tokenId);

        if (!info.revealed) {
            return string.concat(_baseURI(), "placeholder/", Strings.toString(tokenId));
        }

        if (_projectType(info.projectId) == ProjectType.Curated) {
            return string.concat(_baseURI(), "curated/", Strings.toString(tokenId));
        }

        return flex.tokenURI(artblocksTokenID(_artblocksProjectId(info.projectId), info.edition));
    }

    /**
     * @notice Returns all tokenIds for a given project.
     * @dev Intended for front-end consumption and not optimised for gas.
     */
    function tokenIdsByProjectId(uint8 projectId) external view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](numPurchasedPerProject[projectId]);

        uint256 cursor;
        uint256 num = totalSupply();
        for (uint256 i = 0; i < num; ++i) {
            if (_tokenInfo(i).projectId == projectId) {
                tokenIds[cursor++] = i;
            }
        }

        return tokenIds;
    }

    // =================================================================================================================
    //                          Steering
    // =================================================================================================================

    /**
     * @notice Mints the owner reserve.
     */
    function ownerMint(address to) external onlyRole(DEFAULT_STEERING_ROLE) {
        if (_reserveMinted) {
            revert DontGetGreedy();
        }
        _reserveMinted = true;

        uint256 tokenId = _nextTokenId();
        _mint(to, _NUM_PROJECTS);

        for (uint8 projectId = 0; projectId < _NUM_PROJECTS; ++projectId) {
            _assignProject(tokenId, projectId);
            ++tokenId;
        }
    }

    /**
     * @notice Sets the seller contract for a given stage.
     */
    function setStageSeller(Stage stage_, Seller seller) external onlyRole(DEFAULT_STEERING_ROLE) {
        stageSellers[stage_] = seller;
    }

    /**
     *
     * @notice Sets the entropy oracle contract.
     */
    function setEntropyOracle(IEntropyOracleV2 newOracle) external onlyRole(DEFAULT_STEERING_ROLE) {
        entropyOracle = newOracle;
    }

    /**
     * @notice Changes the primary revenue receiver.
     */
    function setStage(Stage stage_) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setStage(stage_);
    }

    function _setStage(Stage stage_) internal {
        stage = stage_;
        _revokeAllSellers();
        address seller = address(stageSellers[stage_]);
        if (seller != address(0)) {
            _grantRole(AUTHORISED_SELLER_ROLE, seller);
        }
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
        override(ERC4906, ERC721ACommon, AccessControlEnumerable, ERC721ACommonBaseTokenURI, SellableERC721ACommon)
        returns (bool)
    {
        return ERC721ACommonBaseTokenURI.supportsInterface(interfaceId) || ERC4906.supportsInterface(interfaceId);
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

    function _projectSizes() internal pure virtual override(ProjectsConfig, Randomiser) returns (uint256[] memory) {
        return ProjectsConfig._projectSizes();
    }
}