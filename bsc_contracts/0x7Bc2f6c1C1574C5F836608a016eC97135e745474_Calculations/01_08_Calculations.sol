// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Interfaces/IDiceGame.sol";

contract Calculations is Initializable, OwnableUpgradeable {
    uint256 private constant BP = 1e18;

    IDiceGame public diceGame;

    function initialize() public virtual initializer {
        __Ownable_init();
    }

    function setDiceGame(address diceGameAddress) external onlyOwner {
        diceGame = IDiceGame(diceGameAddress);
    }

    /// @notice Returns the biggest multiplier that a user can use based on the bet amount
    /// @param betAmount bet amount to sent in the bet
    /// @param token address of the token to use in the bet
    /// @return multiplier number in the wei units representing the biggest multiplier
    function getBiggestMultiplierFromBet(
        uint256 betAmount,
        IERC20Upgradeable token
    ) external view returns (uint256 multiplier) {
        require(
            betAmount <= diceGame.maxBetAmount(),
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        // Formula: multiplier = (getAvailablePrize() + Bet) / Bet
        // This gives us the maximum multiplier possible
        multiplier =
            ((diceGame.getAvailablePrize(token) + betAmount) * BP) /
            betAmount;
        uint256 maxMultiplier = getMaxMultiplier();
        if (multiplier > maxMultiplier) multiplier = maxMultiplier;
        // Calculates the closest multiplier
        uint256 upperNum = getWinningChanceFromMultiplier(multiplier);
        (, multiplier, ) = diceGame.calculateBet(
            uint16(1),
            uint16(upperNum),
            1
        );
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
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
        chainlinkRawNumbers = new uint256[](amountOfNumbers);
        parsedNumbers = new uint256[](amountOfNumbers);
        for (uint256 i = 0; i < amountOfNumbers; i++) {
            chainlinkRawNumbers[i] = uint256(
                keccak256(abi.encode(randomness, i))
            );
            parsedNumbers[i] =
                (chainlinkRawNumbers[i] % diceGame.MAX_NUMBER()) +
                1;
        }
    }

    /// @notice It produces the closest possible multipler based to the bet and profit
    function getMultiplierFromBetAndProfit(
        uint256 betAmount,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        require(
            betAmount <= diceGame.maxBetAmount(),
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        require(
            profit <= diceGame.getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
        require(profit > 0, "DiceGame: profit has to be greater than 0");
        // Formula: multiplier = (bet+profit) / bet
        multiplier = ((betAmount + profit) * BP) / betAmount;

        uint256 upperNum = getWinningChanceFromMultiplier(multiplier);
        (, multiplier, ) = diceGame.calculateBet(
            uint16(1),
            uint16(upperNum),
            1
        );
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
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
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        uint256 winningChanceBeforeRounding = (((diceGame.MAX_NUMBER() -
            diceGame.houseEdge()) * BP) * BP) / multiplier;

        // Before rounding up it uses the current winning chance without decimals to see
        // If it is more than the desired multiplier else add 1 to the winning chance
        (, uint256 multiplierNoRounding, ) = diceGame.calculateBet(
            uint16(1),
            uint16(winningChanceBeforeRounding / BP),
            1
        );
        if (multiplierNoRounding > multiplier)
            winningChance = (winningChanceBeforeRounding + BP) / BP;
        else {
            winningChance = winningChanceBeforeRounding / BP;
        }
    }

    /// @notice The function will adjust the provided multiplier to the closest possible multiplier
    /// @notice And then calculate the profit based on that multiplier
    /// @notice The upperNum can be used to get the multiplier used for the obtained profit
    function getProfitFromBetAndMultiplier(
        uint256 betAmount,
        uint256 multiplier,
        IERC20Upgradeable token
    ) public view returns (uint256 profit, uint256 upperNum) {
        require(
            betAmount <= diceGame.maxBetAmount(),
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        upperNum = getWinningChanceFromMultiplier(multiplier);
        (, , uint256 prizeAmount) = diceGame.calculateBet(
            uint16(1),
            uint16(upperNum),
            betAmount
        );
        profit = prizeAmount - betAmount;
        require(
            profit <= diceGame.getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
    }

    /// @notice Returns the closest possible multiplier generated by the bet amount and win chance
    function getMultiplierFromBetAndChance(
        uint256 betAmount,
        uint256 winningChance,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        require(
            betAmount <= diceGame.maxBetAmount(),
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        require(
            winningChance <= getMaxWinningChance(),
            "DiceGame: winning chance is greater than the max winning chance"
        );

        require(winningChance > 0, "DiceGame: winning chance cannot be 0");

        (, multiplier, ) = diceGame.calculateBet(
            uint16(1),
            uint16(winningChance),
            1
        );
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        require(
            (((multiplier * betAmount) / BP) - betAmount) <=
                diceGame.getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
    }

    /// @notice Returns bet amount to be used for the multiplier and profit
    /// @notice The upperNum can be used to calculate the exact multiplier used for the calculation of the bet amount
    function getBetFromMultiplierAndProfit(
        uint256 multiplier,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 betAmount, uint256 upperNum) {
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        require(
            profit <= diceGame.getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
        // Moves the multiplier to the closest possible multiplier
        upperNum = getWinningChanceFromMultiplier(multiplier);
        (, multiplier, ) = diceGame.calculateBet(
            uint16(1),
            uint16(upperNum),
            1
        );
        // formula = Bet =  profit / multiplier - 1
        betAmount = (profit * BP) / (multiplier - BP);
        require(
            betAmount <= diceGame.maxBetAmount(),
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
    }

    /// @notice The max multiplier comes when a user chooses only one number between 1-10000
    function getMaxMultiplier() public view returns (uint256 maxMultiplier) {
        maxMultiplier = (diceGame.MAX_NUMBER() - diceGame.houseEdge()) * BP;
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
        uint256 multiplier = desiredMultiplier;
        uint256 betAmount;

        // Calculates the bet using multiplier and profit
        if (
            desiredBetAmount == 0 && desiredMultiplier > 0 && desiredProfit > 0
        ) {
            (betAmount, ) = getBetFromMultiplierAndProfit(
                desiredMultiplier,
                desiredProfit,
                token
            );
        } else {
            // Assign a low bet if no bet was passed
            betAmount = desiredBetAmount > 0 ? desiredBetAmount : 1000000000;
        }

        if (multiplier == 0) {
            // Gets the multiplier from the win chance
            if (desiredWinningChance > 0) {
                multiplier = getMultiplierFromBetAndChance(
                    betAmount,
                    desiredWinningChance,
                    token
                );
            } else {
                // Gets the multiplier from the profit and bet
                require(desiredProfit > 0, "DiceGame: fill profit and bet");
                multiplier = getMultiplierFromBetAndProfit(
                    betAmount,
                    desiredProfit,
                    token
                );
            }
            require(multiplier > 0, "DiceGame: fill winning chance");
        }

        uint256 winChance = getWinningChanceFromMultiplier(multiplier);
        uint256 prizeAmount;
        (winChance, multiplier, prizeAmount) = diceGame.calculateBet(
            uint16(1),
            uint16(winChance),
            betAmount
        );
        // Generating profit
        (uint256 profit, ) = getProfitFromBetAndMultiplier(
            betAmount,
            multiplier,
            token
        );
        // Filling results
        resultBetAmount = betAmount;
        resultProfit = profit;
        resultPrize = prizeAmount;
        resultWinningChance = winChance;
        resultMultiplier = multiplier;
    }

    /// @notice The min multiplier comes when a user chooses all numbers except for house edge + 1
    function getMinMultiplier() public view returns (uint256 minMultiplier) {
        uint16 MAX_NUMBER = diceGame.MAX_NUMBER();
        uint16 houseEdge = diceGame.houseEdge();
        minMultiplier =
            ((MAX_NUMBER - houseEdge) * BP) /
            (MAX_NUMBER - (houseEdge + 1));
    }

    /// @notice It estimates the winning chance to cover all the possible numbers except for the  house edge + 1, so that it can get more than 1x
    function getMaxWinningChance()
        public
        view
        returns (uint256 maxWinningChance)
    {
        // Need the leftOver to be greater than the houseEdge
        maxWinningChance = diceGame.MAX_NUMBER() - (diceGame.houseEdge() + 1);
    }

    /// @notice Calculates the chainlink fee using the current tx gas price
    /// @dev Explain to a developer any extra details
    /// @param currentGasPrice gas price to be used in the tx
    /// @param amountOfBets how many numbers will be requested
    /// @return fee amount in native token - wei format
    function estimateChainlinkFee(
        uint256 currentGasPrice,
        uint256 amountOfBets,
        uint256 linkPremium_,
        uint256 maxVerificationGas,
        uint256 callbackGasLimit,
        address linkToNativeTokenPriceFeed
    ) public view returns (uint256) {
        require(
            amountOfBets > 0,
            "DiceGame: amount of numbers must be at least 1"
        );
        (, int256 price, , , ) = AggregatorV3Interface(
            linkToNativeTokenPriceFeed
        ).latestRoundData(); // price in Eth for 1 LINK
        if (price < 0) price = 0; // Prevents error with overflow below
        uint256 priceParsed = (uint256(price) * linkPremium_) / BP;
        currentGasPrice = currentGasPrice + ((currentGasPrice * 5) / 100); // Adds 5% to the current gas price

        return
            (currentGasPrice *
                (maxVerificationGas + (callbackGasLimit * amountOfBets))) +
            priceParsed;
    }

    /// @notice Overrides the renounceOwnership function, it won't be possible to renounce the ownership
    function renounceOwnership() public pure override {
        require(false, "DiceGame: renounceOwnership has been disabled");
    }
}