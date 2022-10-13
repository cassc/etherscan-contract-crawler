// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BlindboxSell is ERC1155Receiver, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    struct Box {
        uint256 amount;
        uint256 limit;
        uint256 price;
    }

    address public blindbox;
    address public currency;
    uint256 public startSaleAt;
    uint256 public globalBuyLimit = 6;
    mapping(uint256 => Box) public boxes;
    mapping(uint256 => uint256) public totalPurchasedPerBox;
    mapping(address => uint256) public totalPurchasedBoxes;
    mapping(address => mapping(uint256 => uint256)) public purchasedPerBox;

    // Events
    event Purchase(
        address _address,
        uint256[] _boxType,
        uint256[] _amount,
        uint256 _purchasedAt
    );
    event ChangeBlindbox(address _blindbox);
    event ChangeCurrency(address _currency);
    event ChangeStartSaleAt(uint256 _startSaleAt);
    event ChangeGlobalBuyLimit(uint256 _globalBuyLimit);
    event BoxListing(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _limit,
        uint256 _price
    );

    constructor(
        address _blindbox,
        address _currency,
        uint256 _startSaleAt
    ) ERC1155Receiver() {
        setBlindbox(_blindbox);
        setCurrency(_currency);
        setStartSaleAt(_startSaleAt);
    }

    function setBlindbox(address _blindbox) public onlyOwner {
        require(_blindbox != address(0), "Invalid blindbox address");
        blindbox = _blindbox;
        emit ChangeBlindbox(_blindbox);
    }

    function setStartSaleAt(uint256 _startSaleAt) public onlyOwner {
        require(
            _startSaleAt >= block.timestamp,
            "Start time must be in the future"
        );

        startSaleAt = _startSaleAt;
        emit ChangeStartSaleAt(_startSaleAt);
    }

    function setCurrency(address _currency) public onlyOwner {
        require(_currency != address(0), "Invalid currency address");
        currency = _currency;
        emit ChangeCurrency(_currency);
    }

    function setGlobalBuyLimit(uint256 _globalBuyLimit) public onlyOwner {
        require(_globalBuyLimit >= 0, "Invalid value");
        globalBuyLimit = _globalBuyLimit;
        emit ChangeGlobalBuyLimit(_globalBuyLimit);
    }

    function boxListing(
        uint256[] memory _tokenIds,
        uint256[] memory _prices,
        uint256[] memory _amounts,
        uint256[] memory _limits
    ) external onlyOwner {
        require(
            _tokenIds.length == _prices.length &&
                _prices.length == _amounts.length &&
                _amounts.length == _limits.length,
            "Four arrays must be same length"
        );

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            boxes[_tokenIds[index]] = Box({
                amount: _amounts[index],
                limit: _limits[index],
                price: _prices[index]
            });
            emit BoxListing(
                _tokenIds[index],
                _amounts[index],
                _limits[index],
                _prices[index]
            );
        }
    }

    function purchase(uint256[] memory _tokenIds, uint256[] memory _amounts)
        external
        whenNotPaused
        nonReentrant
    {
        require(
            _tokenIds.length == _amounts.length,
            "Two arrays must be same length"
        );
        uint256 requestAmount = 0;
        uint256 totalPrice = 0;
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            // Save gas for checking zero amount
            uint256 _amount = _amounts[index];
            if (_amount > 0) {
                uint256 _tokenId = _tokenIds[index];
                Box memory box = boxes[_tokenIds[index]];
                uint256 walletPurchasedBox = purchasedPerBox[msg.sender][
                    _tokenId
                ];
                require(
                    walletPurchasedBox + _amount <= box.limit,
                    "Exceed box buy limit"
                );
                totalPrice += box.price * _amount;
                requestAmount += _amount;
                totalPurchasedPerBox[_tokenId] += _amount;
                purchasedPerBox[msg.sender][_tokenId] =
                    walletPurchasedBox +
                    _amount;
            }
        }
        uint256 walletTotalPurchasedBoxes = totalPurchasedBoxes[msg.sender];
        require(
            walletTotalPurchasedBoxes + requestAmount <= globalBuyLimit,
            "Exceed global buy limit"
        );
        totalPurchasedBoxes[msg.sender] =
            walletTotalPurchasedBoxes +
            requestAmount;
        // transfer fund to owner wallet
        IERC20(currency).transferFrom(msg.sender, owner(), totalPrice);
        IERC1155(blindbox).safeBatchTransferFrom(
            address(this),
            msg.sender,
            _tokenIds,
            _amounts,
            ""
        );
        emit Purchase(msg.sender, _tokenIds, _amounts, block.timestamp);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4) {
        return
        bytes4(
            keccak256(
                "onERC1155Received(address,address,uint256,uint256,bytes)"
            )
        );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override pure returns (bytes4) {
        return
        bytes4(
            keccak256(
                "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
            )
        );
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

}