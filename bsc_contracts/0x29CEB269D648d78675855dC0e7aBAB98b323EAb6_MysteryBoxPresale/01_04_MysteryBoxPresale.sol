// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MysteryBoxPresale is Ownable {

    // @notice Address of the token that is used for purchasing MysteryBox
    address public tokenAddress;

    // @notice boxId --> price
    mapping(uint256 => uint256) public prices;
    uint256 public receiptNonce;

    event MysteryBoxReceipt(address buyer, uint256 boxId, uint256 amount, uint256 price, uint256 nonce);
    event Withdraw(address withdrawer, uint256 amount);
    event PriceChanged(uint256 boxId, uint256 oldPrice, uint256 newPrice);

    error NotSellableItemError();
    error InsufficientAllowanceError();
    error EmptyTokenBalanceError();
    error TransferFailedError();

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    /**
     * @notice Purchasing mystery box and getting MysteryBoxReceipt used for getting mystery box
     * @param _boxId Id of mystery box
     * @param _amount Amount of mystery boxes user want to purchase
     */
    function buyMysteryBox(uint256 _boxId, uint256 _amount) external {
        uint256 price = prices[_boxId];
        if (price == 0) {
            revert NotSellableItemError();
        }

        uint256 purchasePrice = price * _amount;
        IERC20 token = IERC20(tokenAddress);

        uint256 allowance = token.allowance(msg.sender, address(this));
        if (allowance < purchasePrice) {
            revert InsufficientAllowanceError();
        }

        bool success = token.transferFrom(msg.sender, address(this), purchasePrice);
        if (success == false) {
            revert TransferFailedError();
        }

        receiptNonce += 1;
        emit MysteryBoxReceipt(msg.sender, _boxId, _amount, purchasePrice, receiptNonce);
    }

    /**
     * @notice Withdrawing earned tokens from mystery box sales to owner
     */
    function withdraw() external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert EmptyTokenBalanceError();
        }
        bool success = token.transfer(msg.sender, balance);
        if (success == false) {
            revert TransferFailedError();
        }
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Allow to set price for MysteryBox
     * @param _boxId Id of the mystery box
     * @param _price New price for mystery box
     */
    function setPrice(uint256 _boxId, uint256 _price) external onlyOwner {
        uint256 price = prices[_boxId];
        emit PriceChanged(_boxId, price, _price);
        prices[_boxId] = _price;
    }
}