// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CPTPayment is AccessControl, ReentrancyGuard {
    error NotEOA();
    error InvalidQuantity();
    error SupplyExceeded();
    error NotInClaimPeriod();

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR ROLE");
    IERC20 private paymentToken;
    IERC721 private item;
    address private itemHolder;
    uint256 itemId = 714;
    uint256 public maxSupply = 50;
    uint256 public price = 25000 ether;
    uint256 public claimed;
    uint32 public startTime = 1684166400;
    uint32 public endTime = 1688054400;

    constructor(address _paymentToken, address _item, address _itemHolder) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        paymentToken = IERC20(_paymentToken);
        item = IERC721(_item);
        itemHolder = _itemHolder;
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) {
            revert NotEOA();
        }
        _;
    }

    function getSettings() external view returns (
        IERC20 _paymentToken,
        uint256 _itemId,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _claimed,
        uint32 _startTime,
        uint32 _endTime
    ) {
        _paymentToken = paymentToken;
        _itemId = itemId;
        _maxSupply = maxSupply;
        _price = price;
        _claimed = claimed;
        _startTime = startTime;
        _endTime = endTime;
    }

    function updateSchedule(
        uint32 _st,
        uint32 _et
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        startTime = _st;
        endTime = _et;
    }

    function updateItemSettings(
        uint256 _itemId,
        uint256 _maxSupply,
        uint256 _price
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        itemId = _itemId;
        maxSupply = _maxSupply;
        price = _price;
    }

    function buy(uint256 _quantity) external onlyEOA nonReentrant {
        if (startTime > block.timestamp || endTime < block.timestamp) {
            revert NotInClaimPeriod();
        }

        if (_quantity <= 0) {
            revert InvalidQuantity();
        }

        if (claimed + _quantity > maxSupply) {
            revert SupplyExceeded();
        }

        uint256 totalPrice = price * _quantity;

        if (totalPrice > 0) {
            paymentToken.transferFrom(msg.sender, address(this), totalPrice);
        }

        for (uint256 i = 0; i < _quantity; i++) {
            item.transferFrom(itemHolder, msg.sender, itemId + claimed);
            claimed++;
        }
    }

    function withdraw(
        address _to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 amount = paymentToken.balanceOf(address(this));
        if (amount > 0) {
            paymentToken.transfer(_to, amount);
        }
    }

    function balance() external view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }
}