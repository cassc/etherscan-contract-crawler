// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract BetTokenWrapper is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __BetTokenWrapper_init() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    function betToContract(
        uint256 amount_,
        address userAddress_,
        address tokenAddress_
    ) internal {
        IERC20Upgradeable betToken = IERC20Upgradeable(tokenAddress_);
        betToken.safeTransferFrom(userAddress_, address(this), amount_);
    }

    function transferProtocolFee(
        address DAO_,
        uint256 daoValue_,
        address REVENUE_,
        uint256 revenueValue_,
        address tokenAddress_
    ) internal {
        if (daoValue_ != 0) {
            transfer(DAO_, daoValue_, tokenAddress_);
        }

        if (revenueValue_ != 0) {
            transfer(REVENUE_, revenueValue_, tokenAddress_);
        }
    }

    function transferHostCommission(
        address host_,
        uint256 amount_,
        address tokenAddress_
    ) internal {
        transfer(host_, amount_, tokenAddress_);
    }

    function adminTransfer(
        address receiver_,
        uint256 amount_,
        address tokenAddress_
    ) public onlyOwner {
        transfer(receiver_, amount_, tokenAddress_);
    }

    function transfer(
        address receiver_,
        uint256 amount_,
        address tokenAddress_
    ) private {
        require(
            receiver_ != address(0),
            "Error: receiver can not be address 0"
        );

        IERC20Upgradeable betToken = IERC20Upgradeable(tokenAddress_);

        betToken.safeTransfer(receiver_, amount_);
    }

    function withdraw(uint256 amount_, address tokenAddress_) internal {
        IERC20Upgradeable betToken = IERC20Upgradeable(tokenAddress_);

        betToken.safeTransfer(msg.sender, amount_);
    }

    uint256[6] __gap;
}

