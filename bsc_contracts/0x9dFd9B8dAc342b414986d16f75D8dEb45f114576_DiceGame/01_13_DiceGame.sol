// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./RandomNumber.sol";
import "./Interfaces/ICalculations.sol";

contract DiceGame is Initializable, RandomNumber {
    address internal linkToNativeTokenPriceFeed;
    uint256 private constant BP = 1e18;
    uint16 public houseEdge; // Minimum winning percentage for the casino
    address payable public feeRecipient;
    uint256 public linkPremium;
    uint256 public maxBetAmount;
    ICalculations public calculations;

    event RequestId(
        uint256 requestId,
        address indexed user,
        uint256 dateTime,
        uint256 amountOfPlays
    );

    function initialize(
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        address linkToken_,
        address payable feeRecepient_,
        uint16 houseEdge_,
        uint256 linkPremium_,
        uint256 maxBetAmount_,
        address linkToNativeTokenPriceFeed_,
        address nativeToUsdPriceFeed,
        uint256 withdrawalWaitingPeriod_,
        address calculations_
    ) public virtual initializer {
        __RandomNumber_init(
            withdrawalWaitingPeriod_,
            subscriptionId_,
            vrfCoordinator_,
            keyHash_,
            linkToken_
        );
        require(
            houseEdge_ >= 100 && houseEdge_ < MAX_NUMBER,
            "DiceGame: Invalid house edge"
        );
        require(feeRecepient_ != address(0), "DiceGame: Invalid fee recipient");
        feeRecipient = feeRecepient_;
        houseEdge = houseEdge_;
        linkPremium = linkPremium_;
        maxBetAmount = maxBetAmount_;
        linkToNativeTokenPriceFeed = linkToNativeTokenPriceFeed_;
        // Adding the usd price feed of the native token
        tokenToUsdPriceFeed[address(0)] = nativeToUsdPriceFeed;
        addedTokens.push(address(0));
        require(
            calculations_ != address(0),
            "DiceGame: invalid input calculations"
        );
        calculations = ICalculations(calculations_);
    }

    /// @notice Allows to replenish the contract with the native token ETH, BNB, MATIC, etc...
    receive() external payable {}

    /// @notice Allows the users to bet for a guess random number sending a range of numbers in which they think the random number will be generated
    /// @dev the user has to send in the value of the transaction the native token of the bet + the chainlink fees after calculating it with the function estimateChainlinkFee
    /// @dev the user could also bet in allowed erc20 tokens but still need to send in the value of the transaction the chainlinkn fee
    /// @param lowerNumbers Array of Lower number of the range
    /// @param upperNumbers Array of  Higher number of the range
    /// @param betAmounts Array of The amount to bet
    /// @param tokens Array of Token address to use for the bet, use address zero 0x0000000000000000000000000000000000000000 for native token
    /// @param influencer address of the influencer who referred this player
    function playGame(
        uint16[] calldata lowerNumbers,
        uint16[] calldata upperNumbers,
        uint256[] calldata betAmounts,
        IERC20Upgradeable[] calldata tokens,
        address influencer
    ) external payable {
        require(
            lowerNumbers.length == upperNumbers.length &&
                lowerNumbers.length == betAmounts.length &&
                lowerNumbers.length == tokens.length,
            "DiceGame: different inputs size"
        );

        require(betAmounts.length <= 10, "DiceGame: send less than 10 bets");

        uint256 remainingValueForFee = msg.value;
        uint256[] memory prizeAmounts = new uint256[](betAmounts.length);
        uint256[] memory multipliers = new uint256[](betAmounts.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            processInfluencerReferral(
                influencer,
                betAmounts[i],
                address(tokens[i])
            );

            if (tokens[i] == IERC20Upgradeable(address(0))) {
                remainingValueForFee -= betAmounts[i];
            } else {
                require(
                    tokenToUsdPriceFeed[address(tokens[i])] != address(0),
                    "DiceGame: Token is not allowed"
                );

                bool successTransfer = tokens[i].transferFrom(
                    msg.sender,
                    address(this),
                    betAmounts[i]
                );
                require(successTransfer, "DiceGame: error with transferFrom");
            }
            (, multipliers[i], prizeAmounts[i]) = calculateBet(
                lowerNumbers[i],
                upperNumbers[i],
                betAmounts[i]
            );
            require(
                prizeAmounts[i] <= getAvailablePrize(tokens[i]),
                "DiceGame: Insufficient balance to accept bet"
            );
            require(
                prizeAmounts[i] > betAmounts[i],
                "DiceGame: prize is too low"
            );
            totalInBetsPerToken[address(tokens[i])] += betAmounts[i];
        }

        uint256 chainlinkFeeNativeToken = estimateChainlinkFee(
            tx.gasprice,
            tokens.length
        );

        require(
            remainingValueForFee >= chainlinkFeeNativeToken,
            "DiceGame: chainlink fee too low"
        );
        (bool success, ) = feeRecipient.call{value: remainingValueForFee}("");

        require(success, "DiceGame: Error while paying feeRecepient");
        uint256 requestId = requestRandomWords(
            lowerNumbers,
            upperNumbers,
            prizeAmounts,
            betAmounts,
            multipliers,
            tokens
        );
        emit RequestId(requestId, msg.sender, block.timestamp, tokens.length);
    }

    function changeCalculations(address calculations_) external onlyOwner {
        calculations = ICalculations(calculations_);
    }

    function getAddedTokens() external view returns (address[] memory) {
        return addedTokens;
    }

    /// @notice Allows the owner to edit the house edge which is the amount of numbers that cannot be used
    /// @dev The minimum house edge is 1% or 1.00 or 100, so at least 100 of 10000 numbers cannot be used by the user
    /// @param houseEdge_ new house edge to be used in the contract
    function editHouseEdge(uint16 houseEdge_) external onlyOwner {
        require(
            houseEdge_ >= 100 && houseEdge_ < MAX_NUMBER,
            "DiceGame: Invalid house edge"
        );
        houseEdge = houseEdge_;
    }

    function withdraw(IERC20Upgradeable _token, uint256 _amount)
        external
        onlyOwner
    {
        require(
            getAvailablePrize(_token) -
                totalUnpaidToInfluencersByToken[address(_token)] >=
                _amount,
            "DiceGame: amount is more than allowed"
        );
        if (_token == IERC20Upgradeable(address(0))) {
            payable(owner()).transfer(_amount);
        } else {
            bool success = _token.transfer(owner(), _amount);
            require(success, "DiceGame: error in transfer");
        }
    }

    /// @notice Returns the biggest multiplier that a user can use based on the bet amount
    /// @param betAmount bet amount to sent in the bet
    /// @param token address of the token to use in the bet
    /// @return multiplier number in the wei units representing the biggest multiplier
    function getBiggestMultiplierFromBet(
        uint256 betAmount,
        IERC20Upgradeable token
    ) external view returns (uint256 multiplier) {
        multiplier = calculations.getBiggestMultiplierFromBet(betAmount, token);
    }

    /// @notice Show the numbers produced by chainlink using the randomness
    /// @dev The randomness comes from the chainlink event
    //  @dev RandomWordsFulfilled(requestId, randomness, payment, success)
    /// @param randomness source of randomness used to generate the numbers
    /// @param amountOfNumbers how many numbers were generated
    /// @return chainlinkRawNumbers array of big numbers produced by chanlink
    /// @return parsedNumbers array of raw number formated to be in the range from 1 to 10000
    function getNumberFromRandomness(
        uint256 randomness,
        uint256 amountOfNumbers
    )
        external
        view
        returns (
            uint256[] memory chainlinkRawNumbers,
            uint256[] memory parsedNumbers
        )
    {
        (chainlinkRawNumbers, parsedNumbers) = calculations
            .getNumberFromRandomness(randomness, amountOfNumbers);
    }

    /// @notice Allows to estimate the winning chance, multiplier, and prize amount
    /// @dev To choose a single number send the same number in lower and upper inputs
    /// @param lowerNumber Lower number of the range
    /// @param upperNumber Higher number of the range
    /// @param betAmount The amount to bet
    /// @return winningChance The winning chance percentage = (winningChance/10000 * 100)
    /// @return multiplier Multiplier: multiplier/1e18 or multiplier/1000000000000000000
    /// @return prizeAmount Prize amount = prizeAmount/1e18  or prizeAmount/1000000000000000000
    function calculateBet(
        uint16 lowerNumber,
        uint16 upperNumber,
        uint256 betAmount
    )
        public
        view
        returns (
            uint256 winningChance,
            uint256 multiplier,
            uint256 prizeAmount
        )
    {
        require(
            betAmount > 0 && betAmount <= maxBetAmount,
            "DiceGame: Invalid bet amount"
        );
        require(
            lowerNumber <= MAX_NUMBER &&
                upperNumber <= MAX_NUMBER &&
                lowerNumber <= upperNumber &&
                lowerNumber > 0,
            "DiceGame: Invalid range"
        );

        // Checks if there is enough room in the range for the house edge.
        uint16 leftOver = lowerNumber == upperNumber
            ? MAX_NUMBER - 1
            : lowerNumber - MIN_NUMBER + MAX_NUMBER - upperNumber;
        require(leftOver >= houseEdge, "DiceGame: Invalid boundaries");

        winningChance = MAX_NUMBER - leftOver;
        multiplier = ((MAX_NUMBER - houseEdge) * BP) / winningChance;
        prizeAmount = (betAmount * multiplier) / BP;
    }

    /// @notice It produces the closest possible multipler based to the bet and profit
    function getMultiplierFromBetAndProfit(
        uint256 betAmount,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        multiplier = calculations.getMultiplierFromBetAndProfit(
            betAmount,
            profit,
            token
        );
    }

    /// @notice Expects the multiplier to be in wei format 2x equals 2e18
    /// @notice Returns the quantity of numbers that can be used in the bet.
    /// @notice It chooses the closest winning chance to the provided multiplier
    /// @notice Example output: winningChance = 10 means 10 different numbers.
    function getWinningChanceFromMultiplier(uint256 multiplier)
        public
        view
        returns (uint256 winningChance)
    {
        winningChance = calculations.getWinningChanceFromMultiplier(multiplier);
    }

    /// @notice The function will adjust the provided multiplier to the closest possible multiplier
    /// @notice And then calculate the profit based on that multiplier
    /// @notice The upperNum can be used to get the multiplier used for the obtained profit
    function getProfitFromBetAndMultiplier(
        uint256 betAmount,
        uint256 multiplier,
        IERC20Upgradeable token
    ) public view returns (uint256 profit, uint256 upperNum) {
        (profit, upperNum) = calculations.getProfitFromBetAndMultiplier(
            betAmount,
            multiplier,
            token
        );
    }

    /// @notice Returns the closest possible multiplier generated by the bet amount and win chance
    function getMultiplierFromBetAndChance(
        uint256 betAmount,
        uint256 winningChance,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        multiplier = calculations.getMultiplierFromBetAndChance(
            betAmount,
            winningChance,
            token
        );
    }

    /// @notice Returns bet amount to be used for the multiplier and profit
    /// @notice The upperNum can be used to calculate the exact multiplier used for the calculation of the bet amount
    function getBetFromMultiplierAndProfit(
        uint256 multiplier,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 betAmount, uint256 upperNum) {
        (betAmount, upperNum) = calculations.getBetFromMultiplierAndProfit(
            multiplier,
            profit,
            token
        );
    }

    /// @notice The max multiplier comes when a user chooses only one number between 1-10000
    function getMaxMultiplier() public view returns (uint256 maxMultiplier) {
        maxMultiplier = calculations.getMaxMultiplier();
    }

    /// @notice Calculates the values that help to visualize the bet with the most accurate numbers
    /// @notice The function will correct values ​​that are not precise, but will throw an error if the values ​​are out of bounds.
    /// @param desiredMultiplier Desired multiplier in wei units
    /// @param desiredWinningChance Win chance the user would like to have numbers from 1 to 10000
    /// @param desiredProfit Amount of profit the user expects to have
    /// @param desiredBetAmount Bet to be used when playing
    /// @param token Address of the token to be used in the bet
    /// @return resultBetAmount Bet amount to be used in the preview of the bet
    /// @return resultProfit Profit to be used in the preview of the bet
    /// @return resultPrize Prize to be used in the preview of the bet
    /// @return resultWinningChance Win chance to be used in the preview of the bet
    /// @return resultMultiplier Multiplier to be used in the preview of the bet
    function getPreviewNumbers(
        uint256 desiredMultiplier,
        uint256 desiredWinningChance,
        uint256 desiredProfit,
        uint256 desiredBetAmount,
        IERC20Upgradeable token
    )
        public
        view
        returns (
            uint256 resultBetAmount,
            uint256 resultProfit,
            uint256 resultPrize,
            uint256 resultWinningChance,
            uint256 resultMultiplier
        )
    {
        (
            resultBetAmount,
            resultProfit,
            resultPrize,
            resultWinningChance,
            resultMultiplier
        ) = calculations.getPreviewNumbers(
            desiredMultiplier,
            desiredWinningChance,
            desiredProfit,
            desiredBetAmount,
            token
        );
    }

    /// @notice The min multiplier comes when a user chooses all numbers except for house edge + 1
    function getMinMultiplier() public view returns (uint256 minMultiplier) {
        minMultiplier = calculations.getMinMultiplier();
    }

    /// @notice It estimates the winning chance to cover all the possible numbers except for the  house edge + 1, so that it can get more than 1x
    function getMaxWinningChance()
        public
        view
        returns (uint256 maxWinningChance)
    {
        // Need the leftOver to be greater than the houseEdge
        maxWinningChance = calculations.getMaxWinningChance();
    }

    /// @notice Allows the owner to edit the address that receives the chainlink fees
    /// @dev Do not use a contract that can not accept native tokens receive or fallback functions
    /// @param feeRecepient_ Address that receives the chainlink fees
    function editFeeRecipient(address payable feeRecepient_) public onlyOwner {
        require(feeRecepient_ != address(0), "DiceGame: Invalid fee recipient");
        feeRecipient = feeRecepient_;
    }

    /// @notice Allows the owner to edit the maximum bet that users can make
    /// @dev Numbers in wei (1 equals 1 wei), but (1e18 equals 1 token)
    /// @param maxBetAmount_ Maximum bet that users can make
    function editMaxBetAmount(uint256 maxBetAmount_) public onlyOwner {
        maxBetAmount = maxBetAmount_;
    }

    /// @notice Calculates the chainlink fee using the current tx gas price
    /// @dev Explain to a developer any extra details
    /// @param currentGasPrice gas price to be used in the tx
    /// @param amountOfBets how many numbers will be requested
    /// @return fee amount in native token - wei format
    function estimateChainlinkFee(uint256 currentGasPrice, uint256 amountOfBets)
        public
        view
        returns (uint256)
    {
        return
            calculations.estimateChainlinkFee(
                currentGasPrice,
                amountOfBets,
                linkPremium,
                MAX_VERIFICATION_GAS,
                CALLBACK_GAS_LIMIT,
                linkToNativeTokenPriceFeed
            );
    }

    /// @notice Shows the amount of tokens that are available to pay prizes
    /// @dev This function separates the tokens locked waiting for an result from the current balance of the contract
    /// @param token Token address to be requested
    /// @return balance of the token specified that is available to pay prizes
    function getAvailablePrize(IERC20Upgradeable token)
        public
        view
        returns (uint256)
    {
        uint256 lockedInBets = totalInBetsPerToken[address(token)];
        if (token == IERC20Upgradeable(address(0))) {
            return address(this).balance - (lockedInBets);
        } else {
            return token.balanceOf(address(this)) - lockedInBets;
        }
    }
}