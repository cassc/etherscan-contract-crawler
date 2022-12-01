pragma solidity ^0.8.0;

interface IShop{
    /**
     * Query for non existing product
     */
    error NonExistingProduct();

    /**
     * Not a token owner
     */
    error Unauthorized();

    /**
     * Not possible to order a phyiscal item
     */
    error NoPhysicalAvailable();

    /**
     * Product can not have 0 supply
     */
    error ProductZeroSupply();

    /**
     * Product can't have empty string as a name 
     */
    error ProductNoName();

    /**
     * Product can not be free
     */
    error ProductZeroPrice();

    /**
     * Only one auction at time possilbe
     */
    error OnGoingAuction();
    
    /**
     * No live auction
     */
    error NoOnGoingAuction();

    /**
     * Auction should be at least one day long
     */
    error AuctionDurationLessThanDay();

    /**
     * Before starting new auction, the previous bid shuold be resolved
     */
    error AuctionNotResolved();

    /**
     * Bidder offer less then starting big or under bids the current higehst bidder
     */
    error UnderBid();

    /**
     * ERC20 USD contract address needs to bet set before interacting with contract
     */
    error UnsetERC20USDContract();

    /**
     * Emits on every auction start
     */
    event AuctionStart(uint32 start, uint32 expires);

    /**
     * Emits on every succefull order
     */
    event Order(uint256 tokenId, string pName);    
    
    /**
     * Emits on every succfulll auction bid
     */
    event AuctionBid(address owner, uint256 tokenId, uint256 $usdc);

    /**
     * Emits when new product is added
     */
    event ProductAdded(string productName, uint8 supply, uint256 ProductZeroPrice);

    /**
     * Emits when product is removed
     */
    event ProductRemoved(string productName);

    struct AuctionInfo {
        // Auction start in unix seconds 
        uint32 start;
        // Auction end in unix seconds 
        uint32 expires;
    }

    struct Bid {
        // Bid sender
        address owner;
        // Erc721 token id 
        uint256 tokenId;
        // Bidding amount in usdc
        uint256 $usdc;
    }

    struct ProductInfo {
        // Supply of an item
        uint8 physical_supply;
        // Price of a product
        uint256 price;
    }

    // =============================================================
    //                      Stable coin
    // =============================================================
    function setErc20USDAddress(address erc20UsdAddress) external;

    function withdraw(address to) external;

    // =============================================================
    //                        Auction
    // =============================================================
    function startAuction(uint32 duration) external;

    function setAuctionDuration(uint32 duration) external;
    
    function resolveBidding() external;

    function isAuctionLive() external view returns (bool);

    // =============================================================
    //                 Product order/bidding
    // =============================================================
    function orderProduct(uint256 tokenId, string memory pName) external;

    function placeBid(uint256 tokenId, uint256 $usdc) external ;

    // =============================================================
    //                Product operations & queries
    // =============================================================    
    function getProductInfo(string memory pName) external view returns(ProductInfo memory);

    function addProductInfo(string memory pName, uint8 supply, uint256 price) external;

    function updateProductInfo(string memory pName, uint8 supply, uint256 price) external;

    function removeProductInfo(string memory pName) external;
}