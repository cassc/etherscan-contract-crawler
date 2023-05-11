pragma solidity 0.8.19;

//SPDX-License-Identifier: BUSL-1.1

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IOracleAggregator.sol";
import "./interfaces/IFlashLoanReceiver.sol";

interface IFees {
    function feeCollector(uint256 _index) external view returns (address);

    function depositStatus(uint256 _index) external view returns (bool);

    function calcFee(
        uint256 _strategyId,
        address _user,
        address _feeToken
    ) external view returns (uint256);
}

contract DCAStrategy is
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint16 public constant STRATEGY_INDEX = 23;
    uint16 public constant DIVISOR = 1000;
    IFees public feesInstance;
    address public oracleAggregator;
    uint32 public numPairs;
    uint public fillingFee;

    function initialize(
        address feesAddress_,
        address oracleAggregator_,
        uint fillingFee_
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        feesInstance = IFees(feesAddress_);
        oracleAggregator = oracleAggregator_;
        fillingFee = fillingFee_;
    }

    /// @notice struct denoting user's orders
    /// @param startRound starting round of user's order
    /// @param rounds number of rounds to execute user's order
    /// @param amount amount deposited by user
    struct UserData {
        uint64 startRound;
        uint64 rounds;
        uint amount;
    }

    /// @notice struct denoting data for each round
    /// @dev rate can be derived from shares/filled
    /// @param roundFilled amount filled in round
    /// @param roundShares number of shares in that round
    struct RoundData {
        uint roundFilled;
        uint roundShares;
    }

    /// @notice struct denoting data for each pair
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param decimalA token A decimals
    /// @param decimalB token B decimals
    /// @param period purchase interval
    struct PairData {
        address tokenA;
        address tokenB;
        uint8 decimalA;
        uint8 decimalB;
        uint32 period;
    }

    /// @notice mapping of pairId to pairData
    /// @dev used for querying avaliable pairs
    /// @dev pair +1 is always the opposite pair
    /// @dev mapping of pairId => pairData
    mapping(uint => PairData) public pairIdMap;

    /// @notice mapping of pair key to pair id
    /// @dev inverse of pairDataMap
    /// @dev mapping of tokenA => tokenB => period => pairId
    mapping(address => mapping(address => mapping(uint32 => uint)))
        public pairDataMap;

    /// @notice determines the next possible time a pair can be filled
    /// @dev mapping of tokenA  =>  tokenB  =>  period  =>  lastFillTime
    mapping(address => mapping(address => mapping(uint32 => uint)))
        public lastFillTime;

    /// @notice map of user address to their order
    /// @dev mapping of user  =>  tokenA  =>  tokenB  =>  period  =>  UserData
    mapping(address => mapping(address => mapping(address => mapping(uint32 => UserData))))
        public userDataMap;

    /// @notice mapping that provides the amount to fill for a pair + period key
    /// @dev mapping of tokenA  =>  tokenB  =>  period  =>  amountToFill
    mapping(address => mapping(address => mapping(uint32 => uint)))
        public amountToFillMap;

    /// @notice mapping that provides the amount to deduct for a pair + period + round key
    /// @dev mapping of tokenA  =>  tokenB  =>  period  =>  roundNumber  =>  amountToDeduct
    mapping(address => mapping(address => mapping(uint32 => mapping(uint => uint))))
        public amountToDeductMap;

    /// @notice the current round for a pair period
    /// @dev mapping of tokenA  =>  tokenB  =>  period  =>  currentRound for pair
    mapping(address => mapping(address => mapping(uint32 => uint64)))
        public currentRoundMap; // to uint64

    /// @notice round data for a pair period's round
    /// @dev mapping of tokenA  =>  tokenB  =>  period  =>  roundNumber  =>  RoundData
    mapping(address => mapping(address => mapping(uint32 => mapping(uint => RoundData))))
        public roundDataMap;

    /// @notice shares of token
    /// @dev token  =>  shares
    mapping(address => uint) public tokenShares;

    event Deposit(
        address user,
        address tokenA,
        address tokenB,
        uint32 period,
        uint amount,
        uint round,
        uint64 numRounds
    );
    event Withdraw(
        address user,
        address tokenA,
        address tokenB,
        uint32 period,
        uint amountA,
        uint amountB,
        uint round
    );
    event Modify(
        address user,
        address tokenA,
        address tokenB,
        uint32 period,
        uint amount,
        uint32 newPeriod,
        uint64 numRounds,
        bool unwrapEth,
        uint round,
        uint newPeriodRound
    );
    event Fill(
        address executor,
        address tokenA,
        address tokenB,
        uint32 period,
        uint amountIn,
        uint amountOut,
        uint rate
    );
    event CreatePair(
        address tokenA,
        address tokenB,
        uint32 period,
        uint pairId
    );

    /*
     * CONTRACT OWNER
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setFees(uint fillingFee_) external onlyOwner { 
        require(
            fillingFee_ <= 50, // filling fee can never be more than 5%
            "ERR: INVALID_FEE"
        );
        fillingFee = fillingFee_;
    }

    function pauseUnpause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
    /*
     * /CONTRACT OWNER
     */

    /// @notice deposit tokens to contract for DCA
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param amount total input amount
    /// @param numRounds number of periods to commit to
    function deposit(
        address tokenA,
        address tokenB,
        uint32 period,
        uint amount,
        uint64 numRounds
    ) external payable nonReentrant whenNotPaused {
        _deposit(tokenA, tokenB, period, amount, numRounds);
    }

    /// @notice withdraw tokens from contract
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param onlyFilled true to withdraw only filled orders
    /// @param unwrapEth whether to return in raw eth
    /// @param feeToken protocol fee discount token
    function withdraw(
        address tokenA,
        address tokenB,
        uint32 period,
        bool onlyFilled,
        bool unwrapEth,
        address feeToken
    ) external nonReentrant whenNotPaused {
        _withdraw(tokenA, tokenB, period, onlyFilled, unwrapEth, feeToken);
    }

    /// @notice modify existing order
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param amount new amount
    /// @param newPeriod new period
    /// @param numRounds new number of periods to commit to
    /// @param unwrapEth whether to unwrapEth on existing order
    /// @param feeToken protocol fee discount token
    function modify(
        address tokenA,
        address tokenB,
        uint32 period,
        uint amount,
        uint32 newPeriod,
        uint64 numRounds,
        bool unwrapEth,
        address feeToken
    ) external payable nonReentrant whenNotPaused {
        _withdraw(tokenA, tokenB, period, false, unwrapEth, feeToken);
        _deposit(tokenA, tokenB, newPeriod, amount, numRounds);

        emit Modify(msg.sender, tokenA, tokenB, period, amount, newPeriod, numRounds, unwrapEth, currentRoundMap[tokenA][tokenB][period], currentRoundMap[tokenA][tokenB][newPeriod]);
    }

    /// @notice used to fill existing order
    /// @dev as the required token and amounts are netted off, calling tokenA tokenB period & tokenB tokenA period would yield the same result
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param params params to pass on callback, ignored if length 0
    /// @return nett amount filled including searcher fee. This is the total amount pulled by the contract
    function fill(
        address tokenA,
        address tokenB,
        uint32 period,
        bytes memory params
    ) public nonReentrant whenNotPaused returns (uint) {
        require(
            block.timestamp >= lastFillTime[tokenA][tokenB][period] + period,
            "ERR: PERIOD_NOT_READY"
        );
        uint returnAmount;
        uint64 currentRound = currentRoundMap[tokenA][tokenB][period];
        // Gets the token and amount required for filling
        (
            address fillToken,
            uint nettFillAmount,
            uint rate,
            uint amountA,
            uint amountB,
            uint tokenADecimals
        ) = getFillPair(tokenA, tokenB, period, currentRound);

        uint fillingFeeAmount = (nettFillAmount * fillingFee) / DIVISOR;

        if (fillToken == tokenA) {
            // nettFillAmount is in tokenA

            // Optimistically transfer tokens to searcher
            returnAmount = (nettFillAmount * rate) / tokenADecimals;
            IERC20(tokenB).transfer(msg.sender, returnAmount);

            // Callback
            if (params.length > 0) {
                bool success = IFlashLoanReceiver(msg.sender).executeOperation(
                    tokenB,
                    returnAmount,
                    0,
                    params
                );
                require(success);
            }

            // Compute filled amounts
            amountA += nettFillAmount - fillingFeeAmount;
            amountB -= (nettFillAmount * rate) / tokenADecimals;

            // Update shares for the token
            tokenShares[tokenB] -= returnAmount;
            tokenShares[tokenA] += nettFillAmount - fillingFeeAmount;
        } else {
            // fillToken == tokenB
            // nettFillAmount is in tokenB

            // Optimistically transfer tokens to searcher
            returnAmount = (nettFillAmount * tokenADecimals) / rate;
            IERC20(tokenA).transfer(msg.sender, returnAmount);

            if (params.length > 0) {
                bool success = IFlashLoanReceiver(msg.sender).executeOperation(
                    tokenA,
                    returnAmount,
                    0,
                    params
                );
                require(success);
            }

            // Compute filled amounts
            amountB += nettFillAmount - fillingFeeAmount;
            amountA -= (nettFillAmount * tokenADecimals) / rate;

            // Update shares for the token
            tokenShares[tokenA] -= returnAmount;
            tokenShares[tokenB] += nettFillAmount - fillingFeeAmount;
        }

        // Transfer amount from searcher to contract
        IERC20(fillToken).transferFrom(
            msg.sender,
            address(this),
            nettFillAmount - fillingFeeAmount
        );
        emit Fill(
            msg.sender,
            tokenA,
            tokenB,
            period,
            nettFillAmount - fillingFeeAmount,
            returnAmount,
            rate
        );

        // Update fill time
        lastFillTime[tokenA][tokenB][period] = block.timestamp;
        lastFillTime[tokenB][tokenA][period] = block.timestamp;

        // Sync amount to buy for next round
        amountToFillMap[tokenA][tokenB][period] -= amountToDeductMap[tokenA][
            tokenB
        ][period][currentRound];
        amountToFillMap[tokenB][tokenA][period] -= amountToDeductMap[tokenB][
            tokenA
        ][period][currentRound];
        amountToDeductMap[tokenA][tokenB][period][currentRound] = 0;
        amountToDeductMap[tokenB][tokenA][period][currentRound] = 0;


        /// @dev the swap happens here
        // Update round data maps
        roundDataMap[tokenA][tokenB][period][currentRound] = RoundData({
            roundFilled: amountB,
            roundShares: amountToFillMap[tokenA][tokenB][period]
        });
        roundDataMap[tokenB][tokenA][period][currentRound] = RoundData({
            roundFilled: amountA,
            roundShares: amountToFillMap[tokenB][tokenA][period]
        });

        // Increment round
        currentRoundMap[tokenA][tokenB][period] += 1;
        currentRoundMap[tokenB][tokenA][period] += 1;

        return
            fillToken == tokenA
                ? (nettFillAmount - fillingFeeAmount) / rate
                : (nettFillAmount - fillingFeeAmount);
    }

    /// @notice getter for number of shares for a token pair period
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @return totalShares for period
    function totalShares(
        address tokenA,
        address tokenB,
        uint32 period
    ) public view returns (uint) {
        return (amountToFillMap[tokenA][tokenB][period] - amountToDeductMap[tokenA][tokenB][period][currentRoundMap[tokenA][tokenB][period]]);
    }

    /// @notice getter for user's filled and unfilled amounts
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param user address to check
    /// @return unfilledAmounts
    /// @return filledAmounts
    function getAmounts(
        address tokenA,
        address tokenB,
        uint32 period,
        address user
    ) public view returns (uint256, uint256) {
        UserData memory userData = userDataMap[user][tokenA][tokenB][period];
        if (userData.startRound > 0) {
            uint64 currentRound = currentRoundMap[tokenA][tokenB][period];
            uint sharesPerRound = userData.amount / userData.rounds;
            uint256 unfilledAmount;
            if (userData.startRound + userData.rounds > currentRound) {
                // if user rounds are still active
                unfilledAmount =
                    sharesPerRound *
                    (userData.startRound + userData.rounds - currentRound);
            }
            uint256 filledAmount;
            RoundData memory roundData;
            uint64 endRound = userData.startRound + userData.rounds <
                currentRound
                ? userData.startRound + userData.rounds
                : currentRound;

            for (uint i = userData.startRound; i < endRound; ) {
                roundData = roundDataMap[tokenA][tokenB][period][i];
                filledAmount += ((sharesPerRound * roundData.roundFilled) /
                    roundData.roundShares);
                unchecked {
                    ++i;
                }
            }
            return (unfilledAmount, filledAmount);
        } else {
            return (0, 0);
        }
    }

    /// @notice getter for computing the amount to fill
    /// @dev amount return doesn't include filler's fee
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param round round number, typically currentRound
    /// @return token address to fill
    /// @return amount to fill, excluding filler fee
    /// @return oracle rate
    /// @return total amountA
    /// @return total amountB
    /// @return tokenADecimals
    function getFillPair(
        address tokenA,
        address tokenB,
        uint32 period,
        uint round
    ) public view returns (address, uint, uint, uint, uint, uint) {
        // Nett off the amount to fill
        // We compute everything in tokenB
        
        // rateAB
        uint rate = _getPrice(tokenA, tokenB);
        uint tokenADecimals = 10 **
            pairIdMap[pairDataMap[tokenA][tokenB][period]].decimalA;

        uint amountA = ((amountToFillMap[tokenA][tokenB][period] -
            amountToDeductMap[tokenA][tokenB][period][round]) * rate) /
            tokenADecimals;        
        uint amountB = amountToFillMap[tokenB][tokenA][period] -
            amountToDeductMap[tokenB][tokenA][period][round];
        require(amountA > 0 || amountB > 0, "ERR: NO_ORDERS_TO_FILL");
        if (amountA > amountB) {
            // If amountA is larger, the nett deposit required is the difference in tokenB
            return (
                tokenB,
                (amountA - amountB),
                rate,
                (amountA * tokenADecimals) / rate,
                amountB,
                tokenADecimals
            );
        }
        // If amountB is larger, the nett deposit required is the difference in tokenA with the converted amount in tokenA
        return (
            tokenA,
            ((amountB - amountA) * tokenADecimals) / rate,
            rate,
            (amountA * tokenADecimals) / rate,
            amountB,
            tokenADecimals
        );
    }

    /// @notice internal function to get price from oracle
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @return rate of 1 tokenA to token B
    function _getPrice(
        address tokenA,
        address tokenB
    ) internal view returns (uint) {
        return
            IOracleAggregator(oracleAggregator).checkForPrice(tokenA, tokenB);
    }

    /// @notice internal function to check if user has a position
    /// @param user address to check
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @return true if user already has a position
    function _hasPosition(
        address user,
        address tokenA,
        address tokenB,
        uint32 period
    ) internal view returns (bool) {
        return userDataMap[user][tokenA][tokenB][period].startRound > 0;
    }

    /// @notice internal deposit function
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param amount total input amount
    /// @param numRounds number of periods to commit to
    function _deposit(
        address tokenA,
        address tokenB,
        uint32 period,
        uint amount,
        uint64 numRounds
    ) internal {
        require(
            feesInstance.depositStatus(STRATEGY_INDEX),
            "ERR: DEPOSITS_STOPPED"
        );
        if (msg.value > 0) {
            (bool success, ) = payable(wethAddress).call{value: msg.value}("");
            require(success, "ERR: WRAP_ETH_FAILED");

            tokenA = wethAddress;
            amount = msg.value;
        } else {
            IERC20(tokenA).transferFrom(msg.sender, address(this), amount);
        }

        // Only allow deposit if user has no existing position
        require(
            !_hasPosition(msg.sender, tokenA, tokenB, period),
            "ERR: EXISTING_POSITION"
        );

        /// @dev force amount to be divisible
        amount = (amount * numRounds) / numRounds;

        uint64 currentRound = currentRoundMap[tokenA][tokenB][period];

        // Check if pair already exists, else create & emit event
        if (currentRound == 0) {
            currentRoundMap[tokenA][tokenB][period] = 1;
            currentRoundMap[tokenB][tokenA][period] = 1;
            // Update fill time
            lastFillTime[tokenA][tokenB][period] = block.timestamp;
            lastFillTime[tokenB][tokenA][period] = block.timestamp;
            _createPairs(tokenA, tokenB, period);
            currentRound = 1;
        }

        uint amountPerRound = amount / numRounds;
        require(amountPerRound > 0, "ERR: INVALID_AMOUNT");

        // Update & save the user data
        userDataMap[msg.sender][tokenA][tokenB][period] = UserData({
            startRound: currentRound,
            rounds: numRounds,
            /*
                The amount deposited is the amount of shares the user has of the pool
                Money can be added to the pool via flash loans or other functionality we decide to introduce later
                Where the sitting capital is being used to generate yield
            */
            amount: amount
        });

        // Update round info
        /// @dev amountPerRound is derived from trfAmount which should not overflow
        // Update amount to purchase
        amountToFillMap[tokenA][tokenB][period] += amountPerRound;

        // Update amount to deduct
        amountToDeductMap[tokenA][tokenB][period][
            currentRound + numRounds
        ] += amountPerRound;

        // Bug: possible rounding issue, should use amount / numRounds * numRounds
        // Update amount of shares for the token
        tokenShares[tokenA] += amount;

        emit Deposit(
            msg.sender,
            tokenA,
            tokenB,
            period,
            amount,
            currentRound,
            numRounds
        );
    }

    /// @notice internal withdraw function
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    /// @param onlyFilled true to withdraw only filled orders
    /// @param unwrapEth whether to return in raw eth
    /// @param feeToken protocol fee discount token
    function _withdraw(
        address tokenA,
        address tokenB,
        uint32 period,
        bool onlyFilled,
        bool unwrapEth,
        address feeToken
    ) internal {
        // Only allow withdrawal if user has existing position
        require(
            _hasPosition(msg.sender, tokenA, tokenB, period),
            "ERR: MISSING_POSITION"
        );
        UserData memory userData = userDataMap[msg.sender][tokenA][tokenB][
            period
        ];
        uint64 currentRound = currentRoundMap[tokenA][tokenB][period];
        uint64 endRound = userData.startRound + userData.rounds < currentRound
            ? userData.startRound + userData.rounds
            : currentRound;
        (uint unfilledAmount, uint filledAmount) = getAmounts(
            tokenA,
            tokenB,
            period,
            msg.sender
        );

        if (unfilledAmount == 0) {
            onlyFilled = false;
        }

        if (!onlyFilled) {
            userDataMap[msg.sender][tokenA][tokenB][period] = UserData({
                startRound: 0,
                rounds: 0,
                amount: 0
            });

            // Update round info
            /// @dev amountPerRound is derived from trfAmount which should not overflow

            // Update amount to purchase
            uint amountPerRound = userData.amount / userData.rounds;
            if(currentRound <= endRound){
                /*
                    @dev if currentRound > endRound amountToFillMap -= amountToDeductMap
                    would already have been executed on fill call
                */
                amountToFillMap[tokenA][tokenB][period] -= amountPerRound;

                /// @dev the time of updating this doesn't matter as it is scoped to the round number
                // Update amount to deduct                    
                amountToDeductMap[tokenA][tokenB][period][
                    userData.startRound + userData.rounds
                ] -= amountPerRound;
                
                // Update amount of shares for the token
                tokenShares[tokenA] -= unfilledAmount;
            }

            // Transfer unfilled amounts
            _transfer(
                msg.sender,
                tokenA == wethAddress && unwrapEth ? address(0) : tokenA,
                unfilledAmount
            );
        } else {
            uint64 unfilledRounds = userDataMap[msg.sender][tokenA][tokenB][period].rounds - (currentRound - userDataMap[msg.sender][tokenA][tokenB][period].startRound);
            userDataMap[msg.sender][tokenA][tokenB][period] = UserData({
                startRound: currentRound,
                // Unfilled rounds
                rounds: unfilledRounds,
                amount: ((userDataMap[msg.sender][tokenA][tokenB][period].rounds - (currentRound - userDataMap[msg.sender][tokenA][tokenB][period].startRound)) * userDataMap[msg.sender][tokenA][tokenB][period].amount) / userDataMap[msg.sender][tokenA][tokenB][period].rounds
            });
        }
        
        // Send to user filledAmount
        if (filledAmount > 0) {
            uint fee = (filledAmount * feesInstance.calcFee(STRATEGY_INDEX, msg.sender, feeToken)) / DIVISOR;
            IERC20(tokenB).transfer(
                feesInstance.feeCollector(STRATEGY_INDEX),
                fee
            );
            _transfer(
                msg.sender,
                tokenB == wethAddress && unwrapEth ? address(0) : tokenB,
                filledAmount - fee
            );
            tokenShares[tokenB] -= filledAmount;
        }

        emit Withdraw(msg.sender, tokenA, tokenB, period, unfilledAmount, filledAmount, currentRound);
    }

    /// @notice internal function for transferring tokens / raw ether out of contract
    /// @param to address to transfer to
    /// @param token will process as raw eth if address(0)
    /// @param amount amount to transfer
    function _transfer(address to, address token, uint amount) internal {
        if(amount>0){
            if (token == address(0)) {
                IWETH(wethAddress).withdraw(amount);
                (bool success, ) = payable(msg.sender).call{value: amount}("");
                require(success, "ERR: UNWRAP_ETH_FAILED");
            } else {
                IERC20(token).transfer(to, amount);
            }
        }
    }

    /// @notice internal function to create pair
    /// @dev this function is only calledd the first time a pair period is introduced to the contract
    /// @param tokenA token to sell
    /// @param tokenB token to buy
    /// @param period purchase interval
    function _createPairs(
        address tokenA,
        address tokenB,
        uint32 period
    ) internal {
        require(tokenA != tokenB, "ERR: INVALID_TOKENS");

        ++numPairs;
        uint8 decimalA = IERC20(tokenA).decimals();
        uint8 decimalB = IERC20(tokenB).decimals();
        pairIdMap[numPairs] = PairData({
            tokenA: tokenA,
            tokenB: tokenB,
            decimalA: decimalA,
            decimalB: decimalB,
            period: period
        });
        pairDataMap[tokenA][tokenB][period] = numPairs;
        emit CreatePair(tokenA, tokenB, period, numPairs);

        ++numPairs;
        pairIdMap[numPairs] = PairData({
            tokenA: tokenB,
            tokenB: tokenA,
            decimalA: decimalB,
            decimalB: decimalA,
            period: period
        });
        pairDataMap[tokenB][tokenA][period] = numPairs;
        emit CreatePair(tokenB, tokenA, period, numPairs);
    }

    /// @dev fallback function to allow receving ether
    receive() external payable {}
}