contract BettingDynamicOdds is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    BetTokenWrapper
{
    enum Result {
        HIDDEN,
        RIGHT,
        WRONG
    }

    enum GameStatus {
        NOT_CREATED,
        OPEN,
        REPORT_PERIOD,
        CLOSE,
        TERMINATE
    }

    struct PlayerBettingInfo {
        uint256 bettingAmount;
        uint256 index;
        bool joined;
        bool claimed;
    }

    struct PlayersManager {
        mapping(address => PlayerBettingInfo) playerBettingInfo;
        address[] players;
        uint256 totalBettingAmount;
    }

    struct PlayerReport {
        address player;
        Result resultReport;
    }

    struct Report {
        uint256 total;
        mapping(address => bool) reported;
        PlayerReport[] playerReports;
    }

    struct Game {
        address creator;
        Result creatorInitResult;
        Result result;
        mapping(Result => PlayersManager) pools;
        uint256 deadline;
        uint256 reportTimeEnd;
        Report reports;
        GameStatus status;
        address betToken;
        bool penalty;
        uint256 gameMinBetAmount;
        uint256 creatorInitAmount;
    }

    struct GameInfo {
        address creator;
        Result creatorInitResult;
        Result result;
        uint256 wrongTotalBettingAmount;
        uint256 rightTotalBettingAmount;
        uint256 deadline;
        uint256 reportTimeEnd;
        uint256 reportCount;
        GameStatus status;
        address betToken;
        bool penalty;
        uint256 gameMinBetAmount;
        uint256 creatorInitAmount;
    }

    struct WhitelistToken {
        mapping(address => bool) accepted;
        address[] tokens;
    }

    modifier onlyGameOwner(uint256 gameContentHash_) {
        require(
            games[gameContentHash_].creator == msg.sender,
            "Error: You are not the game's owner"
        );
        _;
    }

    event CreateGame(
        address indexed gameOwner_,
        uint256 gameId_,
        uint256 deadline_
    );
    event PlayerBet(
        address indexed player_,
        uint256 gameId_,
        uint256 amount_,
        Result predictResult_
    );
    event FinalizeGame(uint256 gameId_, Result result_);
    event Claim(address indexed player_, uint256 gameId_, uint256 amount_);
    event HostCommission(
        address indexed player_,
        uint256 gameId_,
        uint256 commission_
    );
    event ChargeProtocolFee(
        address indexed player_,
        uint256 gameId_,
        uint256 daoFee_,
        uint256 revenueFee_
    );

    event ReportGame(address indexed player_, uint256 gameId_, Result result_);
    event RequestAdminCheck(uint256 indexed gameId_);
    event TerminateGame(uint256 indexed gameId_);
    event GetRefund(
        uint256 indexed gameId_,
        address indexed player_,
        uint256 refundAmount_
    );

    event AdminResolveReport(uint256 indexed gameId_, Result correctResult_);

    event AllowClaim(uint256 indexed gameId_, Result finalResult_);

    event Penalty(
        uint256 indexed gameId_,
        address gameOwner_,
        uint256 penaltyAmount_
    );

    string public _name;
    address public _DAO;
    address public _REVENUE;
    uint256 public _DAO_RATE; // 1/10000
    uint256 public _REVENUE_RATE; // 1/10000
    uint256 public _HOST_COMMISSION_RATE; // 1/10000
    uint256 public _NOT_REVEAL_RESULT_PENALTY_RATE;
    uint256 public _RATE_DENOMINATOR;
    uint256 public _MAXIMUM_BET_AMOUNT;
    uint256 public _MINIMUM_BET_AMOUNT;
    uint256 public _REQUEST_ADMIN_CHECK_RATE;
    uint256 public _REPORT_CUT_OFF_TIME;
    uint256 public _MINIMUM_DEADLINE;

    uint256[15] __gapStorage;

    WhitelistToken whitelistTokens;

    mapping(address => bool) public operators;

    mapping(uint256 => Game) internal games;

    function initialize(
        string memory name_,
        address DAO_,
        address REVENUE_,
        uint256 daoRate_,
        uint256 revenueRate_,
        uint256 hostCommissionRate_,
        uint256 minBet_,
        uint256 maxBet_,
        address[] memory whitelistTokens_
    ) public initializer {
        __BetTokenWrapper_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _NOT_REVEAL_RESULT_PENALTY_RATE = 10000;
        _RATE_DENOMINATOR = 10000;
        _REQUEST_ADMIN_CHECK_RATE = 3000;
        _REPORT_CUT_OFF_TIME = 1 days;
        _MINIMUM_DEADLINE = 1 days;

        _name = name_;
        _DAO = DAO_;
        _REVENUE = REVENUE_;
        _DAO_RATE = daoRate_;
        _REVENUE_RATE = revenueRate_;
        _HOST_COMMISSION_RATE = hostCommissionRate_;
        _MINIMUM_BET_AMOUNT = minBet_;
        _MAXIMUM_BET_AMOUNT = maxBet_;

        operators[msg.sender] = true;

        uint256 length = whitelistTokens_.length;

        for (uint256 index = 0; index < length; index++) {
            whitelistTokens.accepted[whitelistTokens_[index]] = true;
            whitelistTokens.tokens.push(whitelistTokens_[index]);
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setWhitelistToken(address tokenAddress_) public onlyOwner {
        require(
            whitelistTokens.accepted[tokenAddress_] == false,
            "Can not remove the un-existed token"
        );

        whitelistTokens.accepted[tokenAddress_] = true;

        whitelistTokens.tokens.push(tokenAddress_);
    }

    function removeTokenFromWhitelist(address tokenAddress_) public onlyOwner {
        require(
            whitelistTokens.accepted[tokenAddress_] == true,
            "Can not remove the un-existed token"
        );
        whitelistTokens.accepted[tokenAddress_] = false;

        uint256 length = whitelistTokens.tokens.length;
        for (uint256 index = 0; index < length; index++) {
            if (whitelistTokens.tokens[index] == tokenAddress_) {
                whitelistTokens.tokens[index] = whitelistTokens.tokens[
                    length - 1
                ];
                whitelistTokens.tokens.pop();
                break;
            }
        }
    }

    function setOperators(
        address[] memory removeAddrs,
        address[] memory newAddrs
    ) public onlyOwner {
        uint256 len = removeAddrs.length;
        for (uint256 index = 0; index < len; index++) {
            operators[removeAddrs[index]] = false;
        }

        len = newAddrs.length;
        for (uint256 index = 0; index < len; index++) {
            operators[newAddrs[index]] = true;
        }
    }

    function setDaoRate(uint256 rate_) public onlyOwner {
        require(
            rate_ <= 10000,
            "Error: can not set rate that is greater than 10000"
        );
        _DAO_RATE = rate_;
    }

    function setRevenueRate(uint256 rate_) public onlyOwner {
        require(
            rate_ <= 10000,
            "Error: can not set rate that is greater than 10000"
        );
        _REVENUE_RATE = rate_;
    }

    function setReportCutOffTime(uint256 time_) public onlyOwner {
        _REPORT_CUT_OFF_TIME = time_;
    }

    function setHostCommissionRate(uint256 rate_) public onlyOwner {
        require(
            rate_ <= 10000,
            "Error: can not set rate that is greater than 10000"
        );
        _HOST_COMMISSION_RATE = rate_;
    }

    function setMinimumBetAmount(uint256 amount_) public onlyOwner {
        _MINIMUM_BET_AMOUNT = amount_;
    }

    function setMaximumBetAmount(uint256 amount_) public onlyOwner {
        _MAXIMUM_BET_AMOUNT = amount_;
    }

    function setMinimumDeadline(uint256 minDeadline_) public onlyOwner {
        _MINIMUM_DEADLINE = minDeadline_;
    }

    function setRequestAdminCheckRate(
        uint256 requestCheckRate_
    ) public onlyOwner {
        require(
            requestCheckRate_ <= 10000,
            "Error: can not set rate that is greater than 10000"
        );
        _REQUEST_ADMIN_CHECK_RATE = requestCheckRate_;
    }

    function setDaoAddress(address dao_) public onlyOwner {
        require(dao_ != address(0), "Error: DAO can not be address 0x00");
        _DAO = dao_;
    }

    function setRevenueAddress(address revenue_) public onlyOwner {
        require(
            revenue_ != address(0),
            "Error: Revenue can not be address 0x00"
        );
        _REVENUE = revenue_;
    }

    function setPenaltyRate(uint256 rate_) public onlyOwner {
        require(
            rate_ <= 10000,
            "Error: can not set rate that is greater than 10000"
        );
        _NOT_REVEAL_RESULT_PENALTY_RATE = rate_;
    }

    function getTokenWhitelist() public view returns (address[] memory) {
        return whitelistTokens.tokens;
    }

    /**
     * @notice This function is used to get report info of the game
     * @param gameId_ game id
     */
    function getReportList(
        uint256 gameId_
    ) public view returns (PlayerReport[] memory) {
        return games[gameId_].reports.playerReports;
    }

    /**
     * @notice This function is used by player to bet on the game
     * @notice Player have to approve amount_ token before call this function
     * @param gameId_ game id
     * @param initFee_ the fee that host have to bet on this game first to init the game
     * @param predictResult_ predict result is base on Result enum
     * @param deadline_ unixtimestamp that is the deadline of this game
     */

    function createGame(
        uint256 gameId_,
        uint256 initFee_,
        Result predictResult_,
        uint256 deadline_,
        address betToken_,
        uint256 gameMinBetAmount_
    ) public {
        require(
            whitelistTokens.accepted[betToken_] == true,
            "Error: your token isn't in whitelist"
        );

        require(
            games[gameId_].status == GameStatus.NOT_CREATED,
            "Error: Your game was created!"
        );

        require(
            gameMinBetAmount_ >= _MINIMUM_BET_AMOUNT &&
                gameMinBetAmount_ <= _MAXIMUM_BET_AMOUNT,
            "Error: initFee is not greater than minimum bet and lower than Maximum bet"
        );

        require(
            initFee_ >= gameMinBetAmount_,
            "Error: initFee is not greater than minimum bet"
        );

        require(
            (deadline_ - block.timestamp) >= _MINIMUM_DEADLINE,
            "Error: Your betting period is smaller than _MINIMUM_DEADLINE!"
        );

        games[gameId_].status = GameStatus.OPEN;
        //Set deadline
        games[gameId_].deadline = deadline_;

        games[gameId_].creatorInitResult = predictResult_;

        games[gameId_].creator = msg.sender;

        games[gameId_].betToken = betToken_;

        games[gameId_].gameMinBetAmount = gameMinBetAmount_;

        games[gameId_].creatorInitAmount = initFee_;

        emit CreateGame(msg.sender, gameId_, deadline_);
        //init betting by host
        bet(gameId_, predictResult_, initFee_);
    }

    /**
     * @notice This function is used by player to bet on the game
     * @notice Player have to approve amount_ token before call this function
     * @param gameId_ game id
     * @param predictResult_ predict result is base on Result enum
     * @param amount_ amount that player bet on game
     */
    function bet(
        uint256 gameId_,
        Result predictResult_,
        uint256 amount_
    ) public nonReentrant {
        require(
            games[gameId_].status == GameStatus.OPEN,
            "Error: Your game is not open!"
        );

        require(
            amount_ >= games[gameId_].gameMinBetAmount,
            "Error: Please betting with an amount token that is greater than game min bet amount!"
        );

        require(
            block.timestamp < games[gameId_].deadline,
            "Error: your game is timeout!"
        );

        require(predictResult_ != Result.HIDDEN, "Error: Result can not be 0");

        super.betToContract(amount_, msg.sender, games[gameId_].betToken);

        //update pool
        if (
            games[gameId_]
                .pools[predictResult_]
                .playerBettingInfo[msg.sender]
                .joined == false
        ) {
            games[gameId_]
                .pools[predictResult_]
                .playerBettingInfo[msg.sender]
                .joined = true;

            games[gameId_]
                .pools[predictResult_]
                .playerBettingInfo[msg.sender]
                .index = games[gameId_].pools[predictResult_].players.length;

            games[gameId_].pools[predictResult_].players.push(msg.sender);
        }

        games[gameId_]
            .pools[predictResult_]
            .playerBettingInfo[msg.sender]
            .bettingAmount += amount_;

        //Check if game creator keeps stake in host pool
        if (
            predictResult_ == games[gameId_].creatorInitResult &&
            msg.sender == games[gameId_].creator
        ) {
            require(
                games[gameId_]
                    .pools[predictResult_]
                    .playerBettingInfo[msg.sender]
                    .bettingAmount -
                    games[gameId_].creatorInitAmount <=
                    _MAXIMUM_BET_AMOUNT,
                "Error: your total bet on this result is greater than MAX BET AMOUNT"
            );
        } else {
            require(
                games[gameId_]
                    .pools[predictResult_]
                    .playerBettingInfo[msg.sender]
                    .bettingAmount <= _MAXIMUM_BET_AMOUNT,
                "Error: your total bet on this result is greater than MAX BET AMOUNT"
            );
        }

        games[gameId_].pools[predictResult_].totalBettingAmount += amount_;

        emit PlayerBet(msg.sender, gameId_, amount_, predictResult_);
    }

    /**
     * @notice This function get game info
     * @param gameId_ game id
     */
    function getGame(uint256 gameId_) public view returns (GameInfo memory) {
        GameInfo memory gameInfo;

        gameInfo.creator = games[gameId_].creator;
        gameInfo.result = games[gameId_].result;
        gameInfo.wrongTotalBettingAmount = games[gameId_]
            .pools[Result.WRONG]
            .totalBettingAmount;
        gameInfo.rightTotalBettingAmount = games[gameId_]
            .pools[Result.RIGHT]
            .totalBettingAmount;
        gameInfo.status = games[gameId_].status;
        gameInfo.deadline = games[gameId_].deadline;
        gameInfo.reportCount = games[gameId_].reports.total;
        gameInfo.betToken = games[gameId_].betToken;
        gameInfo.reportTimeEnd = games[gameId_].reportTimeEnd;
        gameInfo.penalty = games[gameId_].penalty;
        gameInfo.gameMinBetAmount = games[gameId_].gameMinBetAmount;
        gameInfo.creatorInitAmount = games[gameId_].creatorInitAmount;

        return gameInfo;
    }

    /**
     * @notice This function list players address that bet in right by game id
     * @param gameId_ game id
     */

    function getRightPlayers(
        uint256 gameId_
    ) public view returns (address[] memory) {
        return games[gameId_].pools[Result.RIGHT].players;
    }

    /**
     * @notice This function list players address that bet in wrong by game id
     * @param gameId_ game id
     */
    function getWrongPlayers(
        uint256 gameId_
    ) public view returns (address[] memory) {
        return games[gameId_].pools[Result.WRONG].players;
    }

    /**
     * @notice This function gets player info by game id
     * @param gameId_ game id
     */
    function getPlayerInfo(
        uint256 gameId_
    )
        public
        view
        returns (PlayerBettingInfo memory right, PlayerBettingInfo memory wrong)
    {
        right = games[gameId_].pools[Result.RIGHT].playerBettingInfo[
            msg.sender
        ];
        wrong = games[gameId_].pools[Result.WRONG].playerBettingInfo[
            msg.sender
        ];
        return (right, wrong);
    }

    /**
     * @notice This function is used to get player betting amount
     * @param player_ player address
     * @param gameId_ game id
     */

    function betBalanceOf(
        address player_,
        uint256 gameId_
    ) public view returns (uint256 right, uint256 wrong) {
        return (
            games[gameId_]
                .pools[Result.RIGHT]
                .playerBettingInfo[player_]
                .bettingAmount,
            games[gameId_]
                .pools[Result.WRONG]
                .playerBettingInfo[player_]
                .bettingAmount
        );
    }

    /**
     * @notice This function is used by admin who has joined the game to finalize the game with result
     * @param gameId_ game id
     * @param result_ game result
     */

    function finalizeGame(uint256 gameId_, Result result_) public nonReentrant {
        require(
            operators[msg.sender] || games[gameId_].creator == msg.sender,
            "Error: you are not game's host or admin"
        );

        require(
            games[gameId_].status == GameStatus.OPEN,
            "Error: Your game is not open!"
        );

        require(
            games[gameId_].deadline < block.timestamp,
            "Error: Your game doesn't reach the deadline!"
        );

        require(result_ != Result.HIDDEN, "Error: Result can not be 0");

        //Terminate the game when there isn't any people bet on counterpart
        if (
            games[gameId_].pools[Result.RIGHT].totalBettingAmount +
                games[gameId_].pools[Result.WRONG].totalBettingAmount ==
            games[gameId_]
                .pools[games[gameId_].creatorInitResult]
                .totalBettingAmount
        ) {
            games[gameId_].status = GameStatus.TERMINATE;
            emit TerminateGame(gameId_);
            return;
        }

        games[gameId_].status = GameStatus.REPORT_PERIOD;
        games[gameId_].reportTimeEnd = block.timestamp + _REPORT_CUT_OFF_TIME;

        games[gameId_].result = result_;

        emit FinalizeGame(gameId_, result_);

        if (operators[msg.sender]) // Penalize if host doesn't reveal the result
        {
            // Mark that host of this game was be penalized
            games[gameId_].penalty = true;

            //allow claim
            games[gameId_].status = GameStatus.CLOSE;

            emit AllowClaim(gameId_, games[gameId_].result);
        }
    }

    function penalty(uint256 gameId_) private returns (uint256) {
        address host = games[gameId_].creator;
        uint256 totalPenalty;
        //calculate penalty

        totalPenalty =
            (games[gameId_]
                .pools[games[gameId_].creatorInitResult]
                .playerBettingInfo[host]
                .bettingAmount * _NOT_REVEAL_RESULT_PENALTY_RATE) /
            _RATE_DENOMINATOR;

        if (totalPenalty != 0) {
            // transfer to DAO
            super.transferProtocolFee(
                _DAO,
                totalPenalty,
                _REVENUE,
                0,
                games[gameId_].betToken
            );
            emit Penalty(gameId_, host, totalPenalty);
        }

        return totalPenalty;
    }

    /**
     * @notice This function is used by player who has joined the game to report game result
     * @param gameId_ game id
     */

    function reportGame(uint256 gameId_, Result result_) public {
        require(result_ != Result.HIDDEN, "Error: Result can not be 0");

        require(
            games[gameId_].creator != msg.sender,
            "Error: Host can not report game"
        );

        require(
            games[gameId_].status == GameStatus.REPORT_PERIOD,
            "Error: your game is not in report period!"
        );

        require(
            (games[gameId_]
                .pools[Result.RIGHT]
                .playerBettingInfo[msg.sender]
                .joined == true) ||
                (games[gameId_]
                    .pools[Result.WRONG]
                    .playerBettingInfo[msg.sender]
                    .joined == true),
            "Error: you did not join this game!"
        );

        require(
            games[gameId_].reports.reported[msg.sender] == false,
            "Error: you have reported!"
        );

        games[gameId_].reports.reported[msg.sender] = true;

        //if still in report period
        if (games[gameId_].reportTimeEnd > block.timestamp) {
            games[gameId_].reports.total += 1;

            //store report result
            games[gameId_].reports.playerReports.push(
                PlayerReport(msg.sender, result_)
            );

            emit ReportGame(msg.sender, gameId_, result_);

            uint256 totalPlayer = games[gameId_]
                .pools[Result.WRONG]
                .players
                .length + games[gameId_].pools[Result.RIGHT].players.length;

            if (
                (games[gameId_].reports.total * _RATE_DENOMINATOR) /
                    totalPlayer >=
                _REQUEST_ADMIN_CHECK_RATE
            ) {
                emit RequestAdminCheck(gameId_);
            }
        }
        //else, the report time is end but game's status is still REPORT_PERIOD => winner can not claim their reward => request admin check
        else {
            emit ReportGame(msg.sender, gameId_, result_);
            emit RequestAdminCheck(gameId_);
        }
    }

    /**
     * @notice This function is used by admin to resolve the report
     * @param gameId_ game id
     * @param newResult_ the correct result
     */
    function adminResolveReport(uint256 gameId_, Result newResult_) public {
        require(operators[msg.sender], "Error: you are not admin");

        require(
            games[gameId_].status == GameStatus.REPORT_PERIOD,
            "Error: your game is not in report period!"
        );

        require(newResult_ != Result.HIDDEN, "Error: Result can not be 0");

        games[gameId_].status = GameStatus.CLOSE;

        games[gameId_].result = newResult_;

        emit AdminResolveReport(gameId_, newResult_);
    }

    /**
     * @notice This function is used by admin to allow player claim reward
     * @param gameId_ game id
     */

    function allowClaim(uint256 gameId_) public {
        require(operators[msg.sender], "Error: you are not admin");

        require(
            games[gameId_].status == GameStatus.REPORT_PERIOD,
            "Error: your game is not in report period!"
        );

        require(
            games[gameId_].reportTimeEnd < block.timestamp,
            "Error: Please wait because your game is in report time!"
        );

        games[gameId_].status = GameStatus.CLOSE;

        emit AllowClaim(gameId_, games[gameId_].result);
    }

    /**
     * @notice calculates protocol fee and host commission
     * @param claimAmount_ amount will be claimed
     */
    function computeProtocolFee(
        uint256 claimAmount_
    )
        internal
        view
        returns (uint256 DAOFee, uint256 revenueFee, uint256 hostCommission)
    {
        DAOFee = (claimAmount_ * _DAO_RATE) / _RATE_DENOMINATOR;
        revenueFee = (claimAmount_ * _REVENUE_RATE) / _RATE_DENOMINATOR;
        hostCommission =
            (claimAmount_ * _HOST_COMMISSION_RATE) /
            _RATE_DENOMINATOR;

        // return (DAOFee, revenueFee, hostCommission);
    }

    /**
     * @notice player claim reward by game
     * @param gameId_ game id that player will claim
     */

    function claim(uint256 gameId_) public nonReentrant {
        require(
            games[gameId_].status == GameStatus.CLOSE,
            "Error:Game result is processing"
        );

        // uint256 award;
        uint256 totalLoserBetting;
        uint256 totalWinnerBetting;
        uint256 winnerbettingAmount;
        uint256 claimAmount;
        uint256 totalDAOFee;
        uint256 totalRevenueFee;

        require(
            games[gameId_]
                .pools[games[gameId_].result]
                .playerBettingInfo[msg.sender]
                .joined == true,
            "Error: you didn't join this game or not a winner!"
        );

        require(
            games[gameId_]
                .pools[Result.RIGHT]
                .playerBettingInfo[msg.sender]
                .claimed ==
                false &&
                games[gameId_]
                    .pools[Result.WRONG]
                    .playerBettingInfo[msg.sender]
                    .claimed ==
                false,
            "Error: you have claimed on this game!"
        );

        //mark claimed
        games[gameId_]
            .pools[Result.RIGHT]
            .playerBettingInfo[msg.sender]
            .claimed = true;

        games[gameId_]
            .pools[Result.WRONG]
            .playerBettingInfo[msg.sender]
            .claimed = true;

        totalWinnerBetting = games[gameId_]
            .pools[games[gameId_].result]
            .totalBettingAmount;

        totalLoserBetting =
            games[gameId_].pools[Result.RIGHT].totalBettingAmount +
            games[gameId_].pools[Result.WRONG].totalBettingAmount -
            totalWinnerBetting;

        winnerbettingAmount = games[gameId_]
            .pools[games[gameId_].result]
            .playerBettingInfo[msg.sender]
            .bettingAmount;

        //winner award and fee calculate
        {
            (
                uint256 winnerAward,
                uint256 winnerDAOFee,
                uint256 winnerRevenueFee,
                uint256 hostCommission
            ) = winnerClaimCalculate(
                    totalWinnerBetting,
                    totalLoserBetting,
                    winnerbettingAmount
                );

            {
                //transfer host commission
                super.transferHostCommission(
                    games[gameId_].creator,
                    hostCommission,
                    games[gameId_].betToken
                );
                emit HostCommission(msg.sender, gameId_, hostCommission);
            }

            {
                uint256 winnerTotalFee = winnerDAOFee +
                    winnerRevenueFee +
                    hostCommission;
                //DAO fee
                totalDAOFee += winnerDAOFee;
                //revenue fee
                totalRevenueFee += winnerRevenueFee;
                //total claim amount
                claimAmount +=
                    winnerbettingAmount +
                    winnerAward -
                    winnerTotalFee;
            }
        }

        //calculate host penalty amount
        if (
            msg.sender == games[gameId_].creator && //game creator claim
            games[gameId_].creatorInitResult == games[gameId_].result && //host pool is winner
            games[gameId_].penalty //host get penalty
        ) {
            uint256 penaltyAmount = penalty(gameId_);
            claimAmount -= penaltyAmount;
        }
        // transfer protocol fee
        super.transferProtocolFee(
            _DAO,
            totalDAOFee,
            _REVENUE,
            totalRevenueFee,
            games[gameId_].betToken
        );

        // //claim
        super.withdraw(claimAmount, games[gameId_].betToken);

        emit ChargeProtocolFee(
            msg.sender,
            gameId_,
            totalDAOFee,
            totalRevenueFee
        );
        emit Claim(msg.sender, gameId_, claimAmount);
    }

    function winnerClaimCalculate(
        uint256 totalWinnerBetting_,
        uint256 totalLoserBetting_,
        uint256 winnerbettingAmount_
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 award;
        uint256 DAOFee;
        uint256 revenueFee;
        uint256 hostCommission;
        //calculate winner award
        award =
            (totalLoserBetting_ * winnerbettingAmount_) /
            totalWinnerBetting_;

        (DAOFee, revenueFee, hostCommission) = computeProtocolFee(award);

        return (award, DAOFee, revenueFee, hostCommission);
    }

    /**
     * @notice player claims all reward by list of game ids
     * @param gameIds_ list of game ids that player will claim
     */
    function claimAll(uint256[] memory gameIds_) public {
        uint256 length = gameIds_.length;

        for (uint256 index = 0; index < length; index++) {
            claim(gameIds_[index]);
        }
    }

    /**
     * @notice player claims all refund of terminate games by list of game ids
     * @param gameIds_ list of game ids that player will claim
     */
    function claimAllRefundTeminateGames(uint256[] memory gameIds_) public {
        uint256 length = gameIds_.length;

        for (uint256 index = 0; index < length; index++) {
            getRefundTerminateGame(gameIds_[index]);
        }
    }

    /**
     * @notice admin terminates the game before this game is closed
     * @param gameId_ game id that admin will terminate
     */

    function terminateGame(uint256 gameId_) public {
        require(operators[msg.sender], "Error: you are not admin");

        require(
            games[gameId_].status != GameStatus.CLOSE,
            "Error: you can not terminate a closed game"
        );

        games[gameId_].status = GameStatus.TERMINATE;
        emit TerminateGame(gameId_);
    }

    /**
     * @notice player gets refund from terminated game
     * @param gameId_ game id that player will get refund
     */
    function getRefundTerminateGame(uint256 gameId_) public {
        require(
            games[gameId_].status == GameStatus.TERMINATE,
            "Error: your game is not terminated!"
        );

        require(
            games[gameId_]
                .pools[Result.RIGHT]
                .playerBettingInfo[msg.sender]
                .claimed ==
                false &&
                games[gameId_]
                    .pools[Result.WRONG]
                    .playerBettingInfo[msg.sender]
                    .claimed ==
                false,
            "Error: You have gotten the refund on this game!"
        );

        games[gameId_]
            .pools[Result.RIGHT]
            .playerBettingInfo[msg.sender]
            .claimed = true;

        games[gameId_]
            .pools[Result.WRONG]
            .playerBettingInfo[msg.sender]
            .claimed = true;

        uint256 refund = games[gameId_]
            .pools[Result.RIGHT]
            .playerBettingInfo[msg.sender]
            .bettingAmount +
            games[gameId_]
                .pools[Result.WRONG]
                .playerBettingInfo[msg.sender]
                .bettingAmount;

        super.withdraw(refund, games[gameId_].betToken);

        emit GetRefund(gameId_, msg.sender, refund);
    }
}