// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./lib/StringsW0x.sol";
//import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "../interfaces/ICostManager.sol";
// import "../interfaces/IFactory.sol";
import "releasemanager/contracts/CostManagerHelperERC2771Support.sol";

import "./interfaces/ISafeHook.sol";
import "@artman325/community/contracts/interfaces/ICommunity.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./INFT.sol";

/**
* @dev
* Storage for any separated parts of NFT: NFTState, NFTView, etc. For all parts storage must be the same. 
* So need to extend by common contrtacts  like Ownable, Reentrancy, ERC721.
* that's why we have to leave stubs. we will implement only in certain contracts. 
* for example "name()", "symbol()" in NFTView.sol and "transfer()", "transferFrom()"  in NFTState.sol
*
* Another way are to decompose Ownable, Reentrancy, ERC721 to single flat contract and implement interface methods only for NFTMain.sol
* Or make like this 
* NFTStorage->NFTBase->NFTStubs->NFTMain, 
* NFTStorage->NFTBase->NFTState
* NFTStorage->NFTBase->NFTView
* 
* Here:
* NFTStorage - only state variables
* NFTBase - common thing that used in all contracts(for state and for view) like _ownerOf(), or can manageSeries,...
* NFTStubs - implemented stubs to make NFTMain are fully ERC721, ERC165, etc
* NFTMain - contract entry point
*/
abstract contract NFTStorage  is 
    IERC165Upgradeable, 
    IERC721MetadataUpgradeable,
    IERC721EnumerableUpgradeable, 
    ReentrancyGuardUpgradeable,
    CostManagerHelperERC2771Support,
    INFT
{
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;
    using StringsW0x for uint256;
    
    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Contract URI
    string internal _contractURI;    
    
    // Address of factory that produced this instance
    //address public factory;
    
    // Utility token, if any, to manage during operations
    //address public costManager;

    //address public trustedForwarder;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    // Array with all token ids, used for enumeration
    uint256[] internal _allTokens;
    
    mapping(uint64 => EnumerableSetUpgradeable.AddressSet) internal hooks;    // series ID => hooks' addresses

    // Constants for shifts
    uint8 internal constant SERIES_SHIFT_BITS = 192; // 256 - 64
    uint8 internal constant OPERATION_SHIFT_BITS = 240;  // 256 - 16
    
    // Constants representing operations
    uint8 internal constant OPERATION_INITIALIZE = 0x0;
    uint8 internal constant OPERATION_SETMETADATA = 0x1;
    uint8 internal constant OPERATION_SETSERIESINFO = 0x2;
    uint8 internal constant OPERATION_SETOWNERCOMMISSION = 0x3;
    uint8 internal constant OPERATION_SETCOMMISSION = 0x4;
    uint8 internal constant OPERATION_REMOVECOMMISSION = 0x5;
    uint8 internal constant OPERATION_LISTFORSALE = 0x6;
    uint8 internal constant OPERATION_REMOVEFROMSALE = 0x7;
    uint8 internal constant OPERATION_MINTANDDISTRIBUTE = 0x8;
    uint8 internal constant OPERATION_BURN = 0x9;
    uint8 internal constant OPERATION_BUY = 0xA;
    uint8 internal constant OPERATION_TRANSFER = 0xB;

    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 internal constant FRACTION = 100000;
    uint192 internal constant MAX_TOKEN_INDEX = type(uint192).max;
    
    string public baseURI;
    string public suffix;
    
//    mapping (uint256 => SaleInfoToken) public salesInfoToken;  // tokenId => SaleInfoToken

    struct FreezeInfo {
        bool exists;
        string baseURI;
        string suffix;
    }

    struct TokenInfo {
        SaleInfoToken salesInfoToken;
        FreezeInfo freezeInfo;
        uint256 hooksCountByToken; // hooks count
        uint256 allTokensIndex; // position in the allTokens array
        uint256 ownedTokensIndex; // index of the owner tokens list
        address owner; //owner address
        address tokenApproval; // approved address
    }

    struct TokenData {
        TokenInfo tokenInfo;
        SeriesInfo seriesInfo;
    }

    struct SeriesWhitelists {
        CommunitySettings transfer;
        CommunitySettings buy;
    }

    mapping (uint256 => TokenInfo) internal tokensInfo;  // tokenId => tokensInfo
    
    mapping (uint64 => SeriesInfo) public seriesInfo;  // seriesId => SeriesInfo

    mapping (uint64 => uint192) public seriesTokenIndex;  // seriesId => tokenIndex

    CommissionInfo public commissionInfo; // Global commission data 

    mapping(uint64 => uint256) public mintedCountBySeries;
    mapping(uint64 => uint256) internal mintedCountBySetSeriesInfo;

    mapping(uint64 => SeriesWhitelists) internal seriesWhitelists;
    
    // vars from ownable.sol
    address private _owner;

    struct SaleInfoToken { 
        SaleInfo saleInfo;
        uint256 ownerCommissionValue;
        uint256 authorCommissionValue;
    }
   
    struct CommunitySettings {
        address community;
        uint8 role;
    }

    event SeriesPutOnSale(
        uint64 indexed seriesId, 
        uint256 price, 
        uint256 autoincrement, 
        address currency, 
        uint64 onSaleUntil
    );

    event SeriesRemovedFromSale(
        uint64 indexed seriesId
    );

    event TokenRemovedFromSale(
        uint256 indexed tokenId,
        address account
    );

    event TokenPutOnSale(
        uint256 indexed tokenId, 
        address indexed seller, 
        uint256 price, 
        address currency, 
        uint64 onSaleUntil
    );
    
    event TokenBought(
        uint256 indexed tokenId, 
        address indexed seller, 
        address indexed buyer, 
        address currency, 
        uint256 price
    );

    event NewHook(
        uint64 seriesId, 
        address contractAddress
    );

    // event from ownable.sol
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    //stubs

    function approve(address/* to*/, uint256/* tokenId*/) public virtual override {revert("stub");}
    function getApproved(uint256/* tokenId*/) public view virtual override returns (address) {revert("stub");}
    function setApprovalForAll(address/* operator*/, bool/* approved*/) public virtual override {revert("stub");}
    function isApprovedForAll(address /*owner*/, address /*operator*/) public view virtual override returns (bool) {revert("stub");}
    function transferFrom(address /*from*/,address /*to*/,uint256 /*tokenId*/) public virtual override {revert("stub");}
    function safeTransferFrom(address /*from*/,address /*to*/,uint256 /*tokenId*/) public virtual override {revert("stub");}
    function safeTransferFrom(address /*from*/,address /*to*/,uint256 /*tokenId*/,bytes memory/* _data*/) public virtual override {revert("stub");}
    function safeTransfer(address /*to*/,uint256 /*tokenId*/) public virtual {revert("stub");}
    function balanceOf(address /*owner*/) public view virtual override returns (uint256) {revert("stub");}
    function ownerOf(uint256 /*tokenId*/) public view virtual override returns (address) {revert("stub");}
    function name() public view virtual override returns (string memory) {revert("stub");}
    function symbol() public view virtual override returns (string memory) {revert("stub");}
    function tokenURI(uint256 /*tokenId*/) public view virtual override returns (string memory) {revert("stub");}
    function tokenOfOwnerByIndex(address /*owner*/, uint256 /*index*/) public view virtual override returns (uint256) {revert("stub");}
    function totalSupply() public view virtual override returns (uint256) {revert("stub");}
    function tokenByIndex(uint256 /*index*/) public view virtual override returns (uint256) {revert("stub");}

    // Base
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        require(_ownerOf(tokenId) != address(0), "ERC721: approved query for nonexistent token");
        return tokensInfo[tokenId].tokenApproval;
    }
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner_ = __ownerOf(tokenId);
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }
    function __ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return tokensInfo[tokenId].owner;
    }
    function _isApprovedForAll(address owner_, address operator) internal view virtual returns (bool) {
        return _operatorApprovals[owner_][operator];
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokensInfo[tokenId].owner != address(0)
            && tokensInfo[tokenId].owner != DEAD_ADDRESS;
    }

    function _baseURIAndSuffix(
        uint256 tokenId
    ) 
        internal 
        view 
        returns(
            string memory baseURI_, 
            string memory suffix_
        ) 
    {
        
        if (tokensInfo[tokenId].freezeInfo.exists) {
            baseURI_ = tokensInfo[tokenId].freezeInfo.baseURI;
            suffix_ = tokensInfo[tokenId].freezeInfo.suffix;
        } else {

            uint64 seriesId = getSeriesId(tokenId);
            baseURI_ = seriesInfo[seriesId].baseURI;
            suffix_ = seriesInfo[seriesId].suffix;

            if (bytes(baseURI_).length == 0) {
                baseURI_ = baseURI;
            }
            if (bytes(suffix_).length == 0) {
                suffix_ = suffix;
            }
        }
    }
    
    function getSeriesId(
        uint256 tokenId
    )
        internal
        pure
        returns(uint64)
    {
        return uint64(tokenId >> SERIES_SHIFT_BITS);
    }

    function _getTokenSaleInfo(uint256 tokenId) 
        internal 
        view 
        returns
        (
            bool isOnSale,
            bool exists, 
            SaleInfo memory data,
            address owner_
        ) 
    {
        data = tokensInfo[tokenId].salesInfoToken.saleInfo;

        exists = _exists(tokenId);
        owner_ = tokensInfo[tokenId].owner;


        uint64 seriesId = getSeriesId(tokenId);
        if (owner_ != address(0)) { 
            if (data.onSaleUntil > block.timestamp) {
                isOnSale = true;
                
            } 
        } else {   
            
            SeriesInfo memory seriesData = seriesInfo[seriesId];
            if (seriesData.saleInfo.onSaleUntil > block.timestamp) {
                isOnSale = true;
                data = seriesData.saleInfo;
                owner_ = seriesData.author;

            }
        }   

        if (exists == false) {
            //using autoincrement for primarysale only
            data.price = data.price + mintedCountBySetSeriesInfo[seriesId] * data.autoincrement;
        }
    }

    // find token for primarySale
    function _getTokenSaleInfoAuto(
        uint64 seriesId
    ) 
        internal 
        returns
        (
            bool isOnSale,
            bool exists, 
            SaleInfo memory data,
            address owner_,
            uint256 tokenId
        ) 
    {
        SeriesInfo memory seriesData;
        for(uint192 i = seriesTokenIndex[seriesId]; i <= MAX_TOKEN_INDEX; i++) {
            tokenId = (uint256(seriesId) << SERIES_SHIFT_BITS) + i;

            data = tokensInfo[tokenId].salesInfoToken.saleInfo;
            exists = _exists(tokenId);
            owner_ = tokensInfo[tokenId].owner;

            if (owner_ == address(0)) { 
                seriesData = seriesInfo[seriesId];
                if (seriesData.saleInfo.onSaleUntil > block.timestamp) {
                    isOnSale = true;
                    data = seriesData.saleInfo;
                    owner_ = seriesData.author;
                    
                    if (exists == false) {
                        //using autoincrement for primarysale only
                        data.price = data.price + mintedCountBySetSeriesInfo[seriesId] * data.autoincrement;
                    }
                    
                    // save last index
                    seriesTokenIndex[seriesId] = i;
                    break;
                }
            } // else token belong to some1
        }

    }

    function _balanceOf(
        address owner_
    ) 
        internal 
        view 
        virtual 
        returns (uint256) 
    {
        require(owner_ != address(0), "ERC721: balance query for the zero address");
        return _balances[owner_];
    }

    ///////
    // // functions from context
    // function _msgSender() internal view virtual returns (address) {
    //     return msg.sender;
    // }

    // function _msgData() internal view virtual returns (bytes calldata) {
    //     return msg.data;
    // }
    function setTrustedForwarder(address forwarder) public virtual override {
        //just stub but must override
    }
    
    ///////
    // functions from ownable
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOnlyOwner() internal view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual {
        requireOnlyOwner();
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        requireOnlyOwner();
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    ///////
    // ERC165 support interface
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

}