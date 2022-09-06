// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "contracts/ICryptoPunk.sol";
import "contracts/TicketStorage.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

/**
 * @dev This contract is used to represent BoredLucky raffle. It supports CryptoPunks, ERC721 and ERC1155 NFTs.
 *
 * Raffle relies on Chainlink VRF to draw the winner.
 *
 * Raffle ensures that buyers will get a fair chance of winning (proportional to the number of purchased tickets), or
 * a way to get ETH back if raffle gets cancelled.
 *
 * Raffle can start only after the correct NFT is transferred to the account.
 *
 * Each raffle has an `owner`, the admin account that has the following abilities:
 * - gets ETH after the raffle is completed
 * - gets back the NFT if raffle is cancelled
 * - able to giveaway tickets
 * - able to cancel raffle before it has started (e.g. created with wrong parameters)
 *
 * Raffle gets cancelled if:
 * - not all tickets are sold before `endTimestamp`
 * - `owner` cancels it before start
 * - for some reason we do not have response from Chainlink VRF for one day after we request random number
 *
 * In any scenario, raffle cannot get stuck and users have a fair chance to win or get ETH back.
 *
 * `PullPayments` are used where possible to increase security.
 *
 * The lifecycle of raffle consist of following states:
 * - WaitingForNFT: after raffle is created, it waits for
 * - WaitingForStart: correct NFT is transferred and we wait for `startTimestamp`
 * - SellingTickets: it possible to purchase tickets
 * - WaitingForRNG: all tickets are sold, we wait for Chainlink VRF to send random number
 * - Completed (terminal) -- we know the winner, it can get NFT, raffle owner can get ETH
 * - Cancelled (terminal) -- raffle cancelled, buyers can get back their ETH, owner can get NFT
 */
