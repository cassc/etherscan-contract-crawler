// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '../plugins/TokensHandler.sol';
import '../plugins/IDiscounts.sol';
import '../plugins/Payable.sol';


contract SALESPARAMS is ERC721Holder, ERC1155Holder, TokensHandler, Payable {

    uint public id;
    uint public fee = 20;
    address public discounts;
    address public methods;
    enum Status {
        LISTED,
        CANCELLED,
        PURCHASED
    }
    struct Sale {
        address seller;
        address buyer;
        address currency;
        address[] nftAddresses;
        uint[] nftIds;
        uint[] nftAmounts;
        uint[] amounts;
        uint price;
        uint32[] nftTypes;
        Status status;
    }
    mapping(uint => Sale) public sales;

    event NewSale(uint indexed id, Sale sale);
    event Purchase(uint indexed id, Sale sale);
    event Cancellation(uint indexed id, Sale sale);

}