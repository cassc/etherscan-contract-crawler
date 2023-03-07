// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract OTC is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    address public constant MUSD = 0x22a2C54b15287472F4aDBe7587226E3c998CdD96;
    address public constant MAI = 0x35803e77c3163FEd8A942536C1c8e0d5bF90f906;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public PRICE_PRECISION;
    uint256 public MIN_AMOUNT;
    uint256 public MIN_REMAIN_AMOUNT;
    uint256 public lastPrice;
    uint256 private _tokenId;

    mapping(uint256 => EnumerableSetUpgradeable.UintSet) private marketPrices;
    mapping(uint256 => mapping(uint256 => uint256)) private priceTotals;
    mapping(uint256 => mapping(uint256 => EnumerableSetUpgradeable.UintSet)) private marketIds;
    mapping(address => EnumerableSetUpgradeable.UintSet) private pendingIds;
    mapping(uint256 => Order) private orders;

    struct Order {
        uint256 direct;
        uint256 price;
        uint256 total;
        uint256 remain;
        address token;
        address sender;
        uint256 status;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        PRICE_PRECISION = 1e16;
        MIN_AMOUNT = 10e18;
        MIN_REMAIN_AMOUNT = 10e18;
    }

    function init2(
        uint256 _precision,
        uint256 _min,
        uint256 _remain
    ) external onlyRole(OPERATOR_ROLE) {
        PRICE_PRECISION = _precision;
        MIN_AMOUNT = _min;
        MIN_REMAIN_AMOUNT = _remain;
    }

    function pending(
        uint256 direct,
        uint256 price,
        uint256 amount
    ) external {
        require(amount >= MIN_AMOUNT, "invalid amount");
        require(price % PRICE_PRECISION == 0, "invalid price");
        address token = direct == 1 ? MUSD : MAI;
        uint256 outAmount = direct == 1 ? (amount * price) / 1e18 : amount;
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), outAmount);

        marketPrices[direct].add(price);
        priceTotals[direct][price] += amount;
        marketIds[direct][price].add(_tokenId);
        pendingIds[msg.sender].add(_tokenId);

        orders[_tokenId].direct = direct;
        orders[_tokenId].price = price;
        orders[_tokenId].total = amount;
        orders[_tokenId].remain = amount;
        orders[_tokenId].status = 0;
        orders[_tokenId].token = token;
        orders[_tokenId].sender = msg.sender;
        _tokenId++;
    }

    function trade(uint256 _index, uint256 amount) external {
        require(_index >= 0, "invalid index");
        require(amount > 0, "invalid amount");
        Order storage order = orders[_index];
        require(order.status == 0, "status error");
        require(order.remain >= amount, "Insufficient remain");
        if (amount != order.remain) {
            require(order.remain - amount >= MIN_REMAIN_AMOUNT, "at least remain");
        }

        bool isBuy = order.direct == 1;
        address token = isBuy ? MAI : MUSD;
        uint256 outAmount = isBuy ? amount : (amount * order.price) / 1e18;
        uint256 inAmount = isBuy ? (amount * order.price) / 1e18 : amount;

        removeFromMarket(order.direct, order.price, amount);
        if (amount == order.remain) {
            marketIds[order.direct][order.price].remove(_index);
            order.status = 1;
        }
        order.remain = order.remain - amount;

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, order.sender, outAmount);
        IERC20Upgradeable(order.token).safeTransfer(msg.sender, inAmount);
        lastPrice = order.price;
    }

    function batchTrade(uint256[] memory _ids) external {
        require(_ids.length > 0, "Invalid ids");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _index = _ids[i];
            Order memory order = orders[_index];
            if (order.direct != 1 && order.direct != 2) {
                continue;
            }
            bool isBuy = order.direct == 1;
            address token = isBuy ? MAI : MUSD;
            uint256 outAmount = isBuy ? order.remain : (order.remain * order.price) / 1e18;
            uint256 inAmount = isBuy ? (order.remain * order.price) / 1e18 : order.remain;

            marketIds[order.direct][order.price].remove(_index);
            removeFromMarket(order.direct, order.price, order.remain);

            order.remain = 0;
            order.status = 1;
            IERC20Upgradeable(token).safeTransferFrom(msg.sender, order.sender, outAmount);
            IERC20Upgradeable(order.token).safeTransfer(msg.sender, inAmount);
            lastPrice = order.price;
        }
    }

    function cancel(uint256 _index) external {
        require(_index >= 0, "invalid index");
        Order storage order = orders[_index];
        require(order.status == 0, "status error");
        require(order.sender == msg.sender, "No permission");

        bool isBuy = order.direct == 1;
        address token = isBuy ? MUSD : MAI;
        uint256 amount = isBuy ? (order.remain * order.price) / 1e18 : order.remain;

        marketIds[order.direct][order.price].remove(_index);
        removeFromMarket(order.direct, order.price, order.remain);

        orders[_index].status = 2;
        orders[_index].remain = 0;
        IERC20Upgradeable(token).safeTransfer(order.sender, amount);
    }

    function removeFromMarket(
        uint256 _direct,
        uint256 _price,
        uint256 _amount
    ) private {
        if (priceTotals[_direct][_price] - _amount == 0) {
            marketPrices[_direct].remove(_price);
        }
        priceTotals[_direct][_price] -= _amount;
    }

    function getMarketPrices(uint256 _direct) external view returns (uint256[] memory) {
        return marketPrices[_direct].values();
    }

    function getPriceTotals(uint256 _direct, uint256 _price) external view returns (uint256) {
        return priceTotals[_direct][_price];
    }

    function getMarketIds(uint256 _direct, uint256 _price) external view returns (uint256[] memory indexs) {
        return marketIds[_direct][_price].values();
    }

    function getPendingIds(address _addr) external view returns (uint256[] memory) {
        return pendingIds[_addr].values();
    }

    function getOrderInfo(uint256 _index) external view returns (Order memory) {
        return orders[_index];
    }
}