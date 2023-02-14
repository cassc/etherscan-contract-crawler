// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../token/ERC2981/IERC2981.sol";
import "../utils/HasCosts.sol";
import "../utils/HasFees.sol";
import "../utils/Monetary.sol";


abstract contract Marketplace is ERC721Holder, ERC1155Holder, HasCosts, HasFees {
    using Address for address payable;
    using Monetary for Monetary.Crypto;

    struct Asset {
        address collection;
        uint tokenId;
        uint amount;
    }

    event Sold(uint id, address seller, address buyer, Asset asset, Monetary.Crypto price);
    event PaymentDelivered(uint id, Asset asset, address seller, Monetary.Crypto payment, Monetary.Crypto royalty, Monetary.Crypto fee);

    /// Marketplace `id` does not exist; it may have been deleted
    error NoSuchMarketplace(uint id);

    /// Marketplace `id` cannot provide sufficient tokens; requested `requested`, but only `provided` is provided
    error InsufficientTokens(uint id, uint requested, uint provided);

    function validate(Asset memory asset) internal view {
        require(asset.amount != 0, "token amount must be positive");
        if (IERC165(asset.collection).supportsInterface(type(IERC721).interfaceId))
            require(
                IERC721(asset.collection).getApproved(asset.tokenId) == address(this) || IERC721(asset.collection).isApprovedForAll(msg.sender, address(this)),
                "ERC721: token or contract not approved for transfer"
            );
        else if (IERC165(asset.collection).supportsInterface(type(IERC1155).interfaceId))
            require(IERC1155(asset.collection).isApprovedForAll(msg.sender, address(this)), "ERC1155: contract not approved for transfer");
        else
            revert("only ERC721 & ERC1155 collections are supported");
    }

    function balanceOf(address collection, address owner, uint tokenId) internal view returns (uint) {
        return IERC165(collection).supportsInterface(type(IERC1155).interfaceId) ?
            IERC1155(collection).balanceOf(owner, tokenId) :
            IERC721(collection).ownerOf(tokenId) == owner ? 1 : 0;
    }

    function transfer(Asset memory asset, address from, address to) internal {
        if (IERC165(asset.collection).supportsInterface(type(IERC721).interfaceId))
            IERC721(asset.collection).safeTransferFrom(from, to, asset.tokenId);
        else
            IERC1155(asset.collection).safeTransferFrom(from, to, asset.tokenId, asset.amount, bytes(""));
    }

    function exchange(uint id, Asset memory asset, Monetary.Crypto memory price, address from, address to) internal virtual {
        deliverSoldToken(id, asset, price, address(this), to);
        deliverPayment(id, asset, price, from);
    }

    function deliverSoldToken(uint id, Asset memory asset, Monetary.Crypto memory price, address from, address to) internal {
        transfer(asset, from, to);
        emit Sold(id, from, to, asset, price);
    }

    function royaltyInfo(Asset memory asset, Monetary.Crypto memory price) private view returns (address, Monetary.Crypto memory) {
        (address receiver, uint amount) = IERC165(asset.collection).supportsInterface(type(IERC2981).interfaceId) ?
            IERC2981(asset.collection).royaltyInfo(asset.tokenId, price.amount) :
            (address(0), 0);
        return (receiver, Monetary.Crypto(amount, price.currency));
    }

    function deliverPayment(uint id, Asset memory asset, Monetary.Crypto memory total, address seller) internal {
        (address royaltyRecipient, Monetary.Crypto memory royalty) = royaltyInfo(asset, total);
        (address feeRecipient, Monetary.Crypto memory fee) = feeInfo(total);
        Monetary.Crypto memory payment = total.minus(royalty).minus(fee);
        royalty.transferTo(royaltyRecipient);
        fee.transferTo(feeRecipient);
        payment.transferTo(seller);
        emit PaymentDelivered(id, asset, seller, payment, royalty, fee);
    }
}