// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./interface/IMarketplaceSecondaryWhitelist.sol";

contract MarketplaceSecondary is Ownable, IERC1155Receiver {
    using SafeERC20 for IERC20;

    // Structures
    struct Sell {
        address paymentToken; // token is address(0), it means native BNB
        uint price; // price of the sell. For ERC1155 it's the price of the bundle
        uint amount; // 1 for ERC721, 1 or more for ERC1155
        uint tokenId;
        address owner; // address that creates the listing
        address collection;
        bool active;
        uint id;
    }

    // Marketplace variables
    address public treasury;
    uint public marketplaceFee; // marketplace fee over 1000 - ex: 50 -> 5%
    uint public maxFee; // max marketplace fee over 1000 - ex: 100 -> 10%
    uint public nextSellId;
    uint public minimumBidPriceIncrease;
    IMarketplaceSecondaryWhitelist public whitelist;

    mapping (uint => Sell) public sellOrdersById;
    mapping (address => uint[]) public sellOrdersByCollection;
    mapping (address => uint[]) public sellOrdersByAccount;

    // ERC-2981 interface
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // royalty percentage with a denominator of 100000. Cannot be more than 5% (500000)
    mapping (address => uint) public royalties;

    // fees denominator
    uint public feePrecision = 10000;

    event SellOrderCreated(address indexed seller, address indexed collection, uint tokenId, uint price, address paymentToken, bool isERC721);
    event SellOrderRemoved(address indexed seller, address indexed collection, uint tokenId, uint price, address paymentToken, bool isERC721);
    event BuyOrder(address indexed buyer, address indexed collection, uint tokenId, uint price, address paymentToken, bool isERC721);
    event ChangePriceOrder(address indexed seller, address indexed collection, uint tokenId, uint price);

    /**
     * @notice Constructor
     * @param _treasury Address that collects fees
     * @param _marketplaceFee Address that collects fees
     * @param _maxFee Address that collects fees
     * @dev set marketplaceFee and maxFee
     */
    constructor (address _treasury, uint _marketplaceFee, uint _maxFee){
        marketplaceFee = _marketplaceFee;
        maxFee = _maxFee;
        treasury = _treasury;
    }

    /**
     * @notice sell a NFT (ERC721)
     * @param _collection Address of the collection
     * @param _tokenId Token ID of the NFT
     * @param _price Price of the bundle (not of the single item)
     * @param _paymentToken Payment Token used (if 0x000... BNB will be used)
     */
    function sell721(address _collection, uint _tokenId, uint _price,
         address _paymentToken) external {

        require (whitelist.is721Whitelisted(_collection), "SecondaryMarketplace: Collection not whitelisted");
        require (IERC721(_collection).ownerOf(_tokenId) == msg.sender, "SecondaryMarketplace: Not owner");
        require (whitelist.isPaymentTokenWhitelisted(_paymentToken), "SecondaryMarketplace: Invalid payment token");
        

        // Transfer the token
        IERC721(_collection).transferFrom(msg.sender, address(this), _tokenId);

        Sell memory sell = Sell({
            paymentToken: _paymentToken,
            price: _price,
            amount: 1,
            tokenId: _tokenId,
            owner: msg.sender,
            collection: _collection,
            active: true,
            id: nextSellId
        });

        sellOrdersByCollection[_collection].push(nextSellId);
        sellOrdersByAccount[msg.sender].push(nextSellId);
        sellOrdersById[nextSellId] = sell;

        nextSellId += 1;

        emit SellOrderCreated(msg.sender, _collection, _tokenId, _price, _paymentToken, true);
    }

    /**
     * @notice Remove NFT from listing
     * @param _index Index of the order
     */
    function cancelSell721(uint _index) external {
        require (_index < nextSellId, "SecondaryMarketplace: Invalid index");

        Sell storage sell = sellOrdersById[_index];
        require (sell.owner == msg.sender, "SecondaryMarketplace: Not owner");
        require (whitelist.is721Whitelisted(sell.collection), "SecondaryMarketplace: Collection not whitelisted");

        // Transfer the token
        IERC721(sell.collection).transferFrom(address(this), msg.sender, sell.tokenId);

        // Cancel the order
        sell.active = false;

        emit SellOrderRemoved(msg.sender, sell.collection, sell.tokenId, sell.price, sell.paymentToken, true);

    }
    function changeSellPrice(uint _index, uint _basePrice) external {
        Sell storage sell = sellOrdersById[_index];
        require (_index < nextSellId, "SecondaryMarketplace: Invalid index");
        require (sell.owner == msg.sender, "SecondaryMarketplace: Not owner");
        sell.price = _basePrice;
        emit ChangePriceOrder(msg.sender,sell.collection,sell.tokenId,_basePrice);
    }

    /**
     * @notice buy a NFT (ERC721)
     * @param _index Index of the order
     */
    function buy721(uint _index) external payable {
        require (_index < nextSellId, "SecondaryMarketplace: Invalid index");

        Sell storage sell = sellOrdersById[_index];
        require (sell.active, "SecondaryMarketplace: Already claimed or sold");

        // Check payment
        processPaymentFrom(sell.paymentToken, msg.sender, sell.price);

        uint sellerAmount = sell.price;

        // Check royalties with ERC2981
        if (checkRoyaltiesWithERC2981(sell.collection)) {
            (address receiver, uint royaltyAmount) = ERC2981(sell.collection).royaltyInfo(sell.tokenId, sell.price);

            processPaymentTo(sell.paymentToken, receiver, royaltyAmount);
            sellerAmount -= royaltyAmount;
        }

        // Check marketplace royalties
        else if (royalties[sell.collection] > 0) {
            address receiver = Ownable(sell.collection).owner();
            uint royaltyAmount = sell.price * royalties[sell.collection] / feePrecision;

            processPaymentTo(sell.paymentToken, receiver, royaltyAmount);
            sellerAmount -= royaltyAmount;
        }

        // Apply marketplace fee
        uint fee = sell.price * marketplaceFee / feePrecision;
        processPaymentTo(sell.paymentToken, treasury, fee);
        sellerAmount -= fee;

        // Send funds to the seller
        processPaymentTo(sell.paymentToken, sell.owner, sellerAmount);

        // Transfer token
        IERC721(sell.collection).transferFrom(address(this), msg.sender, sell.tokenId);

        // Close sale
        sell.active = false;

        emit BuyOrder(msg.sender, sell.collection, sell.tokenId, sell.price, sell.paymentToken, true);
    }

    /**
     * @notice sell one or more NFT (ERC1155)
     * @param _collection Address of the collection
     * @param _tokenId Token ID of the NFT
     * @param _amount Amount of tokens to sell
     * @param _price Price of the bundle (not of the single item)
     * @param _sellStart Start timestamp of the sell
     * @param _sellEnd End timestamp of the sell
     * @param _paymentToken Payment Token used (if 0x000... BNB will be used)
     */
    function sell1155(address _collection, uint _tokenId, uint _amount, uint _price, uint _sellStart, uint _sellEnd, address _paymentToken) external {
        require (whitelist.is1155Whitelisted(_collection), "SecondaryMarketplace: Collection not whitelisted");
        require (IERC1155(_collection).balanceOf(msg.sender, _tokenId) > 0, "SecondaryMarketplace: Does not have items");
        require (whitelist.isPaymentTokenWhitelisted(_paymentToken), "SecondaryMarketplace: Invalid payment token");
        require (_sellEnd > _sellStart, "SecondaryMarketplace: Invalid dates");
        require (_amount > 0, "SecondaryMarketplace: Cannot sell zero items");

        // Transfer the token
        IERC1155(_collection).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");

        Sell memory sell = Sell({
            paymentToken: _paymentToken,
            price: _price,
            amount: _amount,
            tokenId: _tokenId,
            owner: msg.sender,
            collection: _collection,
            active: true,
            id: nextSellId
        });

        sellOrdersByCollection[_collection].push(nextSellId);
        sellOrdersByAccount[msg.sender].push(nextSellId);
        sellOrdersById[nextSellId] = sell;

        nextSellId += 1;

        emit SellOrderCreated(msg.sender, _collection, _tokenId, _price, _paymentToken, false);
    }

    /**
     * @notice Remove NFT from listing
     * @param _index Index of the order
     */
    function cancelSell1155(uint _index) external {
        require (_index < nextSellId, "SecondaryMarketplace: Invalid index");

        Sell storage sell = sellOrdersById[_index];
        require (sell.owner == msg.sender, "SecondaryMarketplace: Not owner");
        require (whitelist.is1155Whitelisted(sell.collection), "SecondaryMarketplace: Collection not whitelisted");

        // Transfer the token
        IERC1155(sell.collection).safeTransferFrom(address(this), msg.sender, sell.tokenId, sell.amount, "");

        // Close the order
        sell.active = false;

        emit SellOrderRemoved(msg.sender, sell.collection, sell.tokenId, sell.price, sell.paymentToken, false);

    }





    /**
     * @notice buy a NFT (ERC1155)
     * @param _index Index of the order
     */
    function buy1155(uint _index) external payable {
        require (_index < nextSellId, "SecondaryMarketplace: Invalid index");

        Sell storage sell = sellOrdersById[_index];
        require (sell.active, "SecondaryMarketplace: Already claimed or sold");

        // Check payment
        processPaymentFrom(sell.paymentToken, msg.sender, sell.price);

        // Apply marketplace fee
        uint fee = sell.price * marketplaceFee / feePrecision;
        processPaymentTo(sell.paymentToken, treasury, fee);

        // Send funds to the seller
        processPaymentTo(sell.paymentToken, sell.owner, sell.price - fee);

        // Transfer token
        IERC1155(sell.collection).safeTransferFrom(address(this), msg.sender, sell.tokenId, sell.amount, "");

        // Close sale
        sell.active = false;

        emit BuyOrder(msg.sender, sell.collection, sell.tokenId, sell.price, sell.paymentToken, false);

    }

    /**
     * @notice Returns the list of orders of a specific collection
     * @param _collection Collection address
     */
    function getSellOrdersByCollection(address _collection) external view returns (uint[] memory) {
        return sellOrdersByCollection[_collection];
    }

    /**
     * @notice Returns the list of orders of a specific account
     * @param _account Collection address
     */
    function getSellOrdersByAccount(address _account) external view returns (uint[] memory) {
        return sellOrdersByAccount[_account];
    }

    // PRIVILEGED METHODS

    /**
     * @notice Change treasury address
     * @param _treasury New treasury address
     */
    function changeTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Change fee address
     * @param _newFee New treasury address
     */
    function changeFee(uint _newFee) external onlyOwner {
        require(_newFee <= maxFee, "SecondaryMarketplace: fee cannot exceeded max fee");
        marketplaceFee = _newFee;
    }

    /**
     * @notice Change marketplace whitelist address
     * @param _marketplaceWhitelist New marketplace whitelist address
     */
    function setMarketplaceWhitelist(address _marketplaceWhitelist) external onlyOwner {
        whitelist = IMarketplaceSecondaryWhitelist(_marketplaceWhitelist);
    }

    // ERC1155 Receiver
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external pure override returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return supportsInterface(interfaceId);
    }

    // INTERNAL METHODS
    // Check whether a NFT smart contract supports royalties through ERC2981
    function checkRoyaltiesWithERC2981(address _collection) internal view returns (bool) {
        (bool success) = IERC165(_collection).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    // Takes funds from the bidder based on the payment token
    function processPaymentFrom(address _token, address _from, uint _amount) internal {
        // BNB
        if (_token == address(0)) {
            require (msg.value >= _amount, "Marketplace: not enough funds");
        }

        // Other tokens
        else {
            IERC20(_token).transferFrom(_from, address(this), _amount);
        }
    }

    // Refund a bidder if it gets outbidded
    function processPaymentTo(address _token, address _to, uint _amount) internal {
        // BNB
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
        }

        // Other tokens
        else {
            IERC20(_token).transfer(_to, _amount);
        }
    }

}