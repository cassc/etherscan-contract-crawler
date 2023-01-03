// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "../money/Found.sol";
import "./ArtData.sol";
import "./DailyMint.sol";

 /*$   /$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$  /$$$$$$
| $$$ | $$ /$$__  $$|__  $$__/| $$_____/ /$$__  $$
| $$$$| $$| $$  \ $$   | $$   | $$      | $$  \__/
| $$ $$ $$| $$  | $$   | $$   | $$$$$   |  $$$$$$
| $$  $$$$| $$  | $$   | $$   | $$__/    \____  $$
| $$\  $$$| $$  | $$   | $$   | $$       /$$  \ $$
| $$ \  $$|  $$$$$$/   | $$   | $$$$$$$$|  $$$$$$/
|__/  \__/ \______/    |__/   |________/ \_____*/

struct Note {
    uint id;
    uint tax;
    uint govt;
    uint artId;
    uint coinId;
    uint expiresAt;
    uint createdAt;
    uint collectedAt;
    uint shares;
    uint principal;
    uint penalty;
    uint income;
    uint taxes;
    uint duration;
    uint dailyBonus;
    address delegate;
    bool closed;
    string memo;
    bytes data;
}

struct MintParams {
    address payer;
    address minter;
    uint coinId;
    uint amount;
}

struct VoteParams {
    address payer;
    address minter;
    uint artId;
    uint amount;
}

struct ClaimParams {
    address minter;
    uint coinId;
    uint amount;
}

struct DepositParams {
    address payer;
    address minter;
    address delegate;
    uint govt;
    uint amount;
    uint duration;
    string memo;
    bytes data;
}

struct WithdrawParams {
    address payee;
    uint depositId;
    bool toEther;
}

