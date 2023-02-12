// "SPDX-License-Identifier: MIT"

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./libraries/Uint256Pagination.sol";
import "./libraries/Collections.sol";
import "./libraries/ExtraInfos.sol";
import "./libraries/Strings.sol";

contract ReameNFT is AccessControlUpgradeable, ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721EnumerableUpgradeable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Uint256Pagination for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;
    using Collections for Collections.Collection;
    using Collections for Collections.Collection[];
    using ExtraInfos for ExtraInfos.ExtraInfoV2;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    struct ExtraInfo 
    {
        uint256 launchTime;
        uint256 launchPrice;
        uint256 apr;
        uint256 rarity;
    }   

    modifier onlyMaintainer 
    {
        require(hasRole(MAINTAINER_ROLE, msg.sender), "Caller is not a maintainer");
        _;
    }

    modifier onlyCreator 
    {
        require(hasRole(CREATOR_ROLE, msg.sender), "Caller is not a creator");
        _;
    }

    modifier onlyAdmin 
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    uint256 public constant FEE_PERCENT_PRECISION = 1e18; // = 1%
    uint256 public constant MAX_LOYALTY_FEE_PERCENT = 10e18; // 10% 

    // token id => loyalty fee percent
    mapping(uint256 => uint256) public loyaltyFeePercent;

    // token id => creator address
    mapping(uint256 => address) public creators;
    
    // creator address => [token id]
    mapping(address => uint256[]) private creations;

    // token id => extra info
    mapping(uint256 => ExtraInfo) public extraInfo;
    
    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _collectionIdTracker;    

    // collection id => collection
    mapping(uint256 => Collections.Collection) public collectionMap;

    // creator address => [collection id]
    mapping(address => EnumerableSet.UintSet) private userCollections;

    // token id => collection id
    mapping(uint256 => uint256) public collections;

    // collection id => [token id]
    mapping(uint256 => EnumerableSet.UintSet) private tokensInCollection;

    function initialize(address _admin) 
        public initializer
    {
        __AccessControl_init_unchained();
        __ERC721_init("ReameNFT Shared Storefront", "ReameNFT");
        __ERC721URIStorage_init();
        __ReameNFT_init_unchained(_admin);
    }

    function __ReameNFT_init_unchained(address _admin)
        internal initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(CREATOR_ROLE, _admin);
        _setupRole(MAINTAINER_ROLE, _admin);
        _tokenIdTracker.increment(); // token id: start at 1
        _collectionIdTracker.increment(); // token id: start at 1
    }

    function _reamenftMint(
        address _creator,
        address _receiver,
        uint256 _loyaltyFeePercent, 
        string memory _uri, 
        uint256 _collectionId
    ) internal returns (uint256 _tokenId)
    {
        require(hasRole(CREATOR_ROLE, _creator), "user is not a creator");
        require(_loyaltyFeePercent <= MAX_LOYALTY_FEE_PERCENT, "loyalty fee is too high");        
        require(_collectionId == 0 || userCollections[_creator].contains(_collectionId), "invalid collection");
        _tokenId = _tokenIdTracker.current();
        creators[_tokenId] = _creator;
        collections[_tokenId] = _collectionId;
        creations[_creator].push(_tokenId);
        if (_collectionId != 0) {
            tokensInCollection[_collectionId].add(_tokenId);
        }
        loyaltyFeePercent[_tokenId] = _loyaltyFeePercent;
        _tokenIdTracker.increment();
        _safeMint(_receiver, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }

    function mint(uint256 _loyaltyFeePercent, string memory _uri, uint256 _collectionId)
        external onlyCreator returns (uint256 _tokenId)
    {        
        _tokenId = _reamenftMint(msg.sender, msg.sender, _loyaltyFeePercent, _uri, _collectionId);
        emit Mint(msg.sender, _tokenId, _collectionId, _uri, _loyaltyFeePercent);
    }

    function mintDelegate(
        address _creator,
        uint256 _loyaltyFeePercent, 
        string memory _uri, 
        uint256 _collectionId
    ) external onlyCreator returns (uint256 _tokenId) {        
        _tokenId = _reamenftMint(_creator, _creator, _loyaltyFeePercent, _uri, _collectionId);
        emit Mint(_creator, _tokenId, _collectionId, _uri, _loyaltyFeePercent);
    }

    function addCollection()
        external onlyCreator returns (uint256 _collectionId) 
    {
        _collectionId = _collectionIdTracker.current();
        collectionMap[_collectionId] = Collections.Collection({
            collectionId: _collectionId,
            owner: msg.sender
        });
        userCollections[msg.sender].add(_collectionId);
        _collectionIdTracker.increment();
        emit AddCollection(msg.sender, _collectionId);
    }

    function moveTokenToCollection(uint256 _tokenId, uint256 _newCollectionId)
        external onlyCreator
    {   
        uint256 _oldCollectionId = collections[_tokenId];
        require(_oldCollectionId != _newCollectionId, "same collection");
        require(_oldCollectionId == 0 || userCollections[msg.sender].contains(_oldCollectionId), "invalid collection");
        require(_newCollectionId == 0 || userCollections[msg.sender].contains(_newCollectionId), "invalid collection");
        collections[_tokenId] = _newCollectionId;
        if (_newCollectionId != 0) {
            tokensInCollection[_newCollectionId].add(_tokenId);
        }
        if (_oldCollectionId != 0) {
            tokensInCollection[_oldCollectionId].remove(_tokenId);
        }
        emit MoveTokenToCollection(msg.sender, _tokenId, _oldCollectionId, _newCollectionId);
    }

    function creationsOf(address _creator)
        public view returns (uint256[] memory)
    {
        return creations[_creator];
    }

    function creationsOf(address _creator, uint256 _page, uint256 _limit)
        external view returns (uint256[] memory)
    {
        return creationsOf(_creator).paginate(_page, _limit);
    }

    function currentTokenId()
        external view returns (uint256)
    {
        return _tokenIdTracker.current().sub(1);
    }

    function calculateRoyaltyFee(uint256 _tokenId, uint256 _amount)
        external view returns (uint256 _feeAmount)
    {
        _feeAmount = _amount.mul(loyaltyFeePercentOf(_tokenId))
            .div(FEE_PERCENT_PRECISION).div(100);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs://", super.tokenURI(tokenId)));
    }

    function creatorOf(uint256 _tokenId)
        external view returns (address)
    {
        return creators[_tokenId];
    }

    function loyaltyFeePercentOf(uint256 _tokenId)
        public view returns (uint256)
    {
        return loyaltyFeePercent[_tokenId];
    }

    function isCreator(address _user)
        external view returns (bool)
    {
        return hasRole(CREATOR_ROLE, _user);
    }

    function isMaintainer(address _user)
        external view returns (bool)
    {
        return hasRole(MAINTAINER_ROLE, _user);
    }

    function supportsInterface(bytes4 interfaceId) 
        public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    function grantCreator(address _creator) external onlyMaintainer {
        _setupRole(CREATOR_ROLE, _creator);
        emit GrantCreator(msg.sender, _creator);
    }

    function revokeCreator(address _creator) external onlyAdmin {
        revokeRole(CREATOR_ROLE, _creator);
        emit RevokeCreator(msg.sender, _creator);
    }

    function grantMaintainer(address _maintainer) external onlyAdmin {
        grantRole(MAINTAINER_ROLE, _maintainer);
    }

    function revokeMaintainer(address _maintainer) external onlyAdmin {
        revokeRole(MAINTAINER_ROLE, _maintainer);
    }

    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setTokenURI(uint256 _tokenId, string memory _uri) external onlyMaintainer {
        _setTokenURI(_tokenId, _uri);
        emit SetTokenURI(_tokenId, _uri);
    }

    event Mint(
        address indexed creator,
        uint256 indexed tokenId,
        uint256 indexed collectionId,
        string uri,
        uint256 loyaltyFeePercent
    );

    event AddCollection(
        address indexed creator,
        uint256 indexed collectionId
    );

    event GrantCreator(
        address indexed admin,
        address indexed user
    );

    event RevokeCreator(
        address indexed admin,
        address indexed user
    );

    event MoveTokenToCollection(
        address indexed creator,
        uint256 indexed tokenId,
        uint256 oldCollectionId,
        uint256 newCollectionId
    );

    event SetTokenURI(
        uint256 tokenId,
        string uri
    );

    uint256[49] private __gap;
}