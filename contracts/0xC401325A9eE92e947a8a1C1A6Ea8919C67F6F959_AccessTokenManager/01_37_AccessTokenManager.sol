// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./Utils.sol";
import "./AccessToken.sol";

/// @author Bella
/// @title Bella Access Token Manager
/// @notice Smart contract to store, generate and manage access token for Bella communities leveraging ERC1155 standards
contract AccessTokenManager is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable, PausableUpgradeable {

    // ERR-1-ATM		ChannelId cannot be empty
    // ERR-2-ATM		Buyer cannot be the channel creator
    // ERR-3-ATM		Please submit required price of:PRICE
    // ERR-4-ATM		tickets sold out
    // ERR-5-ATM		nothing to withdraw
    // ERR-6-ATM		Access Token address cannot be zero-address
    // ERR-7-ATM		Backend address cannot be zero-address
    // ERR-8-ATM		Creator address cannot be zero-address
    // ERR-9-ATM		Royalty cannot be greater than 100%
    // ERR-10-ATM		UriMetadata cannot be empty
    // ERR-11-ATM		Ticket supply must be greater than zero
    // ERR-12-ATM		CommunityId cannot be empty		
    // ERR-13-ATM		ChannelID already exists
    // ERR-14-ATM		newImplementation cannot be zero-address
    // ERR-15-ATM		Utils contract address cannot be zero-address
    // ERR-16-ATM		Bella address cannot be zero-address

    bytes32 private constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    
    address private utilsContract;
    address private backendAddress;
    address private bellaAddress;
    address private accessTokenContract;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    struct AccessTokenItem {
        uint tokenId;
        address payable creator;
        string uriMetadata;
        uint256 tickets;
        uint256 price;   
        uint256 feeCreator;
        uint256 feeBuyer;
        uint96 royaltyPercentage;
        uint256 finalPrice;
        string communityId;
    }   

    event AccessTokenPurchased(
        string channelId,
        uint indexed tokenId
    );

    event AccessTokenInitialized(
        uint tokenId,
        string channelId,
        address indexed creator,
        string uriMetadata,
        uint256 tickets,
        uint256 price, 
        uint256 feeCreator,
        uint256 feeBuyer,
        uint96 royaltyPercentage,
        uint256 finalPrice,
        string communityId
    );

    event WithdrawPerformed(
        address indexed owner,
        uint256 amount
    );

    mapping (string => AccessTokenItem) public idToAccessTokenItem;
    mapping (address => uint256) public pendingWithdrawals;

    uint public creatorFeePercentage;
    uint public buyerFeePercentage;
    uint public minBuyerFee;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // External functions

    /// Purchase a token of the `channelId`.
    /// @param channelId the channelId that user want to buy from
    /// @notice to purchase access token with fee managing
    function purchase(string memory channelId) 
        external 
        payable 
        nonReentrant 
        whenNotPaused
    {   
        AccessTokenItem memory accessToken = idToAccessTokenItem[channelId];        
        Utils(utilsContract).validatePurchase(
            Utils.PurchaseData(msg.sender, msg.value ,channelId, accessTokenContract, accessToken)
        );
        
        bool doLazyMint = false;

        if(accessToken.price > 0 ) {
            pendingWithdrawals[accessToken.creator] += accessToken.price - accessToken.feeCreator;
        }
        pendingWithdrawals[bellaAddress] += accessToken.feeCreator;
        pendingWithdrawals[bellaAddress] += accessToken.feeBuyer;

        if (accessToken.tokenId == 0) {
            accessToken.tokenId = _generateTokenId();
            doLazyMint = true;
        }

        idToAccessTokenItem[channelId] = accessToken;

        emit AccessTokenPurchased(channelId, idToAccessTokenItem[channelId].tokenId);

        if(doLazyMint) {
            AccessToken(accessTokenContract).lazyMint(
                accessToken.creator,
                accessToken.tickets,
                accessToken.royaltyPercentage,
                accessToken.uriMetadata,
                accessToken.tokenId,
                channelId
                );
        }
        
        IERC1155(accessTokenContract).safeTransferFrom(
            address(accessToken.creator),
            address(msg.sender), 
            accessToken.tokenId, 
            1,
            "");
    }

    /// Withdraw
    /// @notice to withdraw sales revenue
    function withdraw() 
        external 
        nonReentrant
    {
        if (pendingWithdrawals[msg.sender] == 0){
            revert("ERR-5-ATM");
        }        
        uint amount = pendingWithdrawals[msg.sender];
        emit WithdrawPerformed(msg.sender, amount);
        
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // External functions - only by backend role

    /// Initialize access token when chat is ready
    /// @param channelId channelId to store
    /// @param tickets supply for ERC1155 token associated
    /// @param price price (wei) for every ticket
    /// @param royaltyPercentage roalty percentage for this token
    /// @param uriMetadata metadata for associated token
    /// @param communityId associated to the access token
    /// @notice store all information on the blockchain to prepare the lazy mint, caller MUST be the backend wallet's address
    function initAccessToken(
        string memory channelId, 
        address creator, 
        uint256 tickets, 
        uint256 price, 
        uint96 royaltyPercentage, 
        string memory uriMetadata,
        string memory communityId
    )
        external 
        onlyRole(BACKEND_ROLE)
        whenNotPaused
    {
 
        Utils(utilsContract).validateInitAccessToken(
            Utils.InitAccessTokenData (
            channelId, creator, tickets, royaltyPercentage, uriMetadata, communityId,idToAccessTokenItem[channelId]
        ));

        (uint finalPrice,uint feeCreator,uint feeBuyer) = Utils(utilsContract).calculateFeesAndPrice(
            Utils.CalculateFeesAndPriceData(price, buyerFeePercentage, creatorFeePercentage, minBuyerFee)
        );
        idToAccessTokenItem[channelId] = AccessTokenItem(0, payable(creator), uriMetadata, tickets, price, feeCreator, feeBuyer, royaltyPercentage, finalPrice, communityId);
        emit AccessTokenInitialized(0, channelId, creator, uriMetadata, tickets, price, feeCreator, feeBuyer, royaltyPercentage, finalPrice, communityId);
    }

    // External function callable only once

    function initialize() 
        external 
        initializer 
    {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        creatorFeePercentage = 400; //4%
        buyerFeePercentage = 0; //0%
        minBuyerFee = 0;
    }

    // External functions - only by default admin role

    /// Initialize access token contract
    /// @param atc the accessToken address
    /// @notice store the address for access token smart contract, caller MUST be the admin
    function initAccessTokenContract(address atc) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(atc != address(0), "ERR-6-ATM");
        accessTokenContract=atc;
    }

    /// Initialize backend address and role
    /// @param ab the backend's wallet address
    /// @notice store the address of backend's wallet, caller MUST be the owner of the contract
    function initBackendAddress(address ab) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(ab != address(0), "ERR-7-ATM");
        backendAddress=ab;
        _setupRole(BACKEND_ROLE, ab);
    }

    /// Set Bella address
    /// @param _bellaAddress the Bella wallet address
    /// @notice store the address of Bella's wallet, caller MUST be the owner of the contract
    function setBellaAddress(address _bellaAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_bellaAddress != address(0), "ERR-16-ATM");
        bellaAddress=_bellaAddress;        
    }

    function initUtilsContract(address c) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(c != address(0), "ERR-15-ATM");
        utilsContract=c;
    }

    // External functions - only by bakcend role

    /// Set fee creator value
    /// @param percentage new fee value for creator of a channel
    /// @notice store the new value percentage for creator's fee, caller MUST be the backend
    function setCreatorFeePercentage(uint percentage) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        creatorFeePercentage = percentage;
    }

    /// Set fee buyer fee value.
    /// @param percentage new fee value for buyer
    /// @notice store the new value percentage for buyer's fee, caller MUST be the backend
    function setBuyerFeePercentage(uint percentage) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        buyerFeePercentage = percentage;
    }

    /// Set min default fee value.
    /// @param value new min default fee value for buyer
    /// @notice store the new value for  min default buyer's fee, caller MUST be the backend
    function setMinBuyerFee(uint value) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minBuyerFee = value;
    }

    // Internal View Functions

    /// Authorize Updgrade
    /// @param newImplementation address to call for new version
    /// @notice define how to authorize smart contract upgrade. The upgradea can be called only by admin and the new address cannot be zero-address 
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        view 
    {
        require(newImplementation != address(0), "ERR-14-ATM");
    }

    /// Set Pause On
    /// @notice pause the smart contract
    function pause()
        external 
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE){
            _pause();            
    }

    /// Set Pause Off
    /// @notice unpause the smart contract
    function unpause()
        external 
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE){
            _unpause();            
    }

    // Private Pure Functions


    /// GenerateTokenId
    /// @notice function that generate the tokenId by a counter
    function _generateTokenId() private returns(uint) {
        _tokenId.increment();
        return _tokenId.current();
    }

  
}