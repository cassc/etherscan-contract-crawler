// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @title Custom Offer Escrow Contract V3
 * @author Noman Aziz
 */

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Escrow {
    // State Variables
    address public escAcc;
    uint256 public escFee;
    uint256 public disputeFee;
    uint256 public minIDEABalance;

    address public constant IDEA_TOKEN =
        0x5d3a4F62124498092Ce665f865E0b38fF6F5FbEa;

    uint256 public totalOffers = 0;

    mapping(uint256 => OfferStruct) private offers;

    mapping(address => uint256) public escAvailTokenBal;

    enum Status {
        PENDING,
        DELIVERED,
        DISPUTED,
        REFUNDED,
        WITHDRAWED
    }

    struct OfferStruct {
        uint256 offerId;
        uint256 amount;
        address paymentToken;
        address buyer;
        address seller;
        string proofUrl;
        Status status;
    }

    event Action(uint256 offerId, Status status, address indexed executor);
    event DisputeResolution(uint256 offerId, bool refunded);

    modifier onlyOwner() {
        require(msg.sender == escAcc, "Only contract owner can call");
        _;
    }

    /**
     * Constructor
     * @param _escFee is the escrow fee cut percentage
     * @param _disputeFee is the dispute fee cut percentage
     * @param _minIDEABalance is the minimum IDEA TOKEN balance present in the user's account on which there is half fee
     */
    constructor(uint256 _escFee, uint256 _disputeFee, uint256 _minIDEABalance) {
        escAcc = msg.sender;
        escFee = _escFee;
        disputeFee = _disputeFee;
        minIDEABalance = _minIDEABalance;
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
    function getOffer(
        uint256 offerId
    ) external view returns (OfferStruct memory) {
        return offers[offerId];
    }

    /**
     * Utility function used to calculate escrow fee on specific conditions
     * No escrow fee deducted on using IDEA_TOKEN
     * Half escrow fee is deducted in case buyer has IDEA_TOKENS in his account greater than equal to MINIMUM_IDEA_BALANCE
     * @param offerId id of the offer
     */
    function _calculateEscrowFee(
        uint256 offerId
    ) internal view returns (uint256) {
        uint256 fee;

        uint256 ideaTokenBalance = IERC20(IDEA_TOKEN).balanceOf(
            offers[offerId].buyer
        );

        if (offers[offerId].paymentToken == IDEA_TOKEN) {
            fee = 0;
        } else if (ideaTokenBalance >= minIDEABalance) {
            fee = (offers[offerId].amount * (escFee / 2)) / 100;
        } else {
            fee = (offers[offerId].amount * escFee) / 100;
        }

        return fee;
    }

    /**
     * Used to create an Escrow Offer
     * @param _acceptor address of the party accepting the offer
     * @param _token ERC20 token address which will be used for payment (should be in supported tokens)
     * @param _amount Amount of payable ERC20 tokens
     */
    function createOffer(
        address _acceptor,
        address _token,
        uint256 _amount
    ) external {
        uint256 offerId = totalOffers++;

        offers[offerId] = OfferStruct({
            offerId: offerId,
            amount: _amount,
            paymentToken: _token,
            buyer: msg.sender,
            seller: _acceptor,
            status: Status.PENDING,
            proofUrl: ""
        });

        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        emit Action(offerId, Status.PENDING, msg.sender);
    }

    /**
     * Used to complete or dispute the offer
     * @param offerId id of the offer
     */
    function confirmDelivery(uint256 offerId) external {
        require(msg.sender == offers[offerId].buyer, "Only buyer allowed");
        require(offers[offerId].status == Status.PENDING);

        offers[offerId].status = Status.DELIVERED;

        uint256 fee = _calculateEscrowFee(offerId);

        IERC20(offers[offerId].paymentToken).transfer(
            offers[offerId].seller,
            offers[offerId].amount - fee
        );

        escAvailTokenBal[offers[offerId].paymentToken] += fee;

        emit Action(offerId, Status.DELIVERED, msg.sender);
    }

    /**
     * Used to initiate dispute for an offer
     * @param offerId id of the offer
     * @param _proofUrl url of the dispute proof
     */
    function initiateDispute(
        uint256 offerId,
        string memory _proofUrl
    ) external {
        require(offers[offerId].status == Status.PENDING);
        require(
            msg.sender == offers[offerId].buyer ||
                msg.sender == offers[offerId].seller,
            "Only buyer or seller allowed"
        );

        offers[offerId].status = Status.DISPUTED;
        offers[offerId].proofUrl = _proofUrl;

        emit Action(offerId, Status.DISPUTED, msg.sender);
    }

    /**
     * Used to resolve the offer's dispute case
     * @param offerId id of the offer
     * @param refund whether the case should be refunded or delivered
     */
    function resolveDispute(uint256 offerId, bool refund) external onlyOwner {
        require(offers[offerId].status == Status.DISPUTED);

        uint256 fee = _calculateEscrowFee(offerId);
        uint256 disputeFees = (offers[offerId].amount * disputeFee) / 100;

        if (refund) {
            offers[offerId].status = Status.REFUNDED;

            IERC20(offers[offerId].paymentToken).transfer(
                offers[offerId].buyer,
                offers[offerId].amount - disputeFees
            );

            escAvailTokenBal[offers[offerId].paymentToken] += disputeFees;

            emit DisputeResolution(offerId, true);
        } else {
            offers[offerId].status = Status.DELIVERED;

            IERC20(offers[offerId].paymentToken).transfer(
                offers[offerId].seller,
                offers[offerId].amount - fee - disputeFees
            );

            escAvailTokenBal[offers[offerId].paymentToken] += (fee + disputeFees);
            
            emit DisputeResolution(offerId, false);
        }
    }

    /**
     * Used to withdraw ETH in case any ETH present in the contract
     * @param to address of the recipient
     * @param amount amount to send
     */
    function withdrawETH(
        address payable to,
        uint256 amount
    ) external onlyOwner {
        require(amount <= address(this).balance);

        to.transfer(amount);

        emit Action(0, Status.WITHDRAWED, msg.sender);
    }

    /**
     * Used to transfer "Accepted" ERC20 tokens from the contract to any account
     * @param to Recipient account address
     * @param _token address of the ERC20 token
     * @param amount amount of tokens to send
     */
    function withdrawERC20Token(
        address to,
        address _token,
        uint256 amount
    ) external onlyOwner {
        require(amount <= escAvailTokenBal[_token]);

        escAvailTokenBal[_token] -= amount;

        require(IERC20(_token).transfer(to, amount), "Token transfer failed");
    }

    /**
     * Used to update the current escrow fee
     * @param _escFee is the escrow fee cut percentage
     */
    function updateEscrowFee(uint256 _escFee) external onlyOwner {
        escFee = _escFee;
    }

    /**
     * Used to update the current dispute fee
     * @param _disputeFee is the dispute fee in ETH
     */
    function updateDisputeFee(uint256 _disputeFee) external onlyOwner {
        disputeFee = _disputeFee;
    }

    /**
     * Used to update minimum idea token balance
     * @param _minIDEABalance is the minimum IDEA TOKEN balance present in the user's account on which there is half fee
     */
    function updateMinIdeaBalance(uint256 _minIDEABalance) external onlyOwner {
        minIDEABalance = _minIDEABalance;
    }

    /**
     * Used to transfer ownership of the contract
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        escAcc = _newOwner;
    }
}