// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../../other/ITrustedForwarder.sol";
import "../../other/IGameFiEntity.sol";

interface IGameFiMarketplaceV1 is IGameFiEntity, ITrustedForwarder {
    enum OrderStatus {
        NULL,
        OPEN,
        CANCELLED,
        EXECUTED
    }
    enum NFTStandart {
        NULL,
        ERC721,
        ERC1155
    }

    struct Order {
        uint256 orderId;
        NFTStandart nftStandart;
        address tokenContract;
        uint256 tokenId;
        uint256 tokenAmount;
        address mainSettlementToken;
        address[] otherSettlementTokens;
        uint256 orderPrice;
        OrderStatus status;
        address seller;
        address buyer;
    }

    event CreateOrder(
        address indexed sender,
        uint256 orderId,
        NFTStandart nftStandart,
        address indexed tokenContract,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        address mainSettlementToken,
        address[] otherSettlementTokens,
        uint256 orderPrice,
        uint256 timestamp
    );
    event CancelOrder(address indexed sender, uint256 indexed orderId, uint256 timestamp);
    event ExecuteOrder(address indexed sender, uint256 indexed orderId, uint256 fee, uint256 timestamp);
    event SetTradeFeePercentage(address indexed sender, uint256 indexed newTradeFeePercentage, uint256 timestamp);
    event AddSettlementToken(address indexed sender, address indexed erc20, uint256 timestamp);
    event RemoveSettlementToken(address indexed sender, address indexed erc20, uint256 timestamp);
    event AddToWhitelistErc721(address indexed sender, address indexed erc721, uint256 timestamp);
    event AddToWhitelistErc1155(address indexed sender, address indexed erc1155, uint256 timestamp);
    event RemoveFromWhitelistErc721(address indexed sender, address indexed erc721, uint256 timestamp);
    event RemoveFromWhitelistErc1155(address indexed sender, address indexed erc1155, uint256 timestamp);
    event WithdrawERC20(address indexed sender, address indexed tokenContract, uint256 amount, uint256 timestamp);

    //
    // constructor
    //

    function initialize(address gameFiCore) external;

    //
    // orders
    //

    function createOrder(
        NFTStandart nftStandart,
        address tokenContract,
        uint256 tokenId,
        uint256 tokenAmount,
        address settlementToken,
        address[] memory otherSettlementTokens,
        uint256 orderPrice
    ) external returns (uint256 orderId);

    function cancelOrder(uint256 orderId) external;

    function executeOrder(uint256 orderId) external;

    function orderDetails(uint256 orderId) external view returns (Order memory);

    function orderDetailsBatch(uint256[] memory orderIds) external view returns (Order[] memory);

    function totalOrders() external view returns (uint256);

    function totalOrdersBy(OrderStatus byStatus) external view returns (uint256);

    function fetchOrdersBy(
        OrderStatus byStatus,
        uint256 cursor,
        uint256 howMany
    ) external view returns (uint256[] memory orderIds, uint256 newCursor);

    function fetchOrdersBy(
        address byUser,
        OrderStatus byStatus,
        uint256 cursor,
        uint256 howMany
    ) external view returns (uint256[] memory orderIds, uint256 newCursor);

    //
    // trade fee
    //

    function setTradeFeePercentage(uint256 newTradeFeePercentage) external;

    function tradeFeePercentage() external view returns (uint256);

    //
    // settlement tokens
    //

    function addSettlementToken(address erc20) external;

    function removeSettlementToken(address erc20) external;

    function containsSettlementToken(address erc20) external view returns (bool);

    function getSettlementTokens() external view returns (address[] memory erc20);

    //
    // nft whitelist
    //

    function addToWhitelistErc721(address erc721) external;

    function addToWhitelistErc1155(address erc1155) external;

    function removeFromWhitelistErc721(address erc721) external;

    function removeFromWhitelistErc1155(address erc1155) external;

    function containsWhitelistErc721(address erc721) external view returns (bool);

    function containsWhitelistErc1155(address erc1155) external view returns (bool);

    function getWhitelistErc721() external view returns (address[] memory erc721);

    function getWhitelistErc1155() external view returns (address[] memory erc1155);

    //
    // other
    //

    function withdrawERC20(address erc20, uint256 amount) external;
}