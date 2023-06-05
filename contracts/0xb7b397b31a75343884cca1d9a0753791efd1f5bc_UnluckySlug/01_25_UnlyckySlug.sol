// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IWETH {
    function withdraw(uint wad) external;
}

/// @author Twitter: @_slugfather_
/// @title Unlucky Slug Lottery
/// @notice An innovative way to buy a token, while having a chance to win amazing prizes in a lottery. The lottery uses Chainlink VRF v2 to generate
///         verifiable Random Numbers.
contract UnluckySlug is VRFConsumerBaseV2, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ---------------------- UNISWAP VARIABLES -------------------------------- //
    IQuoter public immutable quoter;
    ISwapRouter public immutable swapRouter;
    address public WETH9;
    address public slugTokenAddress;
    uint24 public poolFee;

    // ---------------------- CHAINLINK VARIABLES -------------------------------- //
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 subscriptionID;
    bytes32 keyHash;
    uint32 callbackGasLimit = 1_500_000;
    uint16 requestConfirmations = 3;
    uint8 constant NUM_RANDOM_WORDS = 15;

    // ---------------------- LOTTERY VARIABLES -------------------------------- //
    uint256 public currentDay;
    uint256 public currentDayTransferred;
    struct ticketsData {
        uint256 currentDayTransferred;
        uint256 requestId;
        address[] indexToAddress;
        mapping(uint32 => address) randomNumberToAddress;
    }
    mapping(uint256 => ticketsData) public ticketsDataPerDay;
    
    struct RequestData {
        uint256 day;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestData) public requestIdToData;
    mapping(address => mapping(uint8 => uint256)) public userPrizes;

    uint256 public jackPotBalance;
    uint256 public ticketCost = .05 ether;
    uint8 constant public LIMIT_TICKETS_PER_SWAP = 5;
    uint32 LOTTERY_FREQUENCY = 1 days;
    enum PrizeType { Jackpot, FirstPrize, SecondPrize, ThirdPrize }

    // ---------------------- USER VARIABLES -------------------------------- //
    mapping(address => address) public referralToReferrer;
    mapping(address => uint256) public moneySpent;
    mapping(address => uint256) public commissionRewards;


    // ---------------------- PROBABILITIES -------------------------------- //
    uint256 public probabilityEquivalentToOne = 10**6;
    uint256 public jackPotProbability = 1; // 1/probabilityEquivalentToOne = 0.0001% Jackpot Number

    uint256 public VALUE_PERCENTAGE_TO_JACKPOT = 2_500; // 3/probabilityEquivalentToOne = 0.25%
    uint256 public VALUE_PERCENTAGE_TO_FIRST_PRIZE = 1_000; // 1/probabilityEquivalentToOne = 0.1%, so 0.1% of the volume from last day for the first prize
    uint256 public VALUE_PERCENTAGE_TO_SECOND_PRIZE = 150; // 1/probabilityEquivalentToOne = 0.015%, so 3 * 0.015% = 0.045% of the volume from last day for the second prize
    uint256 public VALUE_PERCENTAGE_TO_THIRD_PRIZE = 50; // 1/probabilityEquivalentToOne = 0.005%, so 10 * 0.005% = 0.05% of the volume from last day for the third prize
    
    uint256 public VALUE_PERCENTAGE_TO_REFERRER = 1_000; // 1/probabilityEquivalentToOne = 0.1%
    uint256 public VALUE_PERCENTAGE_TO_CASHBACK = 1_000; // 1/probabilityEquivalentToOne = 0.1%
    
    event JackPot(address indexed _to, uint256 indexed _day, uint32 randomNumber, uint256 _value);
    event FirstPrize(address indexed _to, uint256 indexed _day, uint32 participantNumber, uint256 _value);
    event SecondPrize(address indexed _to, uint256 indexed _day, uint32 participantNumber, uint256 _value);
    event ThirdPrize(address indexed _to, uint256 indexed _day, uint32 participantNumber, uint256 _value);

    event ClaimedJackPot(address indexed _to, uint256 _value);
    event ClaimedFirstPrize(address indexed _to, uint256 _value);
    event ClaimedSecondPrize(address indexed _to, uint256 _value);
    event ClaimedThirdPrize(address indexed _to, uint256 _value);

    event JackPotNumber(uint256 indexed _day, uint32 randomNumber);
    event EnteredLottery(address indexed _to, uint256 _tickets);
    event DayChanged(uint256 _day);
    event RandomNumberGenerated(address indexed _to, uint256 indexed _day, uint32 _randomNumber);
    event ReferralSet(address indexed _referrer, address indexed _referral);


    // @dev Constructor to set up the VRF Consumer
    // @param subscriptionId Identifier of the VRF Subscription
    // @param _swapRouter Address of the Uniswap V3 Swap Router
    // @param _quoter Address of the Uniswap V3 Quoter
    // @param _slugTokenAddress Address of the Slug Token
    constructor(
        uint64 _subscriptionID,
        address _VRFCoordinator,
        bytes32 _keyHash,
        ISwapRouter _swapRouter, 
        IQuoter _quoter, 
        address _wethTokenAddress,
        address _slugTokenAddress, 
        uint24 _poolFee
    ) VRFConsumerBaseV2(_VRFCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_VRFCoordinator);
        subscriptionID = _subscriptionID;
        keyHash = _keyHash;
        swapRouter = _swapRouter;
        quoter = _quoter;
        WETH9 = _wethTokenAddress;
        slugTokenAddress = _slugTokenAddress;
        poolFee = _poolFee;
    }


    // @dev Fallback function to receive Ethers
    receive() external payable {}


    // @dev Function to pause the contract
    function pause() public onlyOwner {
        _pause();
    }


    // @dev Function to unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }


    // @dev Function to set a the Gas limit key Hash for the callback of ChainLink VRF
    // @param _keyHash New Gas Limit key Hash
    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash= _keyHash;
    }


    // @dev Function to set a subscription ID for ChainLink VRF
    // @param _subscriptionID New subscription ID
    function setSubscriptionID(uint64 _subscriptionID) public onlyOwner {
        subscriptionID = _subscriptionID;
    }

    // @dev Function to set the slug token address
    // @param _slugTokenAddress New slug token address
    function setSlugTokenAddress(address _slugTokenAddress) public onlyOwner {
        slugTokenAddress = _slugTokenAddress;
    }

    // @dev Function to be able to modify the ticketCost in case of gasFees are more favorable, or unfavorable since they are paid by the project
    // @param ticketCostWei New ticket cost
    function setTicketCost(uint256 ticketCostWei) public onlyOwner {
        ticketCost = ticketCostWei;
    }

    // @dev Function to set the lottery frequency
    // @param _frequencyInSeconds New frequency in seconds
    function setLotteryFrequency(uint32 _frequencyInSeconds) public onlyOwner {
        LOTTERY_FREQUENCY = _frequencyInSeconds;
    }

    function setJackPotProbability(uint256 _jackPotProbability) public onlyOwner {
        jackPotProbability = _jackPotProbability;
    }
    
    // @dev Function for the owner to be able to deposit Funds for the initial jackpot prize
    function depositFunds() public payable onlyOwner {
    }


    // @dev Function to withdraw the funds of the project
    //      Notice that the jackPotBalance cannot be withdraw from this contract
    // @param _to Address to send the funds
    function withdrawFunds(address payable _to, uint256 amount) public onlyOwner {
        require(amount > 0, "The amount must be greater than 0");
        uint256 balanceAvailableToTransfer = address(this).balance - jackPotBalance;
        require(amount <= balanceAvailableToTransfer, "The amount exceeds the available balance");
        _to.transfer(amount);
    }


    // @dev Function to be able to withdraw any ERC20 token in case of receiving some (you never know)
    // @param _tokenContract The contract address of the token to be withdrawn
    // @param _amount Amount of the token to be withdrawn
    function withdrawERC20(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }


    // @dev Function to claim the commision of the referrer and cashback
    function claimCommision() nonReentrant public {
        uint256 commissionAmount = commissionRewards[msg.sender];
        require(commissionAmount > 0, "You have no commision and cashback to claim");
        commissionRewards[msg.sender] = 0;
        payable(msg.sender).transfer(commissionAmount);
    }


    // @dev Function to check the commision of the referrer and cashback
    function checkCommision(address _address) public view returns (uint256) {
        return commissionRewards[_address];
    }

    function getIndexToAddress(uint256 day, uint256 index) public view returns (address) {
        return ticketsDataPerDay[day].indexToAddress[index];
    }

    function getRandomNumberToAddress(uint256 day, uint32 randomNumber) public view returns (address) {
        return ticketsDataPerDay[day].randomNumberToAddress[randomNumber];
    }

    function getindexToAddressLength(uint256 day) public view returns (uint256) {
        return ticketsDataPerDay[day].indexToAddress.length;
    }

    function getCurrentDay() public view returns (uint256) {
        return currentDay;
    }

    function getCurrentDayTransferred() public view returns (uint256) {
        return currentDayTransferred;
    }

    // Calculate number of tickets options based on the amount inserted and the ticket cost
    function calculateTicketsAmount(uint256 value) internal view returns (uint32) {
        uint256 ticketsAmount = value / ticketCost;
        uint32 _tickets;
        // limit per swap
        if (ticketsAmount > LIMIT_TICKETS_PER_SWAP) {
            _tickets = LIMIT_TICKETS_PER_SWAP;
        }
        else {
            _tickets = uint32(ticketsAmount);
        }
        return _tickets;
    }


    // @dev Function to swap ETH for SLUG
    // @param amountIn Amount of ETH to swap
    // @param amountOutMinimum Minimum amount of SLUG to receive
    function swapExactETHForSLUG(uint256 amountIn, uint256 amountOutMinimum) internal {
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: slugTokenAddress,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp + 1800,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        swapRouter.exactInputSingle{value: amountIn}(params);
    }


    // @dev Function to sell SLUG for ETH
    // @param amountIn Amount of SLUG to swap
    // @param amountOutMinimum Minimum amount of WETH to receive
    function swapSLUGForExactETH(uint256 amountIn, uint256 amountOutMinimum) internal returns (uint256) {
        require(amountIn > 0 , "You need to send at least some money bastard");

        // Transfer the specified amount of SLUG to this contract.
        TransferHelper.safeTransferFrom(slugTokenAddress, msg.sender, address(this), amountIn);

        // Approve the router to spend SLUG.
        TransferHelper.safeApprove(slugTokenAddress, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: slugTokenAddress,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 1800,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut = swapRouter.exactInputSingle(params);

        // Convert WETH to ETH
        IWETH(WETH9).withdraw(amountOut);

        return amountOut;
    }


    // @dev Check if the day changed and if so, update all the previousDayData, request a random number to ChainLink VRF and delete all the variables of the previous day
    function checkDayChanged() internal {
        uint256 today = block.timestamp / LOTTERY_FREQUENCY;
        if (today > currentDay) {
            emit DayChanged(today);
            ticketsData storage previousDayData = ticketsDataPerDay[currentDay];
            uint256 requestId = requestRandomWords(currentDay);

            previousDayData.requestId = requestId;
            previousDayData.currentDayTransferred = currentDayTransferred;

            // delete all the variables of the previous day
            currentDay = today;
            currentDayTransferred = 0;
        }
    }


    // @dev Function to generate a random number for each ticket using keccak256, and save it so we can later check who is the winner of the prizes
    // @param _ticketsAmount Amount of tickets to generate
    function generateTickets(uint256 _ticketsAmount) internal {
        ticketsData storage currentDayData = ticketsDataPerDay[currentDay];

        for (uint32 i = 0; i < _ticketsAmount; i++) {
            uint32 randomNumber = uint32(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, i))) % probabilityEquivalentToOne);
            currentDayData.randomNumberToAddress[randomNumber] = msg.sender;
            currentDayData.indexToAddress.push(msg.sender);
            emit RandomNumberGenerated(msg.sender, currentDay, randomNumber);
        }
    }


    // @dev Function to enter 1 ticket of the lottery and transfer some of the value of the ticket to referrals and cashback
    // @param amountOutMinimum Minimum amount of SLUG to receive
    // @param referrerAddress Address of the referrer
    function enterLottery(uint256 amountOutMinimum, address referrerAddress) public payable whenNotPaused nonReentrant {
        require(msg.value > 0 , "You need to send at least some money bastard");

        // Set the referrer if the conditions are met
        if (referrerAddress != address(0) && moneySpent[referrerAddress] >= .001 ether && referralToReferrer[msg.sender] == address(0)) {
            referralToReferrer[msg.sender] = referrerAddress;
            emit ReferralSet(referrerAddress, msg.sender);
        }

        // 99% of the amount sent is used for swap (0.35%-0.55% stays in the contract for the project)
        uint256 amountIn = msg.value * 99 / 100;
        swapExactETHForSLUG(amountIn, amountOutMinimum);

        referrerAddress = referralToReferrer[msg.sender];
        if (referrerAddress != address(0)) {
            commissionRewards[referrerAddress] += msg.value * VALUE_PERCENTAGE_TO_REFERRER / probabilityEquivalentToOne;
            commissionRewards[msg.sender] += msg.value * VALUE_PERCENTAGE_TO_CASHBACK / probabilityEquivalentToOne;
        }

        // calculate number of tickets
        uint32 ticketsAmount = calculateTicketsAmount(msg.value);
        if (ticketsAmount > 0) {
            emit EnteredLottery(msg.sender, ticketsAmount);
            checkDayChanged();
            generateTickets(ticketsAmount);
        }

        currentDayTransferred += msg.value;
        moneySpent[msg.sender] += msg.value;
        jackPotBalance += msg.value * VALUE_PERCENTAGE_TO_JACKPOT / probabilityEquivalentToOne;
    }


    // @dev Function to enter 1 ticket of the lottery and transfer some of the value of the ticket to refferrals and cashback
    // @param amountIn Amount of SLUG to swap
    // @param amountOutMinimum Minimum amount of WETH to receive
    function sellSLUG(uint256 amountIn, uint256 amountOutMinimum) public whenNotPaused nonReentrant {
        require(amountIn > 0 , "You need to send at least some money bastard");
        
        uint256 amountOut = swapSLUGForExactETH(amountIn, amountOutMinimum);

        // Send ETH to msg.sender
        // 1% of the amount out is used for lottery prizes (0.35%-0.55% stays in the contract for the project)
        (bool success, ) = msg.sender.call{value: amountOut * 99 / 100}("");
        require(success, "Transfer failed.");

        address referrerAddress = referralToReferrer[msg.sender];
        if (referrerAddress != address(0)) {
            commissionRewards[referrerAddress] += amountOut * VALUE_PERCENTAGE_TO_REFERRER / probabilityEquivalentToOne;
            commissionRewards[msg.sender] += amountOut * VALUE_PERCENTAGE_TO_CASHBACK / probabilityEquivalentToOne;
        }

        // calculate number of tickets
        uint32 ticketsAmount = calculateTicketsAmount(amountOut);
        if (ticketsAmount > 0) {
            emit EnteredLottery(msg.sender, ticketsAmount);
            checkDayChanged();
            generateTickets(ticketsAmount);
        }

        currentDayTransferred += amountOut;
        moneySpent[msg.sender] += amountOut;
        jackPotBalance += amountOut * VALUE_PERCENTAGE_TO_JACKPOT / probabilityEquivalentToOne;
    }

    // @dev Function to request the random numbers from Chainlink VRF
    // @return requestId requestId generated by ChainLink VRF to identity different requests
    function requestRandomWords(uint256 _currentDay) internal returns (uint256 _requestId) {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionID,
            requestConfirmations,
            callbackGasLimit,
            NUM_RANDOM_WORDS
        );
        requestIdToData[requestId].day = _currentDay;
        return requestId;
    }


    // @dev Function to receive the random numbers from Chainlink VRF, and then executes logic to
    //      determine if the player has won any prize
    // @param requestId requestId generated by ChainLink VRF to identity different requests
    // @param randomWords Randomwords generated from ChainLink VRF
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        requestIdToData[requestId].randomWords = randomWords;
        assignPrizeWinners(requestId, randomWords);
    }


    function assignPrizeWinners(uint256 requestId, uint256[] memory randomWords) internal {
        // Get data from the previous day
        uint256 lastDay = requestIdToData[requestId].day;
        ticketsData storage previousDayData = ticketsDataPerDay[lastDay];
        
        uint256 _currentDayTransferred = previousDayData.currentDayTransferred;
        uint256 _firstPrizeReward = _currentDayTransferred * VALUE_PERCENTAGE_TO_FIRST_PRIZE / probabilityEquivalentToOne;
        uint256 _secondPrizeReward = _currentDayTransferred * VALUE_PERCENTAGE_TO_SECOND_PRIZE / probabilityEquivalentToOne;
        uint256 _thirdPrizeReward = _currentDayTransferred * VALUE_PERCENTAGE_TO_THIRD_PRIZE / probabilityEquivalentToOne;
        address[] storage lastIndexToAddress = previousDayData.indexToAddress;
        uint256 lastAmountOfTickets = lastIndexToAddress.length;

        uint32 randomNumber;
        if (lastAmountOfTickets > 0) {
            randomNumber = uint32(randomWords[0] % probabilityEquivalentToOne);
            address winner = previousDayData.randomNumberToAddress[randomNumber];
            emit JackPotNumber(lastDay, randomNumber);
            if (winner != address(0)) {
                userPrizes[winner][uint8(PrizeType.Jackpot)] += jackPotBalance;
                emit JackPot(winner, lastDay, randomNumber, jackPotBalance);
                jackPotBalance = 0;
            }
            for (uint256 i = 1; i < NUM_RANDOM_WORDS; i++) {
                randomNumber = uint32(randomWords[i] % lastAmountOfTickets);
                winner = lastIndexToAddress[randomNumber];
                if (i == 1) {
                    userPrizes[winner][uint8(PrizeType.FirstPrize)] += _firstPrizeReward;
                    emit FirstPrize(winner, lastDay, randomNumber, _firstPrizeReward);
                } else if (i >= 2 && i <= 4)  {
                    userPrizes[winner][uint8(PrizeType.SecondPrize)] += _secondPrizeReward;
                    emit SecondPrize(winner, lastDay, randomNumber, _secondPrizeReward);
                } else { // i >= 5 && i <= 14
                    userPrizes[winner][uint8(PrizeType.ThirdPrize)] += _thirdPrizeReward;
                    emit ThirdPrize(winner, lastDay, randomNumber, _thirdPrizeReward);
                }    
            }
        }
    }

    function claimRewards() public whenNotPaused nonReentrant {
        uint256 totalRewards = 0;

        for (uint8 i = 0; i < 4; i++) {
            uint256 prizeAmount = userPrizes[msg.sender][i];
            if (prizeAmount > 0) {
                totalRewards += prizeAmount;
                userPrizes[msg.sender][i] = 0; // Reset the prize amount after claiming

                // Emit events based on the type of prize
                if (PrizeType(i) == PrizeType.Jackpot) {
                    emit ClaimedJackPot(msg.sender, prizeAmount);
                } else if (PrizeType(i) == PrizeType.FirstPrize) {
                    emit ClaimedFirstPrize(msg.sender, prizeAmount);
                } else if (PrizeType(i) == PrizeType.SecondPrize) {
                    emit ClaimedSecondPrize(msg.sender, prizeAmount);
                } else if (PrizeType(i) == PrizeType.ThirdPrize) {
                    emit ClaimedThirdPrize(msg.sender, prizeAmount);
                }
            }
        }

        require(totalRewards > 0, "No rewards to claim");
        payable(msg.sender).transfer(totalRewards);
    }
}