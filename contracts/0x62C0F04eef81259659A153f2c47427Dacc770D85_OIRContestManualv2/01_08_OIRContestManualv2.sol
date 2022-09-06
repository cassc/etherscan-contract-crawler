// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract OIRContestManualv2 is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract
    address public treasuryAddress; 

    struct Contest {
        uint16 id;                                  // unique ID for this contest
        uint16 entryCount;                          // number of entries
        uint16 maxEntries;                          // max number of entries
        uint16 maxEntriesForThree;                  // precalculated value for inexpensive comparison
        uint16 winningEntry;                        // winning entry number
        address paymentToken;                       // payment token address; for native, use 0x0000000000000000000000000000000000000000
        uint256 price;                              // price in token
        uint256 priceForThree;                      // precalculated price for three
        uint256 payments;                           // total of payments
        uint256 paymentsDistributed;                // profit distributed
        bool isWon;                            // if contest has been won
        bool isActive;                              // if contest is accepting entries
        bool refunded;                              // if contest was closed early and refunded
        mapping(uint256 => Entry) Entries;          // list of entries
        mapping(address => uint256) UserEntryCount; // entries count by address
    }

    mapping(uint256 => address) public ContestWinner;   // map contest id to winning address

    struct Entry {
        address user;               // user address
        uint256 amount;             // amount paid by user
    }

    uint256 public paymentsWithdrawn;

    struct FeeRecipient {
        address recipient;
        uint256 basisPoints;
    }

    mapping(uint256 => FeeRecipient) public FeeRecipients;
    uint256 public feeRecipientCount;
    uint256 public totalFeeBasisPoints;
    mapping(uint256 => Contest) public Contests;
    uint16 public contestCount;

    constructor(address treasury_) {
        treasuryAddress = treasury_;
    }

    // ** - CORE - ** //

    function buyOne(uint256 contestID) external payable {
        Contest storage contest = Contests[contestID];
        require(contest.isActive && ContestWinner[contestID] == address(0), "NOT_ACTIVE");
        require(contest.maxEntries > contest.entryCount, "EXCEEDS_MAX_ENTRIES");
        if (contest.paymentToken == address(0)) {
            require(msg.value == contest.price, "INCORRECT_PAYMENT");
        } else {
            IERC20(contest.paymentToken).transferFrom(_msgSender(), address(this), contest.price);
        }
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: contest.price});
        contest.entryCount++;
        contest.payments += contest.price;
        contest.UserEntryCount[_msgSender()]++;
        contest.isActive = contest.entryCount < contest.maxEntries;
        emit BuyOne(_msgSender(), contestID, contest.price);
    }     

    function buyThree(uint256 contestID) external payable {
        Contest storage contest = Contests[contestID];
        require(contest.isActive && ContestWinner[contestID] == address(0), "NOT_ACTIVE");
        require(contest.entryCount < contest.maxEntriesForThree, "EXCEEDS_MAX_ENTRIES");
        if (contest.paymentToken == address(0)) {
            // native
            require(msg.value == contest.priceForThree, "INCORRECT_PAYMENT");
        } else {
            IERC20(contest.paymentToken).transferFrom(_msgSender(), address(this), contest.priceForThree);
        }
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: contest.price});
        contest.entryCount++;
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: contest.price});
        contest.entryCount++;
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: contest.price});
        contest.entryCount++;
        contest.payments += contest.priceForThree;
        contest.UserEntryCount[_msgSender()] += 3;
        contest.isActive = contest.entryCount < contest.maxEntries;
        emit BuyThree(_msgSender(), contestID, contest.priceForThree);
    }

    function buy(uint256 contestID, uint256 amount) external payable {
        Contest storage contest = Contests[contestID];
        require(contest.isActive && ContestWinner[contestID] == address(0), "NOT_ACTIVE");
        require(contest.entryCount + amount <= contest.maxEntries, "EXCEEDS_MAX_ENTRIES");
        uint256 price = contest.price * amount;
        if (contest.paymentToken == address(0)) {
            // native
            require(msg.value == price, "INCORRECT_PAYMENT");
        } else {
            IERC20(contest.paymentToken).transferFrom(_msgSender(), address(this), price);
        }
        for(uint256 x; x < amount; x++) {
            contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: contest.price});
            contest.entryCount++;
        }
        contest.payments += price;
        contest.UserEntryCount[_msgSender()] += amount;
        contest.isActive = contest.entryCount < contest.maxEntries;
        emit Buy(_msgSender(), contestID, amount, msg.value);
    }

    function getContestEntries(uint256 contestID) external view returns(Entry[] memory) {
        Contest storage contest = Contests[contestID];
        Entry[] memory result = new Entry[](contest.entryCount);
        for(uint256 x; x < contest.entryCount; x++) {
            result[x] = contest.Entries[x];
        }
        return result;
    }

    function getUserEntryCount(uint256 contestID, address user) external view returns(uint256) {
        return Contests[contestID].UserEntryCount[user];
    }

    function getUserEntries(uint256 contestID, address user) external view returns(Entry[] memory) {
        Contest storage contest = Contests[contestID];
        Entry[] memory result = new Entry[](Contests[contestID].UserEntryCount[user]);
        uint256 entryCount;
        for(uint256 x; x < contest.entryCount; x++) {
            if (contest.Entries[x].user == user) {
                result[entryCount] = contest.Entries[x];
                entryCount++;
            }
        }
        return result;
    }

    // ** - ADD/EDIT CONTEST - ** //

    function addContest(uint16 maxEntries, bool isActive, address paymentToken, uint256 price) external onlyApproved 
    {
        Contest storage contest = Contests[contestCount];
        contest.id = contestCount;
        contest.maxEntries = maxEntries;
        contest.maxEntriesForThree = maxEntries - 2;
        contest.isActive = isActive;
        contest.paymentToken = paymentToken;
        contest.price = price;
        contest.priceForThree = price * 3;
        emit AddContest(_msgSender(), contestCount);      
        contestCount++;
    }

    function cloneContest(uint256 contestID, bool setActive) external onlyApproved 
    {
        Contest storage oldContest = Contests[contestID];
        Contest storage newContest = Contests[contestCount];
        newContest.id = contestCount;
        newContest.maxEntries = oldContest.maxEntries;
        newContest.maxEntriesForThree = oldContest.maxEntriesForThree;
        newContest.isActive = setActive;
        newContest.paymentToken = oldContest.paymentToken;
        newContest.price = oldContest.price;
        newContest.priceForThree = oldContest.priceForThree;
        emit CloneContest(_msgSender(), contestID, contestCount);      
        contestCount++;
    }    

    function editContest(uint256 contestID, uint16 maxEntries, bool isActive, address paymentToken, uint256 price) external onlyApproved {
        require(Contests[contestID].entryCount == 0, "ENTRIES_EXIST");
        Contest storage contest = Contests[contestID];
        contest.maxEntries = maxEntries;
        contest.isActive = isActive;
        contest.paymentToken = paymentToken;
        contest.price = price;
        contest.priceForThree = price * 3;
        emit EditContest(_msgSender(), contestCount);      
    }

    function setContestActive(uint256 contestID, bool isActive) external onlyApproved {
        require(!isActive || !Contests[contestID].isWon, "ALREADY_WON");
        Contests[contestID].isActive = isActive;
        emit SetContestActive(_msgSender(), contestID, isActive);
    }

    function setPriceForContest(uint256 contestID, uint256 price) external onlyApproved {
        Contests[contestID].price = price;
        Contests[contestID].priceForThree = price * 3;
    }

     // ** - PROXY - ** //

    function singleEntry(uint256 contestID, address receiver) external onlyApproved {
        Contest storage contest = Contests[contestID];
        require(contest.isActive && ContestWinner[contestID] == address(0), "NOT_ACTIVE");
        require(contest.maxEntries > contest.entryCount, "EXCEEDS_MAX_ENTRIES");
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: 0});
        contest.entryCount++;
        contest.UserEntryCount[receiver]++;
        contest.isActive = contest.entryCount < contest.maxEntries;
        emit SingleEntry(_msgSender(), receiver, contestID);
    }

    function tripleEntry(uint256 contestID, address receiver) external onlyApproved {
        Contest storage contest = Contests[contestID];
        require(contest.isActive && ContestWinner[contestID] == address(0), "NOT_ACTIVE");
        require(contest.maxEntriesForThree > contest.entryCount, "EXCEEDS_MAX_ENTRIES");
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: 0});
        contest.entryCount++;
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: 0});
        contest.entryCount++;
        contest.Entries[contest.entryCount] = Entry({user: _msgSender(), amount: 0});
        contest.entryCount++;
        contest.UserEntryCount[receiver] += 3;
        contest.isActive = contest.entryCount < contest.maxEntries;
        emit TripleEntry(_msgSender(), receiver, contestID);
    }

    // ** - ADMIN - ** //

    function endContestWithWinner(uint256 contestID, uint16 entryNum) external nonReentrant onlyOwner {
        require(ContestWinner[contestID] == address(0), "WINNER_PICKED");
        Contest storage contest = Contests[contestID];
        require(entryNum < contest.entryCount, "ENTRYNUM>ENTRYCOUNT");
        contest.isActive = false;
        contest.isWon = true;
        contest.winningEntry = entryNum;
        ContestWinner[contestID] = contest.Entries[entryNum].user;
        emit ManualCompleteContest(_msgSender(), contestID, ContestWinner[contestID]);
    }

    function endContestWithoutWinner(uint256 contestID) external nonReentrant onlyApproved {
        Contest storage contest = Contests[contestID];
        require(!contest.isWon, "CONTEST_WON");
        require(!contest.refunded, "ALREADY_REFUNDED");
        contest.isActive = false;
        contest.refunded = true;
        //refund entrants
        for(uint256 x; x < contest.entryCount; x++) {
            Entry storage entry = contest.Entries[x];
            if (entry.amount == 0) continue; //don't refund free entries
            uint256 amount = entry.amount;
            entry.amount == 0;
            if (contest.paymentToken == address(0)) {
                require(amount <= address(this).balance, "INSUFFICIENT_BNB");
                (bool sent, ) = entry.user.call{value: amount}("");
                require(sent, "FAILED_SENDING_FUNDS");
            } else {
                require(amount <= IERC20(contest.paymentToken).balanceOf(address(this)), "INSUFFICIENT_BALANCE");
                IERC20(contest.paymentToken).transfer(entry.user, amount);
            }
        }
        emit EndContestWithoutWinner(_msgSender(), contestID);
    }

    function withdrawBNB() external nonReentrant onlyApproved {
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        (bool sent, ) = treasuryAddress.call{value: bal}("");
        require(sent, "FAILED_SENDING_FUNDS");
        emit WithdrawBNB(_msgSender(), bal);
    }

    function withdrawTokens(address _token) external nonReentrant onlyApproved {
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        IERC20(_token).safeTransfer(
            treasuryAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    function isProxyToApproved(address proxyAddress) external view onlyOwner returns(bool) {
        return proxyToApproved[proxyAddress];
    }

    // ** - SETTERS - ** //

    function setTreasuryAddress(address addr) external onlyOwner {
        treasuryAddress = addr;
    }

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()] == true, "onlyProxy");
        _;
    }    

    modifier onlyApproved() {
        require(proxyToApproved[_msgSender()] == true || _msgSender() == owner(), "onlyProxy");
        _;
    }  

    event ManualCompleteContest(address indexed user, uint256 indexed contestID, address indexed winner);
    event BuyOne(address indexed user, uint256 indexed contestID, uint256 indexed amount);
    event BuyThree(address indexed user, uint256 indexed contestID, uint256 indexed amount);
    event Buy(address indexed user, uint256 indexed contestID, uint256 indexed amount, uint256 value);
    event AddContest(address indexed user, uint256 indexed id);
    event EditContest(address indexed user, uint256 indexed id);
    event SetContestActive(address indexed user, uint256 indexed id, bool indexed isActive);
    event SetPriceForContest(address indexed user, uint256 indexed contestID, uint256 indexed price);
    event SingleEntry(address indexed user, address indexed recipient, uint256 contestID);
    event TripleEntry(address indexed user, address indexed recipient, uint256 contestID);
    event DistributeFunds(address indexed sender, uint256 indexed contestID, address indexed recipient, uint256 amount);
    event WithdrawBNB(address indexed sender, uint256 indexed balance);
    event EndContestWithWinner(address indexed user, uint256 indexed contestID);
    event EndContestWithoutWinner(address indexed user, uint256 indexed contestID);
    event CloneContest(address indexed user, uint256 indexed oldContestID, uint256 indexed newContestID);
}