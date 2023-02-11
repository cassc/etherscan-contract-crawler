// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Custom Offer Escrow Contract
 * @author Noman Aziz
 */
contract Escrow is ReentrancyGuard, Ownable {
    // State Variables
    address public escAcc;
    uint256 public escFee;
    uint256 public totalOffers = 0;
    uint256 public totalDelivered = 0;
    uint256 public totalWithdrawed = 0;

    mapping(uint256 => OfferStruct) private offers;
    mapping(address => OfferStruct[]) private offersOf;
    mapping(uint256 => address) public creatorOf;

    mapping(address => bool) public acceptedTokens;

    enum Status {
        PENDING,
        DELIVERED,
        DISPUTED,
        REFUNDED,
        WITHDRAWED
    }

    struct OfferStruct {
        uint256 offerId;
        string serviceType;
        uint256 amount;
        address paymentToken;
        uint256 timestamp;
        address creator;
        address acceptor;
        Status status;
    }

    event Action(
        uint256 offerId,
        string actionType,
        Status status,
        address indexed executor
    );

    /**
     * Constructor
     * @param _escFee is the escrow fee cut percentage
     * @param _tokenAddresses addresses of supported ERC20 tokens
     * @param _numberOfTokens length of array of token addresses
     */
    constructor(
        uint256 _escFee,
        address[] memory _tokenAddresses,
        uint256 _numberOfTokens
    ) {
        escAcc = msg.sender;
        escFee = _escFee;

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            acceptedTokens[_tokenAddresses[i]] = true;
        }
    }

    /**
     * Used to create an Escrow Offer
     * @param _serviceType service title of the offer
     * @param _acceptor address of the party accepting the offer
     * @param _token ERC20 token address which will be used for payment (should be in supported tokens)
     * @param _amount Amount of payable ERC20 tokens
     */
    function createOffer(
        string memory _serviceType,
        address _acceptor,
        address _token,
        uint256 _amount
    ) external payable returns (bool) {
        require(bytes(_serviceType).length > 0, "Service Type cannot be empty");
        require(acceptedTokens[_token], "Payment Token not supported");

        IERC20 token = IERC20(_token);

        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Payable amount is greater than allowance"
        );

        uint256 offerId = totalOffers++;
        OfferStruct memory offer;

        offer.offerId = offerId;
        offer.serviceType = _serviceType;
        offer.amount = _amount;
        offer.paymentToken = _token;
        offer.timestamp = block.timestamp;
        offer.creator = msg.sender;
        offer.acceptor = _acceptor;
        offer.status = Status.PENDING;

        offers[offerId] = offer;
        offersOf[msg.sender].push(offer);
        creatorOf[offerId] = msg.sender;

        bool receipt = token.transferFrom(msg.sender, address(this), _amount);

        emit Action(offerId, "OFFER CREATED", Status.PENDING, msg.sender);

        return receipt;
    }

    /**
     * Returns all the offers created
     */
    function getOffers() external view returns (OfferStruct[] memory props) {
        props = new OfferStruct[](totalOffers);

        for (uint256 i = 0; i < totalOffers; i++) {
            props[i] = offers[i];
        }
    }

    /**
     * Returns an offer struct based on offer id
     * @param offerId offer id
     */
    function getOffer(uint256 offerId)
        external
        view
        returns (OfferStruct memory)
    {
        return offers[offerId];
    }

    /**
     * Only returns all the created offers of the sender
     */
    function myOffers() external view returns (OfferStruct[] memory) {
        return offersOf[msg.sender];
    }

    /**
     * Used to complete or refund the offer
     * @param offerId id of the offer
     * @param completed whether it is completed or refunded
     */
    function confirmDelivery(uint256 offerId, bool completed)
        external
        returns (bool)
    {
        require(msg.sender == creatorOf[offerId], "Only creator allowed");
        require(
            offers[offerId].status == Status.PENDING,
            "Already delivered or withdrawed, create a new Offer"
        );

        if (completed) {
            uint256 fee = (offers[offerId].amount * escFee) / 100;

            IERC20 token = IERC20(offers[offerId].paymentToken);
            token.transfer(
                offers[offerId].acceptor,
                offers[offerId].amount - fee
            );

            offers[offerId].status = Status.DELIVERED;
            totalDelivered++;

            emit Action(offerId, "DELIVERED", Status.DELIVERED, msg.sender);
        } else {
            IERC20 token = IERC20(offers[offerId].paymentToken);
            token.transfer(offers[offerId].creator, offers[offerId].amount);

            offers[offerId].status = Status.REFUNDED;
            totalWithdrawed++;

            emit Action(offerId, "REFUNDED", Status.REFUNDED, msg.sender);
        }

        return true;
    }

    /**
     * Used to withdraw any ETH present in the contract
     * @param to address of the recipient
     * @param amount amount to send
     */
    function withdrawETH(address payable to, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        to.transfer(amount);

        emit Action(
            block.timestamp,
            "WITHDRAWED",
            Status.WITHDRAWED,
            msg.sender
        );

        return true;
    }

    /**
     * Used to transfer ERC20 tokens from the contract to any account
     * @param to Recipient account address
     * @param _token address of the ERC20 token
     * @param amount amount of tokens to send
     */
    function withdrawERC20Token(
        address to,
        address _token,
        uint256 amount
    ) external onlyOwner {
        require(acceptedTokens[_token], "Payment Token not supported");
        IERC20 token = IERC20(_token);
        token.transfer(to, amount);
    }

    /**
     * Used to add further supported ERC20 tokens
     * @param _tokenAddress address of the ERC20 token
     */
    function addSupportedToken(address _tokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        acceptedTokens[_tokenAddress] = true;
        return true;
    }

    /**
     * Used to update the current escrow fee
     * @param _escFee is the escrow fee cut percentage
     */
    function updateEscrowFee(uint256 _escFee)
        external
        onlyOwner
        returns (bool)
    {
        escFee = _escFee;
        return true;
    }
}