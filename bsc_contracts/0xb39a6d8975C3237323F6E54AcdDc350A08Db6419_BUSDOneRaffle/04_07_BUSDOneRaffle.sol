// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BUSDOneRaffle is Initializable {
    address public owner;
    token public BUSD;
    BUSDOneV3Interface public stakingContract;
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
    uint256 public overallPot;

    mapping(uint256 => mapping(address => uint16)) public walletEntries;
    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => TicketEntry[]) public raffleEntries;

    mapping(address => uint16) public userid;
    address[] public walletFromId;

    address public dualSystemAddress;
    address public toBnbAddress;
    address public serverAddress;

    uint256 public toDistribute;

    struct Raffle {
        uint256 winnerPot;
        address winner;
        uint32 startDate;
        uint32 drawDate;
        uint32 totalTickets;
    }

    struct TicketEntry {
        uint16 userid;
        uint16 amount;
    }

    function initialize(
        address _stakingContract,
        address busdContract,
        address developer,
        address team,
        address _dualSystemAddress,
        address _toBnbAddress,
        address _serverAddress
    ) external initializer {
        owner = msg.sender;

        BUSD = token(busdContract);
        stakingContract = BUSDOneV3Interface(_stakingContract);
        stakingAddress = _stakingContract;
        dualSystemAddress = _dualSystemAddress;
        toBnbAddress = _toBnbAddress;
        serverAddress = _serverAddress;

        entryPrice = 5 ether;
        percentDivider = 100;

        deductors.push(Deductor(developer, 3));
        deductors.push(Deductor(team, 3));

        referralBonuses = [7, 3, 2];
        walletFromId.push(address(this));

        createRaffle();
    }

    // Raffle Management

    function createRaffle() public onlyOwner {
        latestRaffle++;
        raffles[latestRaffle].startDate = uint32(block.timestamp);
    }

    function drawRaffle(
        string memory randomString,
        uint256 index
    ) public onlyOwner returns (address winner) {
        Raffle storage raffle = raffles[index];
        require(
            raffle.winner == address(0),
            "This raffle already has a winner."
        );

        require(raffle.winnerPot > 0, "No winner pot.");

        uint16[] memory entries = new uint16[](raffle.totalTickets);

        uint256 currentIndex;
        TicketEntry memory entry;

        for (uint256 i = 0; i < raffleEntries[index].length; ++i) {
            entry = raffleEntries[index][i];
            for (uint256 j = 0; j < entry.amount; ++j) {
                entries[currentIndex] = entry.userid;
                currentIndex++;
            }
        }

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    entries,
                    randomString
                )
            )
        );

        uint256 winnerIndex = randomNumber % entries.length;

        winner = walletFromId[entries[winnerIndex]];

        raffle.winner = winner;
        BUSD.transfer(winner, raffle.winnerPot);

        raffle.drawDate = uint32(block.timestamp);

        emit RaffleWinner(index, winner, raffle.winnerPot);
    }

    function drawAndCreateRaffle(
        string memory randomString
    ) external onlyOwner returns (address winner) {
        winner = drawRaffle(randomString, latestRaffle);
        createRaffle();
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner || msg.sender == serverAddress,
            "Not allowed."
        );
        _;
    }

    // User Methods
    function receiveDualIncome(
        address wallet,
        address referrer,
        uint256 tickets,
        uint256 totalAmount
    ) external {
        require(msg.sender == dualSystemAddress, "Not allowed.");

        uint256 index = latestRaffle;
        Raffle storage raffle = raffles[index];
        if (totalAmount > 0) {
            // Partitioning the amount
            uint256 toWinner = totalAmount / 2;

            if (raffle.winnerPot + toWinner > 3000 ether) {
                toWinner = 3000 ether - raffle.winnerPot;
            }
            if (toWinner > 0) {
                raffle.winnerPot += toWinner;
                overallPot += toWinner;
            }

            toDistribute += totalAmount - toWinner;
        }

        // Register tickets
        if (userid[wallet] == 0) {
            walletFromId.push(wallet);
            userid[wallet] = uint16(walletFromId.length) - 1;
        }

        uint16 id = userid[wallet];
        raffleEntries[index].push(TicketEntry(id, uint16(tickets)));
        walletEntries[index][wallet] += uint16(tickets);

        raffle.totalTickets += uint32(tickets);

        if (referrer != address(0)) {
            if (userid[referrer] == 0) {
                walletFromId.push(referrer);
                userid[referrer] = uint16(walletFromId.length) - 1;
            }

            id = userid[referrer];
            raffleEntries[index].push(TicketEntry(id, uint16(tickets)));
            walletEntries[index][referrer] += uint16(tickets);

            raffle.totalTickets += uint32(tickets);
        }
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
        currentEntries = raffle.totalTickets;
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

    function setAddress(uint256 index, address addr) external onlyOwner {
        if (index == 1) {
            stakingAddress = addr;
            stakingContract = BUSDOneV3Interface(addr);
        } else if (index == 2) {
            toBnbAddress = addr;
        } else if (index == 3) {
            dualSystemAddress = addr;
        }
    }

    function distribute() external onlyOwner {
        uint256 toContract = toDistribute;

        uint256 length = deductors.length;
        uint256 amount;
        for (uint256 i = 0; i < length; ++i) {
            amount = (toDistribute * deductors[i].percent) / percentDivider;
            BUSD.transfer(deductors[i].wallet, amount);
            toContract -= amount;
        }

        BUSD.transfer(stakingAddress, toContract / 2);
        BUSD.transfer(toBnbAddress, toContract / 2);

        toDistribute = 0;
    }

    event RaffleWinner(
        uint256 indexed raffleIndex,
        address indexed winner,
        uint256 indexed amount
    );

    event RaffleEntry(uint256 indexed raffleIndex, address indexed wallet);
}

interface BUSDOneV3Interface {
    function users(
        address addr
    )
        external
        view
        returns (
            address referrer,
            uint32 lastClaim,
            uint32 startIndex,
            uint128 bonusClaimed,
            uint96 bonus_0,
            uint32 downlines_0,
            uint96 bonus_1,
            uint32 downlines_1,
            uint96 bonus_2,
            uint32 downlines_2,
            uint96 leftOver,
            uint32 lastWithdraw,
            uint96 totalStaked
        );

    function registerStaker(address addr, address upline) external;
}

interface token {
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