//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract NFTFactoryNodeBuyer is EIP712, Ownable, AccessControl {

    //Ticket signing 
    string private constant SIGNING_DOMAIN = "NFTFactoryNodeBuyer";
    string private constant SIGNATURE_VERSION = "1";

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    //Max tokens by user
    uint256 private constant MAX_TOKENS_BY_USER = 1;

    //Ticket
    struct SignedTicket {
        //The id of the ticket to be redeemed. Must be unique - if another ticket with this ID already exists, the buyWithTicket function will revert.
        uint256 ticketId;

        //Token infos
        uint256 tokenId;
        uint256 amount;
        uint256 tokenId2;
        uint256 amount2;
        uint256 price;

        //EIP-712 signature of all other fields in the SignedTicket struct. For a ticket to be valid, it must be signed by a signer.
        bytes signature;
    }

    //Tickets used
    mapping(uint256 => bool) private _tickets_used;

    //ERC1155 contract interface
    IERC1155 private _erc1155Contract;

    bool private _is_locked; // only ticket buy is allowed

    //Mapping from token ID to price
    mapping(uint256 => uint256) private _prices;

    //Withdrawals balance for owner
    uint256 private _pendingWithdrawals;


    //Construct with ERC1155 contract address
    constructor(address erc1155Addr) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _erc1155Contract = IERC1155(erc1155Addr);
        _is_locked = true;

        _setupRole(SIGNER_ROLE, _msgSender());
    }

    function unlock() public onlyOwner {
        _is_locked = false;
    }

    //Set prices of tokens
    function setPrice(uint256 tokenId, uint256 price) public onlyOwner {

        require(price > 0, 'NFTFactoryNodeBuyer: price must be > 0');

        _prices[tokenId] = price;
    }

    function setPriceBatch(uint256[] memory tokenIds, uint256[] memory prices) public onlyOwner {

        require(tokenIds.length == prices.length, 'NFTFactoryNodeBuyer: tokensIds and prices length do not match');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(prices[i] > 0, 'NFTFactoryNodeBuyer: price must be > 0');
            _prices[tokenIds[i]] = prices[i];
        }
    }

    function getPrice(uint256 tokenId) public view returns(uint256) {
        return _prices[tokenId];
    }

    //Buy function
    function buyToken(address to, uint256 tokenId, uint256 amount, bytes memory data) public payable {

        uint256 totalAmount = amount + _erc1155Contract.balanceOf(to, tokenId);
        uint256 totalPrice = _prices[tokenId] * amount;

        require(!_is_locked, 'NFTFactoryNodeBuyer: you need a ticket to buy tokens');
        require(_prices[tokenId] > 0, 'NFTFactoryNodeBuyer: wrong token id');
        require(totalAmount <= MAX_TOKENS_BY_USER, "NFTFactoryNodeBuyer: max tokens by user exceeded");
        require(msg.value >= totalPrice, "NFTFactoryNodeBuyer: not enough ETH sent");

        //Check overflows
        require(totalAmount >= amount, 'NFTFactoryNodeBuyer: amount overflow');
        require(totalPrice >= _prices[tokenId], 'NFTFactoryNodeBuyer: price overflow');        

        //Transfer tokens
        _erc1155Contract.safeTransferFrom(
            owner(),
            to,
            tokenId,
            amount,
            data
        );

        //Record payment to signer's withdrawal balance
        _pendingWithdrawals += msg.value;
    }

    //BuyBatch function
    function buyTokenBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) public payable {
        
        require(!_is_locked, 'NFTFactoryNodeBuyer: you need a ticket to buy tokens');
        require(tokenIds.length == amounts.length, 'NFTFactoryNodeBuyer: tokensIds and amounts length do not match');

        uint256 totalAmount = 0;
        uint256 prevAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_prices[tokenIds[i]] > 0, 'NFTFactoryNodeBuyer: wrong token id');
            require(amounts[i] <= MAX_TOKENS_BY_USER, "NFTFactoryNodeBuyer: max tokens by user exceeded");
            prevAmount = totalAmount;
            totalAmount += _prices[tokenIds[i]] * amounts[i];

            //Check overflows
            require(totalAmount >= prevAmount, 'NFTFactoryNodeBuyer: amount overflow');
        }
        require(msg.value >= totalAmount, "NFTFactoryNodeBuyer: not enough ETH sent");

        //Transfer tokens
        _erc1155Contract.safeBatchTransferFrom(
            owner(),
            to,
            tokenIds,
            amounts,
            data
        );

        //Record payment to signer's withdrawal balance
        _pendingWithdrawals += msg.value;
    }

    //Buy with signed ticket
    function buyWithTicket(address to, SignedTicket calldata ticket, bytes memory data) public payable {

        require(!_tickets_used[ticket.ticketId], "NFTFactoryNodeBuyer: ticket already used");
        require(msg.value >= ticket.price, "NFTFactoryNodeBuyer: not enough ETH sent");

        //Make sure signature is valid and get the address of the signer
        address signer = _verify(ticket);

        //Make sure that the signer is allowed
        require(hasRole(SIGNER_ROLE, signer), "Signature invalid or unauthorized");

        _tickets_used[ticket.ticketId] = true;

        //Transfer tokens
        _erc1155Contract.safeTransferFrom(
            owner(),
            to,
            ticket.tokenId,
            ticket.amount,
            data
        );

        if (ticket.tokenId2 != 0)
        {
            _erc1155Contract.safeTransferFrom(
                owner(),
                to,
                ticket.tokenId2,
                ticket.amount2,
                data
            );
        }

        //Record payment to signer's withdrawal balance
        _pendingWithdrawals += msg.value;
    }

    //Verifies the signature for a given SignedTicket, returning the address of the signer.
    function _verify(SignedTicket calldata ticket) internal view returns (address) {
        bytes32 digest = _hash(ticket);
        return ECDSA.recover(digest, ticket.signature);
    }
    //Returns a hash of the given SignedTicket, prepared using EIP712 typed data hashing rules
    function _hash(SignedTicket calldata ticket) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("SignedTicket(uint256 ticketId,uint256 tokenId,uint256 amount,uint256 tokenId2,uint256 amount2,uint256 price)"),
        ticket.ticketId,
        ticket.tokenId,
        ticket.amount,
        ticket.tokenId2,
        ticket.amount2,
        ticket.price
        )));
    }
    //Returns the chain id of the current blockchain.
    //This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    //  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    //Transfers all pending withdrawal balance to the owner
    function withdraw() public onlyOwner {
        
        //Owner must be a payable address.
        address payable receiver = payable(msg.sender);

        uint amount = _pendingWithdrawals;

        //Set zero before transfer to prevent re-entrancy attack
        _pendingWithdrawals = 0;
        receiver.transfer(amount);
    }

    //Retuns the amount of Ether available to withdraw.
    function availableToWithdraw() public view onlyOwner returns (uint256) {
        return _pendingWithdrawals;
    }
}