// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "./IERC721.sol";
import "./IPackWoodERC1155V1.sol";

abstract contract PackWoodERC721StorageV1 {
    // token count
    uint256 public tokenCounter;

    // token URI
    string internal _before;
    string internal _after;

    // ERC 1155 sereum contract address
    IPackWoodERC1155 public ERC1155Parent;

    // ERC721 monster bud contract address
    IERC721 public MonsterParent;
    
    // child monster breed Information
    struct breedInfomation {
        uint256 tokenId;
        uint256 breedCount;
        uint256 timstamp;
    }
    
    // mapping of token id with breed structure
    mapping(uint256 => breedInfomation) public breedInfo;

    // self breed order structure
    struct SelfBreed {
        uint256 req_token_id;
        uint256 accept_token_id;
        bytes32 signKey;
    }
    
    // SKT fee wallet
    address payable feeSKTWallet;
    
    //new item id
    uint256 internal newItemId;

    // breed status
    bool public selfBreedStatus;

    // breed value in ETH
    uint256 public breedValue;

    // ORDER structure
    struct Order {
        address buyer;
        address owner;
        uint256 token_id;
        string tokenUri;
        uint256 expiryTimestamp;
        uint256 price;
        bytes32 signKey;
        bytes32 signature;
    }

    // fee margin percent
    uint256 feeMargin;

    // purchase status
    bool buyONorOFFstatus;

    // community wallet address
    address SmartContractCommunity;

    // pfp value
    uint256 pfpValue;

    // check whether from generation one or not
    mapping(uint256 => bool) internal checkToken;

    // allowed address
    mapping(address => bool) public allowedAddress;

    // all function access to public
    bool public publicAccess;

    /**
     * @dev Emitted when new token is breed from same owners.
     */
    event breedSelf(
        address indexed selfAddress, // msg.sender address
        uint256 motherTokenId,
        uint256 donorTokenId,
        string tokenURI, // child seed uri
        uint256 newTokenId, // new minted child id
        uint256 sktFeePrice // fee to skt wallet
    );

    /**
     * @dev Emitted when new token is created.
     */ 
    event createChild(
        uint256 _monsterTokenId,
        uint256 _packwoodTokenId,
        uint256 childTokenId
    );

    /**
     * @dev Emitted when new token is purchased.
     */
    event buyTransfer(
        address indexed sellerAddress, // sender address
        address indexed buyerAddress, // buyer address
        uint256 indexed tokenId, // purchase token id
        uint256 price // price of token id
    );

    /**
     * @dev Emitted when pfp is added.
     */
    event PfpDetails(address tokenOwner, uint256 tokenId, uint256 price);

    /**
     * @dev Emitted when new token is breed from same owners.
     */
    event monsterPackwoodSelfBreed(
        address indexed selfAddress, // msg.sender address
        uint256 motherTokenId,
        uint256 donorTokenId,
        string tokenURI, // child seed uri
        uint256 newTokenId, // new minted child id
        uint256 sktFeePrice // fee to skt wallet
    );
}