// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./config/Constant.sol";
import "./interfaces/IGlobalConfig.sol";
import "./interfaces/ICToken.sol";
import "./interfaces/ICETH.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Bank is BPYConstant, Initializable {
    using SafeMath for uint256;
    // globalConfig should be initialized per pool
    IGlobalConfig public globalConfig; // global configuration contract address

    // NOTICE struct to avoid below error:
    // "Contract has 16 states declarations but allowed no more than 15"
    struct BankConfig {
        address poolRegistry;
        // maxUtilToCalcBorrowAPR = 1 - rateCurveConstant / MaxBorrowAPR%
        // ex: minBorrowAPR% = 3%
        // MaxBorrowAPR% = 150%
        // rateCurveConstant = minBorrowAPR = 3
        // maxUtilToCalcBorrowAPR = 1 - 3 / 150 = 0.98 = 98%
        // variable stores value in format => 10^18 = 100%
        uint256 maxUtilToCalcBorrowAPR; // Max Utilization to Calculate Borrow APR
        // rateCurveConstantMultiplier = 1 / (1 - maxUtilToCalcBorrowAPR)
        // ex: maxUtilToCalcBorrowAPR = 0.98 = 98%
        // rateCurveConstantMultiplier = 1 / (1 - 0.98) = 50
        uint256 rateCurveConstantMultiplier;
    }

    // Bank Config to avoid errors
    BankConfig public bankConfig;
    // token => amount
    mapping(address => uint256) public totalLoans; // amount of lended tokens
    // token => amount
    mapping(address => uint256) public totalReserve; // amount of tokens in reservation
    // token => amount
    mapping(address => uint256) public totalCompound; // amount of tokens in compound
    // Token => block-num => rate
    mapping(address => mapping(uint256 => uint256)) public depositeRateIndex; // the index curve of deposit rate
    // Token => block-num => rate
    mapping(address => mapping(uint256 => uint256)) public borrowRateIndex; // the index curve of borrow rate
    // token address => block number
    mapping(address => uint256) public lastCheckpoint; // last checkpoint on the index curve
    // cToken address => rate
    mapping(address => uint256) public lastCTokenExchangeRate; // last compound cToken exchange rate
    mapping(address => ThirdPartyPool) public compoundPool; // the compound pool

    mapping(address => mapping(uint256 => uint256)) public depositFINRateIndex;
    mapping(address => mapping(uint256 => uint256)) public borrowFINRateIndex;
    mapping(address => uint256) public lastDepositFINRateCheckpoint;
    mapping(address => uint256) public lastBorrowFINRateCheckpoint;

    modifier onlyAuthorized() {
        require(
            msg.sender == address(globalConfig.savingAccount()) || msg.sender == address(globalConfig.accounts()),
            "Only authorized to call from DeFiner internal contracts."
        );
        _;
    }

    modifier onlyGlobalConfig() {
        require(msg.sender == address(globalConfig), "not authorized");
        _;
    }

    struct ThirdPartyPool {
        bool supported; // if the token is supported by the third party platforms such as Compound
        uint256 capitalRatio; // the ratio of the capital in third party to the total asset
        uint256 depositRatePerBlock; // the deposit rate of the token in third party
        uint256 borrowRatePerBlock; // the borrow rate of the token in third party
    }

    event UpdateIndex(address indexed token, uint256 depositeRateIndex, uint256 borrowRateIndex);
    event UpdateDepositFINIndex(address indexed _token, uint256 depositFINRateIndex);
    event UpdateBorrowFINIndex(address indexed _token, uint256 borrowFINRateIndex);

    /**
     * @notice The Bank contract is upgradeable, hence, constructor is not allowed.
     * But `BLOCKS_PER_YEAR` is `immutable` present in `BPYConstant` contract
     * threfore we need to initialize blocksPerYear from the constructor.
     * The `immutable` variables are also does not takes storage slot just like `constant`.
     * refer: https://docs.soliditylang.org/en/v0.8.4/contracts.html?#constant-and-immutable-state-variables
     **/
    // solhint-disable-next-line no-empty-blocks
    constructor(uint256 _blocksPerYear) BPYConstant(_blocksPerYear) {}

    /**
     * Initialize the Bank
     * @param _globalConfig the global configuration contract
     */
    function initialize(IGlobalConfig _globalConfig, address _poolRegistry) public initializer {
        globalConfig = _globalConfig;
        bankConfig.poolRegistry = _poolRegistry;
    }

    /**
     * @dev Configuration of Max Utilization to Calculate Borrow APR and rateCurveConstantMultiplier
     * is done only once from the PoolRegistry
     */
    function configureMaxUtilToCalcBorrowAPR(uint256 _maxBorrowAPR) external onlyGlobalConfig {
        // 1 - rateCurveConstant / MaxBorrowAPR
        // ex:
        // rateCurveConstant = 3e16 = 3%
        // _maxBorrowAPR = 150e16 = 150%
        // maxUtilToCalcBorrowAPR = 1e18 - ((3e16 * 1e18) / 150e16) = 980_000_000_000_000_000 = 0.98 = 98%
        uint256 maxUtilToCalcBorrowAPR = INT_UNIT - ((globalConfig.rateCurveConstant() * INT_UNIT) / _maxBorrowAPR);

        // rateCurveConstantMultiplier = 1 / (1 - maxUtilToCalcBorrowAPR)
        // rateCurveConstantMultiplier = 1e18 / (1e18 - maxUtilToCalcBorrowAPR)
        // but to keep value in 18 decimal, multiply hence
        // rateCurveConstantMultiplier = (1e18 * 1e18) / (1e18 - maxUtilToCalcBorrowAPR)
        // above calculation results in multiplier in 18 decimals, so that we can avoid decimal truncation
        // when maxUtilToCalcBorrowAPR is in lower bound
        // ex:
        // maxUtilToCalcBorrowAPR = 980_000_000_000_000_000 = 0.98 = 98%
        // rateCurveConstantMultiplier
        //      = (1e18 * 1e18) / (1e18 - 980_000_000_000_000_000) = 50_000_000_000_000_000_000 = 50
        bankConfig.rateCurveConstantMultiplier = (INT_UNIT * INT_UNIT) / (INT_UNIT - maxUtilToCalcBorrowAPR);

        // stored at last to avoid storage read
        bankConfig.maxUtilToCalcBorrowAPR = maxUtilToCalcBorrowAPR;
    }

    /**
     * Total amount of the token in Saving account
     * @param _token token address
     */
    function getTotalDepositStore(address _token) public view returns (uint256) {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        // totalLoans[_token] = U   totalReserve[_token] = R
        // return totalAmount = C + U + R
        return totalCompound[cToken].add(totalLoans[_token]).add(totalReserve[_token]);
    }

    /**
     * Update total amount of token in Compound as the cToken price changed
     * @param _token token address
     */
    function updateTotalCompound(address _token) internal {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        if (cToken != address(0)) {
            totalCompound[cToken] = ICToken(cToken).balanceOfUnderlying(address(globalConfig.savingAccount()));
        }
    }

    /**
     * Update the total reservation. Before run this function, make sure that totalCompound has been updated
     * by calling updateTotalCompound. Otherwise, totalCompound may not equal to the exact amount of the
     * token in Compound.
     * @param _token token address
     * @param _action indicate if user's operation is deposit or withdraw, and borrow or repay.
     * @return compoundAmount the actual amount deposit/withdraw from the saving pool
     */
    // solhint-disable-next-line code-complexity
    function updateTotalReserve(
        address _token,
        uint256 _amount,
        ActionType _action
    ) internal returns (uint256 compoundAmount) {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        uint256 totalAmount = getTotalDepositStore(_token);
        if (_action == ActionType.DepositAction || _action == ActionType.RepayAction) {
            // Total amount of token after deposit or repay
            if (_action == ActionType.DepositAction) {
                totalAmount = totalAmount.add(_amount);
            } else {
                totalLoans[_token] = totalLoans[_token].sub(_amount);
            }

            // Expected total amount of token in reservation after deposit or repay
            uint256 totalReserveBeforeAdjust = totalReserve[_token].add(_amount);

            if (
                cToken != address(0) &&
                totalReserveBeforeAdjust > totalAmount.mul(globalConfig.maxReserveRatio()).div(100)
            ) {
                uint256 toCompoundAmount = totalReserveBeforeAdjust.sub(
                    totalAmount.mul(globalConfig.midReserveRatio()).div(100)
                );
                //toCompound(_token, toCompoundAmount);
                compoundAmount = toCompoundAmount;
                totalCompound[cToken] = totalCompound[cToken].add(toCompoundAmount);
                totalReserve[_token] = totalReserve[_token].add(_amount).sub(toCompoundAmount);
            } else {
                totalReserve[_token] = totalReserve[_token].add(_amount);
            }
        } else if (_action == ActionType.LiquidateRepayAction) {
            // When liquidation is called the `totalLoans` amount should be reduced.
            // We dont need to update other variables as all the amounts are adjusted internally,
            // hence does not require updation of `totalReserve` / `totalCompound`
            totalLoans[_token] = totalLoans[_token].sub(_amount);
        } else {
            // The lack of liquidity exception happens when the pool doesn't have enough tokens for borrow/withdraw
            // It happens when part of the token has lended to the other accounts.
            // However in case of withdrawAll, even if the token has no loan, this requirment may still false because
            // of the precision loss in the rate calcuation. So we put a logic here to deal with this case: in case
            // of withdrawAll and there is no loans for the token, we just adjust the balance in bank contract to the
            // to the balance of that individual account.
            if (_action == ActionType.WithdrawAction) {
                if (totalLoans[_token] != 0) {
                    require(getPoolAmount(_token) >= _amount, "Lack of liquidity when withdraw.");
                } else if (getPoolAmount(_token) < _amount) {
                    totalReserve[_token] = _amount.sub(totalCompound[cToken]);
                }
                totalAmount = getTotalDepositStore(_token);
            } else require(getPoolAmount(_token) >= _amount, "Lack of liquidity when borrow.");

            // Total amount of token after withdraw or borrow
            if (_action == ActionType.WithdrawAction) {
                totalAmount = totalAmount.sub(_amount);
            } else {
                totalLoans[_token] = totalLoans[_token].add(_amount);
            }

            // Expected total amount of token in reservation after deposit or repay
            uint256 totalReserveBeforeAdjust = totalReserve[_token] > _amount ? totalReserve[_token].sub(_amount) : 0;

            // Trigger fromCompound if the new reservation ratio is less than 10%
            if (
                cToken != address(0) &&
                (totalAmount == 0 ||
                    totalReserveBeforeAdjust < totalAmount.mul(globalConfig.minReserveRatio()).div(100))
            ) {
                uint256 totalAvailable = totalReserve[_token].add(totalCompound[cToken]).sub(_amount);
                if (totalAvailable < totalAmount.mul(globalConfig.midReserveRatio()).div(100)) {
                    // Withdraw all the tokens from Compound
                    compoundAmount = totalCompound[cToken];
                    totalCompound[cToken] = 0;
                    totalReserve[_token] = totalAvailable;
                } else {
                    // Withdraw partial tokens from Compound
                    uint256 totalInCompound = totalAvailable.sub(
                        totalAmount.mul(globalConfig.midReserveRatio()).div(100)
                    );
                    compoundAmount = totalCompound[cToken].sub(totalInCompound);
                    totalCompound[cToken] = totalInCompound;
                    totalReserve[_token] = totalAvailable.sub(totalInCompound);
                }
            } else {
                totalReserve[_token] = totalReserve[_token].sub(_amount);
            }
        }
        return compoundAmount;
    }

    function update(
        address _token,
        uint256 _amount,
        ActionType _action
    ) public onlyAuthorized returns (uint256 compoundAmount) {
        updateTotalCompound(_token);
        // updateTotalLoan(_token);
        compoundAmount = updateTotalReserve(_token, _amount, _action);
        return compoundAmount;
    }

    /**
     * The function is called in Bank.deposit(), Bank.withdraw() and Accounts.claim() functions.
     * The function should be called AFTER the newRateIndexCheckpoint function so that the account balances are
     * accurate, and BEFORE the account balance acutally updated due to deposit/withdraw activities.
     */
    function updateDepositFINIndex(address _token) public onlyAuthorized {
        uint256 currentBlock = getBlockNumber();
        uint256 deltaBlock;
        // If it is the first deposit FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on depositFINRateIndex is zero.
        deltaBlock = lastDepositFINRateCheckpoint[_token] == 0
            ? 0
            : currentBlock.sub(lastDepositFINRateCheckpoint[_token]);
        // If the totalDeposit of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        depositFINRateIndex[_token][currentBlock] = depositFINRateIndex[_token][lastDepositFINRateCheckpoint[_token]]
            .add(
                getTotalDepositStore(_token) == 0
                    ? 0
                    : depositeRateIndex[_token][lastCheckpoint[_token]]
                        .mul(deltaBlock)
                        .mul(globalConfig.tokenRegistry().depositeMiningSpeeds(_token))
                        .div(getTotalDepositStore(_token))
            );
        lastDepositFINRateCheckpoint[_token] = currentBlock;

        emit UpdateDepositFINIndex(_token, depositFINRateIndex[_token][currentBlock]);
    }

    function updateBorrowFINIndex(address _token) public onlyAuthorized {
        uint256 currentBlock = getBlockNumber();
        uint256 deltaBlock;
        // If it is the first borrow FIN rate checkpoint, set the deltaBlock value be 0 so that the first
        // point on borrowFINRateIndex is zero.
        deltaBlock = lastBorrowFINRateCheckpoint[_token] == 0
            ? 0
            : currentBlock.sub(lastBorrowFINRateCheckpoint[_token]);
        // If the totalBorrow of the token is zero, no FIN token should be mined and the FINRateIndex is unchanged.
        borrowFINRateIndex[_token][currentBlock] = borrowFINRateIndex[_token][lastBorrowFINRateCheckpoint[_token]].add(
            totalLoans[_token] == 0
                ? 0
                : borrowRateIndex[_token][lastCheckpoint[_token]]
                    .mul(deltaBlock)
                    .mul(globalConfig.tokenRegistry().borrowMiningSpeeds(_token))
                    .div(totalLoans[_token])
        );
        lastBorrowFINRateCheckpoint[_token] = currentBlock;

        emit UpdateBorrowFINIndex(_token, borrowFINRateIndex[_token][currentBlock]);
    }

    function updateMining(address _token) public onlyAuthorized {
        newRateIndexCheckpoint(_token);
        updateTotalCompound(_token);
    }

    /**
     * Get the borrowing interest rate.
     * @param _token token address
     * @return the borrow rate for the current block
     */
    function getBorrowRatePerBlock(address _token) public view returns (uint256) {
        uint256 capitalUtilizationRatio = getCapitalUtilizationRatio(_token);
        // rateCurveConstant = <'3 * (10)^16'_rateCurveConstant_configurable>
        uint256 rateCurveConstant = globalConfig.rateCurveConstant();
        // compoundSupply = Compound Supply Rate * <'0.4'_supplyRateWeights_configurable>
        uint256 compoundSupply = compoundPool[_token].depositRatePerBlock.mul(globalConfig.compoundSupplyRateWeights());
        // compoundBorrow = Compound Borrow Rate * <'0.6'_borrowRateWeights_configurable>
        uint256 compoundBorrow = compoundPool[_token].borrowRatePerBlock.mul(globalConfig.compoundBorrowRateWeights());
        // nonUtilizedCapRatio = (1 - U) // Non utilized capital ratio
        uint256 nonUtilizedCapRatio = INT_UNIT.sub(capitalUtilizationRatio);

        bool isSupportedOnCompound = globalConfig.tokenRegistry().isSupportedOnCompound(_token);
        if (isSupportedOnCompound) {
            uint256 compoundSupplyPlusBorrow = compoundSupply.add(compoundBorrow).div(10);
            uint256 rateConstant;
            // if the token is supported in third party (like Compound), check if U = 1
            if (capitalUtilizationRatio > bankConfig.maxUtilToCalcBorrowAPR) {
                // > 0.999
                // if U = 1,
                // borrowing rate =
                //  compoundSupply + compoundBorrow +
                //  ((rateCurveConstant * rateCurveConstantMultiplier) / BLOCKS_PER_YEAR).div(INT_UNIT)

                // NOTICE: rateCurveConstantMultiplier is in 18 decimals, to normalize
                // it divide by INT_UNIT after multiplication
                rateConstant = rateCurveConstant.mul(bankConfig.rateCurveConstantMultiplier).div(BLOCKS_PER_YEAR).div(
                    INT_UNIT
                );
                return compoundSupplyPlusBorrow.add(rateConstant);
            } else {
                // if U != 1,
                // borrowing rate = compoundSupply + compoundBorrow + ((rateCurveConstant / (1 - U)) / BLOCKS_PER_YEAR)
                rateConstant = rateCurveConstant.mul(10**18).div(nonUtilizedCapRatio).div(BLOCKS_PER_YEAR);
                return compoundSupplyPlusBorrow.add(rateConstant);
            }
        } else {
            // If the token is NOT supported by the third party, check if U = 1
            if (capitalUtilizationRatio > bankConfig.maxUtilToCalcBorrowAPR) {
                // > 0.999
                // if U = 1, borrowing rate = rateCurveConstant * rateCurveConstantMultiplier

                // NOTICE: rateCurveConstantMultiplier is in 18 decimals, to normalize
                // it divide by INT_UNIT after multiplication
                return rateCurveConstant.mul(bankConfig.rateCurveConstantMultiplier).div(BLOCKS_PER_YEAR).div(INT_UNIT);
            } else {
                // if 0 < U < 1, borrowing rate = 3% / (1 - U)
                return rateCurveConstant.mul(10**18).div(nonUtilizedCapRatio).div(BLOCKS_PER_YEAR);
            }
        }
    }

    /**
     * Get Deposit Rate.  Deposit APR = (Borrow APR * Utilization Rate (U) +  Compound Supply Rate *
     * Capital Compound Ratio (C) )* (1- DeFiner Community Fund Ratio (D)). The scaling is 10 ** 18
     * @param _token token address
     * @return deposite rate of blocks before the current block
     */
    function getDepositRatePerBlock(address _token) public view returns (uint256) {
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        uint256 capitalUtilRatio = getCapitalUtilizationRatio(_token);
        if (!globalConfig.tokenRegistry().isSupportedOnCompound(_token))
            return borrowRatePerBlock.mul(capitalUtilRatio).div(INT_UNIT);

        return
            borrowRatePerBlock
                .mul(capitalUtilRatio)
                .add(compoundPool[_token].depositRatePerBlock.mul(compoundPool[_token].capitalRatio))
                .div(INT_UNIT);
    }

    /**
     * Get capital utilization. Capital Utilization Rate (U )= total loan outstanding / Total market deposit
     * @param _token token address
     * @return Capital utilization ratio `U`.
     *  Valid range: 0 ≤ U ≤ 10^18
     */
    function getCapitalUtilizationRatio(address _token) public view returns (uint256) {
        uint256 totalDepositsNow = getTotalDepositStore(_token);
        if (totalDepositsNow == 0) {
            return 0;
        } else {
            return totalLoans[_token].mul(INT_UNIT).div(totalDepositsNow);
        }
    }

    /**
     * Ratio of the capital in Compound
     * @param _token token address
     */
    function getCapitalCompoundRatio(address _token) public view returns (uint256) {
        address cToken = globalConfig.tokenRegistry().getCToken(_token);
        if (totalCompound[cToken] == 0) {
            return 0;
        } else {
            return uint256(totalCompound[cToken].mul(INT_UNIT).div(getTotalDepositStore(_token)));
        }
    }

    /**
     * It's a utility function. Get the cummulative deposit rate in a block interval ending in current block
     * @param _token token address
     * @param _depositRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getDepositAccruedRate(address _token, uint256 _depositRateRecordStart) external view returns (uint256) {
        uint256 depositRate = depositeRateIndex[_token][_depositRateRecordStart];
        require(depositRate != 0, "_depositRateRecordStart is not a check point on index curve.");
        return depositeRateIndexNow(_token).mul(INT_UNIT).div(depositRate);
    }

    /**
     * Get the cummulative borrow rate in a block interval ending in current block
     * @param _token token address
     * @param _borrowRateRecordStart the start block of the interval
     * @dev This function should always be called after current block is set as a new rateIndex point.
     */
    function getBorrowAccruedRate(address _token, uint256 _borrowRateRecordStart) external view returns (uint256) {
        uint256 borrowRate = borrowRateIndex[_token][_borrowRateRecordStart];
        require(borrowRate != 0, "_borrowRateRecordStart is not a check point on index curve.");
        return borrowRateIndexNow(_token).mul(INT_UNIT).div(borrowRate);
    }

    /**
     * Set a new rate index checkpoint.
     * @param _token token address
     * @dev The rate set at the checkpoint is the rate from the last checkpoint to this checkpoint
     */
    function newRateIndexCheckpoint(address _token) public onlyAuthorized {
        // return if the rate check point already exists
        uint256 blockNumber = getBlockNumber();
        if (blockNumber == lastCheckpoint[_token]) return;

        address cToken = globalConfig.tokenRegistry().getCToken(_token);

        // If it is the first check point, initialize the rate index
        uint256 previousCheckpoint = lastCheckpoint[_token];
        if (lastCheckpoint[_token] == 0) {
            if (cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = INT_UNIT;
                depositeRateIndex[_token][blockNumber] = INT_UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            } else {
                compoundPool[_token].supported = true;
                uint256 cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock(); // initial value
                compoundPool[_token].depositRatePerBlock = ICToken(cToken).supplyRatePerBlock(); // initial value
                borrowRateIndex[_token][blockNumber] = INT_UNIT;
                depositeRateIndex[_token][blockNumber] = INT_UNIT;
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }
        } else {
            if (cToken == address(0)) {
                compoundPool[_token].supported = false;
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositeRateIndex[_token][blockNumber] = depositeRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
            } else {
                compoundPool[_token].supported = true;
                uint256 cTokenExchangeRate = ICToken(cToken).exchangeRateCurrent();
                // Get the curretn cToken exchange rate in Compound, which is need to calculate DeFiner's rate
                compoundPool[_token].capitalRatio = getCapitalCompoundRatio(_token);
                compoundPool[_token].borrowRatePerBlock = ICToken(cToken).borrowRatePerBlock();
                compoundPool[_token].depositRatePerBlock = cTokenExchangeRate
                    .mul(INT_UNIT)
                    .div(lastCTokenExchangeRate[cToken])
                    .sub(INT_UNIT)
                    .div(blockNumber.sub(lastCheckpoint[_token]));
                borrowRateIndex[_token][blockNumber] = borrowRateIndexNow(_token);
                depositeRateIndex[_token][blockNumber] = depositeRateIndexNow(_token);
                // Update the last checkpoint
                lastCheckpoint[_token] = blockNumber;
                lastCTokenExchangeRate[cToken] = cTokenExchangeRate;
            }
        }

        // Update the total loan
        if (borrowRateIndex[_token][blockNumber] != INT_UNIT) {
            totalLoans[_token] = totalLoans[_token].mul(borrowRateIndex[_token][blockNumber]).div(
                borrowRateIndex[_token][previousCheckpoint]
            );
        }

        emit UpdateIndex(
            _token,
            depositeRateIndex[_token][getBlockNumber()],
            borrowRateIndex[_token][getBlockNumber()]
        );
    }

    /**
     * Calculate a token deposite rate of current block
     * @param _token token address
     * @dev This is an looking forward estimation from last checkpoint and not the exactly rate
     *      that the user will pay or earn.
     */
    function depositeRateIndexNow(address _token) public view returns (uint256) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if (lcp == 0) return INT_UNIT;

        uint256 lastDepositeRateIndex = depositeRateIndex[_token][lcp];
        uint256 depositRatePerBlock = getDepositRatePerBlock(_token);
        // newIndex = oldIndex*(1+r*delta_block).
        // If delta_block = 0, i.e. the last checkpoint is current block, index doesn't change.
        return
            lastDepositeRateIndex.mul(getBlockNumber().sub(lcp).mul(depositRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
     * Calculate a token borrow rate of current block
     * @param _token token address
     */
    function borrowRateIndexNow(address _token) public view returns (uint256) {
        uint256 lcp = lastCheckpoint[_token];
        // If this is the first checkpoint, set the index be 1.
        if (lcp == 0) return INT_UNIT;
        uint256 lastBorrowRateIndex = borrowRateIndex[_token][lcp];
        uint256 borrowRatePerBlock = getBorrowRatePerBlock(_token);
        return lastBorrowRateIndex.mul(getBlockNumber().sub(lcp).mul(borrowRatePerBlock).add(INT_UNIT)).div(INT_UNIT);
    }

    /**
     * Get the state of the given token
     * @param _token token address
     */
    function getTokenState(address _token)
        public
        view
        returns (
            uint256 deposits,
            uint256 loans,
            uint256 reserveBalance,
            uint256 remainingAssets
        )
    {
        return (
            getTotalDepositStore(_token),
            totalLoans[_token],
            totalReserve[_token],
            totalReserve[_token].add(totalCompound[globalConfig.tokenRegistry().getCToken(_token)])
        );
    }

    function getPoolAmount(address _token) public view returns (uint256) {
        return totalReserve[_token].add(totalCompound[globalConfig.tokenRegistry().getCToken(_token)]);
    }

    function deposit(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyAuthorized {
        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Update tokenInfo. Add the _amount to principal, and update the last deposit block in tokenInfo
        globalConfig.accounts().deposit(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, _amount, ActionType.DepositAction);

        if (compoundAmount > 0) {
            globalConfig.savingAccount().toCompound(_token, compoundAmount);
        }
    }

    function borrow(
        address _from,
        address _token,
        uint256 _amount
    ) external onlyAuthorized {
        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Update tokenInfo for the user
        globalConfig.accounts().borrow(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, _amount, ActionType.BorrowAction);

        if (compoundAmount > 0) {
            globalConfig.savingAccount().fromCompound(_token, compoundAmount);
        }
    }

    function repay(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyAuthorized returns (uint256) {
        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateBorrowFINIndex(_token);

        // Sanity check
        require(globalConfig.accounts().getBorrowPrincipal(_to, _token) > 0, "Token BorrowPrincipal must be > 0");

        // Update tokenInfo
        uint256 remain = globalConfig.accounts().repay(_to, _token, _amount);

        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, _amount.sub(remain), ActionType.RepayAction);
        if (compoundAmount > 0) {
            globalConfig.savingAccount().toCompound(_token, compoundAmount);
        }

        // Return actual amount repaid
        return _amount.sub(remain);
    }

    /**
     * Withdraw a token from an address
     * @param _from address to be withdrawn from
     * @param _token token address
     * @param _amount amount to be withdrawn
     * @return The actually amount withdrawed, which will be the amount requested minus the commission fee.
     */
    function withdraw(
        address _from,
        address _token,
        uint256 _amount
    ) external onlyAuthorized returns (uint256) {
        require(_amount != 0, "Amount is zero");

        // Add a new checkpoint on the index curve.
        newRateIndexCheckpoint(_token);
        updateDepositFINIndex(_token);

        // Withdraw from the account
        uint256 amount = globalConfig.accounts().withdraw(_from, _token, _amount);

        // Update pool balance
        // Update the amount of tokens in compound and loans, i.e. derive the new values
        // of C (Compound Ratio) and U (Utilization Ratio).
        uint256 compoundAmount = update(_token, amount, ActionType.WithdrawAction);

        // Check if there are enough tokens in the pool.
        if (compoundAmount > 0) {
            globalConfig.savingAccount().fromCompound(_token, compoundAmount);
        }

        return amount;
    }

    /**
     * Get current block number
     * @return the current block number
     */
    function getBlockNumber() private view returns (uint256) {
        return block.number;
    }

    function version() public pure returns (string memory) {
        return "v2.0.0";
    }
}