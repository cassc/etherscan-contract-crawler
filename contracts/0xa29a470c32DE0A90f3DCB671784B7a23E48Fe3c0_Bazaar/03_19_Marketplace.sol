// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../token/ERC2981/IERC2981.sol";
import "../utils/HasCosts.sol";
import "../utils/HasFees.sol";


abstract contract Marketplace is ERC1155Holder, HasCosts, HasFees {
    using Address for address payable;

    struct Asset {
        address collection;
        uint tokenId;
        uint amount;
    }

    event Sold(uint id, address collection, uint tokenId, address seller, address buyer, uint amount, uint price);
    event PaymentDelivered(uint id, address collection, uint tokenId, uint amount, address seller, uint payment, uint royalty, uint fee);

    /// Marketplace `id` does not exist; it may have been deleted
    error NoSuchMarketplace(uint id);

    /// Marketplace `id` cannot provide sufficient tokens; requested `requested`, but only `provided` is provided
    error InsufficientTokens(uint id, uint requested, uint provided);

    function exchange(uint id, address collection, uint tokenId, uint amount, uint price, address from, address to) internal virtual {
        deliverSoldToken(id, collection, tokenId, amount, price, address(this), to);
        deliverPayment(id, collection, tokenId, amount, price, from);
    }

    function deliverSoldToken(uint id, address collection, uint tokenId, uint amount, uint price, address from, address to) internal {
        IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, bytes(""));
        emit Sold(id, collection, tokenId, from, to, amount, price);
    }

    function deliverPayment(uint id, address collection, uint tokenId, uint amount, uint price, address to) internal {
        (address royaltyRecipient, uint royalty) = IERC165(collection).supportsInterface(type(IERC2981).interfaceId) ?
            IERC2981(collection).royaltyInfo(tokenId, price) :
            (address(0), 0);
        (address feeRecipient, uint fee) = feeInfo(price);
        uint payment = price - royalty - fee;
        if (royalty != 0) payable(royaltyRecipient).sendValue(royalty);
        if (fee != 0) payable(feeRecipient).sendValue(fee);
        payable(to).sendValue(payment);
        emit PaymentDelivered(id, collection, tokenId, amount, to, payment, royalty, fee);
    }
}