// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time, max-states-count

// inheritance list
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "../../interface/module/marketplace/IGameFiMarketplaceV1.sol";

// libs
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// external interfaces
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "../../interface/core/IGameFiCoreV2.sol";

/**
 * @author Alex Kaufmann
 * @dev On-chain NFT Marketplace.
 * Allows users to place on-chain sell orders for erc721 and erc1155 tokens.
 */
contract GameFiMarketplaceV1 is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable,
    BaseRelayRecipient,
    IGameFiMarketplaceV1
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    // settings
    address internal _gameFiCore;
    uint256 internal _tradeFeePercentage; // decimals = 2
    EnumerableSetUpgradeable.AddressSet internal _settlementTokens;
    EnumerableSetUpgradeable.AddressSet internal _whitelistErc721;
    EnumerableSetUpgradeable.AddressSet internal _whitelistErc1155;

    // orders
    CountersUpgradeable.Counter internal _totalOrders;
    mapping(uint256 => Order) internal _orders;

    // state for getters
    mapping(OrderStatus => EnumerableSetUpgradeable.UintSet) internal _ordersByStatus;
    mapping(address => mapping(OrderStatus => EnumerableSetUpgradeable.UintSet)) internal _ordersByUserByStatus;

    modifier onlyAdmin() {
        IGameFiCoreV2(_gameFiCore).isAdmin(_msgSender());
        _;
    }

    //
    // constructor
    //

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
     * @param gameFiCore GameFiCore contract address.
     */
    function initialize(address gameFiCore) external override initializer {
        require(gameFiCore != address(0), "GameFiMarketplaceV1: zero gameFiCore address");
        require(gameFiCore.isContract(), "GameFiMarketplaceV1: gameFiCore must be a contract");

        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __ERC1155Holder_init();

        _gameFiCore = gameFiCore;
    }

    //
    // orders
    //

    /**
     * @dev Creates a new marketplace order.
     * @param nftStandart NFTStandart enum.
     * @param tokenContract Address of the token being sold.
     * @param tokenId Id of the token being sold.
     * @param tokenAmount Amount of the sold token.
     * @param mainSettlementToken ERC20 token for which an order can be redeemed.
     * @param otherSettlementTokens Legacy field. Don't use.
     * @param orderPrice Order price in settlement token.
     * @return orderId new order ID.
     */
    function createOrder(
        NFTStandart nftStandart,
        address tokenContract,
        uint256 tokenId,
        uint256 tokenAmount,
        address mainSettlementToken,
        address[] memory otherSettlementTokens,
        uint256 orderPrice
    ) external override nonReentrant returns (uint256 orderId) {
        require(nftStandart != NFTStandart.NULL, "GameFiMarketplaceV1: invalid nft standart");
        require(tokenContract != address(0), "GameFiMarketplaceV1: zero contract address");
        if (nftStandart == NFTStandart.ERC721) {
            require(_whitelistErc721.contains(tokenContract), "GameFiMarketplaceV1: nft not registered");
            require(tokenAmount == 1, "GameFiMarketplaceV1: wrong token amount");
        } else {
            require(_whitelistErc1155.contains(tokenContract), "GameFiMarketplaceV1: nft not registered");
            require(tokenAmount >= 1, "GameFiMarketplaceV1: wrong token amount");
        }
        require(mainSettlementToken != address(0), "GameFiMarketplaceV1: zero trade token address");
        require(
            _settlementTokens.contains(mainSettlementToken),
            "GameFiMarketplaceV1: settlement token not registered"
        );
        require(otherSettlementTokens.length == 0, "GameFiMarketplaceV1: only main settlement token");
        require(orderPrice > 0.00001 ether, "GameFiMarketplaceV1: wrong order price");

        // create order
        uint256 newOrderId = _totalOrders.current();
        _orders[newOrderId] = Order({
            orderId: newOrderId,
            nftStandart: nftStandart,
            tokenContract: tokenContract,
            tokenId: tokenId,
            tokenAmount: tokenAmount,
            mainSettlementToken: mainSettlementToken,
            otherSettlementTokens: otherSettlementTokens,
            orderPrice: orderPrice,
            status: OrderStatus.OPEN,
            seller: _msgSender(),
            buyer: address(0)
        });

        // index the state
        _totalOrders.increment();
        _ordersByStatus[OrderStatus.OPEN].add(newOrderId);
        _ordersByUserByStatus[_msgSender()][OrderStatus.OPEN].add(newOrderId);

        // make token transfer
        if (nftStandart == NFTStandart.ERC721) {
            IERC721Upgradeable(tokenContract).safeTransferFrom(_msgSender(), address(this), tokenId);
        } else {
            IERC1155Upgradeable(tokenContract).safeTransferFrom(_msgSender(), address(this), tokenId, tokenAmount, "");
        }

        emit CreateOrder({
            sender: _msgSender(),
            orderId: newOrderId,
            nftStandart: nftStandart,
            tokenContract: tokenContract,
            tokenId: tokenId,
            tokenAmount: tokenAmount,
            mainSettlementToken: mainSettlementToken,
            otherSettlementTokens: otherSettlementTokens,
            orderPrice: orderPrice,
            timestamp: block.timestamp
        });

        return (newOrderId);
    }

    /**
     * @dev Cancel open order.
     * @param orderId Сanceled order identifier.
     */
    function cancelOrder(uint256 orderId) external override nonReentrant {
        require(orderId < _totalOrders.current(), "GameFiMarketplaceV1: order does not exist");

        Order memory order = _orders[orderId];

        require(order.status == OrderStatus.OPEN, "GameFiMarketplaceV1: only for open orders");
        require(order.seller == _msgSender(), "GameFiMarketplaceV1: sender is not the seller");
        require(order.buyer == address(0), "GameFiMarketplaceV1: order already completed");

        _orders[orderId].status = OrderStatus.CANCELLED;

        // index the state
        _ordersByStatus[OrderStatus.OPEN].remove(orderId);
        _ordersByUserByStatus[_msgSender()][OrderStatus.OPEN].remove(orderId);
        _ordersByStatus[OrderStatus.CANCELLED].add(orderId);
        _ordersByUserByStatus[_msgSender()][OrderStatus.CANCELLED].add(orderId);

        // make token transfer
        if (order.nftStandart == NFTStandart.ERC721) {
            IERC721Upgradeable(order.tokenContract).safeTransferFrom(address(this), _msgSender(), order.tokenId);
        } else {
            IERC1155Upgradeable(order.tokenContract).safeTransferFrom(
                address(this),
                _msgSender(),
                order.tokenId,
                order.tokenAmount,
                ""
            );
        }

        emit CancelOrder({sender: _msgSender(), orderId: orderId, timestamp: block.timestamp});
    }

    /**
     * @dev Execute open order and make swap.
     * @param orderId Executed order identifier.
     */
    function executeOrder(uint256 orderId) external override nonReentrant {
        require(orderId < _totalOrders.current(), "GameFiMarketplaceV1: order does not exist");

        Order memory order = _orders[orderId];

        require(order.status == OrderStatus.OPEN, "GameFiMarketplaceV1: only for open orders");
        require(order.seller != _msgSender(), "GameFiMarketplaceV1: not for seller");
        require(order.buyer == address(0), "GameFiMarketplaceV1: order already completed");

        order.buyer = _msgSender();
        order.status = OrderStatus.EXECUTED;
        _orders[orderId] = order;

        // make swap including commission
        uint256 fee = order.orderPrice.mul(_tradeFeePercentage).div(100_00);
        IERC20Upgradeable(order.mainSettlementToken).safeTransferFrom(_msgSender(), address(this), order.orderPrice);
        IERC20Upgradeable(order.mainSettlementToken).safeTransfer(order.seller, order.orderPrice.sub(fee));
        if (order.nftStandart == NFTStandart.ERC721) {
            IERC721Upgradeable(order.tokenContract).safeTransferFrom(address(this), _msgSender(), order.tokenId);
        } else {
            IERC1155Upgradeable(order.tokenContract).safeTransferFrom(
                address(this),
                _msgSender(),
                order.tokenId,
                order.tokenAmount,
                ""
            );
        }

        // index the state
        _ordersByStatus[OrderStatus.OPEN].remove(orderId);
        _ordersByUserByStatus[order.seller][OrderStatus.OPEN].remove(orderId);
        _ordersByStatus[OrderStatus.EXECUTED].add(orderId);
        _ordersByUserByStatus[order.seller][OrderStatus.EXECUTED].add(orderId);

        emit ExecuteOrder({sender: _msgSender(), orderId: orderId, fee: fee, timestamp: block.timestamp});
    }

    /**
     * @dev Returns Order struct by id.
     * @param orderId Target order identifier.
     */
    function orderDetails(uint256 orderId) external view override returns (Order memory) {
        return (_orders[orderId]);
    }

    /**
     * @dev Returns Order struct by id, batch version.
     * @param orderIds Target orders identifiers.
     */
    function orderDetailsBatch(uint256[] memory orderIds) external view override returns (Order[] memory) {
        Order[] memory result = new Order[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; i++) {
            result[i] = _orders[orderIds[i]];
        }
        return (result);
    }

    /**
     * @dev Returns the number of orders in existence.
     * @return Total number of orders.
     */
    function totalOrders() external view override returns (uint256) {
        return (_totalOrders.current());
    }

    /**
     * @dev Returns the number of orders in existence by OrderStatus.
     * @param byStatus Order status.
     */
    function totalOrdersBy(OrderStatus byStatus) external view override returns (uint256) {
        return (_ordersByStatus[byStatus].length());
    }

    /**
     * @dev Returns orders by status with pagination.
     * @param byStatus Order status.
     * @param cursor Pagination cursor.
     * @param howMany Amount of elements.
     * @return orderIds Received orders.
     * @return newCursor New position of the cursor.
     */
    function fetchOrdersBy(
        OrderStatus byStatus,
        uint256 cursor,
        uint256 howMany
    ) external view override returns (uint256[] memory orderIds, uint256 newCursor) {
        return (_fetchWithPagination(_ordersByStatus[byStatus], cursor, howMany));
    }

    /**
     * @dev Returns orders by user and status with pagination.
     * @param byStatus Order status.
     * @param cursor Pagination cursor.
     * @param howMany Amount of elements.
     * @return orderIds Received orders.
     * @return newCursor New position of the cursor.
     */
    function fetchOrdersBy(
        address byUser,
        OrderStatus byStatus,
        uint256 cursor,
        uint256 howMany
    ) external view override returns (uint256[] memory orderIds, uint256 newCursor) {
        return (_fetchWithPagination(_ordersByUserByStatus[byUser][byStatus], cursor, howMany));
    }

    //
    // trade fee
    //

    /**
     * @dev Sets trade fee. Decimals = 2.
     * @param newTradeFeePercentage New fee value.
     */
    function setTradeFeePercentage(uint256 newTradeFeePercentage) external override onlyAdmin {
        _setTradeFeePercentage(newTradeFeePercentage);

        emit SetTradeFeePercentage({
            sender: _msgSender(),
            newTradeFeePercentage: newTradeFeePercentage,
            timestamp: block.timestamp
        });
    }

    /**
     * @dev Returns current trade fee. Decimals = 2.
     * @return Current trade fee.
     */
    function tradeFeePercentage() external view override returns (uint256) {
        return (_tradeFeePercentage);
    }

    //
    // settlement tokens
    //

    /**
     * @dev Add settlement token.
     * @param erc20 New settlement token address.
     */
    function addSettlementToken(address erc20) external override onlyAdmin {
        require(erc20.isContract(), "GameFiMarketplaceV1: token must be a contract");
        _settlementTokens.add(erc20);

        emit AddSettlementToken({sender: _msgSender(), erc20: erc20, timestamp: block.timestamp});
    }

    /**
     * @dev Add settlement token.
     * @param erc20 Settlement token to be removed.
     */
    function removeSettlementToken(address erc20) external override onlyAdmin {
        _settlementTokens.remove(erc20);

        emit RemoveSettlementToken({sender: _msgSender(), erc20: erc20, timestamp: block.timestamp});
    }

    /**
     * @dev Returns if the token is settlement.
     * @param erc20 Target token.
     */
    function containsSettlementToken(address erc20) external view override returns (bool) {
        return (_settlementTokens.contains(erc20));
    }

    /**
     * @dev Returns all settlement tokens.
     * @return erc20 Settlement tokens array.
     */
    function getSettlementTokens() external view override returns (address[] memory erc20) {
        return (_settlementTokens.values());
    }

    //
    // nft whitelist
    //

    /**
     * @dev Add erc721 token to whitelist. Allows to trade this token.
     * @param erc721 Target token.
     */
    function addToWhitelistErc721(address erc721) external override onlyAdmin {
        _zeroTokenCheck(erc721);

        _whitelistErc721.add(erc721);

        emit AddToWhitelistErc721({sender: _msgSender(), erc721: erc721, timestamp: block.timestamp});
    }

    /**
     * @dev Add erc1155 token to whitelist. Allows to trade this token.
     * @param erc1155 Target token.
     */
    function addToWhitelistErc1155(address erc1155) external override onlyAdmin {
        _zeroTokenCheck(erc1155);

        _whitelistErc1155.add(erc1155);

        emit AddToWhitelistErc1155({sender: _msgSender(), erc1155: erc1155, timestamp: block.timestamp});
    }

    /**
     * @dev Remove erc721 token from whitelist. Disallows to trade this token.
     * @param erc721 Target token.
     */
    function removeFromWhitelistErc721(address erc721) external override onlyAdmin {
        _zeroTokenCheck(erc721);

        _whitelistErc721.remove(erc721);

        emit RemoveFromWhitelistErc721({sender: _msgSender(), erc721: erc721, timestamp: block.timestamp});
    }

    /**
     * @dev Remove erc1155 token from whitelist. Disallows to trade this token.
     * @param erc1155 Target token.
     */
    function removeFromWhitelistErc1155(address erc1155) external override onlyAdmin {
        _zeroTokenCheck(erc1155);

        _whitelistErc1155.remove(erc1155);

        emit RemoveFromWhitelistErc1155({sender: _msgSender(), erc1155: erc1155, timestamp: block.timestamp});
    }

    /**
     * @dev Returns if the erc721 token is whitelisted.
     * @param erc721 Target token.
     */
    function containsWhitelistErc721(address erc721) external view override returns (bool) {
        return (_whitelistErc721.contains(erc721));
    }

    /**
     * @dev Returns if the erc1155 token is whitelisted.
     * @param erc1155 Target token.
     */
    function containsWhitelistErc1155(address erc1155) external view override returns (bool) {
        return (_whitelistErc1155.contains(erc1155));
    }

    /**
     * @dev Returns all whitelisted erc721 tokens.
     * @return erc721 Whitelisted tokens array.
     */
    function getWhitelistErc721() external view override returns (address[] memory erc721) {
        return (_whitelistErc721.values());
    }

    // TODO проверить return аргументы на однотипность

    /**
     * @dev Returns all whitelisted erc1155 tokens.
     * @return erc1155 Whitelisted tokens array.
     */
    function getWhitelistErc1155() external view override returns (address[] memory erc1155) {
        return (_whitelistErc1155.values());
    }

    //
    // other
    //

    /**
     * @dev Withdraw erc20 tokens. If erc20 == address(0), sends ETH.
     * @param erc20 Target token.
     * @param amount Token amount.
     */
    function withdrawERC20(address erc20, uint256 amount) external override nonReentrant onlyAdmin {
        if (erc20 != address(0)) {
            IERC20Upgradeable(erc20).safeTransfer(_msgSender(), amount);
        } else {
            payable(_msgSender()).sendValue(amount);
        }
        emit WithdrawERC20({sender: _msgSender(), tokenContract: erc20, amount: amount, timestamp: block.timestamp});
    }

    //
    // entity info
    //

    /**
     * @dev Returns smart contract name.
     * @return Current SC name.
     */
    function name() external pure override returns (string memory) {
        return "GameFiMarketplaceV1";
    }

    /**
     * @dev Returns smart contract version.
     * @return Current SC version.
     */
    function version() external pure override returns (string memory) {
        return "1.1.0";
    }

    //
    // internal functions
    //

    function _setTradeFeePercentage(uint256 newTradeFeePercentage) internal {
        require(
            newTradeFeePercentage >= 0 && newTradeFeePercentage < 100_00,
            "GameFiMarketplaceV1: wrong percent value"
        );
        _tradeFeePercentage = newTradeFeePercentage;
    }

    function _fetchWithPagination(
        EnumerableSetUpgradeable.UintSet storage set,
        uint256 cursor,
        uint256 howMany
    ) internal view returns (uint256[] memory values, uint256 newCursor) {
        uint256 length = howMany;
        if (length > set.length() - cursor) {
            length = set.length() - cursor;
        }

        values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = set.at(cursor + i);
        }

        return (values, cursor + length);
    }

    function _zeroTokenCheck(address token) internal pure {
        require(token != address(0), "GameFiMarketplaceV1: zero token address");
    }

    //
    // GSN
    //

    /**
     * @dev Sets trusted forwarder contract (see https://docs.opengsn.org/).
     * @param newTrustedForwarder New trusted forwarder contract.
     */
    function setTrustedForwarder(address newTrustedForwarder) external override onlyAdmin {
        _setTrustedForwarder(newTrustedForwarder);
    }

    /**
     * @dev Returns recipient version of the GSN protocol (see https://docs.opengsn.org/).
     * @return Version string in SemVer.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
    }
}