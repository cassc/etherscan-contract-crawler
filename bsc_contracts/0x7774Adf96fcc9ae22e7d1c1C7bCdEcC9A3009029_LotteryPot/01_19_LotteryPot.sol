// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import '../interfaces/IMarketplace.sol';
import '../interfaces/enums/TokenType.sol';
import '../interfaces/enums/Network.sol';
import '../interfaces/enums/Environment.sol';
import '../interfaces/IMagics.sol';
import '../Recoverable.sol';
import '../Literals.sol';

contract LotteryPot is AccessControl, Recoverable, Literals {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Statistics {
        Winner firstWinner;
        Winner secondWinner;
        Winner thirdWinner;
        uint256 totalUniqueParticipants;
        address[] ticketHolderAddresses;
        uint256 totalCollection;
        uint256 totalTicketsPurchased;
        uint256 ticketsWonByMint;
        bool hasFinalized;
        bool adminRewardsWereClaimed;
    }

    struct User {
        uint256 totalTicketsOwned;
        bool hasParticipated;
    }

    struct Winner {
        address userAddress;
        bool hasClaimed;
        bool hasClaimedTheFixedReward;
    }

    mapping(uint256 => mapping(TokenType => Statistics)) private _statistics;
    mapping(uint256 => mapping(address => mapping(TokenType => User)))
        private _user;
    mapping(uint256 => bool) private _theWeekIsValid;

    Network private immutable _network;

    bytes32 public constant NFT_CONTRACT = keccak256('NFT_CONTRACT');

    mapping(TokenType => uint256) public ticketPriceForCurrency;

    mapping(uint256 => mapping(TokenType => uint256)) private _fixedRewardForRank;

    Environment private _env;

    uint256 private _randomSeed;
    uint256 private _oneWeek;
    uint256 private _sixMonths;

    uint8 private constant _FIRST_PRIZE_SHARE = 40;
    uint8 private constant _SECOND_PRIZE_SHARE = 30;
    uint8 private constant _THIRD_PRIZE_SHARE = 20;
    uint8 private constant _ADMIN_SHARE = 10;

    IERC20 private immutable _ayraToken;
    IERC20 private immutable _ithdToken;

    address private _nftContract;
    address private _nftHashContract;
    address private _marketplace;

    uint256 public currentWeek;

    event TicketPurchased(
        address indexed user,
        uint256 indexed week,
        TokenType tokenType,
        uint256 count
    );

    event LotteryFinalized(
        uint256 week,
        TokenType tokenType,
        address firstWinner,
        address secondWinner,
        address thirdWinner
    );

    event LotteryRewardsClaimed(
        address indexed user,
        uint256 indexed week,
        TokenType tokenType,
        uint8 forRank
    );

    event LotteryAdminRewardsClaimed(
        address admin,
        uint256 indexed week,
        TokenType tokenType
    );

    event FixedRewardsWithdrawn(
        uint256 indexed week,
        address indexed userAddress,
        uint256 rank,
        TokenType tokenType
    );

    event UnclaimedRewardsWithdrawn(
        address admin,
        uint256 indexed week,
        TokenType tokenType
    );

    modifier onlyMarketplaceOwner() {
        require(
            _msgSender() == IMarketplace(_marketplace).owner(),
            'Unauthorized!'
        );
        _;
    }

    modifier onlyBridgeAdmin() {
        require(
            _msgSender() == IMarketplace(_marketplace).bridgeAdmin(),
            'Unauthorized!'
        );
        _;
    }

    constructor(
        Network network,
        Environment env,
        IERC20 ayraToken,
        IERC20 ithdToken,
        uint256 _currentWeek,
        address nftContract,
        address nftHashContract,
        address marketplace
    ) {
        _network = network;
        _env = env;

        if (_network == Network.Binance) {
            ticketPriceForCurrency[TokenType.Native] = 0.0015 ether;
            ticketPriceForCurrency[TokenType.AYRA] = 8 ether;
            ticketPriceForCurrency[TokenType.ITHD] = 10 ether;
        } else if (_network == Network.Polygon) {
            ticketPriceForCurrency[TokenType.Native] = _env ==
                Environment.Development
                ? 0.0065 ether
                : 0.65 ether;
        }

        if (_env == Environment.Development) {
            _oneWeek = 40 minutes;
            _sixMonths = 120 minutes;
        } else {
            _oneWeek = 7 days;
            _sixMonths = 6 * (30 days);
        }

        _ayraToken = ayraToken;
        _ithdToken = ithdToken;

        _nftContract = nftContract;
        _nftHashContract = nftHashContract;
        _marketplace = marketplace;

        // Should set the current week as the same on both networks
        // Else if they are destined be different, manage the same on the front-end
        if (_currentWeek != _ZERO) {
            currentWeek = _currentWeek;
        } else {
            currentWeek = block.timestamp;
        }

        _updateWeek();

        _grantRole(NFT_CONTRACT, _nftContract);
        _grantRole(NFT_CONTRACT, _nftHashContract);

        if (_env == Environment.Development) {
            _fixedRewardForRank[_ONE][TokenType.AYRA] = 60 ether;
            _fixedRewardForRank[_ONE][TokenType.ITHD] = 8 ether;

            _fixedRewardForRank[_TWO][TokenType.AYRA] = 35 ether;
            _fixedRewardForRank[_TWO][TokenType.ITHD] = 4 ether;

            _fixedRewardForRank[_THREE][TokenType.AYRA] = 20 ether;
            _fixedRewardForRank[_THREE][TokenType.ITHD] = 1.5 ether;
        } else {
            _fixedRewardForRank[_ONE][TokenType.AYRA] = 6000 ether;
            _fixedRewardForRank[_ONE][TokenType.ITHD] = 800 ether;

            _fixedRewardForRank[_TWO][TokenType.AYRA] = 3500 ether;
            _fixedRewardForRank[_TWO][TokenType.ITHD] = 400 ether;

            _fixedRewardForRank[_THREE][TokenType.AYRA] = 2000 ether;
            _fixedRewardForRank[_THREE][TokenType.ITHD] = 150 ether;
        }
    }

    receive() external payable {}

    function changeTicketPrice(
        TokenType tokenType,
        uint256 newPrice
    ) external onlyMarketplaceOwner {
        ticketPriceForCurrency[tokenType] = newPrice;
    }

    function setFixedRewardsForRank(
        uint256 rank,
        TokenType tokenType,
        uint256 amount
    ) external onlyMarketplaceOwner {
        _fixedRewardForRank[rank][tokenType] = amount;
    }

    function changeMarketplaceContract(
        address newAddress
    ) external onlyMarketplaceOwner {
        _marketplace = newAddress;
    }

    function changeNftContract(
        address newAddress
    ) external onlyMarketplaceOwner {
        _revokeRole(NFT_CONTRACT, _nftContract);
        _nftContract = newAddress;
        _grantRole(NFT_CONTRACT, _nftContract);
    }

    function changeNftHashContract(
        address newAddress
    ) external onlyMarketplaceOwner {
        _revokeRole(NFT_CONTRACT, _nftHashContract);
        _nftHashContract = newAddress;
        _grantRole(NFT_CONTRACT, _nftHashContract);
    }

    function noteCollection(
        TokenType tokenType,
        uint256 takenLotteryFee
    ) external onlyRole(NFT_CONTRACT) {
        if (_shouldUpdateWeek()) _updateWeek();

        Statistics storage statistics = _statistics[currentWeek][tokenType];

        statistics.totalCollection = statistics.totalCollection.add(
            takenLotteryFee
        );
    }

    function purchaseTickets(
        address userAddress,
        TokenType tokenType,
        uint256 count
    ) external payable {
        if (_shouldUpdateWeek()) _updateWeek();

        require(count <= _TWENTY, 'Cannot purchase more than twenty tickets');

        if (_network == Network.Polygon) {
            require(
                tokenType == TokenType.Native,
                'Invalid token type for this network!'
            );
        }

        uint256 amountToCollect = ticketPriceForCurrency[tokenType].mul(count);

        if (!hasRole(NFT_CONTRACT, _msgSender())) {
            require(
                userAddress == _msgSender(),
                'Cannot purchase tickets for someone else'
            );

            _takeFundsFromUser(tokenType, userAddress, amountToCollect);
        }

        Statistics storage statistics = _statistics[currentWeek][tokenType];
        User storage user = _user[currentWeek][userAddress][tokenType];

        if (!user.hasParticipated) {
            user.hasParticipated = true;
            statistics.totalUniqueParticipants = statistics
                .totalUniqueParticipants
                .add(_ONE);
        }

        user.totalTicketsOwned = user.totalTicketsOwned.add(count);

        for (uint256 i = _ZERO; i < count; i++) {
            statistics.ticketHolderAddresses.push(userAddress);
        }

        if (hasRole(NFT_CONTRACT, _msgSender())) {
            statistics.ticketsWonByMint = statistics.ticketsWonByMint.add(
                count
            );
        } else {
            statistics.totalTicketsPurchased = statistics
                .totalTicketsPurchased
                .add(count);

            statistics.totalCollection = statistics.totalCollection.add(
                amountToCollect
            );
        }

        _updateSeed(userAddress);

        emit TicketPurchased(userAddress, currentWeek, tokenType, count);
    }

    function claimLotteryRewards(
        uint256 week,
        TokenType tokenType,
        uint8 forRank
    ) external {
        Statistics storage statistics = _statistics[week][tokenType];

        require(statistics.hasFinalized, 'Statistics has not finalized!');

        address userAddress = _msgSender();

        _checkRankClaim(week, tokenType, forRank, userAddress);

        if (_sixMonthsHavePassedFor(week)) {
            revert('cannot withdraw rewards older than 6 months');
        }

        require(
            statistics.totalCollection > _ZERO,
            'There has been no collection in this duration'
        );

        uint256 prizeAmount = _getPrizeAmountForRank(week, tokenType, forRank);

        _transferAmountToUser(tokenType, userAddress, prizeAmount);

        emit LotteryRewardsClaimed(userAddress, week, tokenType, forRank);

        _claimLotteryAdminRewards(week, tokenType);
    }

    function withdrawUnclaimedRewards(
        uint256 week,
        TokenType tokenType
    ) external onlyMarketplaceOwner {
        require(
            _sixMonthsHavePassedFor(week),
            'can only withdraw rewards older than 6 months'
        );

        Statistics memory statistics = _statistics[week][tokenType];

        address adminAddress = IMarketplace(_marketplace).owner();

        require(
            statistics.firstWinner.userAddress != _ZERO_ADDRESS &&
                statistics.secondWinner.userAddress != _ZERO_ADDRESS &&
                statistics.thirdWinner.userAddress != _ZERO_ADDRESS,
            'No winners in this week'
        );

        bool wasClaimed;

        if (!statistics.firstWinner.hasClaimed) {
            statistics.firstWinner.hasClaimed = true;

            uint256 prizeAmount = _getPrizeAmountForRank(week, tokenType, _ONE);

            _transferAmountToUser(tokenType, adminAddress, prizeAmount);

            wasClaimed = true;
        }

        if (!statistics.secondWinner.hasClaimed) {
            statistics.secondWinner.hasClaimed = true;

            uint256 prizeAmount = _getPrizeAmountForRank(week, tokenType, _TWO);

            _transferAmountToUser(tokenType, adminAddress, prizeAmount);

            wasClaimed = true;
        }

        if (!statistics.thirdWinner.hasClaimed) {
            statistics.thirdWinner.hasClaimed = true;

            uint256 prizeAmount = _getPrizeAmountForRank(
                week,
                tokenType,
                _THREE
            );

            _transferAmountToUser(tokenType, adminAddress, prizeAmount);

            wasClaimed = true;
        }

        if (wasClaimed) {
            emit UnclaimedRewardsWithdrawn(adminAddress, week, tokenType);
        }
    }

    function claimLotteryAdminRewards(
        uint256 week,
        TokenType tokenType
    ) external onlyMarketplaceOwner {
        _claimLotteryAdminRewards(week, tokenType);
    }

    /**
     * @dev The bridge admin should check if the user is eligible for fixed rewards
     * by calling this function on Polygon, every time the coupled
     * transactions are called.
     * No reenterancy should be tolerated in the bridge.
     */
    function withdrawFixedReward(
        uint256 week,
        address userAddress,
        uint8 rank, // We depend on the bridge to explicitly provide the rank on Binance network
        TokenType tokenType
    ) external {
        require(_msgSender() == _marketplace, 'Unauthorized!');
        // && only the bridge admin, authorize using marketplace contract

        if (_sixMonthsHavePassedFor(week)) {
            revert('cannot withdraw rewards older than 6 months');
        }

        if (_network == Network.Polygon) {
            _consumeRankClaimFor(week, tokenType, rank, userAddress);
        } else {
            // Trust the `rank` input
            uint256 fixedRewardInAYRA = _fixedRewardForRank[rank][
                TokenType.AYRA
            ];

            _transferAmountToUser(
                TokenType.AYRA,
                userAddress,
                fixedRewardInAYRA
            );

            uint256 fixedRewardInITHD = _fixedRewardForRank[rank][
                TokenType.ITHD
            ];

            _transferAmountToUser(
                TokenType.ITHD,
                userAddress,
                fixedRewardInITHD
            );
        }

        emit FixedRewardsWithdrawn(week, userAddress, rank, tokenType);
    }

    function finalizeLottery(
        uint256 week,
        TokenType tokenType
    ) external onlyBridgeAdmin {
        _finalizeLottery(week, tokenType);
    }

    function recoverFunds(
        address token,
        address to,
        uint256 amount
    ) external onlyMarketplaceOwner {
        _recoverFunds(token, to, amount);
    }

    function getStatisticsForAllCurrencies(
        uint256 week
    ) external view returns (Statistics[] memory) {
        if (_network == Network.Binance) {
            Statistics[] memory tempStatistics = new Statistics[](_THREE);

            tempStatistics[uint8(TokenType.Native)] = getStatistics(
                week,
                TokenType.Native
            );
            tempStatistics[uint8(TokenType.AYRA)] = getStatistics(
                week,
                TokenType.AYRA
            );
            tempStatistics[uint8(TokenType.ITHD)] = getStatistics(
                week,
                TokenType.ITHD
            );

            return tempStatistics;
        } else {
            Statistics[] memory tempStatistics = new Statistics[](_ONE);

            tempStatistics[uint8(TokenType.Native)] = getStatistics(
                week,
                TokenType.Native
            );

            return tempStatistics;
        }
    }

    function getMarketplaceContract() external view returns (address) {
        return _marketplace;
    }

    function getNftContract() external view returns (address) {
        return _nftContract;
    }

    function getNftHashContract() external view returns (address) {
        return _nftHashContract;
    }

    function getMyUnclaimedWinningsCount(
        uint256 week,
        address userAddress
    ) external view returns (uint256) {
        uint256 unclaimedWinnings;

        Statistics memory statsNative = _statistics[week][TokenType.Native];

        if (
            statsNative.firstWinner.userAddress == userAddress &&
            !statsNative.firstWinner.hasClaimed
        ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

        if (
            statsNative.secondWinner.userAddress == userAddress &&
            !statsNative.secondWinner.hasClaimed
        ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

        if (
            statsNative.thirdWinner.userAddress == userAddress &&
            !statsNative.thirdWinner.hasClaimed
        ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

        if (_network == Network.Binance) {
            Statistics memory statsAYRA = _statistics[week][TokenType.AYRA];

            if (
                statsAYRA.firstWinner.userAddress == userAddress &&
                !statsAYRA.firstWinner.hasClaimed
            ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

            if (
                statsAYRA.secondWinner.userAddress == userAddress &&
                !statsAYRA.secondWinner.hasClaimed
            ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

            if (
                statsAYRA.thirdWinner.userAddress == userAddress &&
                !statsAYRA.thirdWinner.hasClaimed
            ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

            Statistics memory statsITHD = _statistics[week][TokenType.ITHD];

            if (
                statsITHD.firstWinner.userAddress == userAddress &&
                !statsITHD.firstWinner.hasClaimed
            ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

            if (
                statsITHD.secondWinner.userAddress == userAddress &&
                !statsITHD.secondWinner.hasClaimed
            ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

            if (
                statsITHD.thirdWinner.userAddress == userAddress &&
                !statsITHD.thirdWinner.hasClaimed
            ) unclaimedWinnings = unclaimedWinnings.add(_ONE);

            return unclaimedWinnings;
        } else {
            return unclaimedWinnings;
        }
    }

    function getUserStatisticsForAllCurrencies(
        uint256 week,
        address userAddress
    ) external view returns (User[] memory) {
        if (_network == Network.Binance) {
            User[] memory tempUser = new User[](_THREE);

            tempUser[uint8(TokenType.Native)] = getUserStatistics(
                week,
                userAddress,
                TokenType.Native
            );

            tempUser[uint8(TokenType.AYRA)] = getUserStatistics(
                week,
                userAddress,
                TokenType.AYRA
            );

            tempUser[uint8(TokenType.ITHD)] = getUserStatistics(
                week,
                userAddress,
                TokenType.ITHD
            );

            return tempUser;
        } else {
            User[] memory tempUser = new User[](_ONE);

            tempUser[uint8(TokenType.Native)] = getUserStatistics(
                week,
                userAddress,
                TokenType.Native
            );

            return tempUser;
        }
    }

    function getAllTicketPrices() external view returns (uint256[] memory) {
        if (_network == Network.Binance) {
            uint256[] memory tempPrices = new uint256[](_THREE);

            tempPrices[uint8(TokenType.Native)] = ticketPriceForCurrency[
                TokenType.Native
            ];

            tempPrices[uint8(TokenType.AYRA)] = ticketPriceForCurrency[
                TokenType.AYRA
            ];

            tempPrices[uint8(TokenType.ITHD)] = ticketPriceForCurrency[
                TokenType.ITHD
            ];

            return tempPrices;
        } else {
            uint256[] memory tempPrices = new uint256[](_ONE);

            tempPrices[uint8(TokenType.Native)] = ticketPriceForCurrency[
                TokenType.Native
            ];

            return tempPrices;
        }
    }

    function getUserStatistics(
        uint256 week,
        address userAddress,
        TokenType tokenType
    ) public view returns (User memory) {
        return _user[week][userAddress][tokenType];
    }

    function getStatistics(
        uint256 week,
        TokenType tokenType
    ) public view returns (Statistics memory) {
        Statistics memory tempStats = _statistics[week][tokenType];

        if (tempStats.ticketHolderAddresses.length > 10) {
            tempStats.ticketHolderAddresses = new address[](_ZERO);
        }

        return tempStats;
    }

    function _updateWeek() private {
        uint256 timeDiff = block.timestamp.sub(currentWeek);

        if (timeDiff > _oneWeek) {
            uint256 weeksPassed = timeDiff.div(_oneWeek);

            currentWeek = currentWeek.add(weeksPassed.mul(_oneWeek));
        } else {
            currentWeek = currentWeek.add(_oneWeek);
        }

        _theWeekIsValid[currentWeek] = true;
    }

    /**
     * @dev Also updates the `hasClaimed` flag if needed.
     */
    function _checkRankClaim(
        uint256 week,
        TokenType tokenType,
        uint8 forRank,
        address userAddress
    ) private {
        string
            memory notWonInThisPosition = 'You have not won in this position';
        string memory alreadyClaimed = 'You have already claimed these rewards';

        Statistics storage statistics = _statistics[week][tokenType];

        if (forRank == _ONE) {
            require(
                statistics.firstWinner.userAddress == userAddress,
                notWonInThisPosition
            );

            require(!statistics.firstWinner.hasClaimed, alreadyClaimed);

            statistics.firstWinner.hasClaimed = true;
        } else if (forRank == _TWO) {
            require(
                statistics.secondWinner.userAddress == userAddress,
                notWonInThisPosition
            );

            require(!statistics.secondWinner.hasClaimed, alreadyClaimed);

            statistics.secondWinner.hasClaimed = true;
        } else if (forRank == _THREE) {
            require(
                statistics.thirdWinner.userAddress == userAddress,
                notWonInThisPosition
            );
            require(!statistics.thirdWinner.hasClaimed, alreadyClaimed);

            statistics.thirdWinner.hasClaimed = true;
        } else {
            revert('Invalid rank!');
        }
    }

    /**
     * @dev Also updates the `hasClaimedTheFixedReward` flag if needed.
     */
    function _consumeRankClaimFor(
        uint256 week,
        TokenType tokenType,
        uint8 forRank,
        address userAddress
    ) private {
        string
            memory notWonInThisPosition = 'You have not won in this position';
        string memory alreadyClaimed = 'You have already claimed these rewards';

        Statistics storage statistics = _statistics[week][tokenType];

        if (forRank == _ONE) {
            require(
                statistics.firstWinner.userAddress == userAddress,
                notWonInThisPosition
            );

            require(
                !statistics.firstWinner.hasClaimedTheFixedReward,
                alreadyClaimed
            );

            statistics.firstWinner.hasClaimedTheFixedReward = true;
        } else if (forRank == _TWO) {
            require(
                statistics.secondWinner.userAddress == userAddress,
                notWonInThisPosition
            );

            require(
                !statistics.secondWinner.hasClaimedTheFixedReward,
                alreadyClaimed
            );

            statistics.secondWinner.hasClaimedTheFixedReward = true;
        } else if (forRank == _THREE) {
            require(
                statistics.thirdWinner.userAddress == userAddress,
                notWonInThisPosition
            );
            require(
                !statistics.thirdWinner.hasClaimedTheFixedReward,
                alreadyClaimed
            );

            statistics.thirdWinner.hasClaimedTheFixedReward = true;
        } else {
            revert('Invalid rank!');
        }
    }

    function _finalizeLottery(uint256 week, TokenType tokenType) private {
        Statistics storage statistics = _statistics[week][tokenType];

        require(_theWeekIsValid[week], 'Week is not valid');

        uint256 currentTime = block.timestamp;

        require(week < currentTime, 'Cannot finalise future lotteries');
        require(
            !statistics.hasFinalized,
            'Lottery already finalized for this week/currency'
        );
        require(
            _oneWeekHasPassedFor(week),
            'Ticket purchasing duration has not ended yet'
        );
        require(
            statistics.totalCollection > _ZERO,
            'There has been no collection in this duration'
        );

        statistics.hasFinalized = true;

        uint256 terminalIndex = statistics
            .totalTicketsPurchased
            .add(statistics.ticketsWonByMint)
            .sub(_ONE);

        address firstWinnerAddress = statistics.ticketHolderAddresses[
            _random(terminalIndex)
        ];

        address secondWinnerAddress = statistics.ticketHolderAddresses[
            _random(terminalIndex)
        ];

        address thirdWinnerAddress = statistics.ticketHolderAddresses[
            _random(terminalIndex)
        ];

        statistics.firstWinner.userAddress = firstWinnerAddress;
        statistics.secondWinner.userAddress = secondWinnerAddress;
        statistics.thirdWinner.userAddress = thirdWinnerAddress;

        emit LotteryFinalized(
            week,
            tokenType,
            firstWinnerAddress,
            secondWinnerAddress,
            thirdWinnerAddress
        );
    }

    function _claimLotteryAdminRewards(
        uint256 week,
        TokenType tokenType
    ) private {
        address adminAddress = IMarketplace(_marketplace).owner();

        Statistics storage statistics = _statistics[week][tokenType];

        require(_theWeekIsValid[week], 'Week is not valid');
        require(statistics.hasFinalized, 'Lottery not yet finalized');

        if (!statistics.adminRewardsWereClaimed) {
            statistics.adminRewardsWereClaimed = true;

            uint256 prizeAmount = statistics
                .totalCollection
                .mul(_ADMIN_SHARE)
                .div(_ONE_HUNDRED);

            _transferAmountToUser(tokenType, adminAddress, prizeAmount);

            emit LotteryAdminRewardsClaimed(adminAddress, week, tokenType);
        }
    }

    function _takeFundsFromUser(
        TokenType tokenType,
        address userAddress,
        uint256 amount
    ) private {
        if (tokenType == TokenType.Native) {
            require(msg.value >= amount, _INSUFFICIENT_VALUE);
        } else if (tokenType == TokenType.AYRA) {
            _ayraToken.safeTransferFrom(userAddress, address(this), amount);
        } else if (tokenType == TokenType.ITHD) {
            _ithdToken.safeTransferFrom(userAddress, address(this), amount);
        }
    }

    function _transferAmountToUser(
        TokenType tokenType,
        address userAddress,
        uint256 amount
    ) private {
        if (amount == _ZERO) return;

        if (tokenType == TokenType.Native) {
            payable(userAddress).transfer(amount);
        } else {
            require(
                _network == Network.Binance,
                '_transferAmountToUser: Call in wrong context'
            );

            if (tokenType == TokenType.AYRA) {
                _ayraToken.safeTransfer(userAddress, amount);
            } else if (tokenType == TokenType.ITHD) {
                _ithdToken.safeTransfer(userAddress, amount);
            }
        }
    }

    /**
     * @dev returns a random number from zero to `to`.
     */
    function _random(uint256 to) private returns (uint256) {
        _randomSeed = uint256(
            keccak256(
                abi.encodePacked(
                    uint160(msg.sender) +
                        block.timestamp +
                        block.difficulty +
                        _randomSeed /
                        _THREE
                )
            )
        );

        return _randomSeed % (to + _ONE);
    }

    /**
     * @dev We would update the `_randomSeed` with every purchase transaction. The randomness gets
     * better on every purchase
     */
    function _updateSeed(address userAddress) private {
        _randomSeed = uint256(
            keccak256(
                abi.encodePacked(uint160(userAddress) + _randomSeed / _THREE)
            )
        );
    }

    function _getPrizeAmountForRank(
        uint256 week,
        TokenType tokenType,
        uint8 rank
    ) private view returns (uint256) {
        Statistics storage statistics = _statistics[week][tokenType];

        uint256 prizeAmount;

        if (rank == _ONE) {
            prizeAmount = statistics
                .totalCollection
                .mul(_FIRST_PRIZE_SHARE)
                .div(_ONE_HUNDRED);
        } else if (rank == _TWO) {
            prizeAmount = statistics
                .totalCollection
                .mul(_SECOND_PRIZE_SHARE)
                .div(_ONE_HUNDRED);
        } else if (rank == _THREE) {
            prizeAmount = statistics
                .totalCollection
                .mul(_THIRD_PRIZE_SHARE)
                .div(_ONE_HUNDRED);
        } else {
            revert('Invalid rank');
        }

        return prizeAmount;
    }

    function _shouldUpdateWeek() private view returns (bool) {
        uint256 currentTime = block.timestamp;

        return currentTime.sub(currentWeek) > _oneWeek;
    }

    function _sixMonthsHavePassedFor(uint256 week) private view returns (bool) {
        uint256 weeksEndTime = week.add(_oneWeek);
        uint256 currentTime = block.timestamp;

        return
            weeksEndTime < currentTime &&
            currentTime.sub(weeksEndTime) > _sixMonths;
    }

    function _oneWeekHasPassedFor(uint256 week) private view returns (bool) {
        uint256 currentTime = block.timestamp;

        return currentTime.sub(week) > _oneWeek;
    }
}