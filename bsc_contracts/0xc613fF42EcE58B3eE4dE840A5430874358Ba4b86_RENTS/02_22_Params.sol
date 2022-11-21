// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '../plugins/TokensHandler.sol';
import '../plugins/IDiscounts.sol';
import '../plugins/Payable.sol';


contract RENTSPARAMS is ERC721Holder, ERC1155Holder, TokensHandler, Payable {

    uint public id;
    uint public fee = 20;
    address public discounts;
    address public methods;
    enum Status {
        LISTED,
        RENTED,
        CANCELLED,
        TERMINATED
    }
    struct Rent {
        address owner;
        address currency;
        address client;
        address[] nftAddresses;
        uint[] nftIds;
        uint[] nftAmounts;
        uint returningTime;
        uint valability;
        uint expiration;
        uint price;
        uint fee;
        uint32[] nftTypes;
        Status status;
    }
    mapping(uint => Rent) public rents;

    event NewRent(uint indexed id, Rent rent);
    event RentOngoing(uint indexed id, Rent rent);
    event RentCancelled(uint indexed id, Rent rent);
    event RentDone(uint indexed id, Rent rent);

}