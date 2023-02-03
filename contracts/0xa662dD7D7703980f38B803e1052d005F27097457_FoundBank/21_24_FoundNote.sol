// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../art/ArtData.sol";
import "./DailyMint.sol";

 /*$   /$$  /$$$$$$  /$$$$$$$$ /$$$$$$$$  /$$$$$$
| $$$ | $$ /$$__  $$|__  $$__/| $$_____/ /$$__  $$
| $$$$| $$| $$  \ $$   | $$   | $$      | $$  \__/
| $$ $$ $$| $$  | $$   | $$   | $$$$$   |  $$$$$$
| $$  $$$$| $$  | $$   | $$   | $$__/    \____  $$
| $$\  $$$| $$  | $$   | $$   | $$       /$$  \ $$
| $$ \  $$|  $$$$$$/   | $$   | $$$$$$$$|  $$$$$$/
|__/  \__/ \______/    |__/   |________/ \_____*/

interface IFound is IERC20 {}

struct CoinVote {
    address payer;
    address minter;
    uint artId;
    uint amount;
}

struct MintCoin {
    address payer;
    address minter;
    uint coinId;
    uint amount;
}

struct ClaimCoin {
    address minter;
    uint coinId;
    uint amount;
}

struct CreateNote {
    address payer;
    address minter;
    address delegate;
    address payee;
    uint fund;
    uint amount;
    uint duration;
    string memo;
    bytes data;
}

struct Note {
    uint id;
    uint artId;
    uint coinId;
    uint fund;
    uint reward;
    uint expiresAt;
    uint createdAt;
    uint collectedAt;
    uint shares;
    uint principal;
    uint penalty;
    uint earnings;
    uint funding;
    uint duration;
    uint dailyBonus;
    address delegate;
    address payee;
    bool closed;
    string memo;
    bytes data;
}

struct WithdrawNote {
    address payee;
    uint noteId;
    uint target;
}

struct DelegateNote {
    uint noteId;
    address delegate;
    address payee;
    string memo;
}

