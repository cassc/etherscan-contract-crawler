// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftScythe is ReentrancyGuard, IERC721Receiver, Ownable, Pausable {

    struct SoldItemDetail {
        address seller;
        uint256 expiration; // easier to keep track of soldTime but expiration ensures that at sale time, you are guaranteed the buyback period
    }

    /**********************
     * Variables *
     **********************/
    uint256 private _sellerPrice; // price paid to sellers in ETH, must be greater than zero
    uint256 private _exclusiveBuyerPrice; // price paid by original seller in ETH, must be >0 and >sellerPrice
    uint256 private _unrestrictedBuyerPrice; // price paid by any buyer in ETH, must >0 and >sellerPrice

    uint256 private _exclusiveBuybackPeriod = 86400*30; // time period in seconds
    mapping (address => mapping(uint256 => SoldItemDetail)) private _buybackItemsByItemAddress; // lookup by NFT address
    
    bool private _unrestrictedBuyingEnabled = false; // if items can be bought from the contract
    bool private _exclusiveBuybackEnabled = true;

    /**********************
     *  Modifiers  *
     **********************/
    modifier unpaused() {
        require(!paused(), 'Scythe paused');
        _;
    }

    modifier enoughFunds(uint256 amount) {
        require(address(this).balance >= amount, "Not enough funds");
        _;
    }

    modifier itemOwnedByScythe(address nftAddress, uint256 tokenId) {
        require(IERC721(nftAddress).ownerOf(tokenId) == address(this), "Item must be owned by Scythe");
        _;
    }

    modifier priceGreaterThanZero(uint256 price) {
        require (price > 0, "Price must be greater than 0");
        _;
    }

    /**********************
     *  Functions  *
     **********************/
    constructor(uint256 sPrice, uint256 exclusiveBPrice, uint256 unrestrictedBPrice){
        require(sPrice > 0 && exclusiveBPrice > 0 && unrestrictedBPrice > 0, "Prices must be greater than 0");
        require(sPrice < exclusiveBPrice && sPrice < unrestrictedBPrice, "Seller price must be less than buyer prices");
 
        _sellerPrice = sPrice;
        _exclusiveBuyerPrice = exclusiveBPrice;
        _unrestrictedBuyerPrice = unrestrictedBPrice;
    }

    // hook called when an ERC721 received
    function onERC721Received(address, address from, uint256 tokenId, bytes memory) 
        external 
        virtual 
        override
        unpaused
        nonReentrant
        itemOwnedByScythe(msg.sender,tokenId)
        enoughFunds(_sellerPrice)
        returns (bytes4) {

        // record sale in the item mappings
        _buybackItemsByItemAddress[msg.sender][tokenId] = SoldItemDetail(from, block.timestamp+_exclusiveBuybackPeriod);

        // make the payment
        // "msg.sender" is now the nftcontract's address. 'from' is the seller.
        (bool success, ) = payable(from).call{value: _sellerPrice}("");
        require(success, "Transfer failed");

        // generate event
        emit ItemSold(from, msg.sender, tokenId, _sellerPrice);
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId;
    }

    // generic function to allow receiving Ether, needed to fund contract initially
    receive() external payable {}

    // Allows protocol owner to withdraw from the contract
    function withdrawProtocolFunds(uint256 amount) 
        external 
        nonReentrant 
        enoughFunds(amount)
        onlyOwner {

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**********************
     *  Buying Functions  *
     **********************/

    // private function to move items
    function _transferItem(address to, address nftAddress, uint256 tokenId) 
        private {

        IERC721(nftAddress).safeTransferFrom(address(this), to, tokenId);        
        // delete mapping
        delete _buybackItemsByItemAddress[nftAddress][tokenId];
    }
    
    // allows Contract owner to move NFT out of the contract
    // listed as a failsafe to always be able to move NFTs out
    // Can also enable future use cases like an Auction
    function transferItem(address nftAddress, uint256 tokenId) external onlyOwner{
        _transferItem(msg.sender, nftAddress, tokenId);
    }

    // Anyone can buy any NFT for the price set in the contract
    function buyItemUnrestricted(address nftAddress, uint256 tokenId) 
        external 
        payable 
        nonReentrant
        unpaused
        itemOwnedByScythe(nftAddress, tokenId) {
        
        // check conditions
        require(_unrestrictedBuyingEnabled, "Unrestricted buying is not enabled");
        require((msg.value == _unrestrictedBuyerPrice), "Incorrect buy price");
        require((_fetchInitializedBuybackItem(nftAddress, tokenId).expiration <= block.timestamp), "Item still under exclusive buyback period");

        // transfer
        _transferItem(msg.sender, nftAddress, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, _unrestrictedBuyerPrice);
    }

    // Allows buyback exclusively to the seller
    function buybackItem(address nftAddress, uint256 tokenId) 
        external 
        payable 
        nonReentrant
        unpaused
        itemOwnedByScythe(nftAddress, tokenId) {

        // check conditions
        require(_exclusiveBuybackEnabled, "Exclusive buyback is not enabled");
        require(msg.value == _exclusiveBuyerPrice, "Incorrect buy price");
        SoldItemDetail memory itemDetail = _fetchInitializedBuybackItem(nftAddress, tokenId);
        require(itemDetail.seller == msg.sender, "Only seller can buyback");
        require(itemDetail.expiration >= block.timestamp, "Item no longer under exclusive period");


        // transfer
        _transferItem(msg.sender, nftAddress, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, _exclusiveBuyerPrice);
    }

    /**********************
     *  Getters  *
     **********************/

    function getSellerPrice() external view returns (uint256) {
        return _sellerPrice;
    }

    function getUnrestrictedBuyerPrice() external view returns (uint256) {
        return _unrestrictedBuyerPrice;
    }

    function getExclusiveBuyerPrice() external view returns (uint256) {
        return _exclusiveBuyerPrice;
    }
    
    function getExclusiveBuybackPeriod() public view returns (uint256) {
        return _exclusiveBuybackPeriod;
    }

    function checkUnrestrictedBuyingEnabled() external view returns (bool) {
        return _unrestrictedBuyingEnabled;
    }

    function checkExclusiveBuybackEnabled() external view returns (bool) {
        return _exclusiveBuybackEnabled;
    }

    function checkBuybackStatusByItem(address nftAddress, uint256 tokenId) public view returns (SoldItemDetail memory) {
        return _buybackItemsByItemAddress[nftAddress][tokenId];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**********************
     *  Setters  *
     **********************/

    function setSellerPrice(uint256 newSellerPrice) 
        external 
        onlyOwner
        priceGreaterThanZero(newSellerPrice) {
        require(newSellerPrice <= _exclusiveBuyerPrice && newSellerPrice <= _unrestrictedBuyerPrice, "Seller price can't be more than buyer prices");
        _sellerPrice = newSellerPrice;
    }

    function setUnrestrictedBuyerPrice(uint256 newPrice) 
        external 
        onlyOwner 
        priceGreaterThanZero(newPrice){

        require(newPrice >= _sellerPrice, "Buyer price can't be less than seller price");
        _unrestrictedBuyerPrice = newPrice;
    }

    function setExclusiveBuyerPrice(uint256 newPrice) 
        external 
        onlyOwner 
        priceGreaterThanZero(newPrice) {
            
        require(newPrice >= _sellerPrice, "Buyer price can't be less than seller price");
        _exclusiveBuyerPrice = newPrice;
    }

    function setUnrestrictedBuying(bool value) external onlyOwner {
        _unrestrictedBuyingEnabled = value;
    }

    function setExclusiveBuyback(bool value) external onlyOwner {
        _exclusiveBuybackEnabled = value;
    }

    function setExclusiveBuybackPeriod(uint256 period) external onlyOwner {
        require(period >= 0, "Exclusive buyback period can't be less than 0");
        _exclusiveBuybackPeriod = period;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**********************
     *  Helpers  *
     **********************/

    function _fetchInitializedBuybackItem(address nftAddress, uint256 tokenId) private view returns (SoldItemDetail memory) {
        SoldItemDetail memory itemDetail = _buybackItemsByItemAddress[nftAddress][tokenId];
        require(itemDetail.seller != address(0x0), "Item not registered in Scythe");
        return itemDetail;
    }

    /**********************
     *  Events  *
     **********************/

    // when item is sold to Scythe
    event ItemSold (
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    // when item is bought from Scythe
    event ItemBought (
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
}