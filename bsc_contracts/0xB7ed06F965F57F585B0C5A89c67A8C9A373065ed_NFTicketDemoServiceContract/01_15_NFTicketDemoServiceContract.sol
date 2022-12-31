// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../libs/SafeMath.sol";
import "../interfaces/INFTicket.sol";
import "../interfaces/INFTicketProcessor.sol";
import "../interfaces/INFTServiceTypes.sol";
import "../interfaces/INFTServiceProvider.sol";
import "./interfaces/IDemoServiceContract.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Service contract for the NFTicket demo
 * @author Lukas Reinarz | bloXmove
 */
contract NFTicketDemoServiceContract is IDemoServiceContract, AccessControl {
    using SafeMath for uint256;

    // NFTicket contract
    INFTicket NFTicketContract;

    // NFTicket contract
    INFTicketProcessor NFTicketProcessorContract;

    // ERC20 token to be distributed to consumers
    IERC20 ERC20Contract;

    // Number of credits on newly minted ticket
    uint256 public numCredits;

    // Number of BLXM tokens (in Wei) to give to a consumer
    uint256 public numErc20PerConsumer;

    // Service descriptors for IS_TICKET and CASH_VOUCHER
    uint32 public ticketServiceDescriptor = 0x08000200;
    uint32 public cashVoucherServiceDescriptor = 0x0A000200;

    // Mapping containing wallets who have already been added ERC20 to their NFTickets
    address[] alreadyClaimed;

    //===================================Initializer===================================//
    constructor(
        address _NFTicketAddress,
        address _NFTicketProcessorAddress,
        address _ERC20Address,
        uint256 _numCredits,
        uint256 _numErc20PerConsumer
    ) {
        NFTicketContract = INFTicket(_NFTicketAddress);
        NFTicketProcessorContract = INFTicketProcessor(
            _NFTicketProcessorAddress
        );
        ERC20Contract = IERC20(_ERC20Address);
        numCredits = _numCredits;
        numErc20PerConsumer = _numErc20PerConsumer;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //===================================Modifiers===================================//
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only admin can do this"
        );
        _;
    }

    modifier onlyTicketOwner(uint256 _ticketId) {
        require(
            IERC721(address(NFTicketContract)).ownerOf(_ticketId) ==
                _msgSender(),
            "Only ticket owner can do this"
        );
        _;
    }

    modifier onlyRedeemed(uint256 _ticketId) {
        Ticket memory ticket = NFTicketContract.getTicketData(_ticketId);
        require(ticket.credits == 0, "Not yet redeemed");
        _;
    }

    modifier onlyCashVoucher(uint256 _ticketId) {
        Ticket memory ticket = NFTicketContract.getTicketData(_ticketId);
        require(
            ticket.serviceDescriptor == cashVoucherServiceDescriptor,
            "Not a cash voucher"
        );
        _;
    }

    //===================================Public functions===================================//
    /**
     * @notice Mints an NFTicket with one credit
     *
     * @param _URI - A URI saved on the ticket; can point to some IPFS resource, for example.
     *
     * @dev Emits a TicketMinted(uint256 newTicketId, address userAddress) event, both parameters indexed
     */
    function mintNfticket(string calldata _URI) public override {
        address user = _msgSender();

        Ticket memory ticket = getTicketParams(user, _URI);

        Ticket memory newTicket = NFTicketContract.mintNFTicket(user, ticket);

        emit TicketMinted(newTicket.tokenID, user);
    }

    /**
     * @notice Reduced the number of credits on a newly minted ticket to zero and
     *         converts the ticket to a cash voucher
     *
     * @param _ticketId - The Id of the ticket to redeem
     *
     * @dev Emits a CreditRedeemed(uint256 ticketId, address presenterAddress) event,
     *      both parameters indexed
     */
    function redeemNfticket(uint256 _ticketId) public override {
        address presenter = _msgSender();

        // NFTicket contract checks credits on ticket and reduces credits if appropriate
        NFTicketProcessorContract.presentTicket(
            _ticketId,
            presenter,
            address(this),
            numCredits,
            uint8(CheckInMode.neither) // TODO Lukas confirm: we do not keep the NFTicket here
        );

        // NFticket contract changes the service descriptor of the ticket
        // to a cash voucher
        NFTicketContract.updateServiceType(
            _ticketId,
            cashVoucherServiceDescriptor
        );

        emit CreditRedeemed(_ticketId, presenter);
    }

    /**
     * @notice Adds a certain amount of an ERC20 token to the ticket which can be withdrawn later
     *
     * @param _ticketId - The Id of the ticket to add the ERC20 tokens to
     *
     * @dev Emits a BalanceAdded(uint256 ticketId, address userAddress, uint256 numErc20) with
     *      all parameters indexed.
     */
    function addBalanceToTicket(uint256 _ticketId)
        public
        override
        onlyTicketOwner(_ticketId)
        onlyRedeemed(_ticketId)
        onlyCashVoucher(_ticketId)
    {
        // Only tickets that have never gotten ERC20 tokens before can now get them
        address consumer = _msgSender();
        require(!hasGottenERC20(consumer), "Not a new wallet");

        // Contract balance must be sufficient
        uint256 currentContractBalance = ERC20Contract.balanceOf(address(this));
        require(
            currentContractBalance > numErc20PerConsumer,
            "Not enough BLXM left in contract"
        );

        // Add wallet to a blacklist so that it won't get ERC20 in the future
        alreadyClaimed.push(consumer);

        // Approve NFTicket contract to withdraw tokens from this contract
        address NFTicketAddress = address(NFTicketContract);
        uint256 currentAllowance = ERC20Contract.allowance(
            address(this),
            NFTicketAddress
        );
        ERC20Contract.approve(
            NFTicketAddress,
            currentAllowance.add(numErc20PerConsumer)
        );

        // Update the ticket BLXM balance
        uint256 creditsAffordable;
        uint256 chargedErc20;
        (creditsAffordable, chargedErc20) = NFTicketContract.topUpTicket(
            _ticketId,
            0, // number of credits to top up
            address(ERC20Contract),
            numErc20PerConsumer
        );

        emit BalanceAdded(_ticketId, consumer, numErc20PerConsumer);
    }

    /**
     * @notice Transfers the ERC20 on a ticket to the owner's wallet
     *
     * @param _ticketId - The Id of the ticket to withdraw the tokens from
     *
     * @dev Emits a Erc20Withdrawn(uint256 ticketId, address userAddress, uint256 numErc20) with
     *      all parameters indexed.
     */
    function getErc20(uint256 _ticketId)
        external
        override
        onlyTicketOwner(_ticketId)
        onlyRedeemed(_ticketId)
        onlyCashVoucher(_ticketId)
    {
        uint256 ticketBalance = NFTicketContract.getTicketBalance(_ticketId);
        require(
            ticketBalance == numErc20PerConsumer,
            "Not enough balance on ticket"
        );

        address consumer = _msgSender();
        NFTicketContract.withDrawERC20(
            _ticketId,
            address(ERC20Contract),
            ticketBalance,
            consumer
        );

        emit Erc20Withdrawn(_ticketId, consumer, numErc20PerConsumer);
    }

    function setNumCredits(uint256 _credits) external override onlyAdmin {
        numCredits = _credits;
    }

    function setNumErc20PerConsumer(uint256 _num) external override onlyAdmin {
        numErc20PerConsumer = _num;
    }

    function setTicketServiceDescriptor(uint32 _newDescriptor)
        external
        override
        onlyAdmin
    {
        ticketServiceDescriptor = _newDescriptor;
    }

    function setCashVoucherServiceDescriptor(uint32 _newDescriptor)
        external
        override
        onlyAdmin
    {
        cashVoucherServiceDescriptor = _newDescriptor;
    }

    function withdrawRemainingErc20() external override onlyAdmin {
        uint256 currentBalance = ERC20Contract.balanceOf(address(this));
        ERC20Contract.transfer(_msgSender(), currentBalance);
    }

    //===================================Private functions===================================//
    /**
     * @dev The mintNFTicket() function in NFTicket.sol requires two parameters one of which
     * is a Ticket struct. This Ticket struct is assembled here.
     */
    function getTicketParams(address _recipient, string calldata _URI)
        internal
        view
        returns (Ticket memory ticket)
    {
        ticket.tokenID = 0; // This Id will be assigned correctly in the NFTicket contract
        ticket.serviceProvider = address(this);
        ticket.serviceDescriptor = ticketServiceDescriptor;
        ticket.issuedTo = _recipient;
        ticket.certValue = 0;
        ticket.certValidFrom = 0;
        ticket.price = 0;
        ticket.credits = numCredits;
        ticket.pricePerCredit = 0;
        ticket.serviceFee = 900 * 1 ether;
        ticket.resellerFee = 100 * 1 ether;
        ticket.transactionFee = 0 * 1 ether;
        ticket.tokenURI = _URI;
    }

    function hasGottenERC20(address _address) internal view returns (bool) {
        uint256 numAddresses = alreadyClaimed.length;

        for (uint256 i = 0; i < numAddresses; i++) {
            if (alreadyClaimed[i] == _address) {
                return true;
            }
        }

        return false;
    }
}