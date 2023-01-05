// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Secret is AccessControlUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event LogOrderDeposit(uint256 orderId);
    event LogOrderRelease(uint256 orderId);
    event LogOrderBackout(uint256 orderId);
    event LogOrderFinish(uint256 orderId);

    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    uint256 private count;

    struct Order {
        uint32 time;
        address from;
        address to;
        address token;
        uint256 amount;
        uint256 preAmount;
        uint256 release;
    }

    mapping(uint256 => Order) private orders;
    mapping(address => EnumerableSetUpgradeable.UintSet) private sendOrderIds;
    mapping(address => EnumerableSetUpgradeable.UintSet) private receiveOrderIds;
    mapping(address => uint256[]) private finishOrderIds;

    EnumerableSetUpgradeable.AddressSet private supportTokens;

    function initialize() external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MAINTAINER_ROLE, _msgSender());
    }

    function deposit(
        address token,
        address to,
        uint256 amount,
        uint256 preAmount
    ) external {
        require(supportTokens.contains(token),"Not support token.");
        count += 1;
        orders[count].time = uint32(block.timestamp);
        orders[count].from = _msgSender();
        orders[count].to = to;
        orders[count].token = token;
        orders[count].amount = amount;
        orders[count].preAmount = preAmount;
        sendOrderIds[_msgSender()].add(count);
        receiveOrderIds[to].add(count);
        IERC20Upgradeable(token).safeTransferFrom(_msgSender(), address(this), amount);
        emit LogOrderDeposit(count);
    }

    function release(uint256 orderId, uint256 amount) external {
        require(sendOrderIds[_msgSender()].contains(orderId), "Forbidden, not you own");
        Order memory order = orders[orderId];
        require(order.release + amount <= order.amount, "Insufficient deposit");
        if (order.release + amount == order.amount) {
            handleFinish(_msgSender(), order.to, orderId);
        }
        orders[orderId].release += amount;
        IERC20Upgradeable(order.token).safeTransfer(order.to, amount);
        emit LogOrderRelease(count);
    }

    function backout(uint256 orderId) external {
        require(sendOrderIds[_msgSender()].contains(orderId), "Forbidden, not you own");
        Order memory order = orders[orderId];
        uint256 amount = order.amount - order.release;
        handleFinish(_msgSender(), order.to, orderId);
        IERC20Upgradeable(order.token).safeTransfer(_msgSender(), amount);
        emit LogOrderBackout(count);
    }

    function sendingOrderList() external view returns (uint256[] memory orderIds, Order[] memory orders_) {
        orderIds = sendOrderIds[_msgSender()].values();
        orders_ = new Order[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; i++) {
            orders_[i] = orders[orderIds[i]];
        }
    }

    function receivingOrderList() external view returns (uint256[] memory orderIds, Order[] memory orders_) {
        orderIds = receiveOrderIds[_msgSender()].values();
        orders_ = new Order[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; i++) {
            orders_[i] = orders[orderIds[i]];
        }
    }

    function finishOrderList(uint256 offset, uint256 size)
        external
        view
        returns (uint256[] memory orderIds, Order[] memory orders_)
    {
        if (offset + size > finishOrderIds[_msgSender()].length) {
            size = finishOrderIds[_msgSender()].length - offset;
        }
        orderIds = new uint256[](size);
        orders_ = new Order[](size);
        for (uint256 i = 0; i < orderIds.length; i++) {
            orderIds[i] = finishOrderIds[_msgSender()][i + offset];
            orders_[i] = orders[orderIds[i]];
        }
    }

    function handleFinish(
        address from,
        address to,
        uint256 orderId
    ) private {
        sendOrderIds[from].remove(orderId);
        receiveOrderIds[to].remove(orderId);
        finishOrderIds[from].push(orderId);
        finishOrderIds[to].push(orderId);
        emit LogOrderFinish(orderId);
    }

    function addSupportToken(address token) external onlyRole(MAINTAINER_ROLE) {
        supportTokens.add(token);
    }

    function removeSupportToken(address token) external onlyRole(MAINTAINER_ROLE) {
        supportTokens.remove(token);
    }

    function supportTokenList() external view returns (address[] memory) {
        return supportTokens.values();
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}