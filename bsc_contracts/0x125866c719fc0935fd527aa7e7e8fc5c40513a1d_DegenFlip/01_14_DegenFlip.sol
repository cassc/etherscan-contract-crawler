// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./DegenFlipTypes.sol";

interface IDFCoinNFT {
    function accountData(address account) external view returns (AccountTokenData memory);
    function getTokens(uint16[] calldata tokens) external view returns (Token[] memory);
    function isApprovedForAll(address owner, address operator) external view returns(bool);
}

contract DegenFlip is Ownable, AccessControlEnumerable, Pausable, ReentrancyGuard {

    struct Shares {
        uint16 holders; uint16 house; uint16 team;
    }

    struct Balance {
        uint holders; uint house; uint team;
    }

    struct Claimed {
        uint holders; uint team;
    }

    struct CoinsItemized {
        uint Crown;
        uint Banana;
        uint Diamond;
        uint Ape;
    }

    struct Flip {
        uint id;
        uint bet;
        uint flippedOn;
        uint resolvedOn;
        uint randomResult;
        address account;
        bool won;
        CoinSide side;
    }

    struct Rewards {
        uint fees; uint winnings;
    }

    struct AccountData {
        uint flips;
        uint totalPayment;
        uint losses;
        uint lossesBalance;
        uint lastLoss;
        uint wins;
        uint winsBalance;
        uint lastWin;
        uint claimed;
        Rewards rewards;
    }

    struct ContractData {
        uint8 maxFlipsPerTx;
        uint16 flipFees;
        uint minBetAmount;
        uint maxBetAmount;
        uint winsTotal;
        uint lossesTotal;
        uint currentId;
        uint lastResolvedId;
        address coinAddress;
        address teamWallet;
        Shares shares;
        Balance balance;
        Claimed claimed;
    }

    uint8 public MAX_FLIPS_PER_TX = 1;
    uint16 public FLIP_FEES = 350; // (350 / 1e4)% = 3.5%
    uint16 public HOLDERS_SHARES = 8572; // (300 / 1e4)% = 3% of FLIP_FEES -> (300 * 1e4) / 350 = 8571.4285714286
    uint16 public HOUSE_SHARES = 715; // (25 / 1e4)% = 0.25% of FLIP_FEES -> (25 * 1e4) / 350 = 714.2857142857
    uint16 public TEAM_SHARES = 713; // (25 / 1e4)% = 0.25% of FLIP_FEES -> 1e4 - (8572 + 715) = 713

    uint public MIN_BET_AMOUNT = 0.05 ether; // 0.05BNB
    uint public MAX_BET_AMOUNT = 2.0 ether; // 2.0 BNB

    uint public HOLDERS_BALANCE;
    uint public HOLDERS_CLAIMED;
    uint public HOUSE_BALANCE;
    uint public TEAM_BALANCE;
    uint public TEAM_CLAIMED;

    // flips
    uint public WINS_TOTAL;
    uint public LOSSES_TOTAL;
    uint public CURRENT_ID;
    uint public LAST_RESOLVED_ID;
    mapping(uint => Flip) private Flips;

    // coins
    mapping(CoinType => uint16) private COINS_TOTAL;
    mapping(CoinType => uint) private COINS_LIFETIME_REWARDS;
    mapping(uint16 => uint) private COINS_REWARDS_CLAIMED;

    // account
    mapping(address => uint) private ACCOUNT_PAYMENT_TOTAL;
    mapping(address => uint) private ACCOUNT_LOSSES;
    mapping(address => uint) private ACCOUNT_LOSSES_BALANCE;
    mapping(address => uint) private ACCOUNT_LAST_LOSS;
    mapping(address => uint) private ACCOUNT_WINNINGS;
    mapping(address => uint) private ACCOUNT_WINNINGS_BALANCE;
    mapping(address => uint) private ACCOUNT_WINNINGS_CLAIMED;
    mapping(address => uint) private ACCOUNT_LAST_WIN;

    event Flipped(address indexed account, uint flipId, uint bet, CoinSide side, uint timestamp);
    event HouseWalletTopOff(uint amount, uint timestamp);
    event HouseBalanceForwarded(address newGameContract, uint timestamp);
    event Resolved(address indexed account, uint flipId, CoinSide side, uint bet, bool result, uint timestamp);
    event RewardsClaimed(address indexed account, uint rewards, uint timestamp);
    event TeamFeesPayout(uint amount, uint timestamp);
    event TeamWalletUpdated(address wallet, uint timestamp);

    address TEAM_WALLET;
    address COIN_ADDRESS;
    IDFCoinNFT CoinNFT;

    constructor(address coin) Ownable() {
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(ADMIN, owner());
        _grantRole(OPERATOR, owner());

        COIN_ADDRESS = coin;
        CoinNFT = IDFCoinNFT(coin);
    }

    // internal //
    function _getPercentage(uint amount, uint percentage) internal pure returns(uint) {
        return (amount * percentage) / 1e4;
    }

    function _splitShares(uint bets, uint payment) internal {
        uint _fees = payment - bets;
        uint _holders = _getPercentage(_fees, HOLDERS_SHARES);
        uint _perCoinType = _getPercentage(_holders, 2500); // each coin type has 1/4 of the 3% fees
        uint _house = _getPercentage(_fees, HOUSE_SHARES);
        uint _team = _fees - (_holders + _house);

        // balance
        HOLDERS_BALANCE += _holders;
        HOUSE_BALANCE += (_house + bets);
        TEAM_BALANCE += _team;

        // coins
        COINS_LIFETIME_REWARDS[CoinType.Crown] += _perCoinType / COINS_TOTAL[CoinType.Crown];
        COINS_LIFETIME_REWARDS[CoinType.Banana] += _perCoinType / COINS_TOTAL[CoinType.Banana];
        COINS_LIFETIME_REWARDS[CoinType.Diamond] += _perCoinType / COINS_TOTAL[CoinType.Diamond];
        COINS_LIFETIME_REWARDS[CoinType.Ape] += _perCoinType / COINS_TOTAL[CoinType.Ape];
    }

    function _getTokensRewards(Token[] memory tokens) internal view returns(uint) {
        uint _totalRewards;
        Token memory _coin;

        for (uint8 _index = 0; _index < tokens.length; _index++) {
            _coin = tokens[_index];
            _totalRewards += COINS_LIFETIME_REWARDS[_coin.coinType] - COINS_REWARDS_CLAIMED[_coin.tokenId];
        }

        return _totalRewards;
    }

    function _claimTokensRewards(Token[] memory tokens) internal returns(uint) {
        uint _totalRewards;
        uint _coinRewards;
        Token memory _coin;

        for (uint8 _index = 0; _index < tokens.length; _index++) {
            _coin = tokens[_index];
            _coinRewards = COINS_LIFETIME_REWARDS[_coin.coinType] - COINS_REWARDS_CLAIMED[_coin.tokenId];
            _totalRewards += _coinRewards;
            COINS_REWARDS_CLAIMED[_coin.tokenId] += _coinRewards;
        }

        return _totalRewards;
    }

    function _flip(address account, uint bet, CoinSide side) internal {
        uint _now = block.timestamp;
        CURRENT_ID += 1;

        Flips[CURRENT_ID] = Flip({
            id: CURRENT_ID,
            bet: bet,
            flippedOn: _now,
            resolvedOn: 0,
            account: account,
            randomResult: 0,
            side: side,
            won: false
        });

        emit Flipped(account, CURRENT_ID, bet, side, _now);
    }

    function _claimRewards(address account) internal {
        AccountTokenData memory _tokensData = CoinNFT.accountData(account);
        uint _winningsTotal = ACCOUNT_WINNINGS_BALANCE[account] - ACCOUNT_WINNINGS_CLAIMED[account];
        uint _feesRewards = _claimTokensRewards(_tokensData.tokens);
        uint _totalRewards = _feesRewards + _winningsTotal;

        if (_totalRewards > 0) {
            HOLDERS_BALANCE -= _feesRewards;
            HOLDERS_CLAIMED += _feesRewards;
            ACCOUNT_WINNINGS_CLAIMED[account] += _winningsTotal;

            // transfer rewards
            payable(account).transfer(_totalRewards);

            emit RewardsClaimed(account, _totalRewards, block.timestamp);
        }
    }

    // ADMIN only //
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    function setMaxFlipsPerTx(uint8 flips) external onlyRole(ADMIN) {
        MAX_FLIPS_PER_TX = flips;
    }

    function setTeamWallet(address wallet) external onlyRole(ADMIN) {
        TEAM_WALLET = wallet;
        emit TeamWalletUpdated(wallet, block.timestamp);
    }

    function teamsFeesPayout() external payable onlyRole(ADMIN) {
        require(TEAM_WALLET != address(0), "Team wallet not set");
        require(TEAM_BALANCE > 0, "Zero balance");

        payable(TEAM_WALLET).transfer(TEAM_BALANCE);
        TEAM_CLAIMED += TEAM_BALANCE;
        TEAM_BALANCE = 0;

        emit TeamFeesPayout(TEAM_BALANCE, block.timestamp);
    }

    function forwardHouseBalance(address newGameContract) external onlyRole(ADMIN) {
        payable(newGameContract).transfer(HOUSE_BALANCE);
        HOUSE_BALANCE = 0;

        emit HouseBalanceForwarded(newGameContract, block.timestamp);
    }

    function sendRewards(address account) external onlyRole(ADMIN) {
        _claimRewards(account);
    }

    // only OPERATOR //
    function setCoinsTotal(CoinType cType, uint16 total) external onlyRole(OPERATOR) {
        COINS_TOTAL[cType] = total;
    }

    function resolve(uint[] calldata flipIds, uint[] calldata results) external onlyRole(OPERATOR) {
        require(flipIds.length == results.length, "Number of flips and results must be the same");

        uint _now = block.timestamp;
        uint _flipId;
        uint _randomResult;
        address _account;
        bool _won;
        uint _winnings;
        for (uint8 _index = 0; _index < flipIds.length; _index++) {
            _flipId = flipIds[_index];
            if (Flips[_flipId].resolvedOn > 0) {
                continue;
            }

            _account = Flips[_flipId].account;
            _randomResult = results[_index]; // random number from resolver
            _won = Flips[_flipId].side == ((_randomResult % 2) == 0 ? CoinSide.HEADS : CoinSide.TAILS); // even is HEADS/0, odd is TAILS/1

            if (_won) {
                _winnings = 2 * Flips[_flipId].bet;
                Flips[_flipId].won = _won;
                WINS_TOTAL += 1;
                HOUSE_BALANCE -= _winnings;
                ACCOUNT_WINNINGS[_account] += 1;
                ACCOUNT_WINNINGS_BALANCE[_account] += _winnings;
                ACCOUNT_LAST_WIN[_account] = _now;
            } else {
                LOSSES_TOTAL += 1;
                ACCOUNT_LOSSES[_account] += 1;
                ACCOUNT_LOSSES_BALANCE[_account] += Flips[_flipId].bet;
                ACCOUNT_LAST_LOSS[_account] = _now;
            }

            Flips[_flipId].resolvedOn = _now;
            Flips[_flipId].randomResult = _randomResult;
            LAST_RESOLVED_ID = _flipId;

            emit Resolved(_account, _flipId, Flips[_flipId].side, Flips[_flipId].bet, _won, _now);
        }
    }

    // public - writes //
    function houseWalletTopOff() external payable {
        require(msg.value > 0, "Insufficient top-off amount");
        HOUSE_BALANCE += msg.value;
        emit HouseWalletTopOff(msg.value, block.timestamp);
    }

    function flip(uint bet, uint amount, CoinSide side) external payable whenNotPaused {
        require(
            bet >= MIN_BET_AMOUNT && bet <= MAX_BET_AMOUNT && amount <= MAX_FLIPS_PER_TX,
            "Did not meet bet's min/max requirements"
        );
        uint _totalBet = bet * amount;
        uint _totalFees = _getPercentage(_totalBet, uint(FLIP_FEES));
        require(msg.value >= _totalBet + _totalFees, "Insufficient payment");
        require(HOUSE_BALANCE >= 2 * _totalBet, "Insufficient house balance for payout");

        address _account = _msgSender();
        for (uint8 _index = 0; _index < amount; _index++) {
            _flip(_account, bet, side);
        }

        // calculate shares
        _splitShares(_totalBet, msg.value);

        // record lifetime spend
        ACCOUNT_PAYMENT_TOTAL[_account] += msg.value;
    }

    function claimRewards() external whenNotPaused nonReentrant {
        _claimRewards(_msgSender());
    }

    // public - views //
    function getFlips(uint[] memory flips) external view returns(Flip[] memory) {
        Flip[] memory _allFlips = new Flip[](flips.length);

        for (uint8 _index = 0; _index < flips.length; _index++) {
            _allFlips[_index] = Flips[flips[_index]];
        }

        return _allFlips;
    }

    function getTokensRewards(uint16[] memory tokens) external view returns(uint) {
        return _getTokensRewards(CoinNFT.getTokens(tokens));
    }

    function getAccountRewards(address account) public view returns(Rewards memory) {
        AccountTokenData memory _tokensData = CoinNFT.accountData(account);

        return Rewards({
            fees: _getTokensRewards(_tokensData.tokens),
            winnings: ACCOUNT_WINNINGS_BALANCE[account] - ACCOUNT_WINNINGS_CLAIMED[account]
        });
    }

    function coinTotals() external view returns (CoinsItemized memory) {
        return CoinsItemized({
            Crown: uint(COINS_TOTAL[CoinType.Crown]),
            Banana: uint(COINS_TOTAL[CoinType.Banana]),
            Diamond: uint(COINS_TOTAL[CoinType.Diamond]),
            Ape: uint(COINS_TOTAL[CoinType.Ape])
        });
    }

    function coinRewards(CoinType cType) external view returns (uint) {
        return COINS_LIFETIME_REWARDS[cType];
    }

    function allCoinRewards() external view returns (CoinsItemized memory) {
        return CoinsItemized({
            Crown: COINS_LIFETIME_REWARDS[CoinType.Crown],
            Banana: COINS_LIFETIME_REWARDS[CoinType.Banana],
            Diamond: COINS_LIFETIME_REWARDS[CoinType.Diamond],
            Ape: COINS_LIFETIME_REWARDS[CoinType.Ape]
        });
    }

    function walletData(address account) public view returns(AccountData memory) {
        return AccountData({
            flips: ACCOUNT_WINNINGS[account] + ACCOUNT_LOSSES[account],
            totalPayment: ACCOUNT_PAYMENT_TOTAL[account],
            losses: ACCOUNT_LOSSES[account],
            lossesBalance: ACCOUNT_LOSSES_BALANCE[account],
            lastLoss: ACCOUNT_LAST_LOSS[account],
            wins: ACCOUNT_WINNINGS[account],
            winsBalance: ACCOUNT_WINNINGS_BALANCE[account],
            lastWin: ACCOUNT_LAST_WIN[account],
            claimed: ACCOUNT_WINNINGS_CLAIMED[account],
            rewards: getAccountRewards(account)
        });
    }

    function accountData() public view returns (AccountData memory) {
        return walletData(_msgSender());
    }

    function contractData() external view returns(ContractData memory) {
        return ContractData({
            coinAddress: COIN_ADDRESS,
            teamWallet: TEAM_WALLET,
            maxFlipsPerTx: MAX_FLIPS_PER_TX,
            minBetAmount: MIN_BET_AMOUNT,
            maxBetAmount: MAX_BET_AMOUNT,
            flipFees: FLIP_FEES,
            winsTotal: WINS_TOTAL,
            lossesTotal: LOSSES_TOTAL,
            currentId: CURRENT_ID,
            lastResolvedId: LAST_RESOLVED_ID,
            shares: Shares({holders: HOLDERS_SHARES, house: HOUSE_SHARES, team: TEAM_SHARES}),
            balance: Balance({holders: HOLDERS_BALANCE, house: HOUSE_BALANCE, team: TEAM_BALANCE}),
            claimed: Claimed({holders: HOLDERS_CLAIMED, team: TEAM_CLAIMED})
        });
    }
}