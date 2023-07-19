// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

/// @author 3n16m4.eth (c) 2023
/// @notice Make a wish 11:11 (https://11h11.io)

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

error onlyContractOwner();
error zeroPrice();
error zeroAddress();
error transferFailed();
error approvalFailed();

contract PriceOracle is IPriceOracle, Ownable {
    using SafeERC20 for IERC20;
    uint256 public price;

    event ChangedPrice(uint256 oldPrice, uint256 newPrice);

    constructor(uint256 _price) {
        price = _price;
    }

    receive() external payable {}

    function changePrice(uint256 newPrice) external onlyOwner {
        if (newPrice == 0) {
            revert zeroPrice();
        }

        emit ChangedPrice(price, newPrice);
        price = newPrice;
    }

    function withdrawEther(address recipient) external onlyOwner {
        if (recipient == address(0)) {
            revert zeroAddress();
        }

        payable(recipient).transfer(address(this).balance);
    }

    function withdrawToken(
        address tokenContract,
        address recipient
    ) external onlyOwner {
        if (recipient == address(0)) {
            revert zeroAddress();
        }

        bool success;
        IERC20 token = IERC20(tokenContract);

        success = token.approve(address(this), token.balanceOf(address(this)));
        if (!success) {
            revert approvalFailed();
        }

        success = token.transferFrom(
            address(this),
            recipient,
            token.balanceOf(address(this))
        );
        if (!success) {
            revert transferFailed();
        }
    }

    function lastPrice() external view returns (uint256) {
        return price;
    }
}