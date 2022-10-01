//SPDX-License-Identifier: CC0
/**                       
 __    _____ _____ _____ 
|  |  |     |   __|_   _|
|  |__|  |  |__   | | |  
|_____|_____|_____| |_|  
                                                 
 _____ __    _____ _____ 
|     |  |  |  |  | __  |
|   --|  |__|  |  | __ -|
|_____|_____|_____|_____|
                                                
 _____ _____ __ __ _____ 
|_   _|     |  |  |   __|
  | | |  |  |_   _|__   |
  |_| |_____| |_| |_____|
Creator Collectionss  
*/
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 @title Lost CLub Toys Creator Collections ERC721 NFT Contract
 @author Calli_Kai
*/

contract LostClubToysCreatorCollections is
    ERC721Upgradeable,
    AccessControlUpgradeable
{
    using StringsUpgradeable for uint256;

    /* ========== INITIALIZER ========== */
    function initialize() public initializer {
        __ERC721_init("Lost Club Toys Creator Collections", "LCTCC");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        nextCollectionId = 1;
        COLLECTIONS_RESERVED_BLOCK = 1000000;
        contractURIString= "http://metadata.lostclubtoys.com/COLLECTIONS/COLLECTIONS.json";
    }

    /* ========== STATE VARIABLES ========== */

    //Permissions
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant NAMING_ROLE = keccak256("NAMING_ROLE");
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant PROJECTS_ADMIN = keccak256("PROJECT_ADMIN");

    //Contract
    string public baseURI;
    string public contractURIString;

    //Naming
    uint256 COLLECTIONS_RESERVED_BLOCK;
    uint256 nextCollectionId;

    //Minting
    uint256 public maxMintBatchSize;

    //
    mapping(uint256 => CreatorCollection) public creatorCollections;

    //Artist Struct
    struct CreatorCollection {
        string name;
        uint256 pricePerTokenInWei;
        string CollectionBaseURI;
        uint256 currentQuantity;
        uint256 totalPurchased;
        uint256 maxQuantity;
        uint256 maxTotalPurchaseable;
        uint256 activeBlock;
        uint256 maxPurchaseQuantityPerTX;
        bool paused;
    }

    /* ========== VIEW FUNCTIONS ========== */
    /**
     @notice Get Contract URI
     @dev 
     @return Contract URI
    */
    function contractURI() public view returns (string memory) {
        return contractURIString;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(
                creatorCollections[
                    uint256(tokenId) / uint256(COLLECTIONS_RESERVED_BLOCK)
                ].CollectionBaseURI
            ).length > 0
                ? string(
                    abi.encodePacked(
                        creatorCollections[
                            uint256(tokenId) / uint256(COLLECTIONS_RESERVED_BLOCK)
                        ].CollectionBaseURI,
                        StringsUpgradeable.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /**
     @notice Public Mint Functions
     @dev checks if activeblock has passed, funds, batch limit, and token limit
     @param _quantity Quantity of NFTs top mint
     @param _CollectionId Creator Collections ID to mint
    */
    function publicMint(uint256 _CollectionId, uint256 _quantity) public payable {
        require(
            block.number >= creatorCollections[_CollectionId].activeBlock,
            "Inactive"
        );

        require(!creatorCollections[_CollectionId].paused, "Collection Paused");

        require(
            _quantity <= creatorCollections[_CollectionId].maxPurchaseQuantityPerTX,
            "Exceeded max per TX purchase amount"
        );
        require(
            _quantity + creatorCollections[_CollectionId].totalPurchased <=
                creatorCollections[_CollectionId].maxTotalPurchaseable,
            "Exceeded max purchaseable amount"
        );
        require(
            creatorCollections[_CollectionId].currentQuantity + _quantity <=
                creatorCollections[_CollectionId].maxQuantity,
            "Purchase would exceed max supply of tokens"
        );
        require(
            creatorCollections[_CollectionId].pricePerTokenInWei * (_quantity) <=
                msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(
                msg.sender,
                (uint256(COLLECTIONS_RESERVED_BLOCK) * (_CollectionId)) +
                    creatorCollections[_CollectionId].currentQuantity++
            );

            creatorCollections[_CollectionId].currentQuantity++;
            creatorCollections[_CollectionId].totalPurchased++;
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function createCollection(
        string memory _name,
        uint256 _pricePerTokenInWei,
        string memory _CollectionBaseURI,
        uint256 _maxPurchaseQuantityPerTX,
        uint256 _maxTotalPurchaseable,
        uint256 _maxQuantity,
        uint256 _activeBlock
    ) public onlyRole(PROJECTS_ADMIN) {
        uint256 CollectionId = nextCollectionId;

        creatorCollections[CollectionId].name = _name;
        creatorCollections[CollectionId].pricePerTokenInWei = _pricePerTokenInWei;
        creatorCollections[CollectionId].CollectionBaseURI = _CollectionBaseURI;
        creatorCollections[CollectionId]
            .maxPurchaseQuantityPerTX = _maxPurchaseQuantityPerTX;
        creatorCollections[CollectionId].maxQuantity = _maxQuantity;
        creatorCollections[CollectionId].maxTotalPurchaseable = _maxTotalPurchaseable;
        creatorCollections[CollectionId].activeBlock = _activeBlock;
        creatorCollections[CollectionId].paused = false;
        nextCollectionId = nextCollectionId + 1;
    }

    function modifyCollection(
        uint256 _CollectionId,
        string memory _name,
        uint256 _pricePerTokenInWei,
        string memory _CollectionBaseURI,
        uint256 _maxPurchaseQuantityPerTX,
        uint256 _maxTotalPurchaseable,
        uint256 _maxQuantity,
        uint256 _activeBlock
    ) public onlyRole(PROJECTS_ADMIN) {
        creatorCollections[_CollectionId].name = _name;
        creatorCollections[_CollectionId].pricePerTokenInWei = _pricePerTokenInWei;
        creatorCollections[_CollectionId].CollectionBaseURI = _CollectionBaseURI;
        creatorCollections[_CollectionId]
            .maxPurchaseQuantityPerTX = _maxPurchaseQuantityPerTX;
        creatorCollections[_CollectionId].maxQuantity = _maxQuantity;
        creatorCollections[_CollectionId].maxTotalPurchaseable = _maxTotalPurchaseable;
        creatorCollections[_CollectionId].activeBlock = _activeBlock;
    }

    function claimMint(
        uint256 _CollectionId,
        uint256 _numberOfTokens,
        address _claimer
    ) public onlyRole(CLAIM_ROLE) {
        require(
            creatorCollections[_CollectionId].currentQuantity + _numberOfTokens <=
                creatorCollections[_CollectionId].maxQuantity,
            "Claim would exceed max supply of tokens"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _mint(
                _claimer,
                (uint256(COLLECTIONS_RESERVED_BLOCK) * (_CollectionId)) +
                    creatorCollections[_CollectionId].currentQuantity
            );

            creatorCollections[_CollectionId].currentQuantity++;
        }
    }

    /**
     @notice Set the base URI for all tokens
     @param _baseURI Base URI for all tokens to include trailing slash
    */
    function setBaseURI(string memory _baseURI)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        baseURI = _baseURI;
    }

    function setCollectionActiveBlock(uint256 _CollectionId, uint256 _activeBlock)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        creatorCollections[_CollectionId].activeBlock = _activeBlock;
    }

    function setCollectionPaused(uint256 _CollectionId, bool _paused)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        creatorCollections[_CollectionId].paused = _paused;
    }

    /**
     @notice Set the contract URI for contract level metadata
     @param _contractURI Contract metadata URI
    */
    function setContractURI(string memory _contractURI)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        contractURIString = _contractURI;
    }

    function setCollectionPrice(uint256 _CollectionId, uint256 _pricePerTokenInWei)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        creatorCollections[_CollectionId].pricePerTokenInWei = _pricePerTokenInWei;
    }

    /**
     @notice Sets active block for public sale
     @dev Requires `PROJECTS_ADMIN` permissions
     @param _CollectionId Collection ID
     @param _activeBlock Active blockheight of project
    */
    function setCollectionPublicSaleActiveBlock(
        uint256 _CollectionId,
        uint256 _activeBlock
    ) public onlyRole(PROJECTS_ADMIN) {
        creatorCollections[_CollectionId].activeBlock = _activeBlock;
    }

    /**
     @notice Sets max mint batch size
     @dev Requires `PROJECTS_ADMIN` permissions
     @param _maxMintBatchSize Max mint batch size
    */
    function setMaxMintBatchSize(uint256 _maxMintBatchSize)
        public
        onlyRole(PROJECTS_ADMIN)
    {
        maxMintBatchSize = _maxMintBatchSize;
    }

    /**
     @notice Withdraws funds to specified address
     @dev Requires `WITHDRAW_ROLE` permissions
     @param recipient Recipient of funds
     @param amount Amount of funds in Wei
    */
    function withdraw(address payable recipient, uint256 amount)
        public
        onlyRole(WITHDRAW_ROLE)
    {
        recipient.transfer(amount);
    }

    /* ========== INTERNAL ========== */

    /* ========== OVERRIDES ========== */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}