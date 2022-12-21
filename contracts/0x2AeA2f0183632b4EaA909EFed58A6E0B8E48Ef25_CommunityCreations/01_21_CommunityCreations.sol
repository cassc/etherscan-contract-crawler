// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title: Community Creations
/// @author: x0r (Michael Blau) & Henry Borska

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {AdminControl} from "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC1155CreatorCore} from "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import {ICreatorExtensionTokenURI} from "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import {IPriceOracle} from "./IPriceOracle.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract CommunityCreations is
    AdminControl,
    ICreatorExtensionTokenURI,
    ReentrancyGuard
{
    // =================== CUSTOM ERRORS =================== //
    error NotCreator();
    error NonExistentToken();
    error InsufficientPayment();
    error NotMEVArmyCollector();
    error AlreadyMintedToken();

    // =================== CUSTOM STRUCTS =================== //
    struct Creation {
        address creatorAddress;
        bool isFree;
        bool isPublicMint;
        string tokenURI;
        string name;
        uint256 dateCreated;
    }

    // manifold creator contract address
    address public immutable creatorContract;

    // MEV Army contract address
    address public immutable mevArmyAddress;

    // number of "Community Creations" created so far
    uint256 public numCreations;

    // address of the price oracle
    address public priceOracle;

    // mapping between a tokenId and a Creation
    mapping(uint256 => Creation) public tokenIdToCreation;

    // mapping that keeps track of all payments a Creator receives when someone mints their Creation.
    mapping(address => uint256) public creatorBalance;

    constructor(
        address _creatorContract,
        address _priceOracle,
        address _mevArmyAddress
    ) {
        creatorContract = _creatorContract;
        priceOracle = _priceOracle;
        mevArmyAddress = _mevArmyAddress;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC165, AdminControl) returns (bool) {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(AdminControl).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Accept mint fee and mint a Creation. If not a public mint, only MEV Army collectors can mint.
     * @param _tokenId of the Creation you want to mint
     */
    function mintCreation(uint256 _tokenId) public payable {
        // check that _tokenId exists.
        if (_tokenId > numCreations) revert NonExistentToken();

        // check if msg.sender has minted this tokenId
        if (IERC1155(creatorContract).balanceOf(msg.sender, _tokenId) > 0)
            revert AlreadyMintedToken();

        Creation memory creation = tokenIdToCreation[_tokenId];

        if (!creation.isPublicMint) {
            if (IERC721(mevArmyAddress).balanceOf(msg.sender) == 0)
                revert NotMEVArmyCollector();
        }

        if (!creation.isFree) {
            uint256 currentPriceInEth = IPriceOracle(priceOracle)
                .getPriceInEth();
            if (msg.value < currentPriceInEth) revert InsufficientPayment();

            // allocate mint fee to the Creator of this tokenId
            creatorBalance[creation.creatorAddress] += currentPriceInEth;

            // refund any excess funds to the minter
            payable(msg.sender).transfer(msg.value - currentPriceInEth);
        }

        _mint(_tokenId);
    }

    /**
     * @dev mint an 1155 token on the manifold creator contract
     * @param _tokenId to mint
     */
    function _mint(uint256 _tokenId) internal {
        address[] memory to = new address[](1);
        to[0] = msg.sender;

        uint256[] memory token = new uint256[](1);
        token[0] = _tokenId;

        uint256[] memory amount = new uint256[](1);
        amount[0] = 1;

        IERC1155CreatorCore(creatorContract).mintExtensionExisting(
            to,
            token,
            amount
        );
    }

    /**
     * @notice return the metadata for a given tokenId
     * @param _creatorContract to check the correct manifold creator contract
     * @param _tokenId of the NFT
     */
    function tokenURI(
        address _creatorContract,
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_creatorContract == creatorContract);
        return tokenIdToCreation[_tokenId].tokenURI;
    }

    /**
     * @notice make a new Creation and mint the first token to the Creator.
     * @param _creator who made the new Creation
     * @param _isFree is the Creation free to mint
     * @param _tokenURI of the new Creation
     */
    function makeNewCreation(
        address _creator,
        bool _isFree,
        bool _isPublicMint,
        string memory _tokenURI,
        string memory _name
    ) external adminRequired {
        // register a new Creation
        ++numCreations;
        tokenIdToCreation[numCreations] = Creation(
            _creator,
            _isFree,
            _isPublicMint,
            _tokenURI,
            _name,
            block.timestamp
        );

        // mint the first token of the Creation to the Creator
        address[] memory to = new address[](1);
        to[0] = _creator;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        string[] memory uris = new string[](1);
        uris[0] = "";

        IERC1155CreatorCore(creatorContract).mintExtensionNew(
            to,
            amounts,
            uris
        );
    }

    // ====================== Creator Admin Functions ====================== //

    /**
     * @notice withdraw Creator balance.
     */
    function withdrawCreatorBalance() external nonReentrant {
        uint256 balanceToWithdraw = creatorBalance[msg.sender];
        creatorBalance[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: balanceToWithdraw}(
            ""
        );
        require(success);
    }

    /**
     * @notice update the tokenURI of a Creation. Only the Creator of a Creation can update its tokenURI.
     * @param _tokenId of the Creation you want to update
     * @param _newTokenURI of the Creation
     */
    function updateCreationTokenURI(
        uint256 _tokenId,
        string memory _newTokenURI
    ) external {
        Creation storage creation = tokenIdToCreation[_tokenId];
        if (msg.sender != creation.creatorAddress) revert NotCreator();
        creation.tokenURI = _newTokenURI;
    }

    /**
     * @notice update the creatorAddress for a given Creation. Only the Creator of a Creation can update its creator address.
     * @param _tokenId of the Creation you want to update
     * @param _newCreatorAddress of the Creation
     */
    function updateCreationCreatorAddress(
        uint256 _tokenId,
        address _newCreatorAddress
    ) external {
        Creation storage creation = tokenIdToCreation[_tokenId];
        if (msg.sender != creation.creatorAddress) revert NotCreator();
        creation.creatorAddress = _newCreatorAddress;
    }

    /**
     * @notice update the isFree parameter for a given Creation. Only the Creator of a Creation can update whether a Creation is free or not.
     * @param _tokenId of the Creation you want to update
     * @param _isFree parameter of the Creation
     */
    function updateCreationIsFree(uint256 _tokenId, bool _isFree) external {
        Creation storage creation = tokenIdToCreation[_tokenId];
        if (msg.sender != creation.creatorAddress) revert NotCreator();
        creation.isFree = _isFree;
    }

    /**
     * @notice update the isPublicMint parameter for a given Creation. Only the Creator of a Creation can update whether a Creation is a public mint or not.
     * @param _tokenId of the Creation you want to update
     * @param _isPublicMint parameter of the Creation
     */
    function updateCreationIsPublicMint(
        uint256 _tokenId,
        bool _isPublicMint
    ) external {
        Creation storage creation = tokenIdToCreation[_tokenId];
        if (msg.sender != creation.creatorAddress) revert NotCreator();
        creation.isPublicMint = _isPublicMint;
    }

    // ====================== View Functions ====================== //
    /**
     * @notice get a list of all Creations created by the given Creator.
     * @param _creator whose Creations you want
     */
    function getCreations(
        address _creator
    ) public view returns (Creation[] memory) {
        Creation[] memory creations = new Creation[](numCreations);

        for (uint256 i = 0; i < numCreations; i++) {
            Creation memory creation = tokenIdToCreation[i + 1];
            if (_creator == creation.creatorAddress) {
                creations[i] = creation;
            }
        }

        return creations;
    }

    /**
     * @notice get a list of all Creations.
     */
    function getAllCreations() public view returns (Creation[] memory) {
        Creation[] memory creations = new Creation[](numCreations);

        for (uint256 i = 0; i < numCreations; i++) {
            Creation memory creation = tokenIdToCreation[i + 1];
            creations[i] = creation;
        }

        return creations;
    }

    /**
     * @notice get the number of Creations.
     */
    function getNumCreations() public view returns (uint256) {
        return numCreations;
    }

    // ====================== Admin Functions ====================== //

    function setPriceOracle(address _priceOracle) external adminRequired {
        priceOracle = _priceOracle;
    }
}