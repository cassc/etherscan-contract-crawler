// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarket {
    enum OrderType {
        Sell, // sell nft
        Buy, // buy nft
        Auction, // aution
        DutchAuction // dutch aution
    }

    enum NFTType {
        ERC721, // ERC721
        ERC1155 // ERC1155
    }

    event CreateOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        Order order
    );

    event ChangeOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address token,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    );

    event CompleteOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address payer,
        Order order
    );

    event CancelOrder(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address nftToken,
        uint256 tokenId
    );

    event Bid(
        uint256 indexed id,
        uint256 indexed orderType,
        address indexed orderOwner,
        address bidder,
        uint256 bidTime,
        address token,
        uint256 price
    );

    struct Order {
        uint256 id; //order id
        OrderType orderType; // 0: sell nft, 1: buy nft, 2: auction, 3: dutch auction
        address orderOwner; // order owner
        NftInfo nftInfo; // nft info
        address token; // ERC20 token address
        uint256 price; //order price
        uint256 startTime; // order start timestimp
        uint256 endTime; // order end timestimp
        uint256 changeRate; // least percent for auction, decrease percent every hour for dutch auction
        uint256 minPrice; // min price for dutch auction
    }

    struct NftInfo {
        NFTType nftType; // 0: ERC721, 1: ERC1155
        address nftToken; //nft token address
        uint256 tokenId; // token id
        uint256 tokenAmount; // token amount, for ERC721 is always 1
    }

    struct BidInfo {
        address bidder; // bidder
        uint256 price; // highest price
    }

    // read methods
    function name() external pure returns (string memory);

    function getTradeFeeRate() external view returns (uint256);

    function getDutchPrice(uint256 orderId) external view returns (uint256);

    function getOrder(uint256 orderId) external view returns (Order memory);

    function getBidInfo(uint256 orderId) external view returns (BidInfo memory);

    function getOrdersByOwner(address orderOwner)
        external
        view
        returns (Order[] memory);

    function getOrdersByNft(address nftToken, uint256 tokenId)
        external
        view
        returns (Order[] memory);

    // write methods
    function createOrder(
        OrderType orderType,
        NFTType nftType,
        address nftToken,
        uint256 tokenId,
        uint256 tokenAmount,
        address token,
        uint256 price,
        uint256 timeLimit,
        uint256 changeRate,
        uint256 minPrice
    ) external returns (uint256);

    function cancelOrder(uint256 orderId) external;

    function fulfillOrder(uint256 orderId, uint256 price) external;

    function changeOrder(
        uint256 orderId,
        uint256 price,
        uint256 timeLimit
    ) external;

    function bid(uint256 orderId, uint256 price) external;

    function claim(uint256 orderId) external;
}