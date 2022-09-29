//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./uniswap/IUniswapV2Router02.sol";
import "./BitHotelRoomCollection.sol";

/**@title Presale BitHotel smart contract
 * @author BitHotel Team
 */
 // solhint-disable-next-line max-states-count
contract PresaleBitHotelRoomCollectionBTH is AccessControl, ERC721Holder, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    struct GameNFT {
        BitHotelRoomCollection collection;
        uint256 tokenId;
        string uri;
        uint256 royaltyValue;
        uint256 price;
        uint256 discountPrice;
        bool valid;
    }

    struct CounterTokenId {
        Counters.Counter tokenIdCounter;
    }

    mapping(address => mapping(uint256 => GameNFT)) private _gameNfts; 
    mapping(address => uint256) private _bought;
    mapping(address => uint256) private _whitelistIndex;
    mapping(address => uint256) private _discountedIndex;
    mapping(address => CounterTokenId) private _counter;

    uint8 private constant _MAX_BUYS = 2;
    uint256 private _discountRate;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant DISCOUNTED_ROLE = keccak256("DISCOUNTED_ROLE");
    address[] private _whitelisted;
    address[] private _discounted;

    // Amount of BTH wei raised
    uint256 private _weiRaised;

    address private _wallet;
    uint256 private _globalRoyaltyValue;
    bool private _isWhitelistEnabled = true;

    IUniswapV2Router02 private _v2Router;
    address private _v2RouterAddress;
    address[] private _tokenPath;
    IERC20 private _bth;
    address private _bthAddress;
    address private _busdAddress;

    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    modifier maxBuys(address beneficiary) {
        // solhint-disable-next-line reason-string
        require(_bought[beneficiary] < _MAX_BUYS, "BitHotelRoomCollection: already bought MAX amount NFTs");
        _;
    }

    /**
     * @dev Event emitted when GameNFT is added.
     * @param collectionAddress the address of the nft collection
     * @param tokenId the token identification of the nft
     * @param uri ipfs uris of the nft
     * @param royaltyValue the royalty value for the team
     * @param price the price of the nft
     * @param discountPrice the discount price of the nft
     * @param valid true of false
     */
    event AddGameNFT(address collectionAddress, uint256 tokenId, string uri, uint256 royaltyValue, uint256 price, uint256 discountPrice, bool valid);
    event Claimed(address receiver, address contractAddress, uint256 tokenId);
     /**
     * @dev Event emitted when BTH token is received from beneficiary.
     */
    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);
    /**
     * @dev Event emitted when assets are deposited
     *
     * @param purchaser who deposit for the stablecoin/BTH
     * @param to where deposit forward to
     * @param token IERC20 stablecoin/BTH deposited
     * @param amount amount of tokens deposited
     */
    event Deposited(address indexed purchaser, address indexed to, address token, uint256 amount);

    constructor(
        address wallet_,
        address busdAddress,
        address bthAddress,
        uint256 globalRoyaltyValue_,
        uint256 discountRate_
    ){
        _wallet = wallet_;
        _busdAddress = busdAddress;
        _bthAddress = bthAddress;
        _bth = IERC20(bthAddress);
        _globalRoyaltyValue = globalRoyaltyValue_;
        _discountRate = discountRate_;

        //_v2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pancakeswap mainnet
        _v2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //pancakeswap TESTNET
        _v2RouterAddress = address(_v2Router);
        _tokenPath = new address[](2);
        _tokenPath[0] = busdAddress;
        _tokenPath[1] = bthAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, wallet_);
    }

    /**
     * @dev initializer will run after deploy the contract immediately.
     *
     * @param gameNfs set up the game collection NFTs 
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `gameNfs` can not be the empty array.
     * - `collectionAddress` within `gameNfs` input array can not be the zero address.
     * - `tokenId` within input array can not be the zero value.
     *
     */
    function initializer(GameNFT[] calldata gameNfs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(gameNfs.length > 0, "BitHotelRoomCollection: empty gameNfs");
        for(uint256 i = 0; i< gameNfs.length; i++) {
            address collectionAddress = address(gameNfs[i].collection);
            GameNFT storage gameNft = _gameNfts[collectionAddress][gameNfs[i].tokenId];
            // solhint-disable-next-line reason-string
            require(address(gameNft.collection) != address(0), "BitHotelRoomCollection: collection address is the zero address");
            // solhint-disable-next-line reason-string
            require(gameNft.tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
            addGameNft(
                collectionAddress,
                gameNft.tokenId,
                gameNft.uri,
                gameNft.royaltyValue,
                gameNft.price
           );
               
         }
    }

    /**
     * @dev remove whitelisted addresses.
     * @param whitelists array of addresses
     *
     * Requirements:
     *
     * - `whitelists` whitelists length cannot be 0.
     *
    */
    function bulkRemoveWhitelist(address[] calldata whitelists) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelists.length > 0, "BitHotelRoomCollection: empty whitelist");
        for (uint256 i = 0; i < whitelists.length; i++) {
            address whitelisted_ = whitelists[i];
            removeWhitelist(whitelisted_);
        }
    }

    /**
     * @dev remove discounted addresses.
     * @param discountedAddresses array of addresses
     *
     * Requirements:
     *
     * - `discountedAddresses` discountedAddresses length cannot be 0.
     *
    */
    function bulkRemoveDiscountedAddresses(address[] calldata discountedAddresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discountedAddresses.length > 0, "BitHotelRoomCollection: empty discountedAddres");
        for (uint256 i = 0; i < discountedAddresses.length; i++) {
            address discountedAddres = discountedAddresses[i];
            removeDiscounted(discountedAddres);
        }
    }

    /** 
     * @dev add multiple GameNFT in to Presale contract
     * @param tokenIds arrays of nft identifications
     * @param uris array of ipfs uris
     * @param royaltyValues array of royalty value, 
     *   if 0 then the smart contrac will use globalRoyaltyValue
     * @param prices array of bth prices of NFTs
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenIds` tokenIds length cannot be 0.
     * - `uris` uris length must be equal to tokenIds length.
     * - `royaltyValues` royaltyValues length must be equal to tokenIds length.
     * - `prices` prices length must be equal to tokenIds length.
     * - `tokenId` within `gameNfs` input array can not be the zero value.
     * - `price` within `gameNfs` input array can not be the zero value.
     *
    */
    function bulkAddGameNFTs(
        address collectionAddress, 
        uint256[] memory tokenIds,
        string[] memory uris,
        uint256[] memory royaltyValues,
        uint256[] memory prices
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenIds.length > 0, "BitHotelRoomCollection: empty nft");
        // solhint-disable-next-line reason-string
        require(tokenIds.length == uris.length, "BitHotelRoomCollection: invalid uri length");
        // solhint-disable-next-line reason-string
        require(tokenIds.length == royaltyValues.length, "BitHotelRoomCollection: invalid royaltyValues length");
        // solhint-disable-next-line reason-string
        require(tokenIds.length == prices.length, "BitHotelRoomCollection: invalid prices length");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 bthPrice = prices[i];
            // solhint-disable-next-line reason-string
            require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
            // solhint-disable-next-line reason-string
            require(bthPrice != 0, "BitHotelRoomCollection: price is zero");
            addGameNft(collectionAddress, tokenId, uris[i], royaltyValues[i], bthPrice);
        }
    }

    /** 
     * @dev set Room informations into collection contract
     *
     * @param collectionAddress the address of the nft collection
     * @param tokenId the token identification of the nft
     * @param number the room number of the nft
     * @param floorId the floorId of the room, on which floor is the room situated
     * @param roomTypeId the id of the room type
     * @param locked the ability to locked transfers of the nft
     * @param x the x position of the room within the floor
     * @param y the y position of the room within the floor
     * @param width the width of the room 
     * @param height the height of the room 
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenId` can not be the zero value.
     * - `collectionAddress` and `tokenId` must be added in `GameNFT`.
     *
    */
    function setRoomInfos(
        address collectionAddress,
        uint256 tokenId,
        uint256 number,
        string memory floorId,
        string memory roomTypeId,
        bool locked,
        uint8 x,
        uint8 y,
        uint32 width,
        uint32 height
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
        // solhint-disable-next-line reason-string
        require(exists(collectionAddress, tokenId), "BitHotelRoomCollection: tokenID does not exist in GameNFT");
        BitHotelRoomCollection(collectionAddress).setRoomInfos(tokenId, number, floorId, roomTypeId, locked, x, y, width, height);
    }

    function whitelisted() external view returns(address[] memory) {
        return _whitelisted;
    }

    function discounted() external view returns(address[] memory) {
        return _discounted;
    }

    function tokenPath() external view returns(address[] memory){
        return _tokenPath;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setDiscountRate(uint256 discountRate_) external onlyRole(DEFAULT_ADMIN_ROLE) {
         _discountRate = discountRate_;
    }

    function setWhitelistEnabled(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isWhitelistEnabled = value;
    }

    /** 
     * @dev lock trading for the specific nft
     *
     * @param collectionAddress the address of the nft collection
     * @param tokenId the nft identifications
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenId` can not be the zero value.
     * - `collectionAddress` and `tokenId` must added in `GameNFT`.
     *
     */
    function lockTokenId(address collectionAddress, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
        // solhint-disable-next-line reason-string
        require(exists(collectionAddress, tokenId), "BitHotelRoomCollection: tokenID does not exist in GameNFT");
        BitHotelRoomCollection(collectionAddress).lockTokenId(tokenId);
    }

    /** 
     * @dev lock trading for the specific nft
     *
     * @param collectionAddress the address of the nft collection
     * @param tokenId the nft identifications
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenId` can not be the zero value.
     * - `collectionAddress` and `tokenId` must added in `GameNFT`.
     *
     */
    function releaseLockedTokenId(address collectionAddress, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
        // solhint-disable-next-line reason-string
        require(exists(collectionAddress, tokenId), "BitHotelRoomCollection: tokenID does not exist in GameNFT");
        BitHotelRoomCollection(collectionAddress).releaseLockedTokenId(tokenId);
    }

    /**
    * @dev set whitelisted addresses.
    * @param whitelists array of addresses
    */
    function bulkWhitelist(address[] calldata whitelists) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelists.length > 0, "BitHotelRoomCollection: empty address");
        for (uint256 i = 0; i < whitelists.length; i++) {
            address whitelisted_ = whitelists[i];
            setWhitelist(whitelisted_);
        }
    }

    /**
    * @dev set bulk discounted addresses.
    * @param discountAddresses array of addresses
    */
    function bulkDiscounted(address[] calldata discountAddresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discountAddresses.length > 0, "BitHotelRoomCollection: empty address");
        for (uint256 i = 0; i < discountAddresses.length; i++) {
            address discounted_ = discountAddresses[i];
            setDiscountAddress(discounted_);
        }
    }

    /**
     * @dev See {IBitHotelRoomCollection-setController}.
     */
    function setController(address collectionAddress, address controller_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BitHotelRoomCollection(collectionAddress).setController(controller_);
    }

    function setToken(address token_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_bthAddress != token_, "PresaleBitHotel: token already set");
        _bth = IERC20(token_);
        _bthAddress = token_;
    }

    // PUBLIC 

    // testing
    function token() public view returns(address) {
        return _bthAddress;
    }

    function busd() public view returns(address) {
        return _busdAddress;
    }

    function router() public view returns(address) {
        return _v2RouterAddress;
    }

    function discountRate() public view returns(uint256) {
        return _discountRate;
    }

    function wallet() public view returns(address) {
        return _wallet;
    }

    function globalRoyaltyValue() public view returns(uint256) {
        return _globalRoyaltyValue;
    }

    /**
     * @return the amount of BTH wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function totalWhitelisted() public view returns(uint256) {
        return _whitelisted.length;
    }

    function totalDiscounted() public view returns(uint256) {
        return _discounted.length;
    }

    function getTokenIdByCollection(address collectionAddress) public view returns(uint256) {
        return _counter[collectionAddress].tokenIdCounter.current();
    }

    //return the index of whitelisted address
    function whitelistIndex(address whitelisted_) public view returns(uint256) {
        return _whitelistIndex[whitelisted_];
    }

    //return the index of discounted address
    function discountedIndex(address discountedAddress) public view returns(uint256) {
        return _discountedIndex[discountedAddress];
    }

    function bought(address beneficiary) public view returns (uint256) {
        return _bought[beneficiary];
    }

    function exists(address collectionAddress, uint256 tokenId) public view returns(bool) {
        return _gameNfts[collectionAddress][tokenId].tokenId == tokenId;
    }


    function getAmountsOut(uint256 amountIn)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _v2Router.getAmountsOut(amountIn, _tokenPath);
    }

    /**
     * @return the GameNFT storage information
     */
    function gameNFTbyTokenId(address collection, uint256 tokenId) public view returns(uint256, string memory, uint256, uint256, bool) {
        uint256 tokenId_ = _gameNfts[collection][tokenId].tokenId;
        string memory uri_ = _gameNfts[collection][tokenId].uri;
        uint256 royaltyValue = _gameNfts[collection][tokenId].royaltyValue;
        uint256 price = _gameNfts[collection][tokenId].price;
        bool valid = _gameNfts[collection][tokenId].valid;
        return (tokenId_, uri_, royaltyValue, price, valid);
    }

    /**
     * @return the discound bus price of the nft
     */
    function getDiscountPriceByTokenID(address collection, uint256 tokenId) public view returns(uint256) {
        return _gameNfts[collection][tokenId].discountPrice;
    }

    function isWhitelistEnabled() public view returns(bool) {
        return _isWhitelistEnabled;
    }

    /**
     * @dev set one whitelist address.
     * @param whitelist address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `whitelist` can not be the zero address.
     */
    function setWhitelist(address whitelist) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelist != address(0), "PresaleBitHotel: whitelisted is the zero address");
        if (!hasRole(WHITELISTED_ROLE, whitelist)) {
            uint256 index;
            index = totalWhitelisted() + 1; // mapping index starts with 1
            _whitelistIndex[whitelist] = index;
            _whitelisted.push(whitelist);
            _setupRole(WHITELISTED_ROLE, whitelist);
        }
    }

    /**
     * @dev set one discounted address.
     * @param discountAddress address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `discountAddress` can not be the zero address.
     */
    function setDiscountAddress(address discountAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discountAddress != address(0), "PresaleBitHotel: discountAddress is the zero address");
        if (!hasRole(DISCOUNTED_ROLE, discountAddress)) {
            uint256 index;
            index = totalDiscounted() + 1; // mapping index starts with 1
            _discountedIndex[discountAddress] = index;
            _discounted.push(discountAddress);
            _setupRole(DISCOUNTED_ROLE, discountAddress);
            // Discounted must have WHITELISTED_ROLE
            if (!hasRole(WHITELISTED_ROLE, discountAddress)) {
                setWhitelist(discountAddress);
            }
        }
    }

    /** 
     * @dev add one GameNFT in to Presale contract
     * @param tokenId the nft identifications
     * @param uri ipfs uris of the nft
     * @param royaltyValue the royalty value for the team, 
     *   if 0 then the smart contrac will use globalRoyaltyValue
     * @param price the BTH price of the NFT
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `collection` can not be the zero address.
     * - `tokenId` within can not be the zero value.
     * - `price` within must be greater than zero.
     *
     */
   function addGameNft(
       address collection,
       uint256 tokenId,
       string memory uri,
       uint256 royaltyValue,
       uint256 price
   ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collection != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is the zero value");
        // solhint-disable-next-line reason-string
        require(price > 0, "BitHotelRoomCollection: price is the zero value");
       
        if (royaltyValue == 0) {
            royaltyValue = globalRoyaltyValue();
        }

        uint256 weiPrice = price * 1 ether; // 18 decimals of BTH
        GameNFT storage gameNft = _gameNfts[collection][tokenId];
        gameNft.collection = BitHotelRoomCollection(collection);
        gameNft.tokenId = tokenId;
        gameNft.uri = uri;
        gameNft.royaltyValue = royaltyValue;
        gameNft.price = weiPrice;
        gameNft.discountPrice =  weiPrice - (weiPrice * discountRate() / 100);
        gameNft.valid = true;
        emit AddGameNFT(collection, tokenId, uri, royaltyValue, weiPrice, gameNft.discountPrice, gameNft.valid);
    }

    /**
     * @dev remove from whitelist.
     * @param whitelist address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `whitelist` must have WHITELISTED_ROLE.
     * - `whitelist` must have whitelisted mapping.
     */
    function removeWhitelist(address whitelist) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelist != address(0), "PresaleBitHotel: whitelisted is the zero address");
        // solhint-disable-next-line reason-string
        require(hasRole(WHITELISTED_ROLE, whitelist), "PresaleBitHotel: address not whitelisted");

        uint256 index = whitelistIndex(whitelist);
        // solhint-disable-next-line reason-string
        require(index > 0, "PresaleBitHotelRoomCollection: no whitelist index found in mapping");

        uint256 arrayIndex = index - 1;
        // solhint-disable-next-line reason-string
        require(arrayIndex >= 0, "PresaleBitHotelRoomCollection: array out-of-bounds");
        if(arrayIndex != _whitelisted.length - 1) {
            _whitelisted[arrayIndex] = _whitelisted[_whitelisted.length-1];
            _whitelistIndex[_whitelisted[arrayIndex]] = index;
        }
        _whitelisted.pop();
        delete _whitelistIndex[whitelist];
        _revokeRole(WHITELISTED_ROLE, whitelist);
    }

    /**
     * @dev remove from whitelist.
     * @param discounted_ address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `discounted_` must have DISCOUNTED_ROLE.
     * - `discounted_` must have discounted mapping.
     */
    function removeDiscounted(address discounted_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discounted_ != address(0), "PresaleBitHotel: discounted is the zero address");
        // solhint-disable-next-line reason-string
        require(hasRole(DISCOUNTED_ROLE, discounted_), "PresaleBitHotel: address not discounted");

        uint256 index = discountedIndex(discounted_);
        // solhint-disable-next-line reason-string
        require(index > 0, "PresaleBitHotelRoomCollection: no discounted index found in mapping");
        
        uint256 arrayIndex = index - 1;
        // solhint-disable-next-line reason-string
        require(arrayIndex >= 0, "PresaleBitHotelRoomCollection: array out-of-bounds");
        if(arrayIndex != _discounted.length - 1) {
            _discounted[arrayIndex] = _discounted[_discounted.length-1];
            _discountedIndex[_discounted[arrayIndex]] = index;
        }
        _discounted.pop();
        delete _discountedIndex[discounted_];
        _revokeRole(DISCOUNTED_ROLE, discounted_);
        if (hasRole(WHITELISTED_ROLE, discounted_)) {
            removeWhitelist(discounted_);
        }
    }

    function presetTokenIdByCollection(address collectionAddress, uint256 starWith) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(collectionAddress != address(0), "PresaleBitHotel: collection is the zero address");
        require(starWith > 0, "PresaleBitHotel: startwith is the zero value");
        for(uint i = 0; i < starWith; i++ ) {
            _nextTokenIdByCollection(collectionAddress);
        }
    }
  
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn"t be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     * @param bthAmount amount of the BTH token
     * @param collection address of the nft collection
     *
     * Requirements:
     *
     * - `token()` must have a token address.
     * - `beneficiary` cannot be the zero address.
     * - `bthAmount` cannot be the zero value.
     * - `collection` address cannot be the zero address.
     * - `tokenId` must exist in GameNFt storage.
     * - `bthAmount` must be the same as gameNFT bthAmount,
     *      if discounted must be the same as gameNFT discountPrice. 
     * - collection totalSupply must be smaller than replicas
     *   (there are still tokens available to mint)
     */
    function buy(address beneficiary, uint256 bthAmount, address collection) 
        external 
        nonReentrant 
        whenNotPaused
    {
        if (isWhitelistEnabled()) {
            // solhint-disable-next-line reason-string
            require(hasRole(WHITELISTED_ROLE, _msgSender()), "PresaleBitHotelRoomCollection: sender is not whitelisted");
            // solhint-disable-next-line reason-string
            require(_bought[_msgSender()] < _MAX_BUYS, "BitHotelRoomCollection: already bought MAX amount NFTs");
        }
        _preValidateBuy(beneficiary, bthAmount, collection);
        _nextTokenIdByCollection(collection);
        uint256 tokenId = getTokenIdByCollection(collection);
        _preValidateMint(collection, tokenId, bthAmount);
        address operator = _msgSender();
        

        uint256 balanceBefore = _bth.balanceOf(operator);
        // solhint-disable-next-line reason-string
        require(balanceBefore >= bthAmount, "PresaleBitHotelRoomCollection, not enough BTH token in beneficiary wallet");
    
        _receiveTokens(operator, bthAmount);
        emit Deposited(operator, wallet(), token(), bthAmount);

        _processMintNft(collection, beneficiary, tokenId);

         // update state       
        _weiRaised += bthAmount;
        _bought[operator] += 1;
    }

    /**
     * @dev Validation of an incoming buy. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Sale to extend their validations.
     * @param beneficiary Address performing the token purchase
     * @param bthAmount Value in wei involved in the purchase
     * @param collection address of the nft collection
     *
     * Requirements:
     *
     * - `beneficiary` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - `collection` address cannot be the zero address.
     */
    function _preValidateBuy(address beneficiary, uint256 bthAmount, address collection) internal virtual view {
        // solhint-disable-next-line reason-string
        require(token() != address(0), "PresaleBitHotel: token is the zero address");
        // solhint-disable-next-line reason-string
        require(beneficiary != address(0), "PresaleBitHotel: beneficiary is the zero address");
        require(bthAmount != 0, "PresaleBitHotel: bthAmount is 0");
         // solhint-disable-next-line reason-string
        require(collection!= address(0), "PresaleBitHotel: collection address is the zero address");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

     /**
     * @dev Validation of an incoming minting. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Sale to extend their validations.
     * @param collection address of the nft collection
     * @param tokenId The id of the nft
     * @param bthAmount amount of the stable coin
     *
     * Requirements:
     *
     * - `tokenId` must exist in GameNFt storage.
     * - `bthAmount` must be the same as gameNFT bthPrice,
     *      if discounted must be the same as gameNFT discountPrice. 
     * - `tokenId` not minted before
     * - collection totalSupply must be smaller than replicas
     *   (there are still tokens available to mint)
     *
     */
    function _preValidateMint(address collection, uint256 tokenId, uint256 bthAmount) internal virtual view {
        // solhint-disable-next-line reason-string
        require(exists(collection, tokenId), "PresaleBitHotel: tokenId not yet added to GameNFT");
        if (hasRole(DISCOUNTED_ROLE, _msgSender())) {
            uint256 discountPrice = getDiscountPriceByTokenID(collection, tokenId);
            // solhint-disable-next-line reason-string
            require(bthAmount == discountPrice, "PresaleBitHotel, bthAmount is not equal to discountPrice");
        } else {
            (,,, uint256 bthPrice,) = gameNFTbyTokenId(collection, tokenId);
            // solhint-disable-next-line reason-string
            require(bthAmount == bthPrice, "PresaleBitHotel, bthAmount is not equal to bthPrice");
        }
        bool exists_ = BitHotelRoomCollection(collection).exists(tokenId);
        // solhint-disable-next-line reason-string
        require(!exists_, "PresaleBitHotel: tokenId already minted");
        uint256 replicas = BitHotelRoomCollection(collection).replicas();
        uint256 totalSupply = BitHotelRoomCollection(collection).totalSupply();
        // solhint-disable-next-line reason-string
        require(totalSupply < replicas, "PresaleBitHotel: all tokens already minted.");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev SafeTransferFrom beneficiary. Override this method to modify the way in which the sale ultimately gets and sends
    * its tokens.
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _receiveTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        _bth.safeTransferFrom(beneficiary, wallet(), tokenAmount);
    }

    /**
     * @dev Executed when a buy has been validated and is ready to be executed. Doesn"t necessarily mint
     *      nfts.
     * @param beneficiary Address receiving the tokens
     * @param collection address of the nft collection
     * @param tokenId The id of the nft
     */
    function _processMintNft(address collection, address beneficiary, uint256 tokenId) internal {
        _safeMint(beneficiary, collection, tokenId);
    }

    function _nextTokenIdByCollection(address collectionAddress) internal {
        _counter[collectionAddress].tokenIdCounter.increment();
    }

    /**
    * @dev mint of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
    * its tokens.
    * @param beneficiary Address performing the token purchase
    * @param collection address of the nft collection
    * @param tokenId The id of the nft
    */
    function _safeMint(
        address beneficiary,
        address collection,
        uint256 tokenId
        ) internal virtual {

        // get GameNFT by `tokenId`
        (,string memory uri, uint256 royaltyValue,,) = gameNFTbyTokenId(collection, tokenId);
        bytes memory data_ = "0x";
        BitHotelRoomCollection(collection).safeMint(
            beneficiary,
            tokenId,
            uri,
            wallet(), 
            royaltyValue,
            data_
        );
    }
}