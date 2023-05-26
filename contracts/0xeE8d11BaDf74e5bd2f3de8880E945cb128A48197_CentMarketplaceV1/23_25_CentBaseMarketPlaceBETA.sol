// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./CentBaseTimedAuctionBETA.sol";


/// @title CentMarketplaceV1.
/// @author @Dadogg80 - Viken Blockchain Solutions.

/// @notice This is the marketplace smartcontract with all the global variables, custom errors, events, 
///         and modifiers derived from the Centaurify TimedAuction and Storage smart contracts.     


contract CentMarketplaceV1 is CentBaseTimedAuctionBETA {
    using Counters for Counters.Counter;
    using ERC165Checker for address;
    
    Counters.Counter private _itemsIndex;
    Counters.Counter private _itemsSold;

    Counters.Counter private _orderIds;
    Counters.Counter private _ordersSold;

    /// @notice The constructor will set the serviceWallet address and deploy a escrow contract.
    /// @dev Will emit the event { EscrowDeployed }.
    constructor(address payable _serviceWallet, address _operator) {
        require(_serviceWallet != address(0));

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _operator);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ITEM_CREATOR_ROLE, _operator);

        serviceFee = 200;
        serviceWallet = _serviceWallet;
        escrow = new Escrow();

        emit EscrowDeployed(escrow, address(this));
    }

    /// @notice Creates an new MarketItem on the marketplace.
    /// @dev ATTENTION this function require approvals from `nftContract` to transfer tokenId
    /// @param nftContract Contract address of the nft to add to marketplace. 
    /// @param tokenId The tokenId the token to add on the marketplace.
    /// @param seller The address of the seller of this nft.
    /// @return itemId Will return the bytes32 marketItemId.
    function createMarketItem(address nftContract, uint256 tokenId, address payable seller) 
        public
        onlyRole(ITEM_CREATOR_ROLE)
        returns (bytes32 itemId) 
    {
        //if (seller != IERC721(nftContract).ownerOf(tokenId)) revert NotTokenOwner();
        return _createMarketItem(nftContract, tokenId, seller);
    }

    /// @notice Creates an new MarketOrder of a marketItem.
    /// @param itemId Id of the marketItem to create a market order. 
    /// @param priceInWei The sales price of this order.
    /// @return orderId Will return the bytes32 orderId. 
    function createMarketOrder(bytes32 itemId, uint256 priceInWei) 
        public
        nonReentrant
        isAuthorized(itemId)
        isNotActive(itemId)
        returns (bytes32)
    {
        MarketItem storage _item = itemsMapping[itemId];
        uint256 _priceInWei = priceInWei;
        
        if (_priceInWei <= 0) revert LowValue(_priceInWei);

        _orderIds.increment();
        bytes32 _orderId = bytes32(_orderIds.current());
        
        if (ordersMapping[_orderId].isOrder) revert ActiveOrder(_orderId);

        ordersMapping[_orderId] = MarketOrder(
            _orderId,
            _item.itemId,
            _priceInWei,
            true,
            false
        );

        _item.status = Status(1);
        _item.active = true;

        arrayOfOrderIds.push(_orderId);

        emit MarketOrderCreated(
            _orderId,
            _item.itemId,
            _priceInWei,
            true
        );

        return _orderId;
    }

    /// @notice Method used to purchase a marketOrder.
    /// @param one Requires the param to be bool true.
    /// @param orderId The id of the MarketOrder to purchase.
    function executeOrder(bool one, bytes32 orderId) 
        external 
        payable 
        isActiveOrder(orderId) nonReentrant 
        costs(one, orderId) 
    {
        _executeOrder(one, orderId, _msgSender());
    }

    /// @notice Method used to remove an order from listing on our marketplace.
    /// @dev Restricted to the {seller/tokenOwner} or the marketplace {owner} account.
    /// @dev Will emit the event { MarketOrderRemoved }.
    /// @param orderId The orderId to cancel.
    function cancelOrder(bytes32 orderId) 
        external 
        isActiveOrder(orderId)
        isAuthorized(ordersMapping[orderId].itemId)
    {
        bytes32 _orderId = orderId;
        bytes32 _itemId = ordersMapping[_orderId].itemId;
        MarketItem storage _item = itemsMapping[_itemId];

        ordersMapping[_orderId].isOrder = false;
        ordersMapping[_orderId].sold = false;

        _item.status = Status(0);
        _item.active = false;
        
        _orderRemove(_orderId);
        emit MarketOrderRemoved(_orderId, _msgSender());
    }

    /// @notice Method used to remove an item from our marketplace.
    /// @param itemId The itemId to remove.
    /// @dev Restricted to the {seller/tokenOwner} or the marketplace {owner} account.
    /// @dev Will emit the event { MarketItemRemoved }.
    function removeItem(bytes32 itemId) external isAuthorized(itemId) isNotActive(itemId) {
        _itemRemove(itemId);
        emit MarketItemRemoved(itemId, _msgSender());
    }

    /// @notice Get the market item.
    /// @param itemId The itemId to query .
    /// @return marketItem Returns the MarketItem struct.
    function getMarketItem(bytes32 itemId) external view returns (MarketItem memory) {
        return itemsMapping[itemId];
    }

    /// @notice Get the information regarding a specific orderId.
    /// @param orderId The orderId to query.
    /// @return marketOrder Returns the MarketOrder struct.
    function getMarketOrder(bytes32 orderId) external view returns (MarketOrder memory) {
        return ordersMapping[orderId];
    }

       /// @notice Internal method to fetch all the marketItems.
    /// @return activeMarketItems Returns an bytes32 array of all active marketItemIds.
    function fetchMarketItems() external view returns (bytes32[] memory){
        return activeMarketItems;
    }

    /// @notice Method used to fetch all the marketOrders.
    /// @return marketOrder Returns an array of all the active marketOrders structs.
    function fetchMarketOrders() external view returns (MarketOrder[] memory) {
        uint orderCount = _orderIds.current();
        uint unsoldOrderCount = _orderIds.current() - _ordersSold.current();
        uint currentIndex = 0;

        MarketOrder[] memory _orders = new MarketOrder[](unsoldOrderCount);
        for (uint i = 0; i < orderCount; i++) {
            bytes32 currentId = bytes32(i + 1);
            MarketOrder storage currentOrder = ordersMapping[currentId];
            if (currentOrder.isOrder) {
                _orders[currentIndex] = currentOrder;
                currentIndex += 1;
            }
            if (currentIndex == unsoldOrderCount) break;
        }
        return _orders;
    }

