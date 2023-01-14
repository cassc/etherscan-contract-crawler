// SPDX-License-Identifier: MarrowLabs
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./FeeCalculator.sol";

enum RaffleStatus {
    ONGOING,
    PENDING_COMPLETION,
    COMPLETE,
    FAILED
}

struct Raffle {
    address creator;
    address nftContractAddress;
    uint256 nftId;
    uint256 totalPrice;
    uint256 totalTickets;
    address[] tickets;
    uint256 minTicketsSold;
    uint256 deadline;
    address winner;
    RaffleStatus status;
}

contract AngelDustRaffle is IERC721Receiver, VRFConsumerBase, Ownable {
    // stores raffles
    Raffle[] internal raffles;

    // params for Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;

    // map VRF request to raffle
    mapping(bytes32 => uint256) internal randomnessRequestToRaffle;

    uint256 internal _collectedFees;
    FeeCalculator feeCalculator;

    event RaffleCreated(uint256 id, address indexed creator);
    event TicketsPurchased(uint256 indexed id, address indexed buyer, uint256 numTickets);
    event RaffleComplete(uint256 indexed id, address winner);
    event RaffleFailed(uint256 indexed id);

    constructor(
        address _vrfCoordinator,
        address _linkToken,
        uint256 _fee,
        bytes32 _keyHash,
        address _feeCalculator
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) Ownable() {
        keyHash = _keyHash;
        fee = _fee;
        feeCalculator = FeeCalculator(_feeCalculator);
    }

    // creates a new raffle
    // nftContract.approve should be called before this
    function createRaffle(
        address _nftContract,
        uint256 _nftId,
        uint256 _numTickets,
        uint256 _totalPrice,
        uint256 _minTicketsSold,
        uint256 _deadline
    ) external {
        require(_deadline > block.timestamp, "Deadline must be in the future.");

        // transfer the nft from the raffle creator to this contract
        IERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _nftId,
            abi.encode(_numTickets, _totalPrice, _minTicketsSold, _deadline)
        );
    }

    // complete raffle creation when receiving ERC721
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        (
            uint256 _numTickets,
            uint256 _totalPrice,
            uint256 _minTicketsSold,
            uint256 _deadline
        ) = abi.decode(data, (uint256, uint256, uint256, uint256));
        // init tickets
        address[] memory _tickets;
        // create raffle
        Raffle memory _raffle = Raffle(
            tx.origin,
            msg.sender,
            _tokenId,
            _totalPrice,
            _numTickets,
            _tickets,
            _minTicketsSold,
            _deadline,
            address(0),
            RaffleStatus.ONGOING
        );
        // store raffle in state
        raffles.push(_raffle);

        // emit event
        unchecked {
            emit RaffleCreated(raffles.length - 1, tx.origin);
        }

        // return funciton singature to confirm safe transfer
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    // enters a user in the draw for a given raffle
    function enterRaffle(uint256 raffleId, uint256 tickets)
        external
        payable
    {
        Raffle memory raffle = raffles[raffleId];

        require(
            uint256(raffle.status) == uint256(RaffleStatus.ONGOING),
            "Raffle no longer active"
        );
        require(
            tickets + raffle.tickets.length <= raffle.totalTickets,
            "Not enough tickets available"
        );
        require(tickets > 0, "Not enough tickets purchased");
        require(
            msg.value == (tickets * raffle.totalPrice) / raffle.totalTickets,
            "Ticket price not paid"
        );

        // add tickets
        unchecked {
            for (uint256 i = 0; i < tickets; i++)
                raffles[raffleId].tickets.push(payable(msg.sender));
        }

        emit TicketsPurchased(raffleId, msg.sender, tickets);

        // award prizes if this was the last ticket purchased
        if (raffles[raffleId].tickets.length == raffle.totalTickets)
            chooseWinner(raffleId);
    }

    // function that will close raffle after deafline
    function endRaffle(uint256 _raffleId) external {
        Raffle memory raffle = raffles[_raffleId];

        require(
            uint256(raffle.status) == uint256(RaffleStatus.ONGOING),
            "Raffle is already closed or pending completion."
        );
        require(
            raffle.deadline < block.timestamp,
            "Raffle cannot be closed before deadline."
        );

        if (raffle.tickets.length < raffle.minTicketsSold) {
            raffles[_raffleId].status = RaffleStatus.FAILED; // mark raffle as failed

            emit RaffleFailed(_raffleId);
        } else chooseWinner(_raffleId); // enough of the tickets are sold and we can choose the winner
    }

    function chooseWinner(uint256 _raffleId) virtual internal {
        // Request a random number from Chainlink
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK, notify the administrators to top up to contract to complete this action"
        );

        raffles[_raffleId].status = RaffleStatus.PENDING_COMPLETION;

        bytes32 requestId = requestRandomness(keyHash, fee);
        randomnessRequestToRaffle[requestId] = _raffleId;
    }

    // this function refunds the nft to the owner if raffle has failed
    function refundNFT(uint256 _raffleId) external {
        Raffle memory raffle = raffles[_raffleId];

        require(
            raffle.creator != address(0),
            "NFT has already been refunded to the creator."
        );
        require(
            uint256(raffle.status) == uint256(RaffleStatus.FAILED),
            "You can refund NFT only if raffle the has failed."
        );

        raffles[_raffleId].creator = address(0);
        
        IERC721(raffle.nftContractAddress).safeTransferFrom(
            address(this),
            raffle.creator,
            raffle.nftId,
            ""
        );
    }

    // this function refunds ether used to buy tickers for a failed raffle
    function refundTickets(uint256 _raffleId, uint256[] calldata myTickets)
        external
    {
        Raffle memory raffle = raffles[_raffleId];

        require(
            uint256(raffle.status) == uint256(RaffleStatus.FAILED),
            "You can get a tickets refund only if the raffle has failed."
        );
        require(myTickets.length > 0, "No refund neccessary.");

        uint256 t = 0;

        for (; t < myTickets.length; t++) {
            if (raffle.tickets[myTickets[t]] != msg.sender)
                revert("You can only refund your tickets and only once.");

            raffles[_raffleId].tickets[myTickets[t]] = address(0);
        }

        payable(msg.sender).transfer(
            (raffle.totalPrice / raffle.totalTickets) * t
        );
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        Raffle memory raffle = raffles[randomnessRequestToRaffle[requestId]];

        // map randomness to value between 0 and raffle.tickets.length
        uint256 winnerIndex = randomness % raffle.tickets.length;
        address winner = raffle.tickets[winnerIndex];
            
        raffles[randomnessRequestToRaffle[requestId]].status = RaffleStatus
            .COMPLETE;

        // award winner
        IERC721(raffle.nftContractAddress).transferFrom(
            address(this),
            winner,
            raffle.nftId
        );

        // pay raffle creator
        uint256 totalCollected = raffle.tickets.length * (raffle.totalPrice / raffle.totalTickets);
        uint256 _fee = totalCollected / 1000 * feeCalculator.getFee(raffle.creator);

        unchecked {
            _collectedFees += _fee;

            payable(raffle.creator).transfer(
                totalCollected - _fee
            );
        }

        raffles[randomnessRequestToRaffle[requestId]].winner = winner;

        emit RaffleComplete(
            randomnessRequestToRaffle[requestId],
            raffle.tickets[winnerIndex]
        );
    }

    function getRafflesLength() external view returns (uint256) {
        return raffles.length;
    }

    function getRaffle(uint256 index) external view returns (Raffle memory) {
        return raffles[index];
    }

    function collectedFees() view external returns (uint256) {
        return _collectedFees;
    }

    function collectFees() external onlyOwner {
        payable(msg.sender).transfer(_collectedFees);

        _collectedFees = 0;
    }

    function getFeeCalculator() view external returns (address) {
        return address(feeCalculator);
    }

    function changeFeeCalculator(address _feeCalculator) external onlyOwner {
        feeCalculator = FeeCalculator(_feeCalculator);
    }
}