// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/IRoyaltyFeeRegistry.sol";

/// @title DeRafl
/// @author 0xCappy
/// @notice This contract is used by DeRafl to hold raffles for any erc721 token
/// @dev Designed to be as trustless as possible.
/// Chainlink VRF is used to determine a winning ticket of a raffle.
/// A refund for a raffle can be initiated 2 days after a raffles expiry date if not already released.
/// LooksRare royaltyFeeRegistry is used to determine royalty rates for collections.
/// Collection royalties are honoured with a max payout of 5%

contract DeRafl is VRFConsumerBaseV2, Ownable, ERC1155Holder {
    error InvalidRaffleState();
    error InvalidExpiryTimestamp();
    error CreateNotEnabled();
    error EthInputTooSmall();
    error EthInputInvalid();
    error TicketAmountInvalid();
    error MsgValueInvalid();
    error RaffleBatchNotWinner();
    error SendEthFailed();
    error TimeSinceExpiryInsufficientForRefund();
    error TicketsAlreadyRefunded();
    error RaffleOwnerCannotPurchaseTickets();
    error InsufficientTicketsSold();

    // CONSTANTS
    /// @dev ERC721 interface
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    /// @dev ERC2981 interface
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// @dev Maximum seconds a raffle can be active
    uint256 internal constant MAX_RAFFLE_DURATION_SECONDS = 30 days;
    /// @dev Minimum amount of Eth
    uint256 internal constant MIN_ETH = 0.1 ether;
    /// @dev Denominator for fee calculations
    uint256 internal constant FEE_DENOMINATOR = 10000;
    /// @dev Maximum royalty fee percentage (5%)
    uint64 internal constant MAX_ROYALTY_FEE_PERCENTAGE = 500;
    /// @dev DeRafl protocol fee (0.5%)
    uint256 internal constant DERAFL_FEE_PERCENTAGE = 50;
    /// @dev Price per ticket
    uint96 internal constant TICKET_PRICE = 0.001 ether;

    // CHAINLINK
    uint64 internal subscriptionId;
    address internal vrfCoordinator;
    bytes32 internal keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 internal callbackGasLimit = 40000;
    uint16 internal requestConfirmations = 3;
    uint32 internal numWords = 1;
    VRFCoordinatorV2Interface internal COORDINATOR;

    /// @dev Emitted when a raffle is created
    /// @param raffleId The id of the raffle created
    /// @param nftAddress The address of the NFT being raffled
    /// @param tokenId The tokenId of the NFT being raffled
    /// @param tickets Maximum amount of tickets to be sold
    /// @param expires The timestamp when the raffle expires
    event RaffleOpened(
        uint64 indexed raffleId,
        address indexed nftAddress,
        uint256 tokenId,
        uint96 tickets,
        uint64 expires
    );

    /// @dev Emitted when a raffle is closed
    /// @param raffleId The id of the raffle being closed
    event RaffleClosed(uint64 indexed raffleId);

    /// @dev Emitted when a raffle is drawn and winning ticket determined
    /// @param raffleId The id of the raffle being drawn
    /// @param winningTicket The winning ticket of the raffle being drawn
    event RaffleDrawn(uint64 indexed raffleId, uint96 winningTicket);

    /// @dev Emitted when a raffle is released
    /// @param raffleId The id of the raffle being released
    /// @param winner The address of the winning ticket holder
    /// @param royaltiesPaid Collection royalties paid in wei
    /// @param ethPaid Ethereum paid to the raffle owner in wei
    event RaffleReleased(uint64 indexed raffleId, address indexed winner, uint256 royaltiesPaid, uint256 ethPaid);

    /// @dev Emitted when a raffle has been changed to a refunded state
    /// @param raffleId The id of the raffle being refunded
    event RaffleRefunded(uint64 indexed raffleId);

    /// @dev Emitted when tickets are purchased
    /// @param raffleId The raffle id of the tickets being purchased
    /// @param batchId The batch id of the ticket purchase
    /// @param purchaser The address of the account making the purchase
    /// @param ticketFrom The first ticket of the ticket batch
    /// @param ticketAmount The amount of tickets being purchased
    event TicketPurchased(
        uint64 indexed raffleId,
        uint96 batchId,
        address indexed purchaser,
        uint96 ticketFrom,
        uint96 ticketAmount
    );

    /// @dev Emitted when a refund has been placed
    /// @param raffleId The raffle id of the raffle being refunded
    /// @param refundee The account being issued a refund
    /// @param ethAmount The ethereum amount being refunded in wei
    event TicketRefunded(uint64 indexed raffleId, address indexed refundee, uint256 ethAmount);

    /// @dev Emitted when create raffle is toggled
    /// @param enabled next state of createEnabled
    event CreateEnabled(bool enabled);

    enum RaffleState {
        NONE,
        ACTIVE,
        CLOSED,
        REFUNDED,
        PENDING_DRAW,
        DRAWN,
        RELEASED
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    /// @dev Ticket Owner represents a participants total input in a raffle (sum of all ticket batches)
    struct TicketOwner {
        uint128 ticketsOwned;
        bool isRefunded;
    }

    /// @dev TicketBatch represents a batch of tickets purchased for a raffle
    struct TicketBatch {
        address owner;
        uint96 startTicket;
        uint96 endTicket;
    }

    struct Raffle {
        address royaltyRecipient;
        uint96 winningTicket;
        address nftAddress;
        uint96 ticketsAvailable;
        address payable raffleOwner;
        uint96 ticketsSold;
        address winner;
        uint96 batchIndex;
        uint256 chainlinkRequestId;
        uint256 tokenId;
        uint64 royaltyPercentage;
        uint64 raffleId;
        RaffleState raffleState;
        uint64 expiryTimestamp;
        TokenType tokenType;
    }

    /// @dev LooksRare royaltyFeeRegistry
    IRoyaltyFeeRegistry royaltyFeeRegistry;
    /// @dev mapping of raffleId => raffle
    mapping(uint64 => Raffle) raffles;
    /// @dev maps a participants TOTAL tickets bought for a raffle
    mapping(uint64 => mapping(address => TicketOwner)) ticketOwners;
    /// @dev maps ticketBatches purchased for a raffle
    mapping(uint64 => mapping(uint96 => TicketBatch)) ticketBatches;
    /// @dev maps raffleId to a chainlink VRF request
    mapping(uint256 => uint64) chainlinkRequestIdMap;
    /// @dev incremented raffleId
    uint64 raffleNonce = 1;
    /// @dev address to collect protocol fee
    address payable deraflFeeCollector;
    /// @dev indicates if a raffle can be created
    bool createEnabled = true;

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address royaltyFeeRegistryAddress,
        address feeCollector
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        royaltyFeeRegistry = IRoyaltyFeeRegistry(royaltyFeeRegistryAddress);
        deraflFeeCollector = payable(feeCollector);
    }

    /// @notice DeRafl Returns information about a particular raffle
    /// @dev Returns the Raffle struct of the specified Id
    /// @param raffleId a parameter just like in doxygen (must be followed by parameter name)
    /// @return raffle the Raffle struct at the specified raffleId
    function getRaffle(uint64 raffleId) external view returns (Raffle memory raffle) {
        raffle = raffles[raffleId];
        bool soldOut = raffle.ticketsSold == raffle.ticketsAvailable;
        bool isExpired = block.timestamp > raffle.expiryTimestamp;
        if (raffle.raffleState == RaffleState.ACTIVE && (soldOut || isExpired)) {
            raffle.raffleState = RaffleState.CLOSED;
        }
    }

    /// @notice DeRafl Returns an accounts particiaption for a raffle
    /// @dev TicketOwner contains the total amount of tickets bought for a raffle (sum of all ticket batches)
    /// and the refund status of a participant in the raffle
    /// @param raffleId The raffle Id of the raffle being queried
    /// @param ticketOwner The address of the participant being queried
    /// @return TicketOwner
    function getUserInfo(uint64 raffleId, address ticketOwner) external view returns (TicketOwner memory) {
        return ticketOwners[raffleId][ticketOwner];
    }

    /// @notice DeRafl Information about a specific TicketBatch for a raffle
    /// @dev Finds the TicketBatch for a specific raffle via the ticketBatches mapping
    /// @param raffleId The raffle Id of the TicketBatch being queried
    /// @param batchId The batchId for the TicketBatch being queried
    /// @return TicketBatch
    function getBatchInfo(uint64 raffleId, uint96 batchId) external view returns (TicketBatch memory) {
        return ticketBatches[raffleId][batchId];
    }

    /// @notice toggles the ability for users to create raffles
    function toggleCreateEnabled() external onlyOwner {
        createEnabled = !createEnabled;
        emit CreateEnabled(createEnabled);
    }

    /// @notice DeRafl Creates a new raffle
    /// @dev Creates a new raffle and adds it to the raffles mapping
    /// @param nftAddress The address of the NFT being raffled
    /// @param tokenId The token id of the NFT being raffled
    /// @param expiryTimestamp How many days until the raffle expires
    /// @param ethInput The maximum amount of Eth to be raised for the raffle
    function createRaffle(address nftAddress, uint256 tokenId, uint64 expiryTimestamp, uint96 ethInput, TokenType tokenType) external {
        if (!createEnabled) revert CreateNotEnabled();
        uint256 duration = expiryTimestamp - block.timestamp;
        if (duration > MAX_RAFFLE_DURATION_SECONDS) revert InvalidExpiryTimestamp();
        if (ethInput % TICKET_PRICE != 0) revert EthInputInvalid();
        if (ethInput < MIN_ETH) revert EthInputTooSmall();

        Raffle storage raffle = raffles[raffleNonce];
        raffle.raffleState = RaffleState.ACTIVE;
        raffle.raffleId = raffleNonce;
        raffleNonce++;
        raffle.raffleOwner = payable(msg.sender);
        raffle.nftAddress = nftAddress;
        raffle.tokenId = tokenId;
        raffle.ticketsAvailable = ethInput / TICKET_PRICE;
        raffle.expiryTimestamp = expiryTimestamp;
        raffle.tokenType = tokenType;

        // set royalty info at creation to avoid unexpected changes in royalties when raffle is closed
        (address royaltyRecipient, uint64 royaltyPercentage) = getRoyaltyInfo(nftAddress, tokenId);
        raffle.royaltyPercentage = royaltyPercentage;
        raffle.royaltyRecipient = royaltyRecipient;
        transferNft(nftAddress, msg.sender, address(this), tokenId, tokenType);
        emit RaffleOpened(raffle.raffleId, nftAddress, tokenId, raffle.ticketsAvailable, raffle.expiryTimestamp);
    }

    /// @notice DeRafl Purchase tickets for a raffle
    /// @dev Allows a user to purchase a ticket batch for a raffle.
    /// Validates the raffle state.
    /// Creates a new ticketBatch and adds to ticketBatches mapping.
    /// Increments ticketOwner in ticketOwners mapping.
    /// Update state of Raffle with specified raffleId.
    /// Emit TicketsPurchased event.
    /// @param raffleId The address of the NFT being raffled
    /// @param ticketAmount The amount of tickets to purchase
    function buyTickets(uint64 raffleId, uint96 ticketAmount) external payable {
        Raffle storage raffle = raffles[raffleId];
        if (msg.sender == raffle.raffleOwner) revert RaffleOwnerCannotPurchaseTickets();
        if (raffle.raffleState != RaffleState.ACTIVE || block.timestamp > raffle.expiryTimestamp)
            revert InvalidRaffleState();
        uint256 ticketsRemaining = raffle.ticketsAvailable - raffle.ticketsSold;
        if (ticketAmount == 0 || ticketAmount > ticketsRemaining) revert TicketAmountInvalid();

        uint256 ethAmount = ticketAmount * TICKET_PRICE;
        if (ethAmount != msg.value) revert MsgValueInvalid();

        // increment the total tickets bought for this raffle by this address
        TicketOwner storage ticketData = ticketOwners[raffleId][msg.sender];
        ticketData.ticketsOwned += ticketAmount;

        uint96 batchId = raffle.batchIndex;
        // create a new batch purchase
        TicketBatch storage batch = ticketBatches[raffleId][batchId];
        batch.owner = msg.sender;
        batch.startTicket = raffle.ticketsSold + 1;
        batch.endTicket = raffle.ticketsSold + ticketAmount;

        raffle.ticketsSold += ticketAmount;
        raffle.batchIndex++;
        emit TicketPurchased(raffleId, batchId, msg.sender, batch.startTicket, ticketAmount);
    }

    /// @notice DeRafl starts the drawing process for a raffle
    /// @dev Sends a request to chainlink VRF for a random number used to draw a winner.
    /// Validates raffleState is closed (sold out), or raffle is expired.
    /// Validates tickets sold > 5 to enusre fees can be covered.
    /// Stores the chainlinkRequestId in chainlinkRequestIdMap against the raffleId.
    /// emits raffle closed event.
    /// @param raffleId The raffleId of the raffle being drawn
    function drawRaffle(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.ACTIVE) revert InvalidRaffleState();
        if (raffle.ticketsSold < 6) revert InsufficientTicketsSold();

        bool soldOut = raffle.ticketsSold == raffle.ticketsAvailable;
        bool isExpired = block.timestamp > raffle.expiryTimestamp;
        if (!soldOut && !isExpired) revert InvalidRaffleState();

        uint256 chainlinkRequestId = requestRandomNumber();
        chainlinkRequestIdMap[chainlinkRequestId] = raffleId;

        raffle.raffleState = RaffleState.PENDING_DRAW;
        raffle.chainlinkRequestId = chainlinkRequestId;
        emit RaffleClosed(raffleId);
    }

    /// @notice Completes a raffle, releases prize and accumulated Eth to relevant stake holders
    /// @dev Validates that the batch referenced includes the winning ticket. Releases
    /// the nft and Ethereum
    /// @param raffleId The raffle Id of the raffle being released
    /// @param batchId The batch Id of the batch including the winning ticket
    function release(uint64 raffleId, uint96 batchId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.DRAWN) revert InvalidRaffleState();

        TicketBatch storage batch = ticketBatches[raffleId][batchId];
        uint256 winningTicket = raffle.winningTicket;

        // confirm that the batch passed in includes the winning ticket
        if (winningTicket < batch.startTicket || winningTicket > batch.endTicket) revert RaffleBatchNotWinner();
        address winner = batch.owner;

        // update state before making any transfers
        raffle.raffleState = RaffleState.RELEASED;

        // send the nft to the winner
        transferNft(raffle.nftAddress, address(this), winner, raffle.tokenId, raffle.tokenType);
        raffle.winner = winner;

        // allocate and send the Eth
        uint256 ethRaised = raffle.ticketsSold * TICKET_PRICE;
        uint256 protocolEth = ethRaised * DERAFL_FEE_PERCENTAGE / FEE_DENOMINATOR;
        uint256 royaltyEth = raffle.royaltyPercentage == 0
            ? 0
            : (ethRaised * raffle.royaltyPercentage) / FEE_DENOMINATOR;
        uint256 ownerEth = ethRaised - protocolEth - royaltyEth;

        (bool feeCallSuccess, ) = deraflFeeCollector.call{value: protocolEth}("");
        if (!feeCallSuccess) revert SendEthFailed();

        (bool ownerCallSuccess, ) = raffle.raffleOwner.call{value: ownerEth}("");
        if (!ownerCallSuccess) revert SendEthFailed();

        if (royaltyEth > 0) {
            (bool royaltyCallSuccess, ) = payable(raffle.royaltyRecipient).call{value: royaltyEth}("");
            if (!royaltyCallSuccess) revert SendEthFailed();
        }

        emit RaffleReleased(raffleId, winner, royaltyEth, ownerEth);
    }

    /// @dev Changes a raffles state to REFUNDED, allowing participants to be issued refunds.
    /// A raffle can be refunded 2 days after it has expired, and is not in a RELEASED state
    /// @param raffleId The raffle id of the raffle being refunded
    function refundRaffle(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState == RaffleState.RELEASED || raffle.raffleState == RaffleState.REFUNDED)
            revert InvalidRaffleState();
        if (block.timestamp < raffle.expiryTimestamp + 2 days) revert TimeSinceExpiryInsufficientForRefund();
        raffle.raffleState = RaffleState.REFUNDED;
        emit RaffleRefunded(raffleId);
    }

    /// @dev Issues a refund to an individual participant for all tickets purchased (sum of all ticket batches)
    /// @param raffleId The raffle id of the raffle being refunded
    function refundTickets(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.REFUNDED) revert InvalidRaffleState();
        TicketOwner storage ticketData = ticketOwners[raffleId][msg.sender];
        if (ticketData.isRefunded) revert TicketsAlreadyRefunded();

        // update refunded before sending any eth
        ticketData.isRefunded = true;
        uint256 refundAmount = ticketData.ticketsOwned * TICKET_PRICE;
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        if (!success) revert SendEthFailed();
        emit TicketRefunded(raffleId, msg.sender, refundAmount);
    }

    /// @dev Returns the NFT of a refunded raffle to the raffle owner
    /// @param raffleId The raffle id of the raffle
    function claimRefundedNft(uint64 raffleId) external {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.raffleState != RaffleState.REFUNDED) revert InvalidRaffleState();
        transferNft(raffle.nftAddress, address(this), raffle.raffleOwner, raffle.tokenId, raffle.tokenType);
    }

    /// @notice Gets the royalty fee percentage of an nft. Returns a maximum of 10%
    /// @dev checks for erc2981 as a priority for royalties, followed by looksrare royaltyFeeRegistry
    /// @dev maximum 5% royalties
    /// @param nftAddress The address of the token being queried
    function getRoyaltyInfo(
        address nftAddress,
        uint256 tokenId
    ) public view returns (address feeReceiver, uint64 royaltyFee) {
        bool isErc2981 = IERC165(nftAddress).supportsInterface(INTERFACE_ID_ERC2981);
        if (isErc2981) {
            (bool status, bytes memory data) = nftAddress.staticcall(
                abi.encodeWithSelector(IERC2981.royaltyInfo.selector, tokenId, FEE_DENOMINATOR)
            );
            if (status) {
                (feeReceiver, royaltyFee) = abi.decode(data, (address, uint64));
            }
        } else {
            try royaltyFeeRegistry.royaltyFeeInfoCollection(nftAddress) returns (
                address,
                address _feeReceiver,
                uint256 _royaltyFee
            ) {
                feeReceiver = _feeReceiver;
                royaltyFee = uint64(_royaltyFee);
            } catch {
                return (address(0), 0);
            }
        }
        royaltyFee = royaltyFee > MAX_ROYALTY_FEE_PERCENTAGE ? MAX_ROYALTY_FEE_PERCENTAGE : royaltyFee;
        return (feeReceiver, royaltyFee);
    }

    /// @dev Requests a random number from chainlink VRF
    /// @return chainlinkRequestId of the request
    function requestRandomNumber() internal returns (uint256) {
        return
            COORDINATOR.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    }

    /// @notice DeRafl Callable by chainlink VRF to receive a random number
    /// @dev Generates a winning ticket number between 0 - tickets sold for a raffle
    /// @param requestId The chainlinkRequestId which maps to raffle id
    /// @param randomWords random words sent by chainlink
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint64 raffleId = chainlinkRequestIdMap[requestId];
        Raffle storage raffle = raffles[raffleId];
        uint96 winningTicket = uint96(randomWords[0] % raffle.ticketsSold) + 1;
        raffle.winningTicket = winningTicket;
        raffle.raffleState = RaffleState.DRAWN;
        emit RaffleDrawn(raffleId, winningTicket);
    }

    /// @notice DeRafl transfers a erc721 or erc1155 token
    /// @dev uses the required interface depending on tokenType
    /// @param tokenAddress the address of the token
    /// @param from the owner transferring the token
    /// @param to the recipient of the token
    /// @param tokenId tokenId of the token being transfered
    /// @param tokenType the type of the token being transferred
    function transferNft(address tokenAddress, address from, address to, uint256 tokenId, TokenType tokenType) internal {
        if (tokenType == TokenType.ERC721) {
            IERC721 nftContract = IERC721(tokenAddress);
            nftContract.transferFrom(from, to, tokenId);
        } else {
            IERC1155 nftContract = IERC1155(tokenAddress);
            nftContract.safeTransferFrom(from, to, tokenId, 1, "");
        }
    }
}