/// --------------------------------- PRIVATE METHODS ---------------------------------

    /// @notice Private method to remove/delete an MarketItem from the marketplace.
    /// @param itemId The id of the order to remove.
    function _itemRemove(bytes32 itemId) private {
        MarketItem memory _item = itemsMapping[itemId];
        if (_item.active) revert IsActive(itemId, itemsMapping[itemId].status);
        
        delete itemsMapping[itemId];

        IERC721(_item.nftContract).safeTransferFrom(
            address(this), 
            _item.tokenOwner, 
            _item.tokenId
        );
        
    }
    
    /// @notice Private method to remove/delete an MarketOrder from the marketplace.
    /// @param orderId The id of the order to remove.
    function _orderRemove(bytes32 orderId) private {
        if (ordersMapping[orderId].isOrder) revert ActiveOrder(orderId);
        delete ordersMapping[orderId];
    }

    /// @notice Private helper method used to purchase a marketOrder.
    /// @param one Requires the param to be bool true.
    /// @param orderId The id of the MarketOrder to purchase.
    /// @param buyer The address of the buyer
    function _executeOrder(bool one, bytes32 orderId, address buyer) private {
        if (one != true) revert ErrorMessage("Requires bool value: true");
        MarketOrder storage _order = ordersMapping[orderId];
        if (!_order.isOrder) revert NoListing(_order.orderId);
 
        _order.isOrder = false;
        _order.sold = true;       
        _ordersSold.increment();

        MarketItem storage _item = itemsMapping[_order.itemId];
        _item.status = Status(0);
        _item.active = false;

        (, uint256 _toSellerAmount, uint256 _totalFeeAmount) = _calculateFees(_order.priceInWei);

        _orderRemove(_order.orderId);
        
        (bool success) = IERC165(_item.nftContract).supportsInterface(_INTERFACE_ID_ERC2981);
        
        if (!success) {
            (bool _success,) = serviceWallet.call{value: _totalFeeAmount}("");
            if (!_success) revert FailedTransaction("Fees");
            _sendPaymentToEscrow(_item.tokenOwner, _toSellerAmount);
            emit TransferServiceFee(serviceWallet, _totalFeeAmount);
        
        } else {
            _transferRoyaltiesAndServiceFee(_item, _totalFeeAmount, _toSellerAmount);
        }

        IERC721(_item.nftContract).safeTransferFrom(address(this), buyer, _item.tokenId);
    
        emit MarketOrderSold(orderId, _item.tokenId, _order.priceInWei, _item.nftContract, _item.escrow, _item.tokenOwner, _msgSender());
    }

    /// @notice Restricted method used to create a new market item
    /// @dev Restricted to internal view.
    function _createMarketItem(address nftContract, uint256 tokenId, address payable seller) 
        internal
        returns (bytes32 itemId) 
    {
        if (seller != IERC721(nftContract).ownerOf(tokenId)) revert NotTokenOwner();
        uint256 _index = _itemsIndex.current();
        uint256 _salt = block.timestamp;
        bytes32 _itemId = keccak256(abi.encodePacked(_msgSender(), nftContract, tokenId, _salt));
        
        itemsMapping[_itemId] = MarketItem(
            _itemId,
            _index,
            payable(seller),
            address(this),
            escrow,
            nftContract,
            tokenId,
            Status(0),
            false
        );

        activeMarketItems.push(_itemId);
        _itemsIndex.increment();

        emit MarketItemCreated(_itemId, _index, seller);

        IERC721(nftContract).safeTransferFrom(seller, address(this), tokenId);
        
        return _itemId;
    }
