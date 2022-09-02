// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./Utils.sol";

/// @author Bella
/// @title Bella Access Token Resel
/// @notice Smart contract to store, generate and manage the resale of existing access token for Bella messaging channels
contract BellaResell is Initializable, UUPSUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable, PausableUpgradeable {

    // ERR-1-BR		    NFT must not be zero-address
    // ERR-2-BR		    Price cannot be zero
    // ERR-3-BR		    Sender must be the seller of this item	da aggiungere
    // ERR-4-BR		    Invalid itemId
    // ERR-5-BR		    Buyer cannot be the seller
    // ERR-6-BR		    Overflow exception
    // ERR-7-BR		    nothing to withdraw
    // ERR-8-BR		    Withdraw not available for this address
    // ERR-9-BR		    newImplementation cannot be zero-address
    // ERR-10-BR		You must own the token
    // ERR-11-BR		Store must be approved as operator
    // ERR-12-BR		The supply is greater than balance
    // ERR-13-BR		Invalid address for nft contract
    // ERR-14-BR		Invalid supply
    // ERR-15-BR		Quantity greater than token supply
    // ERR-16-BR		Please submit required price of 
    // ERR-17-BR        Seller has still NFT to sell
    // ERR-18-BR        Item already closed
    // ERR-19-BR        Sender address not valid
    // ERR-20-BR        Seller address not valid
    // ERR-21-BR        NFT contract not valid
    // ERR-22-BR        Bella address not valid
    // ERR-23-BR        Backend address not valid

    using SafeMathUpgradeable for uint256;

    //Role
    bytes32 private constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    
    //State variables
    address private backendAddress;
    address private bellaAddress;
    address private utilsAddress;
    uint public feePercentage;
    uint public withdrawRoyaltyDelay;

    //Strings
    string private constant ERC721 = "ERC721";
    string private constant ERC1155 = "ERC1155";

    //Counter
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _itemId;
    CountersUpgradeable.Counter private _royaltyId;

    //struct
    struct Item {
        uint tokenId;
        address nftContract;
        address seller;
        uint supply;
        uint price;
        uint buyerFee;
        TokenType tokenType;
    }

    struct RoyaltyWithdraw {
        uint timestamp;
        uint royaltyAmount;
        address royaltyReceiper;
    }

    //Enum
    enum TokenType {
        ERC721,
        ERC1155
    }

    //event
    event ItemOnSale(
        uint indexed itemId,
        address indexed seller,
        uint tokenId,
        address nftContract,
        uint supply,
        uint price,
        uint feeBuyer,
        string tokenType
    );

    event ItemModified(
        uint indexed itemId,
        address indexed seller,
        uint tokenId,
        address nftContract,
        uint supply,
        uint price,
        uint feeBuyer,
        string tokenType
    );

    event ItemSold(
        uint indexed itemId, 
        address indexed seller, 
        address indexed owner, 
        uint tokenId, 
        uint price,
        uint availability,
        uint quantity,
        address royaltyReceiper,
        uint royaltyValue,
        uint royaltyId
    );

     event WithdrawPerformed(
        address indexed owner,
        uint256 amount
    );

    event ItemRemoved(
        uint indexed itemId
    );

    //Mapping
    mapping(uint => Item) public idToItem;
    mapping(address => uint) public pendingWithdrawals;
    mapping(uint => RoyaltyWithdraw) public pendingWithdrawalsRoyalty;

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        feePercentage = 400;
        withdrawRoyaltyDelay = 2 days;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// Public Functions

    /// Supports interface function.
    /// @notice supports interface function
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// External Functions

    /// Sell
    /// @param tokenId to put on sale
    /// @param nftContract address that has generate the token
    /// @param supply for the token (it works only with ERC1155)
    /// @param price for single token
    /// @notice generate an item to put on sale a specific token for the given supply
    function sell(
        uint tokenId, 
        address nftContract, 
        uint supply, 
        uint price) 
    external 
    nonReentrant 
    whenNotPaused
    {
        (bool __isERC721, string memory tokenType) = Utils(utilsAddress).validateSell(
            tokenId, 
            nftContract, 
            supply, 
            price, 
            msg.sender
            );

        uint itemId = _itemId.current();
        _itemId.increment();

        uint buyerFee = Utils(utilsAddress).calculateFee(price, feePercentage);

        if(__isERC721) {
            idToItem[itemId] = Item(
                tokenId,
                nftContract,
                msg.sender,
                1,
                price,
                buyerFee,
                TokenType.ERC721
            );
        } else {
            idToItem[itemId] = Item(
                tokenId,
                nftContract,
                msg.sender,
                supply,
                price,
                buyerFee,
                TokenType.ERC1155
            );
        }

        emit ItemOnSale(
            itemId,
            msg.sender,
            tokenId,
            nftContract,
            supply,
            price,
            buyerFee,
            tokenType
        );
    }

    /// Modify Item
    /// @param itemId to modify
    /// @param supply for the token (if setted to zero means that the token will not on sale)
    /// @param price for single token
    /// @notice modify an item on sale
    function modifyItem(
        uint itemId,
        uint supply, 
        uint price) 
    external 
    nonReentrant 
    whenNotPaused
    {
        Item memory item = idToItem[itemId];
        require(msg.sender == item.seller, "ERR-3-BR");
        (bool __isERC721, string memory tokenType) = Utils(utilsAddress).validateModify(
            item.tokenId, 
            item.nftContract, 
            supply, 
            price, 
            msg.sender);
        
        uint buyerFee = Utils(utilsAddress).calculateFee(price, feePercentage);

        if(__isERC721) {
            idToItem[itemId] = Item(
                item.tokenId,
                item.nftContract,
                msg.sender,
                supply,
                price,
                buyerFee,
                TokenType.ERC721
            );
        } else {
            idToItem[itemId] = Item(
                item.tokenId,
                item.nftContract,
                msg.sender,
                supply,
                price,
                buyerFee,
                TokenType.ERC1155
            );
        }

        emit ItemModified(
            itemId,
            msg.sender,
            item.tokenId,
            item.nftContract,
            supply,
            price,
            buyerFee,
            tokenType
        );
    }

    /// Buy
    /// @param itemId to buy
    /// @param quantity how much token what to buy for the specific token
    /// @notice transfer the token to the buyer and update the withdraw mapping
    function buy(uint itemId, uint quantity) 
        external 
        payable 
        nonReentrant 
        whenNotPaused
    {
        require(itemId < _itemId.current(), "ERR-4-BR");

        Item memory item = idToItem[itemId];
        uint requiredValue = Utils(utilsAddress).validateBuy(
            msg.sender, 
            item.seller, 
            quantity, 
            item.supply, 
            item.price, 
            msg.value);

        idToItem[itemId].supply -= quantity;

        (uint royaltyAmount, address receiptReceiver) = Utils(utilsAddress).isERC2981(
            item.nftContract, 
            item.tokenId, 
            item.price
            );

        //Update pending withdraw
        uint fees = item.buyerFee.mul(quantity);
        royaltyAmount = royaltyAmount.mul(quantity);
        if(receiptReceiver == item.seller) {
            pendingWithdrawals[item.seller] += msg.value - fees;
        } else {
            pendingWithdrawals[item.seller] += msg.value - fees - royaltyAmount;
        }
        pendingWithdrawals[bellaAddress] += fees;


        //Update pending withdraw for royalty
        uint royaltyId = 0;
        if(receiptReceiver != address(0) 
            && receiptReceiver != item.seller 
            && royaltyAmount > 0) 
        {
            _royaltyId.increment();
            royaltyId = _royaltyId.current();

            pendingWithdrawalsRoyalty[royaltyId] = RoyaltyWithdraw(
                block.timestamp + withdrawRoyaltyDelay,
                royaltyAmount,
                receiptReceiver
                );   
        }

        emit ItemSold(
            itemId, 
            item.seller, 
            msg.sender, 
            item.tokenId, 
            requiredValue,
            idToItem[itemId].supply,
            quantity,
            receiptReceiver,
            royaltyAmount,
            royaltyId
        );

        //Transfer token
        if(item.tokenType == TokenType.ERC721) {
            IERC721Upgradeable(item.nftContract).safeTransferFrom(item.seller, msg.sender, item.tokenId);
        } else if(item.tokenType == TokenType.ERC1155) {
            IERC1155Upgradeable(item.nftContract).safeTransferFrom(item.seller, msg.sender, item.tokenId, quantity, "");
        }
    }

    /// Withdraw
    /// @notice to withdraw sales revenue
    function withdraw() 
        external 
        nonReentrant
    {
        if (pendingWithdrawals[msg.sender] == 0){
            revert("ERR-7-BR");
        }        
        uint amount = pendingWithdrawals[msg.sender];
        emit WithdrawPerformed(msg.sender, amount);
        
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /// External Functions - ONLY DEFAULT ADMIN ROLE

    /// Set Withdraw Royalty
    /// @param _withdrawRoyaltyDelay new value fro roaylty delay, for example 1 day = 64800
    /// @notice update the value for withdrawDelay callable by admin only
    function setWithdrawRoyaltyDelay(uint _withdrawRoyaltyDelay) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        withdrawRoyaltyDelay = _withdrawRoyaltyDelay;
    }

    /// Set Backend Address 
    /// @param _backendAddress new backendAddress
    /// @notice update the address for backend and gives role
    function setBackendAddress(address _backendAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_backendAddress != address(0), "ERR-23-BR");
        backendAddress = _backendAddress;
        grantRole(BACKEND_ROLE, _backendAddress);
    }

    /// Initialize Bella address
    /// @param _bellaAddress the Bella wallet address
    /// @notice store the address of Bella's wallet, caller MUST be the owner of the contract
    function setBellaAddress(address _bellaAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_bellaAddress != address(0), "ERR-22-BR");
        bellaAddress=_bellaAddress;        
    }

    /// Set Backend Address 
    /// @param _utilsAddress new address
    /// @notice update the address
    function setUtilsAddress(address _utilsAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        utilsAddress = _utilsAddress;
    }

    /// Set Fee Percentage 
    /// @param _feePercentage new feePercentage
    /// @notice update the feePercentage to apply to seller, for example 5% = 500
    function setFeePercentage(uint _feePercentage) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        feePercentage = _feePercentage;
    }

    /// Set Pause On 
    /// @notice pause the smart contract
    function pause()
        external
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _pause();
    }

    /// Set Pause Off 
    /// @notice unpause the smart contract
    function unpause()
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _unpause();
    }

    /// External Functions - ONLY BACKEND ROLE

    /// Withdraw Royalty
    /// @param royaltyId address to withdraw for royalty
    /// @notice to withdraw sales revenue
    function withdrawRoyalty(uint royaltyId) 
        external 
        nonReentrant
        onlyRole(BACKEND_ROLE)
    {
        if(block.timestamp < pendingWithdrawalsRoyalty[royaltyId].timestamp) {
            revert("ERR-8-BR");
        }
        if(pendingWithdrawalsRoyalty[royaltyId].royaltyAmount == 0) {
            revert("ERR-7-BR");
        }
        if(pendingWithdrawalsRoyalty[royaltyId].royaltyReceiper == address(0)) {
            revert("ERR-7-BR");
        }
        uint amount = pendingWithdrawalsRoyalty[royaltyId].royaltyAmount;
        address royaltyReceiper = pendingWithdrawalsRoyalty[royaltyId].royaltyReceiper;
        emit WithdrawPerformed(pendingWithdrawalsRoyalty[royaltyId].royaltyReceiper, pendingWithdrawalsRoyalty[royaltyId].royaltyAmount);


        pendingWithdrawalsRoyalty[royaltyId].royaltyAmount = 0;
        pendingWithdrawalsRoyalty[royaltyId].timestamp = 0;
        pendingWithdrawalsRoyalty[royaltyId].royaltyReceiper = address(0);
        
        payable(royaltyReceiper).transfer(amount);
    }

    /// Remove Item
    /// @param itemId to close
    /// @notice let to the backend to close an item (only if his actually has not enough supply for the token who want to sell)
    function removeItem(uint itemId) 
        external 
        onlyRole(BACKEND_ROLE) 
    {
        require(itemId < _itemId.current(), "ERR-4-BR");

        Item memory item = idToItem[itemId];
        Utils(utilsAddress).validateRemoveItem(
            item.supply, 
            item.nftContract, 
            item.tokenId, 
            item.seller
            );

        idToItem[itemId].supply = 0;

        emit ItemRemoved(
            itemId
        );     
    }

    /// Internal Functions

    /// Authorize Updgrade
    /// @param newImplementation address to call for new version
    /// @notice define how to authorize smart contract upgrade. The upgradea can be called only by admin and the new address cannot be zero-address 
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        view 
    {
        require(newImplementation != address(0), "ERR-9-BR");
    }

}