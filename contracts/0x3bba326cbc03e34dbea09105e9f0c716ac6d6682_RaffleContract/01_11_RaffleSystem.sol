// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/// RaffleContract was created by DeployERC.  Use any ERC20 token to purchase tickets to raffles created by an ADMIN.
/// Set Ticket Cost, Amount of Tickets available, duration time in seconds and the Prize to be won.  Once duration has expired tickets are no longer available for purchase.
/// It is the admins responsiblity to close the raffle inorder for the contract to pick a winner at random and display the winning address.
contract RaffleContract is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Raffle {
        uint256 ticketPrice;
        uint256 duration;
        uint256 expirationTimestamp;
        bool isOpen;
        uint256 totalTickets;
        uint256 totalTicketsSold;
        address winner;
        mapping(address => Participant) participants;
        address[] participantAddresses;
        string prize;
    }

    struct Participant {
        uint256 ticketCount;
    }

    struct RaffleInfo {
        uint256 raffleId;
        uint256 ticketPrice;
        uint256 duration;
        bool isOpen;
        uint256 totalTickets;
        uint256 totalTicketsSold;
        address winner;
        string prize;
        uint256 expirationTimestamp;
    }

    // ERC20 token contract address
    address public tokenAddress;

    // Array to store raffles
    Raffle[] public raffles;
    uint256[] public activeRaffles;
    uint256[] public closedRaffles;

    // Event emitted when a user purchases tickets for a specific raffle
    event TicketsPurchased(uint256 indexed raffleId, address indexed participant, uint256 ticketCount);

    // Event emitted when the raffle is closed and a winner is selected
    event RaffleClosed(uint256 indexed raffleId, address indexed winner);

    // Contract name and symbol variables
    string public name;
    string public symbol;

    constructor(
        address _tokenAddress,
        string memory _name,
        string memory _symbol
    ) {
        tokenAddress = _tokenAddress;
        name = _name;
        symbol = _symbol;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier checkRaffleExpiration(uint256 _raffleId) {
        require(!_isRaffleExpired(_raffleId), "Raffle has already expired");
        _;
    }

    function createRaffle(
        uint256 _ticketPrice,
        uint256 _duration,
        uint256 _totalTickets,
        string memory _prize
    ) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_totalTickets > 0, "Invalid total tickets");

        Raffle storage newRaffle = raffles.push();
        newRaffle.ticketPrice = _ticketPrice;
        newRaffle.duration = _duration;
        newRaffle.expirationTimestamp = block.timestamp.add(_duration);
        newRaffle.isOpen = true;
        newRaffle.totalTickets = _totalTickets;
        activeRaffles.push(raffles.length - 1);
        newRaffle.prize = _prize;
    }

    function purchaseTickets(uint256 _raffleId, uint256 _ticketCount) external checkRaffleExpiration(_raffleId) {
        require(_raffleId < raffles.length, "Invalid raffle ID");
        Raffle storage raffle = raffles[_raffleId];
        require(raffle.isOpen, "Raffle is not open");
        require(_ticketCount > 0, "Invalid ticket count");
        require(raffle.totalTicketsSold.add(_ticketCount) <= raffle.totalTickets, "Insufficient tickets available");

        uint256 totalCost = raffle.ticketPrice.mul(_ticketCount);

        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= totalCost, "Insufficient allowance");
       
        require(token.balanceOf(msg.sender) >= totalCost, "Insufficient balance");

        token.transferFrom(msg.sender, address(this), totalCost);
        raffle.participants[msg.sender].ticketCount = raffle.participants[msg.sender].ticketCount.add(_ticketCount);
        if (raffle.participants[msg.sender].ticketCount == _ticketCount) {
            raffle.participantAddresses.push(msg.sender);
        }
        raffle.totalTicketsSold = raffle.totalTicketsSold.add(_ticketCount);

        emit TicketsPurchased(_raffleId, msg.sender, _ticketCount);
    }

    function closeRaffle(uint256 _raffleId) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_raffleId < raffles.length, "Invalid raffle ID");

        _closeRaffle(_raffleId);
    }

    function _closeRaffle(uint256 _raffleId) internal {
        Raffle storage raffle = raffles[_raffleId];
        require(raffle.isOpen, "Raffle is not open");

        raffle.isOpen = false;

        if (raffle.totalTicketsSold > 0) {
            require(raffle.winner == address(0), "Raffle already closed");
            raffle.winner = getRandomWinner(_raffleId);
            closedRaffles.push(_raffleId);
            emit RaffleClosed(_raffleId, raffle.winner);
        }
    }

    function closeExpiredRaffle(uint256 _raffleId) external {
        require(_raffleId < raffles.length, "Invalid raffle ID");
        Raffle storage raffle = raffles[_raffleId];
        require(_isRaffleExpired(_raffleId), "Raffle has not expired yet");

        _closeRaffle(_raffleId);
    }

    function getRandomWinner(uint256 _raffleId) internal view returns (address) {
        Raffle storage raffle = raffles[_raffleId];
        require(raffle.totalTicketsSold > 0, "No tickets sold for the raffle");

        uint256 winnerIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number))
        ) % raffle.participantAddresses.length;

        return raffle.participantAddresses[winnerIndex];
    }

    function _isRaffleExpired(uint256 _raffleId) internal view returns (bool) {
        Raffle storage raffle = raffles[_raffleId];
        return block.timestamp >= raffle.expirationTimestamp;
    }

    function getRaffleCount() public view returns (uint256) {
        return raffles.length;
    }

    function getActiveRaffles() public view returns (RaffleInfo[] memory) {
    RaffleInfo[] memory active = new RaffleInfo[](activeRaffles.length);
    uint256 activeCount = 0;
    for (uint256 i = 0; i < activeRaffles.length; i++) {
        uint256 raffleId = activeRaffles[i];
        if (raffles[raffleId].isOpen) {
            Raffle storage raffle = raffles[raffleId];
            active[activeCount] = RaffleInfo(
                raffleId,
                raffle.ticketPrice,
                raffle.duration,
                raffle.isOpen,
                raffle.totalTickets,
                raffle.totalTicketsSold,
                raffle.winner,
                raffle.prize,
                raffle.expirationTimestamp
            );
            activeCount++;
        }
    }
    assembly {
        mstore(active, activeCount)
    }
    return active;
}


    function getClosedRaffles() public view returns (RaffleInfo[] memory) {
        uint256 closedCount = 0;
        for (uint256 i = 0; i < raffles.length; i++) {
            if (!raffles[i].isOpen) {
               
                closedCount++;
            }
        }

        RaffleInfo[] memory closed = new RaffleInfo[](closedCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < raffles.length; i++) {
            if (!raffles[i].isOpen) {
                closed[currentIndex] = RaffleInfo(
                    i,
                    raffles[i].ticketPrice,
                    raffles[i].duration,
                    raffles[i].isOpen,
                    raffles[i].totalTickets,
                    raffles[i].totalTicketsSold,
                    raffles[i].winner,
                    raffles[i].prize,
                    raffles[i].expirationTimestamp
                );
                currentIndex++;
            }
        }

        return closed;
    }

    function getRaffleInfo(uint256 _raffleId)
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            address,
            string memory
        )
    {
        require(_raffleId < raffles.length, "Invalid raffle ID");
        Raffle storage raffle = raffles[_raffleId];
        return (
            raffle.ticketPrice,
            raffle.duration,
            raffle.isOpen,
            raffle.totalTickets,
            raffle.totalTicketsSold,
            raffle.winner,
            raffle.prize
        );
    }

    function getParticipantInfo(uint256 _raffleId, address _participant)
        public
        view
        returns (uint256)
    {
        require(_raffleId < raffles.length, "Invalid raffle ID");
        Raffle storage raffle = raffles[_raffleId];
        return raffle.participants[_participant].ticketCount;
    }

    function addAdmin(address _admin) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        grantRole(ADMIN_ROLE, _admin);
    }

    function removeAdmin(address _admin) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        revokeRole(ADMIN_ROLE, _admin);
    }

    function getContractBalance() public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    function withdrawTokens(uint256 _amount) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Insufficient contract balance");
        token.transfer(msg.sender, _amount);
    }
}