contract FoundNote is FoundBase {
    using Strings for uint;

    IFound private _money;
    address private _bank;
    ArtData private _data;

    uint private _tokenCount;
    uint private _totalShares;
    uint private _totalDeposits;
    uint private _totalEarnings;
    uint private _totalFunding;
    uint private _leap;
    uint private _start;

    uint public constant BASIS_POINTS = 10000;
    uint public constant BID_INCREMENT = 100;
    uint public constant DAY_BUFFER = 301 seconds;
    uint public constant DAY_LENGTH = 25 hours + 20 minutes;
    uint public constant DAYS_PER_WEEK = 7;
    uint public constant MAX_DAYS = 7300;
    uint public constant EARN_WINDOW = 30 * DAY_LENGTH;
    uint public constant LATE_DURATION = 60 * DAY_LENGTH;
    uint public constant MAX_DURATION = MAX_DAYS * DAY_LENGTH;
    uint public constant MIN_DURATION = DAY_LENGTH - 1 hours;

    mapping(uint => mapping(uint => uint)) private _votesOnArt;
    mapping(uint => uint) private _artToCoin;
    mapping(uint => uint) private _coinToArt;
    mapping(uint => Note) private _deposits;
    mapping(uint => uint) private _revenue;
    mapping(uint => uint) private _shares;
    mapping(uint => uint) private _claims;
    mapping(uint => uint) private _locks;

    event CoinCreated(
        uint indexed coinId,
        uint indexed artId,
        uint amount,
        uint timestamp
    );

    event CoinUpdated(
        uint indexed coinId,
        uint indexed from,
        uint indexed to,
        uint timestamp
    );

    event LeapDay(
        uint indexed day,
        uint dayLight,
        uint nightTime,
        uint leapSeconds,
        uint timestamp
    );

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
            msg.sender == address(_bank),
            "Caller is not based"
        );
        _;
    }

    function cash() external view returns (IFound) {
        return _money;
    }

    function data() external view returns (ArtData) {
        return _data;
    }

    function bank() external view returns (address) {
        return _bank;
    }

    function startTime() external view returns (uint) {
        return _start;
    }

    function leapSeconds() external view returns (uint) {
        return _leap;
    }

    function currentDay() external view returns (uint) {
        return _currentDay();
    }

    function timeToCoin(uint timestamp) external view returns (uint) {
        return _timeToCoin(timestamp);
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

    function totalEarnings() external view returns (uint) {
        return _totalEarnings;
    }

    function totalFunding() external view returns (uint) {
        return _totalFunding;
    }

    function getShares(uint noteId) external view returns (uint) {
        return _shares[noteId];
    }

    function getClaim(uint coinId) external view returns (uint) {
        return _claims[coinId];
    }

    function getLock(uint artId) external view returns (uint) {
        return _locks[artId];
    }

    function getNote(uint noteId) external view returns (Note memory) {
        return _requireNote(noteId);
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

    function coinRevenue(uint coinId) external view returns (uint amount) {
        return _revenue[coinId];
    }

    function votesOnArt(uint coinId, uint artId) external view returns (uint amount) {
        return _votesOnArt[coinId][artId];
    }

    function dayLength() external pure returns (uint) {
        return DAY_LENGTH;
    }

    function weekLength() external pure returns (uint) {
        return DAY_LENGTH * DAYS_PER_WEEK;
    }

    function _currentDay() internal view returns (uint) {
        return _timeToCoin(block.timestamp);
    }

    function _timeToCoin(uint timestamp) internal view returns (uint) {
        uint time = timestamp - _start + _leap;
        return time / DAY_LENGTH + 1;
    }

    function collectVote(CoinVote calldata params) external onlyAdmin returns (uint) {
        uint artId = params.artId;

        require(
            artId > 0 && artId <= _data.tokenCount(),
            "Art not found"
        );

        uint coinId = _currentDay();
        uint existing = _artToCoin[artId];

        require(
            existing == 0 || existing == coinId,
            "Art is already a coin"
        );

        uint leaderId = _coinToArt[coinId];
        uint leaderBid = _votesOnArt[coinId][leaderId];

        _revenue[coinId] += params.amount;
        _votesOnArt[coinId][artId] += params.amount;

        if (leaderId == 0 || leaderBid == 0) {
            _coinToArt[coinId] = artId;
            _artToCoin[artId] = coinId;

            emit CoinCreated(
                coinId,
                artId,
                params.amount,
                block.timestamp
            );
        }

        if (leaderId != artId) {
            uint minimum = leaderBid + leaderBid * BID_INCREMENT / BASIS_POINTS;

            if (_votesOnArt[coinId][artId] >= minimum) {
                _artToCoin[leaderId] = 0;
                _coinToArt[coinId] = artId;
                _artToCoin[artId] = coinId;

                emit CoinUpdated(
                    coinId,
                    leaderId,
                    artId,
                    block.timestamp
                );

                uint time = block.timestamp - _start + _leap;
                uint left = DAY_LENGTH - time % DAY_LENGTH;

                if (left < DAY_BUFFER) {
                    uint next = block.timestamp + left + DAY_BUFFER;
                    _leap += DAY_BUFFER;

                    emit LeapDay(
                        coinId,
                        left,
                        next,
                        _leap,
                        block.timestamp
                    );
                }
            }
        }

        return coinId;
    }

    function collectMint(
        uint supply,
        MintCoin calldata params
    ) external onlyAdmin returns (uint) {
        require(
            params.amount > 0,
            "Mint more than 0"
        );

        uint artId = _requireFoundArt(params.coinId);
        _requireUnlockedArt(artId, supply + params.amount);

        _revenue[params.coinId] += params.amount;
        return artId;
    }

    function collectClaim(
        address from,
        uint supply,
        ClaimCoin calldata params
    ) external onlyAdmin returns (uint) {
        require(
            params.amount > 0,
            "Claim more than 0"
        );

        require(
            params.coinId < _currentDay(),
            "Coin is not yet claimable"
        );

        uint artId = _requireFoundArt(params.coinId);
        _requireOwnerOrDelegate(artId, from);

        _requireUnlockedArt(artId, supply + params.amount);

        uint claim = _claims[params.coinId];
        uint limit = (supply - claim) / 10;

        require(
            limit >= params.amount + claim,
            "Claim exceeds allowance"
        );

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
            "Coin is not yet lockable"
        );

        uint artId = _requireFoundArt(coinId);
        _requireOwnerOrDelegate(artId, from);

        _locks[artId] = amount;
    }

      /*$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$  /$$       /$$$$$$$$
     /$$__  $$| $$  | $$ /$$__  $$| $$__  $$ /$$__  $$| $$__  $$| $$      | $$_____/
    | $$  \__/| $$  | $$| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$      | $$
    |  $$$$$$ | $$$$$$$$| $$$$$$$$| $$$$$$$/| $$$$$$$$| $$$$$$$ | $$      | $$$$$
     \____  $$| $$__  $$| $$__  $$| $$__  $$| $$__  $$| $$__  $$| $$      | $$__/
     /$$  \ $$| $$  | $$| $$  | $$| $$  \ $$| $$  | $$| $$  \ $$| $$      | $$
    |  $$$$$$/| $$  | $$| $$  | $$| $$  | $$| $$  | $$| $$$$$$$/| $$$$$$$$| $$$$$$$$
     \______/ |__/  |__/|__/  |__/|__/  |__/|__/  |__/|_______/ |________/|_______*/

    function collectDeposit(
        CreateNote calldata params,
        uint reward
    ) external onlyAdmin returns (Note memory) {
        require(
            params.amount > 0,
            "Deposit more than 0"
        );

        uint coinId = _currentDay() - 1;
        require(coinId > 0, "Staking begins tomorrow");

        uint artId = _coinToArt[coinId];
        require(artId > 0, "No art from yesterday");

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
        note.fund = params.fund;
        note.reward = reward;
        note.delegate = params.delegate;
        note.payee = params.payee;
        note.principal = params.amount;
        note.duration = params.duration;
        note.expiresAt = block.timestamp + params.duration;
        note.createdAt = block.timestamp;
        note.dailyBonus = bonus;
        note.shares = shares;

        _totalShares += shares;
        _totalDeposits += note.principal;

        return note;
    }

    function collectNote(
        address sender,
        address owner,
        uint noteId,
        address payee,
        uint target
    ) external onlyAdmin returns (Note memory) {
        require(
            noteId > 0 && noteId <= _tokenCount,
            "Deposit not found"
        );

        Note storage note = _deposits[noteId];

        require(
            note.collectedAt == 0,
            "Deposit already collected"
        );

        uint timestamp = block.timestamp;
        uint closeAt = note.expiresAt + EARN_WINDOW + LATE_DURATION;

        if (timestamp <= closeAt) {
            bool isOwner = sender == owner;

            require(
                isOwner || sender == note.delegate,
                "Caller is not the deposit owner or delegate"
            );

            require(
                isOwner || note.payee == address(0) || note.payee == payee,
                "Delegated payees do not match"
            );

            (
                note.earnings,
                note.funding,
                note.penalty
            ) = _calculateEarnings(note, timestamp);

            _totalEarnings += note.earnings;
            _totalFunding += note.funding;
        } else {
            note.penalty = note.principal;
            note.closed = true;
        }

        require(
            target == 0 || note.earnings >= target,
            "Earnings missed the target"
        );

        note.collectedAt = timestamp;

        _totalDeposits -= note.principal;
        _totalShares -= note.shares;

        return note;
    }

    function collectDelegate(
        address sender,
        address owner,
        DelegateNote memory params
    ) external onlyAdmin returns (Note memory) {
        uint noteId = params.noteId;
        require(
            noteId > 0 && noteId <= _tokenCount,
            "Deposit not found"
        );

        bool isOwner = sender == owner;
        Note storage note = _deposits[noteId];

        require(
            isOwner || sender == note.delegate,
            "Caller is not the owner or delegate"
        );

        require(
            isOwner || params.payee == note.payee,
            "Only the owner may update the payee"
        );

        require(
            isOwner || params.delegate != address(0),
            "Only the owner may remove the delegate"
        );

        note.memo = params.memo;
        note.delegate = params.delegate;

        if (params.delegate == address(0)) {
            note.payee = address(0);
        } else {
            note.payee = params.payee;
        }

        return note;
    }

    function afterTransfer(uint noteId) external onlyAdmin {
        Note storage note = _deposits[noteId];
        note.delegate = address(0);
        note.payee = address(0);
    }

    function averageRevenue() external view returns (uint) {
        return _calculateAverageRevenue(_currentDay() - 1);
    }

    function calculateAverageRevenue(uint coinId) external view returns (uint) {
        return _calculateAverageRevenue(coinId);
    }

    function _calculateAverageRevenue(uint coinId) internal view returns (uint) {
        uint limit = DAYS_PER_WEEK > coinId ? coinId : DAYS_PER_WEEK;
        uint total = 0;

        if (limit == 0) return 0;

        for (uint i = 0; i < limit; i += 1) {
            total += _revenue[coinId - i];
        }

        return total / limit;
    }

    function treasuryBalance() external view returns (uint) {
        return _treasuryBalance();
    }

    function _treasuryBalance() internal view returns (uint) {
        return _money.balanceOf(address(_bank)) - _totalDeposits;
    }

    function depositBalance(uint noteId) external view returns (uint) {
        return _depositBalance(_requireNote(noteId).shares);
    }

    function _depositBalance(uint shares) internal view returns (uint) {
        return _treasuryBalance() * shares / _totalShares;
    }

    function dailyBonus() external view returns (uint) {
        return _calculateDailyBonus(_currentDay() - 1, 1 ether);
    }

    function calculateDailyBonus(uint coinId, uint amount) external view returns (uint) {
        return _calculateDailyBonus(coinId, amount);
    }

    function _calculateDailyBonus(uint coinId, uint amount) internal view returns (uint) {
        uint current = _revenue[coinId];
        uint average = _calculateAverageRevenue(coinId);
        uint maximum = amount / 20;

        if (average == 0) return 0;
        if (current == 0) return maximum;
        if (current > average) return 0;
        if (average > current * 2) return maximum;

        return maximum * average / current - maximum;
    }

     /*$$$$$$  /$$$$$$$$ /$$    /$$ /$$$$$$$$ /$$   /$$ /$$   /$$ /$$$$$$$$
    | $$__  $$| $$_____/| $$   | $$| $$_____/| $$$ | $$| $$  | $$| $$_____/
    | $$  \ $$| $$      | $$   | $$| $$      | $$$$| $$| $$  | $$| $$
    | $$$$$$$/| $$$$$   |  $$ / $$/| $$$$$   | $$ $$ $$| $$  | $$| $$$$$
    | $$__  $$| $$__/    \  $$ $$/ | $$__/   | $$  $$$$| $$  | $$| $$__/
    | $$  \ $$| $$        \  $$$/  | $$      | $$\  $$$| $$  | $$| $$
    | $$  | $$| $$$$$$$$   \  $/   | $$$$$$$$| $$ \  $$|  $$$$$$/| $$$$$$$$
    |__/  |__/|________/    \_/    |________/|__/  \__/ \______/ |_______*/

    function calculateShares(uint coinId, uint amount, uint duration) public view returns (uint, uint) {
        require(duration >= MIN_DURATION, "Treasury note is too short");
        require(duration <= MAX_DURATION, "Treasury note is too long");

        uint totalDays = duration / DAY_LENGTH;
        uint bonus = _calculateDailyBonus(coinId, amount);
        uint longer = totalDays * totalDays;

        uint baseShares = amount + bonus;
        uint dailyShares = baseShares * totalDays;
        uint bonusShares = 4 * baseShares * longer / MAX_DAYS;

        uint shares = dailyShares + bonusShares;
        return (shares, bonus);
    }

    function calculateEarnings(
        uint noteId, uint timestamp
    ) external view returns (uint earnings, uint funding, uint penalty) {
        return _calculateEarnings(_requireNote(noteId), timestamp);
    }

    function _calculateEarnings(Note memory note, uint timestamp) internal view returns (uint, uint, uint) {
        uint penalty = _calculatePenalty(note, timestamp);

        if (penalty > 0) {
            return (0, 0, penalty);
        }

        uint balance = _depositBalance(note.shares);
        uint funding = balance * note.reward / BASIS_POINTS;

        return (balance - funding, funding, 0);
    }

    function calculatePenalty(uint noteId, uint timestamp) external view returns (uint) {
        return _calculatePenalty(_requireNote(noteId), timestamp);
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

        uint lateAt = expiresAt + EARN_WINDOW;

        if (timestamp > lateAt) {
            uint late = timestamp - lateAt;

            if (LATE_DURATION > late) {
                return principal * late / LATE_DURATION;
            }

            return principal;
        }

        return 0;
    }

    function _requireNote(uint noteId) internal view returns (Note memory) {
        require(
            noteId > 0 && noteId <= _tokenCount,
            "Note not found"
        );
        return _deposits[noteId];
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
            "Coin art has not been choosen"
        );

        require(
            _revenue[coinId] > 0,
            "Coin was not created"
        );

        return _coinToArt[coinId];
    }

    function _requireOwnerOrDelegate(
        uint artId,
        address addr
    ) internal view returns (address, address) {
        address owner = _data.ownerOf(artId);
        address delegate = _data.delegateOf(artId);

        require(
            delegate == addr || owner == addr,
            "Caller is not the owner or delegate"
        );

        return (owner, delegate);
    }

    constructor(
        address bank_,
        ArtData data_,
        IFound money_
    ) {
        _bank = bank_;
        _money = money_;
        _data = data_;
        _start = block.timestamp;
    }
}