contract FoundNote is FoundBase {
    using Strings for uint;

    Found private _cash;
    address private _admin;
    ArtData private _data;

    uint private _start;
    uint private _extend;
    uint private _tokenCount;
    uint private _totalShares;
    uint private _totalDeposits;
    uint private _totalIncome;
    uint private _totalTaxes;

    uint public constant BASIS_POINTS = 10000;
    uint public constant BID_BUFFER = 301 seconds;
    uint public constant BID_INCREMENT = 200;  // 2%
    uint public constant BURN_CLOSE = 60 days;
    uint public constant BURN_WINDOW = 10 days;
    uint public constant DAY_LENGTH = 25 hours;
    uint public constant YEAR_LENGTH = 365 days;
    uint public constant WEEK_DURATION = 7;  // days
    uint public constant MAX_DURATION = 10 * 365;  // days
    uint public constant MIN_DURATION = 1;

    mapping(uint => mapping(uint => uint)) private _votesOnArt;
    mapping(uint => uint) private _artToCoin;
    mapping(uint => uint) private _coinToArt;
    mapping(uint => uint) private _cashOnCoin;
    mapping(uint => Note) private _deposits;
    mapping(uint => uint) private _shares;
    mapping(uint => uint) private _claims;
    mapping(uint => uint) private _locks;

    event ExtendAuction(uint day, uint to, uint timestamp);

      /*$$$$$  /$$$$$$$$ /$$$$$$  /$$$$$$$  /$$$$$$$$
     /$$__  $$|__  $$__//$$__  $$| $$__  $$| $$_____/
    | $$  \__/   | $$  | $$  \ $$| $$  \ $$| $$
    |  $$$$$$    | $$  | $$  | $$| $$$$$$$/| $$$$$
     \____  $$   | $$  | $$  | $$| $$__  $$| $$__/
     /$$  \ $$   | $$  | $$  | $$| $$  \ $$| $$
    |  $$$$$$/   | $$  |  $$$$$$/| $$  | $$| $$$$$$$$
     \______/    |__/   \______/ |__/  |__/|_______*/

    modifier onlyAdmin() {
        require(
            msg.sender == address(_admin),
            "Caller is not based"
        );
        _;
    }

    function cash() external view returns (Found) {
        return _cash;
    }

    function data() external view returns (ArtData) {
        return _data;
    }

    function admin() external view returns (address) {
        return _admin;
    }

    function startTime() external view returns (uint) {
        return _start;
    }

    function extendTime() external view returns (uint) {
        return _extend;
    }

    function tokenCount() external view returns (uint) {
        return _tokenCount;
    }

    function totalShares() external view returns (uint) {
        return _totalShares;
    }

    function totalDeposits() external view returns (uint) {
        return _totalDeposits;
    }

    function totalIncome() external view returns (uint) {
        return _totalIncome;
    }

    function totalTaxes() external view returns (uint) {
        return _totalTaxes;
    }

    function getShares(uint depositId) external view returns (uint) {
        return _shares[depositId];
    }

    function getClaims(uint coinId) external view returns (uint) {
        return _claims[coinId];
    }

    function getNote(uint depositId) external view returns (Note memory) {
        return _requireNote(depositId);
    }

    function getCoin(uint coinId) external view returns (Art memory) {
        return _data.getArt(_artToCoin[coinId]);
    }

    function artToCoin(uint artId) external view returns (uint coinId) {
        return _artToCoin[artId];
    }

    function coinToArt(uint coinId) external view returns (uint artId) {
        return _coinToArt[coinId];
    }

    function cashOnCoin(uint coinId) external view returns (uint amount) {
        return _cashOnCoin[coinId];
    }

    function votesOnArt(uint coinId, uint artId) external view returns (uint amount) {
        return _votesOnArt[coinId][artId];
    }

    function treasuryBalance() external view returns (uint) {
        return _treasuryBalance();
    }

    function currentDay() external view returns (uint) {
        return _currentDay();
    }

    function dayDuration() external pure returns (uint) {
        return DAY_LENGTH;
    }

    function weekDuration() external pure returns (uint) {
        return DAY_LENGTH * WEEK_DURATION;
    }

    function timeToCoin(uint timestamp) external view returns (uint) {
        return _timeToCoin(timestamp);
    }

     /*$      /$$ /$$$$$$ /$$   /$$ /$$$$$$$$ /$$$$$$  /$$$$$$$  /$$       /$$$$$$$$
    | $$$    /$$$|_  $$_/| $$$ | $$|__  $$__//$$__  $$| $$__  $$| $$      | $$_____/
    | $$$$  /$$$$  | $$  | $$$$| $$   | $$  | $$  \ $$| $$  \ $$| $$      | $$
    | $$ $$/$$ $$  | $$  | $$ $$ $$   | $$  | $$$$$$$$| $$$$$$$ | $$      | $$$$$
    | $$  $$$| $$  | $$  | $$  $$$$   | $$  | $$__  $$| $$__  $$| $$      | $$__/
    | $$\  $ | $$  | $$  | $$\  $$$   | $$  | $$  | $$| $$  \ $$| $$      | $$
    | $$ \/  | $$ /$$$$$$| $$ \  $$   | $$  | $$  | $$| $$$$$$$/| $$$$$$$$| $$$$$$$$
    |__/     |__/|______/|__/  \__/   |__/  |__/  |__/|_______/ |________/|_______*/

    function collectMint(
        uint supply,
        MintParams calldata params
    ) external onlyAdmin returns (uint) {
        require(params.amount > 0, "Must mint some coins");
        
        uint artId = _requireFoundArt(params.coinId);
        _requireUnlockedArt(artId, supply + params.amount);

        _cashOnCoin[params.coinId] += params.amount;
        return artId;
    }

    function collectVote(VoteParams calldata params) external onlyAdmin returns (uint) {
        uint artId = params.artId;
        require(
            artId > 0 && artId <= _data.tokenCount(),
            "Art not found"
        );

        uint coinId = _currentDay();
        uint existing = _artToCoin[artId];
        require(
            existing == 0 || existing == coinId,
            "Art has already been minted as a currency"
        );

        uint leaderId = _coinToArt[coinId];
        uint leaderBid = _votesOnArt[coinId][leaderId];

        _cashOnCoin[coinId] += params.amount;
        _votesOnArt[coinId][artId] += params.amount;

        if (leaderId == 0 || leaderBid == 0) {
            _coinToArt[coinId] = artId;
            _artToCoin[artId] = coinId;
        }

        if (leaderId != artId) {
            uint minimum = leaderBid + leaderBid * BID_INCREMENT / BASIS_POINTS;
            
            if (_votesOnArt[coinId][artId] >= minimum) {
                _artToCoin[leaderId] = 0;
                _coinToArt[coinId] = artId;
                _artToCoin[artId] = coinId;

                uint time = block.timestamp - _start + _extend;
                uint remaining = DAY_LENGTH - time % DAY_LENGTH;

                if (remaining < BID_BUFFER) {
                    _extend += BID_BUFFER;

                    uint ends = block.timestamp + remaining + BID_BUFFER;
                    emit ExtendAuction(coinId, ends, block.timestamp);
                }
            }
        }

        return coinId;
    }

    function collectClaim(
        address from,
        uint supply,
        ClaimParams calldata params
    ) external onlyAdmin returns (uint) {
        require(
            params.amount > 0,
            "Claim more than 0"
        );

        require(
            params.coinId < _currentDay(),
            "Coin is not claimable yet"
        );

        uint artId = _requireFoundArt(params.coinId);
        _requireUnlockedArt(artId, supply + params.amount);

        address owner = _data.ownerOf(artId);
        address delegate = _data.delegateOf(artId);

        require(
            delegate == from || owner == from, 
            "Caller is not the owner or delegate"
        );

        uint claimed = _claims[params.coinId];
        uint minted = supply - claimed;

        bool claimable = minted / 10 >= params.amount + claimed;
        require(claimable, "Claim too large");

        _claims[params.coinId] += params.amount;
        return artId;
    }

    function collectLock(
        address from, 
        uint coinId, 
        uint amount
    ) external onlyAdmin {
        require(
            coinId < _currentDay(),
            "Coin is not lockable yet"
        );

        uint artId = _requireFoundArt(coinId);
        address owner = _data.ownerOf(artId);

        require(owner == from, "Caller is not the owner");
        _locks[artId] = amount;
    }

     /*$$$$$$  /$$$$$$$$ /$$    /$$ /$$$$$$$$ /$$   /$$ /$$   /$$ /$$$$$$$$
    | $$__  $$| $$_____/| $$   | $$| $$_____/| $$$ | $$| $$  | $$| $$_____/
    | $$  \ $$| $$      | $$   | $$| $$      | $$$$| $$| $$  | $$| $$
    | $$$$$$$/| $$$$$   |  $$ / $$/| $$$$$   | $$ $$ $$| $$  | $$| $$$$$
    | $$__  $$| $$__/    \  $$ $$/ | $$__/   | $$  $$$$| $$  | $$| $$__/
    | $$  \ $$| $$        \  $$$/  | $$      | $$\  $$$| $$  | $$| $$
    | $$  | $$| $$$$$$$$   \  $/   | $$$$$$$$| $$ \  $$|  $$$$$$/| $$$$$$$$
    |__/  |__/|________/    \_/    |________/|__/  \__/ \______/ |_______*/

    function collectDeposit(DepositParams calldata params, uint tax) external onlyAdmin returns (Note memory) {
        require(
            params.amount > 0,
            "Deposit more than 0"
        );

        require(
            params.duration <= MAX_DURATION * 1 days,
            "Deposit cannot expire that far in the future"
        );

        require(
            params.duration >= MIN_DURATION * 1 days,
            "Deposit must expire further in the future"
        );

        uint coinId = _currentDay() - 1;
        require(coinId > 0, "Staking begins tomorrow");

        uint artId = _coinToArt[coinId];
        require(artId > 0, "No coin from yesterday");

        uint shares; uint bonus;
        (shares, bonus) = calculateShares(
            coinId,
            params.amount,
            params.duration
        );

        Note storage note = _deposits[++_tokenCount];
        note.id = _tokenCount;
        note.data = params.data;
        note.memo = params.memo;
        note.artId = artId;
        note.coinId = coinId;
        note.delegate = params.delegate;
        note.principal = params.amount;
        note.duration = params.duration;
        note.expiresAt = block.timestamp + params.duration;
        note.createdAt = block.timestamp;
        note.dailyBonus = bonus;
        note.shares = shares;

        if (tax > 0) {
            note.tax = tax;
            note.govt = params.govt;
        }

        _totalShares += shares;
        _totalDeposits += note.principal;

        return note;
    }

    function collectNote(
        uint depositId,
        address sender,
        address owner
    ) external onlyAdmin returns (Note memory) {
        require(
            depositId > 0 && depositId <= _tokenCount,
            "Deposit not found"
        );

        Note storage note = _deposits[depositId];

        require(
            note.collectedAt == 0,
            "Deposit already collected"
        );

        uint timestamp = block.timestamp;

        if (timestamp > note.expiresAt + BURN_CLOSE) {
            note.penalty = note.principal;
            note.closed = true;
        } else {
            require(
                sender == owner || sender == note.delegate, 
                "Caller is not the deposit owner or delegate"
            );

            (
                note.income,
                note.taxes,
                note.penalty
            ) = _calculateNotePayout(note, timestamp);
        }

        _totalDeposits -= note.principal;
        _totalShares -= note.shares;
        
        _totalIncome += note.income;
        _totalTaxes += note.taxes;

        note.collectedAt = timestamp;

        return note;
    }


    function delegateNote(
        uint depositId,
        address sender,
        address owner,
        address to, 
        string memory memo
    ) external onlyAdmin {
        require(
            depositId > 0 && depositId <= _tokenCount,
            "Deposit not found"
        );

        Note storage note = _deposits[depositId];

        require(
            sender == owner || sender == note.delegate,
            "Caller is not the owner or delegate"
        );

        note.delegate = to;
        note.memo = memo;
    }

    function calculateShares(uint coinId, uint amount, uint duration) public view returns (uint, uint) {
        uint totalDays = duration / 1 days;
        require(totalDays >= 1, "Treasury note is too short");
        require(totalDays <= MAX_DURATION, "Treasury note is too old");

        uint bonus = _calculateDailyBonus(coinId, amount);
        uint longer = (totalDays * totalDays) / MAX_DURATION;

        uint baseShares = amount + bonus;
        uint dailyShares = baseShares * totalDays;
        uint bonusShares = baseShares * longer;

        uint shares = dailyShares + bonusShares;
        return (shares, bonus);
    }

    function dailyBonus() external view returns (uint) {
        return _calculateDailyBonus(_currentDay() - 1, 1 ether);
    }

    function weeklyAverage() external view returns (uint) {
        return calculateWeeklyAverage(_currentDay() - 1);
    }

    function calculateDailyBonus(uint coinId, uint amount) public view returns (uint) {
        return _calculateDailyBonus(coinId, amount);
    }

    function _calculateDailyBonus(uint coinId, uint amount) internal view returns (uint) {
        uint current = _cashOnCoin[coinId];
        uint average = calculateWeeklyAverage(coinId);
        uint maximum = amount / 20;

        if (average == 0) return 0;
        if (current == 0) return maximum;
        if (current > average) return 0;
        if (average > current * 2) return maximum;

        return maximum * average / current - maximum;
    }

    function calculateWeeklyAverage(uint coinId) public view returns (uint) {
        uint limit = WEEK_DURATION > coinId ? coinId : WEEK_DURATION;
        uint total = 0;

        if (limit == 0) return 0;

        for (uint i = 0; i < limit; i += 1) {
            total += _cashOnCoin[coinId - i];
        }

        return total / limit;
    }

    function currentRevenue(uint depositId) public view returns (uint) {
        return _currentRevenue(_requireNote(depositId).shares);
    }

    function calculatePenalty(uint depositId, uint timestamp) external view returns (uint) {
        return _calculatePenalty(_requireNote(depositId), timestamp);
    }

    function calculateNotePayout(
        uint depositId, uint timestamp
    ) external view returns (uint income, uint taxes, uint penalty) {
        return _calculateNotePayout(_requireNote(depositId), timestamp);
    }

    function _calculatePenalty(Note memory note, uint timestamp) internal pure returns (uint) {
        uint expiresAt = note.expiresAt;
        uint principal = note.principal;

        if (timestamp < expiresAt) {
            uint createdAt = note.createdAt;
            uint remaining = expiresAt - timestamp;
            uint duration = expiresAt - createdAt;

            if (remaining >= duration) {
                return principal;
            }

            return principal * remaining / duration;
        }

        uint deadline = expiresAt + BURN_WINDOW;

        if (timestamp > deadline) {
            uint late = timestamp - deadline;

            if (BURN_CLOSE > late) {
                return principal * late / BURN_CLOSE;
            }

            return principal;
        }

        return 0;
    }

    function _calculateNotePayout(Note memory note, uint timestamp) internal view returns (uint, uint, uint) {
        uint penalty = _calculatePenalty(note, timestamp);

        if (penalty > 0) {
            return (0, 0, penalty);
        }

        uint total = _currentRevenue(note.shares);
        uint taxes = total * note.tax / BASIS_POINTS;

        return (total - taxes, taxes, 0);
    }

    function _currentDay() internal view returns (uint) {
        return _timeToCoin(block.timestamp);
    }

    function _timeToCoin(uint timestamp) internal view returns (uint) {
        uint time = timestamp - _start + _extend;
        return time / DAY_LENGTH + 1;
    }

    function _currentRevenue(uint shares) internal view returns (uint) {
        return _treasuryBalance() * shares / _totalShares;
    }

    function _treasuryBalance() internal view returns (uint) {
        return _cash.balanceOf(address(_admin)) - _totalDeposits;
    }

    function _requireNote(uint depositId) internal view returns (Note memory) {
        require(
            depositId > 0 && depositId <= _tokenCount,
            "Note not found"
        );
        return _deposits[depositId];
    }

    function _requireUnlockedArt(uint artId, uint targetSupply) internal view {
        uint lock = _locks[artId];
        require(
            lock == 0 || lock >= targetSupply, 
            "Coin supply has been locked"
        );
    }

    function _requireFoundArt(uint coinId) internal view returns (uint artId) {
        require(
            coinId > 0 && coinId < _currentDay(),
            "Coin has not been minted"
        );

        require(
            _cashOnCoin[coinId] > 0,
            "Coin was not minted"
        );

        return _coinToArt[coinId];
    }

    function _afterTokenTransfer(
        address from, address, uint tokenId, uint
    ) internal virtual {
        if (from != address(0)) {
            Note storage note = _deposits[tokenId];
            note.delegate = address(0);
        }
    }

    constructor(
        address admin_,
        ArtData data_,
        Found cash_
    ) {
        _admin = admin_;
        _cash = cash_;
        _data = data_;
        _start = block.timestamp;
    }
}