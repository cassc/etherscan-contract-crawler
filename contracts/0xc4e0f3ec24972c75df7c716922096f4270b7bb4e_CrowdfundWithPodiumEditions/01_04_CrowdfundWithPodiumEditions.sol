// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {ERC721} from "../../../external/ERC721.sol";
import {ICrowdfundWithPodiumEditions} from "./interface/ICrowdfundWithPodiumEditions.sol";

/**
 * @title CrowdfundWithPodiumEditions
 * @author MirrorXYZ
 */
contract CrowdfundWithPodiumEditions is ERC721, ICrowdfundWithPodiumEditions {
    // ============ Constants ============

    string public constant name = "Crowdfunded Mirror Editions";
    string public constant symbol = "CROWDFUND_EDITIONS";

    bytes32 public constant PRODUCER_TYPE = "0x123123";

    uint256 internal constant REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant REENTRANCY_ENTERED = 2;

    // ============ Setup Storage ============

    // The CrowdfundFactory that is able to create editions.
    address public editionCreator;

    // ============ Mutable Storage ============

    // Mapping of edition id to descriptive data.
    mapping(uint256 => Edition) public editions;
    // Mapping of token id to edition id.
    mapping(uint256 => uint256) public tokenToEdition;
    // The contract that is able to mint.
    mapping(uint256 => address) public editionToMinter;
    // `nextTokenId` increments with each token purchased, globally across all editions.
    uint256 private nextTokenId;
    // Editions start at 1, in order that unsold tokens don't map to the first edition.
    uint256 private nextEditionId = 1;
    // Reentrancy
    uint256 internal reentrancyStatus;
    // Administration
    address public owner;
    address public nextOwner;
    // Base URI can be modified by multisig owner, for intended future
    // migration of API domain to a decentralized one.
    string public baseURI;

    // ============ Events ============

    event EditionCreated(
        uint256 quantity,
        uint256 price,
        address fundingRecipient,
        uint256 indexed editionId
    );

    event EditionPurchased(
        uint256 indexed editionId,
        uint256 indexed tokenId,
        // `numSold` at time of purchase represents the "serial number" of the NFT.
        uint256 numSold,
        uint256 amountPaid,
        // The account that paid for and received the NFT.
        address buyer,
        address receiver
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event EditionCreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    modifier onlyMinter(uint256 editionId) {
        // Only the minter can call this function.
        // This allows us to mint through another contract, and
        // there not have to transfer funds into this contract to purchase.
        require(
            msg.sender == editionToMinter[editionId],
            "sender not allowed minter"
        );
        _;
    }

    // ============ Constructor ============

    constructor(string memory baseURI_, address owner_) {
        baseURI = baseURI_;
        owner = owner_;
    }

    // ============ Setup ============

    function setEditionCreator(address editionCreator_) external {
        require(editionCreator == address(0), "already set");
        editionCreator = editionCreator_;
        emit EditionCreatorChanged(address(0), editionCreator_);
    }

    // ============ Edition Methods ============

    function createEditions(
        EditionTier[] memory tiers,
        // The account that should receive the revenue.
        address payable fundingRecipient,
        // The address (e.g. crowdfund proxy) that is allowed to mint
        // tokens in this edition.
        address minter
    ) external override {
        // Only the crowdfund factory can create editions.
        require(msg.sender == editionCreator);
        // Copy the next edition id, which we reference in the loop.
        uint256 firstEditionId = nextEditionId;
        // Update the next edition id to what we expect after the loop.
        nextEditionId += tiers.length;
        // Execute a loop that created editions.
        for (uint8 x = 0; x < tiers.length; x++) {
            uint256 id = firstEditionId + x;
            uint256 quantity = tiers[x].quantity;
            uint256 price = tiers[x].price;
            bytes32 contentHash = tiers[x].contentHash;

            editions[id] = Edition({
                quantity: quantity,
                price: price,
                fundingRecipient: fundingRecipient,
                numSold: 0,
                contentHash: contentHash
            });

            editionToMinter[id] = minter;

            emit EditionCreated(quantity, price, fundingRecipient, id);
        }
    }

    function buyEdition(uint256 editionId, address recipient)
        external
        payable
        override
        onlyMinter(editionId)
        returns (uint256 tokenId)
    {
        return _buyEdition(editionId, recipient);
    }

    function _buyEdition(uint256 editionId, address recipient)
        internal
        returns (uint256 tokenId)
    {
        // Track and update token id.
        tokenId = nextTokenId;
        nextTokenId++;
        // Check that the edition exists. Note: this is redundant
        // with the next check, but it is useful for clearer error messaging.
        require(editions[editionId].quantity > 0, "Edition does not exist");
        // Check that there are still tokens available to purchase.
        require(
            editions[editionId].numSold < editions[editionId].quantity,
            "This edition is already sold out."
        );
        // Increment the number of tokens sold for this edition.
        editions[editionId].numSold++;
        // Mint a new token for the sender, using the `tokenId`.
        _mint(recipient, tokenId);
        // Store the mapping of token id to the edition being purchased.
        tokenToEdition[tokenId] = editionId;

        emit EditionPurchased(
            editionId,
            tokenId,
            editions[editionId].numSold,
            msg.value,
            msg.sender,
            recipient
        );

        return tokenId;
    }

    // ============ NFT Methods ============

    // Returns e.g. https://mirror-api.com/editions/[editionId]/[tokenId]
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // If the token does not map to an edition, it'll be 0.
        require(tokenToEdition[tokenId] > 0, "Token has not been sold yet");
        // Concatenate the components, baseURI, editionId and tokenId, to create URI.
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _toString(tokenToEdition[tokenId]),
                    "/",
                    _toString(tokenId)
                )
            );
    }

    // Returns e.g. https://mirror-api.com/editions/metadata
    function contractURI() public view override returns (string memory) {
        // Concatenate the components, baseURI, editionId and tokenId, to create URI.
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    // Given an edition's ID, returns its price.
    function editionPrice(uint256 editionId)
        external
        view
        override
        returns (uint256)
    {
        return editions[editionId].price;
    }

    // The hash of the given content for the NFT. Can be used
    // for IPFS storage, verifying authenticity, etc.
    function getContentHash(uint256 tokenId) public view returns (bytes32) {
        // If the token does not map to an edition, it'll be 0.
        require(tokenToEdition[tokenId] > 0, "Token has not been sold yet");
        // Concatenate the components, baseURI, editionId and tokenId, to create URI.
        return editions[tokenToEdition[tokenId]].contentHash;
    }

    function getRoyaltyRecipient(uint256 tokenId)
        public
        view
        returns (address)
    {
        require(tokenToEdition[tokenId] > 0, "Token has not been minted yet");
        return editions[tokenToEdition[tokenId]].fundingRecipient;
    }

    function setRoyaltyRecipient(
        uint256 editionId,
        address payable newFundingRecipient
    ) public {
        require(
            editions[editionId].fundingRecipient == msg.sender,
            "Only current fundingRecipient can modify its value"
        );

        editions[editionId].fundingRecipient = newFundingRecipient;
    }

    // ============ Admin Methods ============

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    // Allows the creator contract to be swapped out for an upgraded one.
    // NOTE: This does not affect existing editions already minted.
    function changeEditionCreator(address editionCreator_) public onlyOwner {
        emit EditionCreatorChanged(editionCreator, editionCreator_);
        editionCreator = editionCreator_;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        emit OwnershipTransferred(owner, msg.sender);

        owner = msg.sender;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    // ============ Private Methods ============

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}