// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./RoyaltyLibrary.sol";

library PaymentLibrary {
    function escrowFund(address tokenContractAddr, uint256 price) internal {
        if (tokenContractAddr == address(0)) {
            require(msg.value >= price, "Insufficient Fund");
        } else {
            IERC20(tokenContractAddr).transferFrom(
                msg.sender,
                address(this),
                price
            );
        }
    }

    function transferFund(
        address tokenContractAddr,
        uint256 price,
        address destination
    ) internal {
        if (tokenContractAddr == address(0)) {
            payable(destination).transfer(price);
        } else {
            IERC20(tokenContractAddr).transfer(destination, price);
        }
    }

    function payFund(
        address tokenContractAddr,
        uint256 price,
        address destination,
        address royaltyAddr,
        uint256 royaltyPercent,
        address contractAddr,
        uint256 tokenId
    ) internal {
        require(
            royaltyPercent == 0 || royaltyAddr != address(0),
            "Royalty Address Not Set"
        );
        uint256 saleValue;
        if (RoyaltyLibrary.hasRoyalty(contractAddr)) {
            saleValue = RoyaltyLibrary.deduceRoyalties(
                contractAddr,
                tokenId,
                tokenContractAddr,
                price
            );
        } else {
            saleValue = price;
        }
        if (royaltyPercent > 0) {
            transferFund(
                tokenContractAddr,
                (saleValue * royaltyPercent) / 10000,
                royaltyAddr
            );
        }
        transferFund(
            tokenContractAddr,
            (saleValue * (10000 - royaltyPercent)) / 10000,
            destination
        );
    }
}