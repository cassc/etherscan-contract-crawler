// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BUSDOneV2.sol";

contract BUSDOneRaffle is Initializable {
    address public owner;
    address serverAddress;
    token public BUSD;
    BUSDOneV2 public stakingContract;
    address public stakingAddress;

    struct Deductor {
        address wallet;
        uint16 percent;
    }

    Deductor[] public deductors;
    uint16[] public referralBonuses;
    uint16 public percentDivider;

    uint256 public latestRaffle;
    uint256 public entryPrice;

    mapping(uint256 => mapping(address => uint16)) public walletEntries;
    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => uint16[]) public raffleEntries;

    mapping(address => uint16) public userid;
    address[] public walletFromId;

    struct Raffle {
        uint256 winnerPot;
        address winner;
        uint32 startDate;
        uint32 drawDate;
    }

    function initialize(
        address _stakingContract,
        address busdContract,
        address developer,
        address team,
        address _serverAddress
    ) external initializer {
        owner = msg.sender;
        serverAddress = _serverAddress;

        BUSD = token(busdContract);
        stakingContract = BUSDOneV2(_stakingContract);
        stakingAddress = _stakingContract;

        entryPrice = 5 ether;
        percentDivider = 100;

        deductors.push(Deductor(developer, 3));
        deductors.push(Deductor(team, 3));

        referralBonuses = [7, 3, 2];
        walletFromId.push(address(this));
    }

    // Raffle Management

    function createRaffle() public onlyOwner {
        latestRaffle++;
        raffles[latestRaffle].startDate = uint32(block.timestamp);

        emit NewRaffle(latestRaffle, uint32(block.timestamp));
    }

    function drawRaffle(
        string memory randomString,
        uint256 index
    ) public onlyOwner {
        Raffle storage raffle = raffles[index];
        require(
            raffle.winner == address(0),
            "This raffle already has a winner."
        );

        require(raffle.winnerPot > 0, "No winner pot.");

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    raffleEntries[index],
                    randomString
                )
            )
        );

        uint256 winnerIndex = randomNumber % raffleEntries[index].length;

        address winner = walletFromId[raffleEntries[index][winnerIndex]];

        raffle.winner = winner;
        BUSD.transfer(winner, raffle.winnerPot);

        raffle.drawDate = uint32(block.timestamp);

        emit RaffleWinner(index, winner, raffle.winnerPot);
    }

    function drawAndCreateRaffle(
        string memory randomString
    ) external onlyOwner {
        drawRaffle(randomString, latestRaffle);
        createRaffle();
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == serverAddress);
        _;
    }

    function governanceJoin(address wallet) external onlyOwner {
        uint256 index = latestRaffle;
        if (userid[wallet] == 0) {
            walletFromId.push(wallet);
            userid[wallet] = uint16(walletFromId.length) - 1;
        }

        raffleEntries[index].push(userid[wallet]);
        walletEntries[index][wallet]++;
    }

    // User Methods

    function joinRaffle(uint256 index, uint256 tickets) external {
        Raffle storage raffle = raffles[index];
        require(raffle.winner == address(0), "This already ended.");
        require(raffle.startDate > 0, "Raffle hasn't started.");
        uint256 totalAmount = entryPrice * tickets;
        BUSD.transferFrom(msg.sender, address(this), totalAmount);

        uint256 halfAmount = totalAmount / 2;
        raffle.winnerPot += halfAmount;
        uint256 toContract = halfAmount;

        uint256 length = deductors.length;
        uint256 amount;
        for (uint256 i = 0; i < length; ++i) {
            amount = (halfAmount * deductors[i].percent) / percentDivider;
            BUSD.transfer(deductors[i].wallet, amount);
            toContract -= amount;
        }

        length = referralBonuses.length;
        address targetAddress = msg.sender;
        for (uint256 i = 0; i < length; ++i) {
            targetAddress = getUserReferrer(targetAddress);
            if (targetAddress == address(0)) break;

            if (walletEntries[index][targetAddress] > 0) {
                amount = (halfAmount * referralBonuses[i]) / percentDivider;
                BUSD.transfer(targetAddress, amount);
                toContract -= amount;
            }
        }

        BUSD.transfer(stakingAddress, toContract);

        if (userid[msg.sender] == 0) {
            walletFromId.push(msg.sender);
            userid[msg.sender] = uint16(walletFromId.length) - 1;
        }

        uint16 id = userid[msg.sender];
        for (uint256 i = 0; i < tickets; ++i) {
            raffleEntries[index].push(id);
        }

        walletEntries[index][msg.sender] += uint16(tickets);
    }

    function getRaffleSummary(
        address addr
    )
        external
        view
        returns (
            uint256 latestIndex,
            uint32 currentStartDate,
            uint256 currentPot,
            uint256 currentEntries,
            uint256 entryCount,
            uint32 previousDrawDate,
            address previousWinner,
            uint256 previousPot
        )
    {
        latestIndex = latestRaffle;
        Raffle memory raffle = raffles[latestRaffle];
        currentStartDate = raffle.startDate;
        currentPot = raffle.winnerPot;
        currentEntries = raffleEntries[latestRaffle].length;
        entryCount = walletEntries[latestRaffle][addr];
        previousDrawDate = raffles[latestRaffle - 1].drawDate;
        previousWinner = raffles[latestRaffle - 1].winner;
        previousPot = raffles[latestRaffle - 1].winnerPot;
    }

    function getUserReferrer(address wallet) public view returns (address) {
        (address referrer, , , , , , , , , , , , ) = stakingContract.users(
            wallet
        );
        return referrer;
    }

    event NewRaffle(uint256 indexed raffleIndex, uint32 indexed startDate);
    event RaffleWinner(
        uint256 indexed raffleIndex,
        address indexed winner,
        uint256 indexed amount
    );

    event RaffleEntry(uint256 indexed raffleIndex, address indexed wallet);
}