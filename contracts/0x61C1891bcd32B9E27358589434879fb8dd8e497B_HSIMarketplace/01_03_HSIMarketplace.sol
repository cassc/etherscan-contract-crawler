// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IHEXStakeInstanceManager {
    function approve(address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);
}

interface IFeeCollection {
    function manageFees(uint256 value, uint256 addShare) external;
}

contract HSIMarketplace is Ownable {
    IHEXStakeInstanceManager public IHSIMtoken;
    IFeeCollection public IfeeCollection;
    address payable fee;
    uint256 public totalFeeShare = 2222; // 2.222 Percentage

    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    ItemForSale[] public itemsForSale;
    mapping(uint256 => bool) public activeItems;

    //Events
    event itemAddedForSale(
        uint256 id,
        address seller,
        uint256 tokenId,
        uint256 price
    );
    event itemSold(uint256 id, address buyer, uint256 tokenId, uint256 price);
    event itemDelisted(uint256 id, uint256 tokenId, bool isActive);

    //Constructor
    constructor(address _hsimtoken, address payable _feeCollection) {
        require(
            (_hsimtoken != address(0) && _feeCollection != address(0)),
            "Zero address is not allowed."
        );

        IHSIMtoken = IHEXStakeInstanceManager(_hsimtoken);
        IfeeCollection = IFeeCollection(_feeCollection); // Interface for Fee Collector contract
        fee = _feeCollection; // Fee collector contract address to transfer ETH to this address
    }

    //Modifier, Check NFT ownership
    modifier OnlyItemOwner(uint256 tokenId) {
        require(
            IHSIMtoken.ownerOf(tokenId) == msg.sender,
            "Sender is not the owner of this NFT"
        );
        _;
    }

    //Modifier, Check if NFT is approved for this contract
    modifier HasTransferApproval(uint256 tokenId) {
        require(
            IHSIMtoken.getApproved(tokenId) == address(this),
            "NFT not approved for this Marketplace"
        );
        _;
    }

    //Modifier, Check if NFT listed for sale
    modifier ItemExists(uint256 id) {
        require(
            id < itemsForSale.length && itemsForSale[id].id == id,
            "NFT not listed for sale"
        );
        _;
    }

    //Modifier, Check if listed NFT is sold or not
    modifier IsForSale(uint256 id) {
        require(!itemsForSale[id].isSold, "Item is already sold");
        require(
            activeItems[itemsForSale[id].tokenId],
            "Item is delisted for sale"
        );
        _;
    }

    /* ======== USER FUNCTIONS ======== */

    /*
     *@notice List NFT for sale
     *@param tokenId uint256, NFT ID
     *@param price(in wei) uint256, NFT selling price
     *@return uint(newItemId)
     */
    function putItemForSale(uint256 tokenId, uint256 price)
        external
        OnlyItemOwner(tokenId)
        HasTransferApproval(tokenId)
        returns (uint256)
    {
        require(!activeItems[tokenId], "Item is already up for sale");
        require(price > 0, "Price should be greater than 0");

        uint256 newItemId = itemsForSale.length;
        itemsForSale.push(
            ItemForSale({
                id: newItemId,
                tokenId: tokenId,
                seller: payable(msg.sender),
                price: price,
                isSold: false
            })
        );
        activeItems[tokenId] = true;

        assert(itemsForSale[newItemId].id == newItemId);
        emit itemAddedForSale(newItemId, msg.sender, tokenId, price);
        return newItemId;
    }

    /*
     *  @notice Buy a NFT
     *  @param uint256 id, index of NFT
     */
    function buyItem(uint256 id)
        external
        payable
        ItemExists(id)
        IsForSale(id)
        HasTransferApproval(itemsForSale[id].tokenId)
    {
        require(msg.value >= itemsForSale[id].price, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);

        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenId] = false;
        IHEXStakeInstanceManager(IHSIMtoken).safeTransferFrom(
            itemsForSale[id].seller,
            msg.sender,
            itemsForSale[id].tokenId
        );

        uint256 addShare = (msg.value * totalFeeShare) / 100000;
        uint256 sellerShare = msg.value - addShare;

        itemsForSale[id].seller.transfer(sellerShare);
        fee.transfer(addShare);
        IfeeCollection.manageFees(msg.value, addShare);

        emit itemSold(
            id,
            msg.sender,
            itemsForSale[id].tokenId,
            itemsForSale[id].price
        );
    }

    /*
     *  @notice Get total number of NFTs for sale
     *  @return uint
     */
    function totalItemsForSale() external view returns (uint256) {
        return itemsForSale.length;
    }

    /*
     *  @notice Get all NFTs for sale
     *  @return tuple
     */
    function getListedItems() external view returns (ItemForSale[] memory) {
        return itemsForSale;
    }

    /*
     *  @notice Remove an NFT from sale
     *  @param uint256 id, Index of NFT in itemsForSale
     *  @param uint256 tokenId, NFT ID
     *  @return uint256
     */
    function delistItem(uint256 id, uint256 tokenId)
        external
        OnlyItemOwner(tokenId)
        IsForSale(id)
        returns (uint256)
    {
        activeItems[itemsForSale[id].tokenId] = false;

        emit itemDelisted(id, tokenId, activeItems[itemsForSale[id].tokenId]);
        return tokenId;
    }

    /*
     *  @notice Update Fee Collector contract  address
     *  @param address payable _fee, new fee collector address
     */
    function updateFeeCollector(address payable _fee) external onlyOwner {
        require(_fee != address(0), "Zero address is not allowed");
        require(_fee != fee, "Cannot add the same address as feeCollector");

        IfeeCollection = IFeeCollection(_fee);
        fee = _fee;
    }

    /*
     *  @notice Update total fee share percentage
     *  @param uint256 _newFeeShare, new fee share percentage, Eg. for 2.222% enter 2222
     */
    function updateTotalFeeShare(uint256 _newFeeShare) external onlyOwner {
        require(_newFeeShare != 0, "Enter fee share greater than 0");
        require(
            _newFeeShare != totalFeeShare,
            "New fee share is same as existing"
        );

        totalFeeShare = _newFeeShare;
    }
}