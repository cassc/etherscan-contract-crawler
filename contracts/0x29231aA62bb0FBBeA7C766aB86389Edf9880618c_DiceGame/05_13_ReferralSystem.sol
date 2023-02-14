// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ReferralSystem is OwnableUpgradeable {
    uint16 public constant MAX_TOKENS_AMOUNT = 130;

    address[] public influencerWallets;
    mapping(address => InfluencerData) public influencerData;
    mapping(address => Payout[]) public historicalPayoutsByInfluencer;
    mapping(address => address) private userReferredBy; // What influencer referred this user
    mapping(address => uint256) public totalPaidToInfluencersByToken; // All the influencers
    mapping(address => uint256) public totalUnpaidToInfluencersByToken; // All the influencers
    mapping(address => address) public tokenToUsdPriceFeed;
    address[] public addedTokens;
    uint256 public withdrawalWaitingPeriod;

    // Read about gaps before adding new variables below:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
    uint256[50] private __gap;

    struct InfluencerData {
        address wallet;
        bool isEnabled;
        uint256 percentage;
        address[] referrals;
        uint256 nextWithdrawalDate;
        mapping(address => uint256) totalBetsByToken;
        mapping(address => uint256) totalUserWinsByToken;
        mapping(address => uint256) totalUserLossesByToken;
        mapping(address => uint256) totalUserRefundsByToken;
        mapping(address => int256) totalInfluencerProfit; // can be negative, calculated with amount * %
        mapping(address => int256) totalCasinoProfit; // can be negative, calculated with amount * %
        mapping(address => uint256) totalPayouts;
    }

    struct Payout {
        address influencer;
        address token;
        uint256 paymentAmount;
        uint256 datetime;
        uint256 totalPayouts;
    }

    struct InfluencerProfitCalculationData {
        uint256 tokensLength;
        int256 total;
        uint256 counter;
        address usdPriceFeed;
        address currentToken;
        uint8 decimals;
        int256 tokenAmount;
        uint256 paymentTotal;
    }

    function __ReferralSystem_init(uint256 withdrawalWaitingPeriod_) internal {
        __Ownable_init();
        withdrawalWaitingPeriod = withdrawalWaitingPeriod_;
    }

    function updateTotalUserLosses(
        uint256 betAmount,
        address token,
        address influencer
    ) internal {
        // The user lost the game, increase user losses of influencer
        // Increase profit of influencer and casino

        influencerData[influencer].totalUserLossesByToken[token] += betAmount;

        // ====== Updating influencer profits ======
        uint256 influencerAmount = calculateInfluencerProfit(
            betAmount,
            influencer
        );
        int256 influencerProfitBefore = influencerData[influencer]
            .totalInfluencerProfit[token];
        influencerData[influencer].totalInfluencerProfit[token] += int256(
            influencerAmount
        );
        int256 influencerProfitAfter = influencerProfitBefore +
            int256(influencerAmount);
        updateTotalUnpaidInfluencers(
            influencerProfitBefore,
            influencerProfitAfter,
            token
        );
        // ====== Updating casino profits ======
        uint256 casinoAmount = betAmount - influencerAmount;
        influencerData[influencer].totalCasinoProfit[token] += int256(
            casinoAmount
        );
    }

    function updateTotalUserRefunds(
        uint256 betAmount,
        address token,
        address influencer
    ) internal {
        // if (influencer == address(0)) return;
        // A refund ocurred, store it as refund if there is an influencer
        influencerData[influencer].totalUserRefundsByToken[token] += betAmount;
    }

    function updateTotalUserWins(
        uint256 prizeAmount,
        uint256 betAmount,
        address token,
        address influencer
    ) internal {
        // Sucessful win payment, increase user wins of influencer
        // Decrease profit of influencer and casino
        uint256 playProfit = prizeAmount - betAmount;
        influencerData[influencer].totalUserWinsByToken[token] += playProfit;

        // ====== Updating influencer profits ======
        uint256 influencerAmount = calculateInfluencerProfit(
            playProfit,
            influencer
        );
        int256 influencerProfitBefore = influencerData[influencer]
            .totalInfluencerProfit[token];
        influencerData[influencer].totalInfluencerProfit[token] -= int256(
            influencerAmount
        );
        int256 influencerProfitAfter = influencerProfitBefore -
            int256(influencerAmount);
        updateTotalUnpaidInfluencers(
            influencerProfitBefore,
            influencerProfitAfter,
            token
        );
        // ====== Updating casino profits ======
        uint256 casinoAmount = playProfit - influencerAmount;
        influencerData[influencer].totalCasinoProfit[token] -= int256(
            casinoAmount
        );
    }

    // percentage is any number <= 100 multiplied by 1e18
    function addInfluencers(
        address[] calldata influencers,
        uint256[] calldata percentages
    ) external onlyOwner {
        require(
            percentages.length == influencers.length,
            "ReferralSystem: different inputs size"
        );

        for (uint256 i = 0; i < influencers.length; i++) {
            require(
                percentages[i] <= 100 ether,
                "ReferralSystem: percentage is greater than 100%"
            );
            require(
                influencerData[influencers[i]].wallet == address(0),
                "ReferralSystem: influencer previously added"
            );

            // Adding the influencer
            influencerWallets.push(influencers[i]);
            influencerData[influencers[i]].wallet = influencers[i];
            influencerData[influencers[i]].isEnabled = true;
            influencerData[influencers[i]].percentage = percentages[i];
            influencerData[influencers[i]].nextWithdrawalDate =
                block.timestamp +
                withdrawalWaitingPeriod;
        }
    }

    function disableInfluencers(address[] calldata influencers)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < influencers.length; i++) {
            require(
                influencerData[influencers[i]].wallet == influencers[i],
                "ReferralSystem: influencer does not exist"
            );
            require(
                influencerData[influencers[i]].isEnabled == true,
                "ReferralSystem: influencer already disabled"
            );
            influencerData[influencers[i]].isEnabled = false;
        }
    }

    // Time in seconds 1 = 1 second
    function editWithdrawalWaitingPeriod(uint256 newWaitingPeriod)
        external
        onlyOwner
    {
        withdrawalWaitingPeriod = newWaitingPeriod;
    }

    function withdrawInfluencerProfit() external {
        require(
            influencerData[msg.sender].wallet == msg.sender,
            "ReferralSystem: caller is not an influencer"
        );
        bool paymentOccurred;
        require(
            influencerData[msg.sender].nextWithdrawalDate <= block.timestamp,
            "ReferralSystem: waiting period has not finished"
        );

        (
            address[] memory tokens,
            uint256[] memory amounts
        ) = getInfluencerWithdrawableBalances(msg.sender);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (amounts[i] == 0) continue;
            // ========= Updating total paid and unpaid =========
            influencerData[msg.sender].totalInfluencerProfit[
                tokens[i]
            ] -= int256(amounts[i]);
            totalPaidToInfluencersByToken[tokens[i]] += amounts[i];
            totalUnpaidToInfluencersByToken[tokens[i]] -= amounts[i];
            influencerData[msg.sender].totalPayouts[tokens[i]] += amounts[i];
            paymentOccurred = true;
            // ========= Transferring of tokens =========
            if (tokens[i] == address(0)) {
                // Payment in native token
                (bool success, ) = payable(msg.sender).call{value: amounts[i]}(
                    ""
                );
                require(success, "ReferralSystem: Error paying influencer");
            } else {
                // Payment in ERC20 token
                bool success = IERC20Upgradeable(tokens[i]).transfer(
                    influencerData[msg.sender].wallet,
                    amounts[i]
                );
                require(success, "ReferralSystem: Error paying influencer");
            }
            Payout memory payout = Payout(
                msg.sender,
                tokens[i],
                uint256(amounts[i]),
                block.timestamp,
                influencerData[msg.sender].totalPayouts[tokens[i]]
            );
            historicalPayoutsByInfluencer[msg.sender].push(payout);
        }
        // Throw error if the total profit is negative
        require(
            paymentOccurred,
            "ReferralSystem: influencer total profit is negative"
        );

        influencerData[msg.sender].nextWithdrawalDate =
            block.timestamp +
            withdrawalWaitingPeriod;
    }

    // This function calculates the total profit of the influencer in all the tokens converted to USD,
    // If the sum of losses and and wins is positive it will create a list of instructions of tokens and amounts
    // That can be used to pay the equivalent amount to the excess of positive profit in USD.
    // If the total profit in USD is negative the function returns two empty lists
    function getInfluencerWithdrawableBalances(address influencer)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        InfluencerProfitCalculationData memory data;
        data.tokensLength = addedTokens.length;
        address[] memory tokenAddresses = new address[](data.tokensLength);
        int256[] memory tokenAmounts = new int256[](data.tokensLength);
        int256[] memory usdPrices = new int256[](data.tokensLength);

        for (uint256 i = 0; i < data.tokensLength; i++) {
            data.currentToken = addedTokens[i];
            data.usdPriceFeed = tokenToUsdPriceFeed[data.currentToken];
            data.decimals = AggregatorV3Interface(data.usdPriceFeed).decimals();
            (, int256 answer, , , ) = AggregatorV3Interface(data.usdPriceFeed)
                .latestRoundData();

            data.tokenAmount = influencerData[influencer].totalInfluencerProfit[
                data.currentToken
            ];

            int256 usdPrice = (data.tokenAmount * answer) /
                int256(10**data.decimals);

            // Adds to the total
            data.total += usdPrice;
            if (usdPrice > 0) {
                tokenAddresses[data.counter] = data.currentToken;
                tokenAmounts[data.counter] = data.tokenAmount;
                usdPrices[data.counter] = usdPrice;
                data.counter++;
            }
        }
        if (data.total < 0) {
            // The total in USD is less negative
            address[] memory tokensEmpty;
            uint256[] memory amountsEmpty;
            return (tokensEmpty, amountsEmpty);
        }

        address[] memory tokens = new address[](usdPrices.length);
        uint256[] memory amounts = new uint256[](usdPrices.length);
        data.counter = 0; // Resets the counter
        // The total in USD is positive, create transfer intructions
        for (uint256 i = 0; i < usdPrices.length; i++) {
            if (usdPrices[i] <= 0) continue; // Skips the empty ones
            tokens[data.counter] = tokenAddresses[i];

            if (
                uint256(data.total) >=
                (data.paymentTotal + uint256(usdPrices[i]))
            ) {
                amounts[data.counter] = uint256(tokenAmounts[i]);
                if (
                    uint256(data.total) ==
                    (data.paymentTotal + uint256(usdPrices[i]))
                ) {
                    return (tokens, amounts);
                }
                data.paymentTotal += uint256(usdPrices[i]);
            } else {
                uint256 missingAmountUSD = (uint256(data.total) -
                    data.paymentTotal);
                amounts[data.counter] =
                    (((uint256(tokenAmounts[i]) * 1e18) /
                        uint256(usdPrices[i])) * missingAmountUSD) /
                    1e18;
                return (tokens, amounts);
            }
            data.counter++;
        }
        return (tokens, amounts);
    }

    function updateTotalUnpaidInfluencers(
        int256 profitBefore,
        int256 profitAfter,
        address token
    ) internal {
        if (profitBefore > 0)
            totalUnpaidToInfluencersByToken[token] -= uint256(profitBefore);
        if (profitAfter > 0)
            totalUnpaidToInfluencersByToken[token] += uint256(profitAfter);
    }

    function processInfluencerReferral(
        address influencer,
        uint256 betAmount,
        address token
    ) internal {
        (address referredBy, bool isEnabled) = getUserReferredBy(msg.sender);
        if (referredBy == address(0)) {
            // Player without influencer
            if (influencer != address(0)) {
                require(
                    influencerData[influencer].isEnabled,
                    "ReferralSystem: influencer is disabled"
                );
                // Setting the influencer for the first time
                userReferredBy[msg.sender] = influencer;
                influencerData[influencer].referrals.push(msg.sender);
                influencerData[influencer].totalBetsByToken[token] += betAmount;
            }
        } else {
            require(
                referredBy == influencer,
                "ReferralSystem: influencer cannot change"
            );
            if (isEnabled) {
                influencerData[influencer].totalBetsByToken[token] += betAmount;
            }
        }
    }

    /// @notice Allows the owner to enable or disable the allowed tokens to be used in the bets
    /// @dev The owner send an array of tokens and array of statuses make sure both are sorted in the same positions
    /// @param tokens Array of token addresses to modify the status
    /// @param usdPriceFeeds Array of token addresses of the chainlink price feed contract used to get the usd price
    function addAllowedTokens(
        address[] memory tokens,
        address[] memory usdPriceFeeds
    ) external onlyOwner {
        require(
            tokens.length == usdPriceFeeds.length,
            "DiceGame: Different inputs size"
        );

        uint32 addedTokensLength = uint32(addedTokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            addedTokensLength++;
            require(
                addedTokensLength <= MAX_TOKENS_AMOUNT,
                "DiceGame: maximum tokens length exceeded"
            );
            require(
                tokenToUsdPriceFeed[tokens[i]] == address(0),
                "DiceGame: Token already added"
            );
            require(
                usdPriceFeeds[i] != address(0),
                "ReferralSystem: invalid usd price feed"
            );
            // Pushes the new token to the list of added tokens
            // Sets the usdPriceFeed address for the token
            tokenToUsdPriceFeed[tokens[i]] = usdPriceFeeds[i];
            addedTokens.push(tokens[i]);
        }
    }

    function editUsdPriceFeed(
        address[] memory tokens,
        address[] memory usdPriceFeeds
    ) external onlyOwner {
        require(
            tokens.length == usdPriceFeeds.length,
            "DiceGame: Different inputs size"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                tokenToUsdPriceFeed[tokens[i]] != address(0),
                "DiceGame: Token has not been added"
            );
            require(
                usdPriceFeeds[i] != address(0),
                "ReferralSystem: invalid usd price feed"
            );
            tokenToUsdPriceFeed[tokens[i]] = usdPriceFeeds[i];
        }
    }

    function getInfluencers() external view returns (address[] memory) {
        return influencerWallets;
    }

    function getInfluencersLength() external view returns (uint256) {
        return influencerWallets.length;
    }

    function getReferralList(address influencer)
        external
        view
        returns (address[] memory)
    {
        return influencerData[influencer].referrals;
    }

    function getReferralLength(address influencer)
        external
        view
        returns (uint256)
    {
        return influencerData[influencer].referrals.length;
    }

    function getHistoricalPayouts(address influencer)
        external
        view
        returns (Payout[] memory)
    {
        return historicalPayoutsByInfluencer[influencer];
    }

    function getTotalNumbersByInfluencer(address influencer, address token)
        external
        view
        returns (
            uint256 totalBets,
            uint256 totalWins,
            uint256 totalLosses,
            uint256 totalRefunds,
            int256 totalInfluencerProfit,
            int256 totalCasinoProfit,
            uint256 totalPayouts
        )
    {
        totalBets = influencerData[influencer].totalBetsByToken[token];
        totalWins = influencerData[influencer].totalUserWinsByToken[token];
        totalLosses = influencerData[influencer].totalUserLossesByToken[token];
        totalRefunds = influencerData[influencer].totalUserRefundsByToken[
            token
        ];
        totalInfluencerProfit = influencerData[influencer]
            .totalInfluencerProfit[token];
        totalCasinoProfit = influencerData[influencer].totalCasinoProfit[token];
        totalPayouts = influencerData[influencer].totalPayouts[token];
    }

    function calculateInfluencerProfit(uint256 amount, address influencer)
        private
        view
        returns (uint256)
    {
        return (influencerData[influencer].percentage * amount) / 100 ether;
    }

    function getUserReferredBy(address user)
        public
        view
        returns (address influencer, bool isEnabled)
    {
        influencer = userReferredBy[user];
        isEnabled = influencerData[influencer].isEnabled;
    }
}