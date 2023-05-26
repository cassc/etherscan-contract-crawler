// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/// @title CentBaseStorageBETA.
/// @author @Dadogg80 - Viken Blockchain Solutions.

/// @notice This is the storage contract containing all the global variables, custom errors, events, 
///         and modifiers inherited by the Centaurify NFT marketplace smart contract.       

contract CentBaseStorageBETA is ERC721Holder, Context, AccessControlEnumerable, ReentrancyGuard {

    /// @notice Enum Status is the different statuses.
    /// @param Listed means token is in our marketplace contract.
    /// @param Order means that a market order is live. 
    /// @param TimedAuction means that a timed auction is live.
    enum Status { Listed, Order, TimedAuction }

    /// @notice Escrow contract that holds the seller funds and pendingReturns.
    /// @return escrow The Escrow contract address.
    Escrow public escrow;

    /// @notice The account that will receive the service fee.
    /// @return serviceWallet The serivce wallet address.
    address payable public serviceWallet;

    /// @notice The service fee cost of listing in BIPS.
    /// @dev 200 BIPS is 2 percent. 
    uint16 public serviceFee; 

    /// @dev Array containing liveMarketItem id's.
    bytes32[] internal activeMarketItems; 

    /// @dev Array containing order ids.
    bytes32[] internal arrayOfOrderIds;

    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ITEM_CREATOR_ROLE = keccak256("ITEM_CREATOR_ROLE");
    bytes32 public constant BUYER_SERVICE_ROLE = keccak256("BUYER_SERVICE_ROLE");

    /// ------------------------------- STRUCTS -------------------------------

    /// @notice A marketItem is a listed token.
    /// @param itemId The uniqe id of this marketItem.
    /// @param tokenOwner The owner of this marketItem.
    /// @param operator The operator is this marketplace contract.
    /// @param escrow The escrow contract address. 
    /// @param nftContract The contract address of this marketItem.
    /// @param TokenId The tokenId of this marketItem.
    /// @param status The current status of this marketItem.
    struct MarketItem {
        bytes32 itemId;
        uint256 index;
        address payable tokenOwner;
        address operator;   
        Escrow escrow; 
        address nftContract;
        uint256 tokenId;
        Status status;
        bool active;
    }

    /// @notice A MarketOrder is a struct with info of a listed NFT token.
    /// @param orderId The id of this marketOrder.
    /// @param itemId The marketItem to sell as this MarketOrder.
    /// @param priceInWei The salesPrice of this MarketOrder.
    /// @param isOrder Is true if this MarketOrder is listed.
    /// @param sold Is true if this MarketOrder is sold.
    struct MarketOrder {
        bytes32 orderId;
        bytes32 itemId;           
        uint256 priceInWei;            
        bool isOrder;
        bool sold;
    }

    /// @notice A marketAuction struct is a marketItem that is in an ongoing timed auction.
    /// @param auctionId The id of the timed auction.
    /// @param itemId The id of the marketitem to sell on timed auction.
    /// @param auctionEndTime The timestamp to end the timed auction.
    /// @param highestBid The current highest bid.
    /// @param ended Is true if ended, false if ongoing.
    /// @param status The current status of this marketItem.
    struct MarketAuction {
        bytes32 auctionId; 
        bytes32 itemId; 
        uint256 auctionEndTime;
        uint256 highestBid;
        address highestBidder;
        bool ended;
    }

    /// ------------------------------- MAPPINGS -------------------------------

    /// @notice Mapping is used to store the MarketItems.
    mapping(bytes32 => MarketItem) public itemsMapping;

    /// @notice From ERC721 registry assetId to MarketOrder (to avoid asset collision).
    mapping(bytes32 => MarketOrder) public ordersMapping;
    
    /// @notice Mapping is used to store the MarketAuctions.
    /// @dev auctionId Pass a auctionId and get the MarketAuction in return. 
    mapping(bytes32 => MarketAuction) public auctionsMapping;

    /// @notice Maps token address to bool for either true (token is accepted as payment).
    mapping(address => bool) public acceptedTokenMap;

    /// @notice Maps user address to amount in pendingReturns.
    mapping(address => uint256) public pendingReturns;

    /// @notice mapping with approved collection addresses.
    mapping(address => bool) public approvedCollections;

    /// ------------------------------- MODIFIERS -------------------------------

    /// @notice Modifier will validate if the itemId is an active marketItem.
    /// @param itemId The itemId of the nft to validate. 
    modifier isActiveItem(bytes32 itemId) {
        MarketItem memory _item = itemsMapping[itemId];
        if (!_item.active) revert NotActive(_item.itemId);
        _;
    }

    /// @notice Modifier will validate if the orderId is an active market order.
    /// @param orderId The orderId of the order to validate. 
    modifier isActiveOrder(bytes32 orderId) {
        MarketOrder memory _order = ordersMapping[orderId];
        if (!_order.isOrder) revert NotActive(_order.orderId);
        _;
    } 

    /// @dev Modifier will validate that the marketItem is not already a live item.
    /// @param itemId The id of the marketItem.
    modifier isNotActive(bytes32 itemId) {
        MarketItem memory _item = itemsMapping[itemId];
        if (_item.active) revert IsActive(_item.itemId, _item.status);
        _;
    }

    /// @dev Modifier will validate if the caller is authorized.
    /// @param itemId The tokenId of the nft to validate.
    modifier isAuthorized(bytes32 itemId) {
        MarketItem memory _item = itemsMapping[itemId];
        if (_item.tokenOwner != _msgSender()) revert NotAuth();
        _;
    }

    /// @dev Modifier will validate if the caller is the seller.
    /// @param seller The account to validate.
    modifier isAuth(address payable seller) {
        if (seller != _msgSender()) revert NotAuth();
        _;
    }

    /// @notice Modifier will validate that the auctionId is a live auction.
    /// @param auctionId The id of the auction to bid on.
    modifier isLiveAuction(bytes32 auctionId) {
        MarketAuction memory _a = auctionsMapping[auctionId];
            if (_a.ended) revert NotActive(_a.auctionId);
        _;
    }

    /// @dev Modifier will validate that the bid is above current highest bid.
    /// @param auctionId The id of the auction to bid on.
    modifier minBid(bytes32 auctionId) {
        MarketAuction memory a = auctionsMapping[auctionId];
        if (msg.value <= a.highestBid) revert LowValue(a.highestBid);
        _;
    }

    /// @dev Modifier will validate that the costs are covered.
    /// @param status The item status, true if ORDER, false if AUCTION.
    /// @param id The id to identify the order/auction.
    modifier costs(bool status, bytes32 id) {
        if (status) {
            MarketOrder memory _order = ordersMapping[id];
            (uint256 serviceAmount, uint256 sellerAmount, ) = _calculateFees(
                _order.priceInWei
            );
            uint256 sum = (_order.priceInWei + serviceAmount);
            if (msg.value < sum) revert LowValue(sum);
        } else {
            MarketAuction memory _auction = auctionsMapping[id];
            (uint256 serviceAmount, uint256 sellerAmount, ) = _calculateFees(
                _auction.highestBid
            );
            uint256 sum = (_auction.highestBid + serviceAmount);
            if (msg.value < sum) revert LowValue(sum);
        }
    _;
    }

    /// ------------------------------- CUSTOM ERRORS -------------------------------

    /// @notice Thrown if 0 is passed as a value.
    error NoZeroValues();

    /// @notice Thrown if caller is not authorized.
    error NotAuth();
   
    /// @notice Thrown if caller is not authorized Role.
    error NotAuthorizedRole();
 
    /// @notice Thrown if caller is not authorized or owner of the token.
    error NotTokenOwner();

    /// @notice Thrown if the msg.value is to low to transact.
    /// @param expected The expected value.
    error LowValue(uint256 expected);

    /// @notice Thrown if the marketItem is not an active market item.
    /// @param id The Id of the market Item.
    error NotActive(bytes32 id);

    /// @notice Thrown if the market item is already a active order or auction.
    /// @param itemId The Id of the market Item.
    /// @param status The status of the market Item.
    error IsActive(bytes32 itemId, Status status);

    /// @notice Thrown if the NFT is already listed as market order.
    /// @param orderId The Id of the market order.
    error ActiveOrder(bytes32 orderId);
 
    /// @notice Thrown if the NFT is not listed as market order.
    /// @param orderId The Id of the market order.
    error NoListing(bytes32 orderId);

    /// @notice Thrown with a string message.
    /// @param message Error message string.
    error ErrorMessage(string message);

    /// @notice Thrown with a string message.
    /// @param failed Error message string describes what transaction failed.
    error FailedTransaction(string failed);

    /// @notice Thrown if the collection is not pre-approved.
    error CollectionNotApproved();

   /// ------------------------------- EVENTS -------------------------------

    /// @notice Emitted when a new marketItem is created.
    /// @param collection Indexed - The address of the collection.
    /// @param isApproved Indexed - The status of the collection.
    event CollectionApproved(
        address indexed collection,
        bool indexed isApproved
    );

    /// @notice Emitted when the serviceWallet is updated.
    /// @param serviceWallet Indexed - The new account to serve as service wallet.
    event ServiceWalletUpdated(
        address indexed serviceWallet
    );

    /// @notice Emitted when the serviceFee transaction is completed.
    /// @param serviceWallet Indexed - The account to receive the fee amount.
    /// @param amount The transacted fee amount.
    event TransferServiceFee(
        address indexed serviceWallet, 
        uint256 amount
    );

    /// @notice Emitted when the serviceFee transaction is completed.
    /// @param receiver Indexed - The account to receive the royalty amount.
    /// @param amount The transacted royalty amount.
    event TransferRoyalty(
        address indexed receiver, 
        uint256 amount
    );

    /// @notice Emitted when a new marketItem is created.
    /// @param itemId Indexed - The Id of this marketItem. 
    /// @param index Indexed - The index position of this marketItem in the "liveMarketItems" array.
    /// @param tokenOwner Indexed - The owner of this marketItem. 
    event MarketItemCreated(
        bytes32 indexed itemId,
        uint256 indexed index,
        address indexed tokenOwner
    );

    /// @notice Emitted when a new marketItem is removed.
    /// @param itemId Indexed - The Id of this marketItem. 
    /// @param tokenOwner Indexed - The owner of this marketItem. 
    event MarketItemRemoved(
        bytes32 indexed itemId,
        address indexed tokenOwner
    );

    /// @notice Emitted when a new marketOrder is created.
    /// @param orderId Indexed - The Id of this marketOrder.
    /// @param itemId Indexed - The marketItemId in this marketOrder. 
    /// @param priceInWei The salesprice nominated in wei.
    /// @param isOrder Indexed - Indicates if this an order or not. 
    event MarketOrderCreated(
        bytes32 indexed orderId,
        bytes32 indexed itemId,                
        uint256 priceInWei,              
        bool indexed isOrder
    );

    /// @notice Emitted when a marketOrder is sold.
    /// @param orderId The Id of this marketOrder.
    /// @param tokenId The tokenId of this marketOrder.
    /// @param priceInWei The salesprice nominated in wei.
    /// @param nftContract Indexed - The smartcontact of this nft.
    /// @param escrow The escrow contract containing the payment.
    /// @param seller Indexed - The seller of this marketOrder.
    /// @param buyer Indexed - The buyer of this marketOrder.
    event MarketOrderSold(
        bytes32 orderId,
        uint256 tokenId,
        uint256 priceInWei,
        address indexed nftContract,
        Escrow escrow,
        address indexed seller,
        address indexed buyer
    );

    /// @notice Emitted when a marketOrder is removed.
    /// @param orderId Indexed - The Id of this marketOrder.
    /// @param tokenOwner Indexed - The tokenOwner of this marketOrder.
    event MarketOrderRemoved(
        bytes32 indexed orderId, 
        address indexed tokenOwner
    );
    
    /// @notice Emitted on marketplace deployment, escrow is deployed by the constructor .
    /// @param escrow Indexed - The contract address of the escrow.
    /// @param operator Indexed - The account authorized to interact with the escrow contract.
    event EscrowDeployed(
        Escrow indexed escrow, 
        address indexed operator
    );

    /// @notice Emitted when a market item has been sold and funds are deposited into escrow.
    /// @param seller Indexed - The receiver of the funds.
    /// @param value The salesprice of the nft, minus the servicefee and royalty amount.
    event DepositToEscrow(
        address indexed seller, 
        uint256 value
    );

    /// @notice Emitted on withdrawals from the escrow contract.
    /// @param seller Indexed - The receiver of the funds.
    event WithdrawFromEscrow(
        address indexed seller
    );
    
    /// @notice Emitted when a new timed auction is created.
    /// @param auctionId Indexed - The auction Id.
    /// @param itemId Indexed - The marketItemId in this auction. 
    /// @param seller Indexed - The seller of this nft.
    event MarketAuctionCreated(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId, 
        address indexed seller
    );
    
    /// @notice Emitted when an auction is claimed.
    /// @param auctionId Indexed - The auctionId.
    /// @param itemId Indexed - The itemId of this auction.
    /// @param winner Indexed - The winner of the auction.
    /// @param amount The amount of the bid.
    event AuctionClaimed(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId, 
        address indexed winner, 
        uint256 amount
    );
    
    
    /// @notice Emitted when an auction is not sold.
    /// @param auctionId Indexed - The auctionId.
    /// @param itemId Indexed - The itemId of this auction.
    event NoBuyer(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId
    );

    /// @notice Emitted when an auction is removed.
    /// @param auctionId Indexed - The auctionId.
    /// @param itemId Indexed - The itemId of this auction.
    /// @param highestBidder Indexed - The winner of the auction.
    /// @param highestBid The highestBid of this auction.
    /// @param timestamp The timestamp when this event was emitted.
    event AuctionRemoved(
        bytes32 indexed auctionId, 
        bytes32 indexed itemId, 
        address indexed highestBidder,
        uint256 highestBid,
        uint256 timestamp
    );

    /// @notice Emitted when a higher bid is registered for an auction.
    /// @param auctionId Indexed - The auctionId.
    /// @param bidder Indexed - The receiver of the funds.
    /// @param amount The amount of the bid.
    event HighestBidIncrease(
        bytes32 indexed auctionId, 
        address indexed bidder, 
        uint256 amount
    );

    /// @notice Emitted on withdrawals from the marketplace contract.
    event Withdraw();

    /// @notice Emitted on withdrawals from the pending returns in escrow.
    /// @param to Indexed - The receiver of the funds.
    /// @param amount The withdraw amount.
    event WithdrawPendingReturns(
        address indexed to, 
        uint256 amount
    );

    /// @notice Emitted after an asset has been purchased and transfered to the new owner
    /// @param to Indexed - The receiver of the ntf.
    /// @param collection Indexed - The NFT smart contract address.
    /// @param tokenId Indexed - The tokenId.
    event AssetSent(
        address indexed to,
        address indexed collection,
        uint256 indexed tokenId
    );

    /// @notice Emitted when an item and order has been batch ready for sale.
    /// @param collection Indexed - The smartcontact address of this nft.
    /// @param seller Indexed - The seller of this marketOrder.
    /// @param tokenId The tokenId of this marketOrder.
    /// @param priceInWei The salesprice nominated in wei.
    /// @param itemId The Id of this marketItem.
    /// @param orderId Indexed - The Id of this marketOrder.
    event ListedForSale(
        address indexed collection, 
        address indexed seller, 
        uint256 tokenId, 
        uint256 priceInWei, 
        bytes32 itemId, 
        bytes32 indexed orderId
    );

    /// @notice Method used to check if the user is a HODLER of a specific nft collection.
    /// @param account The user account.
    /// @param collection The nft contract address to check.
    /// @return balance The amount of nft the user is HODLING.
    function isHodler(address account, address collection) external view returns (uint256 balance){
        return IERC721(collection).balanceOf(account);
    }

    /// @notice Method used to calculate the serviceFee to transfer.
    /// @param _priceInWei the salesPrice.
    /// @return serviceFeeAmount The amount to send to the service wallet.
    /// @return sellerAmount The amount to send to the seller.
    /// @return totalFeeAmount Includes service fee seller side, and service fee buyer side.
    function _calculateFees(uint _priceInWei)
        internal
        view
        returns 
    (
        uint serviceFeeAmount, 
        uint sellerAmount,
        uint totalFeeAmount
    )
    {
        serviceFeeAmount = (serviceFee * _priceInWei) / 10000;
        totalFeeAmount = (serviceFeeAmount * 2);
        sellerAmount = (_priceInWei - totalFeeAmount);
        return (serviceFeeAmount, sellerAmount, totalFeeAmount);
    }

    /// @notice Internal method used to deposit the salesAmount into the Escrow contract.
    /// @param tokenOwner The address of the seller of the MarketOrder.
    /// @param value The priceInWei of the listed order.
    function _sendPaymentToEscrow(address payable tokenOwner, uint256 value)
        internal
    {
        escrow.deposit{value: value}(tokenOwner);
        emit DepositToEscrow(tokenOwner, value);
    }


    /// @notice Internal method used to transfer the royalties and service fee.
    /// @param _item The MarketItem struct.
    /// @param _totalFeeAmount The _totalFeeAmount to transfer.
    /// @param _toSellerAmount The amount to transfer to escrow.
    function _transferRoyaltiesAndServiceFee(
        MarketItem memory _item, 
        uint256 _totalFeeAmount, 
        uint256 _toSellerAmount
    ) 
        internal 
    {

        (address _royaltyReceiver, uint256 _royaltyAmount) = 
            IERC2981(_item.nftContract)
                .royaltyInfo(_item.tokenId, _toSellerAmount);

        uint256 _toEscrow = (_toSellerAmount - _royaltyAmount); 

        (bool success,) = serviceWallet.call{value: _totalFeeAmount}(""); 
        if (!success) revert FailedTransaction("Fees");
        emit TransferServiceFee(serviceWallet, _totalFeeAmount);
        
        (bool _success,) = _royaltyReceiver.call{value: _royaltyAmount}(""); 
        if (!_success) revert FailedTransaction("Royalty");
        
        _sendPaymentToEscrow(_item.tokenOwner, _toEscrow);
        emit TransferRoyalty(_royaltyReceiver, _royaltyAmount);
    }

    /// @notice Allows a seller to withdraw their sales revenue from the escrow contract.
    /// @param seller The seller of the market item.
    /// @dev Only the seller can check their own escrowed balance.
    function withdrawSellerRevenue(address payable seller) public isAuth(seller) {
        _withdrawFromEscrow(seller);
    }

    /// --------------------------------- ESCROW METHODS ---------------------------------

    /// @notice Get the escrowed balance of a token seller.
    /// @dev Only the seller can check their own escrowed balance.
    /// @param seller The seller of a market item.
    /// @return balance The sellers balance in escrow. 
    function balanceInEscrow(address payable seller)external view returns (uint256 balance) {
        return escrow.depositsOf(seller);
    }

    /// @notice Internal method used to withdraw the salesAmount from the Escrow contract.
    /// @param seller The address of the seller of the MarketOrder.
    /// @dev Will also reset pendingReturn to 0.
    function _withdrawFromEscrow(address payable seller) internal {
        pendingReturns[seller] = 0;
        escrow.withdraw(seller);
        emit WithdrawFromEscrow(seller);
    }

    /// @notice Internal method used to send the nft asset to the new token Owner.
    /// @param itemId The itemId of to transfer.
    /// @param receiver The address to receiver the nft.
    function _sendAsset(bytes32 itemId, address receiver) internal {
        IERC721(itemsMapping[itemId].nftContract).safeTransferFrom(
            itemsMapping[itemId].operator,
            receiver,
            itemsMapping[itemId].tokenId
        );

        emit AssetSent(receiver, itemsMapping[itemId].nftContract, itemsMapping[itemId].tokenId);
    }

    function rescue(address collection, uint256[] calldata tokenIds, address receiver) external onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(collection).safeTransferFrom(address(this), receiver, tokenIds[i]);
        }
    }
        
}