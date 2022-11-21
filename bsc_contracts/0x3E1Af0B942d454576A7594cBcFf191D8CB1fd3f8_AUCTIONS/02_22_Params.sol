// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '../plugins/TokensHandler.sol';
import '../plugins/IDiscounts.sol';
import '../plugins/Payable.sol';


contract AUCTIONSPARAMS is ERC721Holder, ERC1155Holder, TokensHandler, Payable {

    uint public id;
    uint public fee = 20;
    address public discounts;
    address public methods;
    enum Status {
        LISTED,
        ONGOING,
        FINISHED,
        CANCELLED
    }
    struct Auction {
        address owner;
        address winner;
        address currency;
        address[] nftAddresses;
        uint[] nftIds;
        uint[] nftAmounts;
        uint price;
        uint tax;
        uint currentBid;
        uint32[] nftTypes;
        Status status;
    }
    mapping(uint => Auction) public auctions;
    
    event NewAuction(uint indexed id, Auction auction);
    event Cancellation(uint indexed id, Auction auction);
    event Bid(uint indexed id, Auction auction);
    event Finished(uint id, Auction auction);

}