/// --------------------------------- ADMIN METHODS ---------------------------------

    /// @notice Restricted method used to withdraw the funds from the marketplace.
    /// @dev Restricted to Admin Role.
    function withdraw() external onlyRole(ADMIN_ROLE) {
        (bool success,) = payable(_msgSender()).call{value: address(this).balance}("");
        if (!success) revert ErrorMessage("Withdraw Failed");
        emit Withdraw();
    }

    /// @notice Restricted method used to withdraw any stuck erc20 in this smart-contract.
    /// @dev Restricted to Admin Role.
    /// @param erc20Token The address of stuck erc20 token to release.
    function releaseStuckTokens(address erc20Token) external onlyRole(ADMIN_ROLE) {
        uint256 balance = IERC20(erc20Token).balanceOf(address(this));
        require(IERC20(erc20Token).transfer(_msgSender(), balance));
    }

    /// @notice Restricted method used to set the serviceWallet.
    /// @dev Restricted to Admin Role.
    /// @param _serviceWallet The new account to receive the service fee.
    /// @dev Emits the event { ServiceWalletUpdated }.
    function updateServiceWallet(address payable _serviceWallet) external onlyRole(ADMIN_ROLE) {
       serviceWallet = _serviceWallet;
       emit ServiceWalletUpdated(serviceWallet);
    }

    /// @notice Updates the service fee of the contract.
    /// @dev Restricted to Admin Role.
    /// @param _serviceFee The updated service fee in percentage to charge for selling and buying on our marketplace.
    function updateServiceFee(uint16 _serviceFee) external onlyRole(ADMIN_ROLE) {
        serviceFee = _serviceFee;
    }

    /// --------------------------------- BUYER SERVICE METHODS ---------------------------------

    /// @notice Method used to purchase a marketOrder on behalf of a buyer.
    /// @param one Requires the param to be bool true.
    /// @param orderId The id of the MarketOrder to purchase.
    /// @param buyer The address of the buyer
    function executeOrderForBuyer(bool one, bytes32 orderId, address buyer) 
        external 
        payable
        onlyRole(BUYER_SERVICE_ROLE)
        isActiveOrder(orderId) nonReentrant 
        costs(one, orderId) 
    {
        _executeOrder(one, orderId, buyer);
    }

    /// @notice Method used to batch { createMarketItem and createMarketOrder } into one transaction.
    /// @dev RESTIRCTED to ITEM_CREATOR_ROLE.
    /// @dev ATTENTION this function require approvals from `collection` to transfer tokenId
    /// @param collection Collection address of the nft to add to marketplace. 
    /// @param tokenId The tokenId the token to add on the marketplace.
    /// @param seller The address of the seller of this nft.
    /// @param priceInWei The sales price of this nft. 
    /// @return itemId orderId Will return the bytes32 itemId and orderId.
    function listAndSellNewCollection(address collection, uint256 tokenId, address payable seller, uint256 priceInWei) 
        external 
        onlyRole(ITEM_CREATOR_ROLE) 
        returns (bytes32 itemId, bytes32 orderId) 
    {
        approvedCollections[collection] = true;
        //if (seller != IERC721(collection).ownerOf(tokenId)) revert NotTokenOwner();
        itemId = _createMarketItem(collection, tokenId, seller);
        orderId = createMarketOrder(itemId, priceInWei);
        emit ListedForSale(collection, seller, tokenId, priceInWei, itemId, orderId);
    }

    /// @notice Method used to batch an pre-approved collection into one transaction.
    /// @dev ATTENTION this function require approvals from `collection` to transfer tokenId
    /// @param collection Collection address of the nft to add to marketplace. 
    /// @param tokenId The tokenId the token to add on the marketplace.
    /// @param priceInWei The sales price of this nft. 
    /// @return itemId orderId Will return the bytes32 itemId and orderId.
    function listAndSellPreApprovedCollection(address collection, uint256 tokenId, uint256 priceInWei) 
        external 
        returns (bytes32 itemId, bytes32 orderId) 
    {
        if(!approvedCollections[collection]) revert CollectionNotApproved();
        itemId = _createMarketItem(collection, tokenId, payable(msg.sender));
        orderId = createMarketOrder(itemId, priceInWei);
        emit ListedForSale(collection, msg.sender, tokenId, priceInWei, itemId, orderId);
    }

    /// @notice Method used to add an pre-approved collection.
    /// @param collection contract address to approve
    /// @param isApproved true to add and false to remove collection.
    function approveCollection(address collection, bool isApproved) external onlyRole(ADMIN_ROLE) {
        approvedCollections[collection] = isApproved;
        emit CollectionApproved(collection, isApproved);
    }


   
}