contract Raffle is Ownable, TicketStorage, ERC1155Holder, ERC721Holder, PullPayment, VRFConsumerBaseV2 {
    event WinnerDrawn(uint16 ticketNumber, address owner);

    enum State {
        WaitingForNFT,
        WaitingForStart,
        SellingTickets,
        WaitingForRNG,
        Completed,
        Cancelled
    }
    State private _state;

    address public immutable nftContract;
    uint256 public immutable nftTokenId;
    enum NFTStandard {
        CryptoPunks,
        ERC721,
        ERC1155
    }
    NFTStandard public immutable nftStandard;

    uint256 public immutable ticketPrice;
    uint256 public immutable startTimestamp;
    uint256 public immutable endTimestamp;

    uint16 private _soldTickets;
    uint16 private _giveawayTickets;
    mapping(address => uint16) private _addressToPurchasedCountMap;

    uint256 private _cancelTimestamp;
    uint256 private _transferNFTToWinnerTimestamp;

    uint256 private _winnerDrawTimestamp;
    uint16 private _winnerTicketNumber;
    address private _winnerAddress;

    VRFCoordinatorV2Interface immutable VRF_COORDINATOR;
    uint64 immutable vrfSubscriptionId;
    bytes32 immutable vrfKeyHash;
    uint256[] public vrfRandomWords;
    uint256 public vrfRequestId;

    uint32 constant VRF_CALLBACK_GAS_LIMIT = 300_000;
    uint16 constant VRF_REQUEST_CONFIRMATIONS = 20;
    uint16 constant VRF_NUM_WORDS = 1;

    constructor(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _nftStandardId,
        uint16 _tickets,
        uint256 _ticketPrice,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint64 _vrfSubscriptionId,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash
    ) TicketStorage(_tickets) VRFConsumerBaseV2(_vrfCoordinator) {
        require(block.timestamp < _startTimestamp, "Start timestamp cannot be in the past");
        require(_endTimestamp > _startTimestamp, "End timestamp must be after start timestamp");
        require(_nftContract != address(0), "NFT contract cannot be 0x0");
        nftStandard = NFTStandard(_nftStandardId);
        require(
            nftStandard == NFTStandard.CryptoPunks || nftStandard == NFTStandard.ERC721 || nftStandard == NFTStandard.ERC1155,
            "Not supported NFT standard"
        );

        nftContract = _nftContract;
        nftTokenId = _nftTokenId;
        ticketPrice = _ticketPrice;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfKeyHash = _vrfKeyHash;
        vrfSubscriptionId = _vrfSubscriptionId;

        _state = State.WaitingForNFT;
    }

    /**
     * @dev Purchases raffle tickets.
     *
     * If last ticket is sold, triggers {_requestRandomWords} to request random number from Chainlink VRF.
     *
     * Requirements:
     * - must be in SellingTickets state
     * - cannot purchase after `endTimestamp`
     * - cannot purchase 0 tickets
     * - must have correct `value` of ETH
     */
    function purchaseTicket(uint16 count) external payable {
        if (_state == State.WaitingForStart) {
            if (block.timestamp > startTimestamp && block.timestamp < endTimestamp) {
                _state = State.SellingTickets;
            }
        }
        require(_state == State.SellingTickets, "Must be in SellingTickets");
        require(block.timestamp < endTimestamp, "End timestamp must be in the future");
        require(count > 0, "Ticket count must be more than 0");
        require(msg.value == ticketPrice * count, "Incorrect purchase amount (must be ticketPrice * count)");

        _assignTickets(msg.sender, count);
        _soldTickets += count;
        assert(_tickets == _ticketsLeft + _soldTickets + _giveawayTickets);

        _addressToPurchasedCountMap[msg.sender] += count;

        if (_ticketsLeft == 0) {
            _state = State.WaitingForRNG;
            _requestRandomWords();
        }
    }

    struct AddressAndCount {
        address receiverAddress;
        uint16 count;
    }

    /**
     * @dev Giveaway tickets. `owner` of raffle can giveaway free tickets, used for promotion.
     *
     * It is possible to giveaway tickets before start, ensuring that promised tickets for promotions can be assigned,
     * otherwise if raffle is quickly sold out, we may not able to do it in time.
     *
     * If last ticket is given out, triggers {_requestRandomWords} to request random number from Chainlink VRF.
     *
     * Requirements:
     * - must be in WaitingForStart or SellingTickets state
     * - cannot giveaway after `endTimestamp`
     */
    function giveawayTicket(AddressAndCount[] memory receivers) external onlyOwner {
        require(
            _state == State.WaitingForStart || _state == State.SellingTickets,
            "Must be in WaitingForStart or SellingTickets"
        );

        if (_state == State.WaitingForStart) {
            if (block.timestamp > startTimestamp && block.timestamp < endTimestamp) {
                _state = State.SellingTickets;
            }
        }
        require(block.timestamp < endTimestamp, "End timestamp must be in the future");

        for (uint256 i = 0; i < receivers.length; i++) {
            AddressAndCount memory item = receivers[i];

            _assignTickets(item.receiverAddress, item.count);
            _giveawayTickets += item.count;
            assert(_tickets == _ticketsLeft + _soldTickets + _giveawayTickets);
        }

        if (_ticketsLeft == 0) {
            _state = State.WaitingForRNG;
            _requestRandomWords();
        }
    }

    /**
     * @dev After the correct NFT (specified in raffle constructor) is transferred to raffle contract,
     * this method must be invoked to verify it and move raffle into WaitingForStart state.
     *
     * Requirements:
     * - must be in WaitingForNFT state
     */
    function verifyNFTPresenceBeforeStart() external {
        require(_state == State.WaitingForNFT, "Must be in WaitingForNFT");

        if (nftStandard == NFTStandard.CryptoPunks) {
            if (ICryptoPunk(nftContract).punkIndexToAddress(nftTokenId) == address(this)) {
                _state = State.WaitingForStart;
            }
        }
        else if (nftStandard == NFTStandard.ERC721) {
            if (IERC721(nftContract).ownerOf(nftTokenId) == address(this)) {
                _state = State.WaitingForStart;
            }
        }
        else if (nftStandard == NFTStandard.ERC1155) {
            if (IERC1155(nftContract).balanceOf(address(this), nftTokenId) == 1) {
                _state = State.WaitingForStart;
            }
        }
    }

    /**
     * @dev Cancels raffle before it has started.
     *
     * Only raffle `owner` can do it and it is needed in case raffle was created incorrectly.
     *
     * Requirements:
     * - must be in WaitingForNFT or WaitingForStart state
     */
    function cancelBeforeStart() external onlyOwner {
        require(
            _state == State.WaitingForNFT || _state == State.WaitingForStart,
            "Must be in WaitingForNFT or WaitingForStart"
        );

        _state = State.Cancelled;
        _cancelTimestamp = block.timestamp;
    }

    /**
     * @dev Cancels raffle if not all tickets were sold.
     *
     * Anyone can call this method after `endTimestamp`.
     *
     * Requirements:
     * - must be in SellingTickets state
     */
    function cancelIfUnsold() external {
        require(
            _state == State.WaitingForStart || _state == State.SellingTickets,
            "Must be in WaitingForStart or SellingTickets"
        );
        require(block.timestamp > endTimestamp, "End timestamp must be in the past");

        _state = State.Cancelled;
        _cancelTimestamp = block.timestamp;
    }

    /**
     * @dev Cancels raffle if there is no response from Chainlink VRF.
     *
     * Anyone can call this method after `endTimestamp` + 1 day.
     *
     * Requirements:
     * - must be in WaitingForRNG state
     */
    function cancelIfNoRNG() external {
        require(_state == State.WaitingForRNG, "Must be in WaitingForRNG");
        require(block.timestamp > endTimestamp + 1 days, "End timestamp + 1 day must be in the past");

        _state = State.Cancelled;
        _cancelTimestamp = block.timestamp;
    }

    /**
     * @dev Transfers purchased ticket refund into internal escrow, after that user can claim ETH
     * using {PullPayment-withdrawPayments}.
     *
     * Requirements:
     * - must be in Cancelled state
     */
    function transferTicketRefundIfCancelled() external {
        require(_state == State.Cancelled, "Must be in Cancelled");

        uint256 refundAmount = _addressToPurchasedCountMap[msg.sender] * ticketPrice;
        if (refundAmount > 0) {
            _addressToPurchasedCountMap[msg.sender] = 0;
            _asyncTransfer(msg.sender, refundAmount);
        }
    }

    /**
     * @dev Transfers specified NFT to raffle `owner`. This method is used to recover NFT (including other NFTs,
     * that could have been transferred to raffle by mistake) if raffle gets cancelled.
     *
     * Requirements:
     * - must be in Cancelled state
     */
    function transferNFTToOwnerIfCancelled(NFTStandard nftStandard, address contractAddress, uint256 tokenId) external {
        require(_state == State.Cancelled, "Must be in Cancelled");

        if (nftStandard == NFTStandard.CryptoPunks) {
            ICryptoPunk(contractAddress).transferPunk(address(owner()), tokenId);
        }
        else if (nftStandard == NFTStandard.ERC721) {
            IERC721(contractAddress).safeTransferFrom(address(this), owner(), tokenId);
        }
        else if (nftStandard == NFTStandard.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(address(this), owner(), tokenId, 1, "");
        }
    }

    /**
     * @dev Transfers raffle NFT to `_winnerAddress` after the raffle has completed.
     *
     * Requirements:
     * - must be in Completed state
     */
    function transferNFTToWinnerIfCompleted() external {
        require(_state == State.Completed, "Must be in Completed");
        assert(_winnerAddress != address(0));

        _transferNFTToWinnerTimestamp = block.timestamp;
        if (nftStandard == NFTStandard.CryptoPunks) {
            ICryptoPunk(nftContract).transferPunk(_winnerAddress, nftTokenId);
        }
        else if (nftStandard == NFTStandard.ERC721) {
            IERC721(nftContract).safeTransferFrom(address(this), _winnerAddress, nftTokenId);
        }
        else if (nftStandard == NFTStandard.ERC1155) {
            IERC1155(nftContract).safeTransferFrom(address(this), _winnerAddress, nftTokenId, 1, "");
        }
    }

    /**
     * @dev Transfers raffle ETHinto internal escrow, after that raffle `owner` can claim it
     * using {PullPayment-withdrawPayments}.
     *
     * Requirements:
     * - must be in Completed state
     */
    function transferETHToOwnerIfCompleted() external {
        require(_state == State.Completed, "Must be in Completed");

        _asyncTransfer(owner(), address(this).balance);
    }

    /**
     * @dev Returns the number of purchased tickets for given `owner`.
     */
    function getPurchasedTicketCount(address owner) public view returns (uint16) {
        return _addressToPurchasedCountMap[owner];
    }

    /**
    * @dev Returns raffle state.
     *
     * If `Completed`, it is possible to use {getWinnerAddress}, {getWinnerDrawTimestamp} and {getWinnerTicketNumber}.
     */
    function getState() public view returns (State) {
        return _state;
    }

    function getCancelTimestamp() public view returns (uint256) {
        return _cancelTimestamp;
    }

    function getTransferNFTToWinnerTimestamp() public view returns (uint256) {
        return _transferNFTToWinnerTimestamp;
    }

    function getWinnerAddress() public view returns (address) {
        return _winnerAddress;
    }

    function getWinnerDrawTimestamp() public view returns (uint256) {
        return _winnerDrawTimestamp;
    }

    function getWinnerTicketNumber() public view returns (uint16) {
        return _winnerTicketNumber;
    }

    /**
     * @dev Chainlink VRF callback function.
     *
     * Returned `randomWords` are stored in `vrfRandomWords`, we determine winner and store all relevant information in
     * `_winnerTicketNumber`, `_winnerDrawTimestamp` and `_winnerAddress`.
     *
     * Requirements:
     * - must have correct `requestId`
     * - must be in WaitingForRNG state
     *
     * Emits a {WinnerDrawn} event.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(vrfRequestId == requestId, "Unexpected VRF request id");
        require(_state == State.WaitingForRNG, "Must be in WaitingForRNG");

        vrfRandomWords = randomWords;
        _winnerTicketNumber = uint16(randomWords[0] % _tickets);
        _winnerDrawTimestamp = block.timestamp;
        _winnerAddress = findOwnerOfTicketNumber(_winnerTicketNumber);
        _state = State.Completed;
        emit WinnerDrawn(_winnerTicketNumber, _winnerAddress);
    }

    /**
     * @dev Requests random number from Chainlink VRF. Called when last ticked is sold or given out.
     *
     * Requirements:
     * - must be in WaitingForRNG state
     */
    function _requestRandomWords() private {
        require(_state == State.WaitingForRNG, "Must be in WaitingForRNG");

        vrfRequestId = VRF_COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            VRF_REQUEST_CONFIRMATIONS,
            VRF_CALLBACK_GAS_LIMIT,
            VRF_NUM_WORDS
        );
    }
}