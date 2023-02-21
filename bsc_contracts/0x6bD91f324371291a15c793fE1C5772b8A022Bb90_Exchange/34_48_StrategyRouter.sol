//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./deps/OwnableUpgradeable.sol";
import "./deps/Initializable.sol";
import "./deps/UUPSUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IUsdOracle.sol";
import {ReceiptNFT} from "./ReceiptNFT.sol";
import {Exchange} from "./exchange/Exchange.sol";
import {SharesToken} from "./SharesToken.sol";
import "./Batch.sol";
import "./StrategyRouterLib.sol";

// import "hardhat/console.sol";

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract StrategyRouter is Initializable, UUPSUpgradeable, OwnableUpgradeable, AutomationCompatibleInterface {
    /* EVENTS */

    /// @notice Fires when user deposits in batch.
    /// @param token Supported token that user want to deposit.
    /// @param amount Amount of `token` transferred from user.
    event Deposit(address indexed user, address token, uint256 amount);
    /// @notice Fires when batch is deposited into strategies.
    /// @param closedCycleId Index of the cycle that is closed.
    /// @param amount Sum of different tokens deposited into strategies.
    event AllocateToStrategies(uint256 indexed closedCycleId, uint256 amount);
    /// @notice Fires when compound process is finished.
    /// @param currentCycle Index of the current cycle.
    /// @param currentTvlInUsd Current TVL in USD.
    /// @param totalShares Current amount of shares.
    event AfterCompound(uint256 indexed currentCycle, uint256 currentTvlInUsd, uint256 totalShares);
    /// @notice Fires when user withdraw from strategies.
    /// @param token Supported token that user requested to receive after withdraw.
    /// @param amount Amount of `token` received by user.
    event WithdrawFromStrategies(address indexed user, address token, uint256 amount);
    /// @notice Fires when user converts his receipt into shares token.
    /// @param shares Amount of shares received by user.
    /// @param receiptIds Indexes of the receipts burned.
    event RedeemReceiptsToShares(address indexed user, uint256 shares, uint256[] receiptIds);
    /// @notice Fires when moderator converts foreign receipts into shares token.
    /// @param receiptIds Indexes of the receipts burned.
    event RedeemReceiptsToSharesByModerators(address indexed moderator, uint256[] receiptIds);

    /// @notice Fires when user withdraw from batch.
    /// @param user who initiated withdrawal.
    /// @param receiptIds original IDs of the corresponding deposited receipts (NFTs).
    /// @param token that is being withdrawn. can be one token multiple times.
    /// @param amount Amount of `token` received by user.
    event WithdrawFromBatch(address indexed user, uint256[] receiptIds, address[] token, uint256[] amount);

    // Events for setters.
    event SetMinDeposit(uint256 newAmount);
    event SetAllocationWindowTime(uint256 newDuration);
    event SetFeeAddress(address newAddress);
    event SetFeePercent(uint256 newPercent);
    event SetAddresses(
        Exchange _exchange,
        IUsdOracle _oracle,
        SharesToken _sharesToken,
        Batch _batch,
        ReceiptNFT _receiptNft
    );

    /* ERRORS */
    error AmountExceedTotalSupply();
    error UnsupportedToken();
    error NotReceiptOwner();
    error CycleNotClosed();
    error CycleClosed();
    error InsufficientShares();
    error DuplicateStrategy();
    error CycleNotClosableYet();
    error AmountNotSpecified();
    error CantRemoveLastStrategy();
    error NothingToRebalance();
    error NotModerator();
    error WithdrawnAmountLowerThanExpectedAmount();

    struct StrategyInfo {
        address strategyAddress;
        address depositToken;
        uint256 weight;
    }

    struct Cycle {
        // block.timestamp at which cycle started
        uint256 startAt;
        // batch USD value before deposited into strategies
        uint256 totalDepositedInUsd;
        // USD value received by strategies after all swaps necessary to ape into strategies
        uint256 receivedByStrategiesInUsd;
        // Protocol TVL after compound idle strategy and actual deposit to strategies
        uint256 strategiesBalanceWithCompoundAndBatchDepositsInUsd;
        // price per share in USD
        uint256 pricePerShare;
        // tokens price at time of the deposit to strategies
        mapping(address => uint256) prices;
    }

    uint8 private constant UNIFORM_DECIMALS = 18;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_FEE_PERCENT = 2000;
    uint256 private constant FEE_PERCENT_PRECISION = 100;
    // we do not try to withdraw amount below this threshold
    // cause gas spendings are high compared to this amount
    uint256 private constant WITHDRAWAL_DUST_THRESHOLD_USD = 1e17; // 10 cents / 0.1 USD

    /// @notice The time of the first deposit that triggered a current cycle
    uint256 public currentCycleFirstDepositAt;
    /// @notice Current cycle duration in seconds, until funds are allocated from batch to strategies
    uint256 public allocationWindowTime;
    /// @notice Current cycle counter. Incremented at the end of the cycle
    uint256 public currentCycleId;
    /// @notice Current cycle deposits counter. Incremented on deposit and decremented on withdrawal.
    uint256 public currentCycleDepositsCount;
    /// @notice Protocol comission in percents taken from yield. One percent is 100.
    uint256 public feePercent;

    ReceiptNFT private receiptContract;
    Exchange public exchange;
    IUsdOracle private oracle;
    SharesToken private sharesToken;
    Batch private batch;
    address public feeAddress;

    StrategyInfo[] public strategies;
    mapping(uint256 => Cycle) public cycles;
    mapping(address => bool) public moderators;

    modifier onlyModerators() {
        if (!moderators[msg.sender]) revert NotModerator();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // lock implementation
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        cycles[0].startAt = block.timestamp;
        allocationWindowTime = 1 hours;
        moderators[owner()] = true;
    }

    function setAddresses(
        Exchange _exchange,
        IUsdOracle _oracle,
        SharesToken _sharesToken,
        Batch _batch,
        ReceiptNFT _receiptNft
    ) external onlyOwner {
        exchange = _exchange;
        oracle = _oracle;
        sharesToken = _sharesToken;
        batch = _batch;
        receiptContract = _receiptNft;
        emit SetAddresses(_exchange, _oracle, _sharesToken, _batch, _receiptNft);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Universal Functions

    /// @notice Send pending money collected in the batch into the strategies.
    /// @notice Can be called when `allocationWindowTime` seconds has been passed or
    ///         batch usd value is more than zero.
    function allocateToStrategies() external {
        /*
        step 1 - preparing data and assigning local variables for later reference
        step 2 - check requirements to launch a cycle
            condition #1: deposit in the current cycle is greater than zero
        step 3 - store USD price of supported tokens as cycle information
        step 4 - collect yield and re-deposit/re-stake depending on strategy
        step 5 - rebalance token in batch to match our desired strategies ratio
        step 6 - batch transfers funds to strategies and strategies deposit tokens to their respective farms
        step 7 - we calculate share price for the current cycle and calculate a new amount of shares to issue

            Description:

                step 7.1 - Get previous TVL from previous cycle and calculate compounded profit: current TVL
                           minus previous cycle TVL. if current cycle = 0, then TVL = 0
                step 7.2 - Save corrected current TVL in Cycle[strategiesBalanceWithCompoundAndBatchDepositsInUsd] for the next cycle
                step 7.3 - Calculate price per share
                step 7.4 - Mint shares for the new protocol's deposits
                step 7.5 - Mint CLT for Clip's treasure address. CLT amount = fee / price per share

            Case example:

                Previous cycle strategies TVL = 1000 USD and total shares count is 1000 CLT
                Compound yield is 10 USD, hence protocol commission (protocolCommissionInUsd) is 10 USD * 20% = 2 USD
                TLV after compound is 1010 USD. TVL excluding platform's commission is 1008 USD

                Hence protocol commission in shares (protocolCommissionInShares) will be

                (1010 USD * 1000 CLT / (1010 USD - 2 USD)) - 1000 CLT = 1.98412698 CLT

        step 8 - Calculate protocol's comission and withhold commission by issuing share tokens
        step 9 - store remaining information for the current cycle
        */
        // step 1
        uint256 _currentCycleId = currentCycleId;
        (uint256 batchValueInUsd, ) = getBatchValueUsd();

        // step 2
        if (batchValueInUsd == 0) revert CycleNotClosableYet();

        currentCycleFirstDepositAt = 0;

        // step 3
        {
            address[] memory tokens = getSupportedTokens();
            for (uint256 i = 0; i < tokens.length; i++) {
                if (ERC20(tokens[i]).balanceOf(address(batch)) > 0) {
                    (uint256 priceUsd, uint8 priceDecimals) = oracle.getTokenUsdPrice(tokens[i]);
                    cycles[_currentCycleId].prices[tokens[i]] = StrategyRouterLib.changeDecimals(
                        priceUsd,
                        priceDecimals,
                        UNIFORM_DECIMALS
                    );
                }
            }
        }

        // step 4
        uint256 strategiesLength = strategies.length;
        for (uint256 i; i < strategiesLength; i++) {
            IStrategy(strategies[i].strategyAddress).compound();
        }

        (uint256 balanceAfterCompoundInUsd,) = getStrategiesValue();
        uint256 totalShares = sharesToken.totalSupply();
        emit AfterCompound(_currentCycleId, balanceAfterCompoundInUsd, totalShares);

        // step 5
        (uint256 strategiesBalanceAfterCompoundInUsd, ) = getStrategiesValue();
        uint256[] memory depositAmountsInTokens = batch.rebalance();

        // step 6
        for (uint256 i; i < strategiesLength; i++) {
            address strategyDepositToken = strategies[i].depositToken;

            if (depositAmountsInTokens[i] > 0) {
                batch.transfer(strategyDepositToken, strategies[i].strategyAddress, depositAmountsInTokens[i]);

                IStrategy(strategies[i].strategyAddress).deposit(depositAmountsInTokens[i]);
            }
        }

        // step 7
        (uint256 strategiesBalanceAfterDepositInUsd, ) = getStrategiesValue();
        uint256 receivedByStrategiesInUsd = strategiesBalanceAfterDepositInUsd - strategiesBalanceAfterCompoundInUsd;

        if (totalShares == 0) {
            sharesToken.mint(address(this), receivedByStrategiesInUsd);
            cycles[_currentCycleId].strategiesBalanceWithCompoundAndBatchDepositsInUsd = strategiesBalanceAfterDepositInUsd;
            cycles[_currentCycleId].pricePerShare = (strategiesBalanceAfterDepositInUsd * PRECISION) / sharesToken.totalSupply();
        } else {
            // step 7.1
            uint256 protocolCommissionInUsd = 0;
            if (strategiesBalanceAfterCompoundInUsd > cycles[_currentCycleId-1].strategiesBalanceWithCompoundAndBatchDepositsInUsd) {
                protocolCommissionInUsd = (strategiesBalanceAfterCompoundInUsd - cycles[_currentCycleId-1].strategiesBalanceWithCompoundAndBatchDepositsInUsd) * feePercent / (100 * FEE_PERCENT_PRECISION);
            }

            // step 7.2
            cycles[_currentCycleId].strategiesBalanceWithCompoundAndBatchDepositsInUsd = strategiesBalanceAfterDepositInUsd;
            // step 7.3
            cycles[_currentCycleId].pricePerShare = ((strategiesBalanceAfterCompoundInUsd - protocolCommissionInUsd) * PRECISION) / totalShares;

            // step 7.4
            uint256 newShares = (receivedByStrategiesInUsd * PRECISION) / cycles[_currentCycleId].pricePerShare;
            sharesToken.mint(address(this), newShares);

            // step 7.5
            uint256 protocolCommissionInShares = (protocolCommissionInUsd * PRECISION) / cycles[_currentCycleId].pricePerShare;
            sharesToken.mint(feeAddress, protocolCommissionInShares);
        }

        // step 8
        cycles[_currentCycleId].receivedByStrategiesInUsd = receivedByStrategiesInUsd;
        cycles[_currentCycleId].totalDepositedInUsd = batchValueInUsd;

        emit AllocateToStrategies(_currentCycleId, receivedByStrategiesInUsd);

        // step 9
        ++currentCycleId;
        currentCycleDepositsCount = 0;
        cycles[_currentCycleId].startAt = block.timestamp;
    }

    /// @notice Harvest yield from farms, and reinvest these rewards into strategies.
    /// @notice Part of the harvested rewards is taken as protocol comission.
    function compoundAll() external {
        if (sharesToken.totalSupply() == 0) revert();

        uint256 len = strategies.length;
        for (uint256 i; i < len; i++) {
            IStrategy(strategies[i].strategyAddress).compound();
        }

        (uint256 balanceAfterCompoundInUsd,) = getStrategiesValue();
        uint256 totalShares = sharesToken.totalSupply();
        emit AfterCompound(currentCycleId, balanceAfterCompoundInUsd, totalShares);
    }

    /// @dev Returns list of supported tokens.
    function getSupportedTokens() public view returns (address[] memory) {
        return batch.getSupportedTokens();
    }

    /// @dev Returns strategy weight as percent of total weight.
    function getStrategyPercentWeight(uint256 _strategyId) public view returns (uint256 strategyPercentAllocation) {
        return StrategyRouterLib.getStrategyPercentWeight(_strategyId, strategies);
    }

    /// @notice Returns count of strategies.
    function getStrategiesCount() public view returns (uint256 count) {
        return strategies.length;
    }

    /// @notice Returns array of strategies.
    function getStrategies() public view returns (StrategyInfo[] memory) {
        return strategies;
    }

    /// @notice Returns deposit token of the strategy.
    function getStrategyDepositToken(uint256 i) public view returns (address) {
        return strategies[i].depositToken;
    }

    /// @notice Returns usd value of the token balances and their sum in the strategies.
    /// @notice All returned amounts have `UNIFORM_DECIMALS` decimals.
    /// @return totalBalance Total usd value.
    /// @return balances Array of usd value of token balances.
    function getStrategiesValue() public view returns (uint256 totalBalance, uint256[] memory balances) {
        (totalBalance, balances) = StrategyRouterLib.getStrategiesValue(oracle, strategies);
    }

    /// @notice Returns usd values of the tokens balances and their sum in the batch.
    /// @notice All returned amounts have `UNIFORM_DECIMALS` decimals.
    /// @return totalBalance Total batch usd value.
    /// @return balances Array of usd value of token balances in the batch.
    function getBatchValueUsd() public view returns (uint256 totalBalance, uint256[] memory balances) {
        return batch.getBatchValueUsd();
    }

    /// @notice Returns stored address of the `Exchange` contract.
    function getExchange() public view returns (Exchange) {
        return exchange;
    }

    /// @notice Calculates amount of redeemable shares by burning receipts.
    /// @notice Cycle noted in receipts should be closed.
    function calculateSharesFromReceipts(uint256[] calldata receiptIds) public view returns (uint256 shares) {
        ReceiptNFT _receiptContract = receiptContract;
        uint256 _currentCycleId = currentCycleId;
        for (uint256 i = 0; i < receiptIds.length; i++) {
            uint256 receiptId = receiptIds[i];
            shares += StrategyRouterLib.calculateSharesFromReceipt(
                receiptId,
                _currentCycleId,
                _receiptContract,
                cycles
            );
        }
    }

    /// @notice Reedem shares for receipts on behalf of their owners.
    /// @notice Cycle noted in receipts should be closed.
    /// @notice Only callable by moderators.
    function redeemReceiptsToSharesByModerators(uint256[] calldata receiptIds) public onlyModerators {
        StrategyRouterLib.redeemReceiptsToSharesByModerators(
            receiptIds,
            currentCycleId,
            receiptContract,
            sharesToken,
            cycles
        );
        emit RedeemReceiptsToSharesByModerators(msg.sender, receiptIds);
    }

    /// @notice Calculate current usd value of shares.
    /// @dev Returned amount has `UNIFORM_DECIMALS` decimals.
    function calculateSharesUsdValue(uint256 amountShares) public view returns (uint256 amountUsd) {
        uint256 totalShares = sharesToken.totalSupply();
        if (amountShares > totalShares) revert AmountExceedTotalSupply();
        (uint256 strategiesLockedUsd, ) = getStrategiesValue();

        uint256 currentPricePerShare = (strategiesLockedUsd * PRECISION) / totalShares;

        return (amountShares * currentPricePerShare) / PRECISION;
    }

    /// @notice Calculate shares amount from usd value.
    /// @dev Returned amount has `UNIFORM_DECIMALS` decimals.
    function calculateSharesAmountFromUsdAmount(uint256 amount) public view returns (uint256 shares) {
        (uint256 strategiesLockedUsd, ) = getStrategiesValue();
        uint256 currentPricePerShare = (strategiesLockedUsd * PRECISION) / sharesToken.totalSupply();
        shares = (amount * PRECISION) / currentPricePerShare;
    }

    /// @notice Returns whether this token is supported.
    /// @param tokenAddress Token address to lookup.
    function supportsToken(address tokenAddress) public view returns (bool isSupported) {
        return batch.supportsToken(tokenAddress);
    }

    // User Functions

    /// @notice Convert receipts into share tokens.
    /// @notice Cycle noted in receipt should be closed.
    /// @return shares Amount of shares redeemed by burning receipts.
    function redeemReceiptsToShares(uint256[] calldata receiptIds) public returns (uint256 shares) {
        shares = StrategyRouterLib.burnReceipts(receiptIds, currentCycleId, receiptContract, cycles);
        sharesToken.transfer(msg.sender, shares);
        emit RedeemReceiptsToShares(msg.sender, shares, receiptIds);
    }

    /// @notice Withdraw tokens from strategies.
    /// @notice On partial withdraw leftover shares transferred to user.
    /// @notice If not enough shares unlocked from receipt, or no receipts are passed, then shares will be taken from user.
    /// @notice Receipts are burned.
    /// @notice Cycle noted in receipts should be closed.
    /// @param receiptIds Array of ReceiptNFT ids.
    /// @param withdrawToken Supported token that user wish to receive.
    /// @param shares Amount of shares to withdraw.
    function withdrawFromStrategies(
        uint256[] calldata receiptIds,
        address withdrawToken,
        uint256 shares,
        uint256 minTokenAmountToWithdraw
    ) external returns (uint256 withdrawnAmount) {
        if (shares == 0) revert AmountNotSpecified();
        if (!supportsToken(withdrawToken)) revert UnsupportedToken();

        // uint256 unlockedShares = StrategyRouterLib.burnReceipts(receiptIds, currentCycleId, receiptContract, cycles);
        ReceiptNFT _receiptContract = receiptContract;
        uint256 _currentCycleId = currentCycleId;
        uint256 unlockedShares;

        // first try to get all shares from receipts
        for (uint256 i = 0; i < receiptIds.length; i++) {
            uint256 receiptId = receiptIds[i];
            if (_receiptContract.ownerOf(receiptId) != msg.sender) revert NotReceiptOwner();
            uint256 receiptShares = StrategyRouterLib.calculateSharesFromReceipt(
                receiptId,
                _currentCycleId,
                _receiptContract,
                cycles
            );
            unlockedShares += receiptShares;
            if (unlockedShares > shares) {
                // receipts fulfilled requested shares and more,
                // so get rid of extra shares and update receipt amount
                uint256 leftoverShares = unlockedShares - shares;
                unlockedShares -= leftoverShares;

                ReceiptNFT.ReceiptData memory receipt = receiptContract.getReceipt(receiptId);
                uint256 newReceiptAmount = (receipt.tokenAmountUniform * leftoverShares) / receiptShares;
                _receiptContract.setAmount(receiptId, newReceiptAmount);
            } else {
                // unlocked shares less or equal to requested, so can take whole receipt amount
                _receiptContract.burn(receiptId);
            }
            if (unlockedShares == shares) break;
        }

        // if receipts didn't fulfilled requested shares amount, then try to take more from caller
        if (unlockedShares < shares) {
            // lack of shares -> get from user
            sharesToken.transferFromAutoApproved(msg.sender, address(this), shares - unlockedShares);
        }

        // shares into usd using current PPS
        uint256 usdToWithdraw = calculateSharesUsdValue(shares);
        sharesToken.burn(address(this), shares);

        // Withhold withdrawen amount from cycle's TVL, to not to affect AllocateToStrategies calculations in this cycle
        uint256 adjustPreviousCycleStrategiesBalanceByInUsd = shares * cycles[currentCycleId-1].pricePerShare / PRECISION;
        cycles[currentCycleId-1].strategiesBalanceWithCompoundAndBatchDepositsInUsd -= adjustPreviousCycleStrategiesBalanceByInUsd;

        withdrawnAmount = _withdrawFromStrategies(usdToWithdraw, withdrawToken, minTokenAmountToWithdraw);
    }

    /// @notice Withdraw tokens from batch.
    /// @notice Receipts are burned and user receives amount of tokens that was noted.
    /// @notice Cycle noted in receipts should be current cycle.
    /// @param _receiptIds Receipt NFTs ids.
    function withdrawFromBatch(uint256[] calldata _receiptIds) public {
        (uint256[] memory receiptIds, address[] memory tokens, uint256[] memory withdrawnTokenAmounts) =
            batch.withdraw(msg.sender, _receiptIds, currentCycleId);

        currentCycleDepositsCount -= receiptIds.length;
        if (currentCycleDepositsCount == 0) currentCycleFirstDepositAt = 0;

        emit WithdrawFromBatch(msg.sender, receiptIds, tokens, withdrawnTokenAmounts);
    }

    /// @notice Deposit token into batch.
    /// @param depositToken Supported token to deposit.
    /// @param _amount Amount to deposit.
    /// @dev User should approve `_amount` of `depositToken` to this contract.
    function depositToBatch(address depositToken, uint256 _amount) external {
        batch.deposit(msg.sender, depositToken, _amount, currentCycleId);
        IERC20(depositToken).transferFrom(msg.sender, address(batch), _amount);

        currentCycleDepositsCount++;
        if (currentCycleFirstDepositAt == 0) currentCycleFirstDepositAt = block.timestamp;

        emit Deposit(msg.sender, depositToken, _amount);
    }

    // Admin functions

    /// @notice Set token as supported for user deposit and withdraw.
    /// @dev Admin function.
    function setSupportedToken(address tokenAddress, bool supported) external onlyOwner {
        batch.setSupportedToken(tokenAddress, supported);
    }

    /// @notice Set wallets that will be moderators.
    /// @dev Admin function.
    function setModerator(address moderator, bool isWhitelisted) external onlyOwner {
        moderators[moderator] = isWhitelisted;
    }

    /// @notice Set address for fees collected by protocol.
    /// @dev Admin function.
    function setFeesCollectionAddress(address _feeAddress) external onlyOwner {
        if (_feeAddress == address(0)) revert();
        feeAddress = _feeAddress;
        emit SetFeeAddress(_feeAddress);
    }

    /// @notice Set percent to take from harvested rewards as protocol fee.
    /// @dev Admin function.
    function setFeesPercent(uint256 percent) external onlyOwner {
        require(percent <= MAX_FEE_PERCENT, "20% Max!");
        feePercent = percent;
        emit SetFeePercent(percent);
    }

    /// @notice Minimum to be deposited in the batch.
    /// @param amount Amount of usd, must be `UNIFORM_DECIMALS` decimals.
    /// @dev Admin function.
    function setMinDepositUsd(uint256 amount) external onlyOwner {
        batch.setMinDepositUsd(amount);
        emit SetMinDeposit(amount);
    }

    /// @notice Minimum time needed to be able to close the cycle.
    /// @param timeInSeconds Duration of cycle in seconds.
    /// @dev Admin function.
    function setAllocationWindowTime(uint256 timeInSeconds) external onlyOwner {
        allocationWindowTime = timeInSeconds;
        emit SetAllocationWindowTime(timeInSeconds);
    }

    /// @notice Add strategy.
    /// @param _strategyAddress Address of the strategy.
    /// @param _depositTokenAddress Token to be deposited into strategy.
    /// @param _weight Weight of the strategy. Used to split user deposit between strategies.
    /// @dev Admin function.
    /// @dev Deposit token must be supported by the router.
    function addStrategy(
        address _strategyAddress,
        address _depositTokenAddress,
        uint256 _weight
    ) external onlyOwner {
        if (!supportsToken(_depositTokenAddress)) revert UnsupportedToken();
        uint256 len = strategies.length;
        for (uint256 i = 0; i < len; i++) {
            if (strategies[i].strategyAddress == _strategyAddress) revert DuplicateStrategy();
        }

        strategies.push(
            StrategyInfo({
                strategyAddress: _strategyAddress,
                depositToken: IStrategy(_strategyAddress).depositToken(),
                weight: _weight
            })
        );
    }

    /// @notice Update strategy weight.
    /// @param _strategyId Id of the strategy.
    /// @param _weight New weight of the strategy.
    /// @dev Admin function.
    function updateStrategy(uint256 _strategyId, uint256 _weight) external onlyOwner {
        strategies[_strategyId].weight = _weight;
    }

    /// @notice Remove strategy and deposit its balance in other strategies.
    /// @notice Will revert when there is only 1 strategy left.
    /// @param _strategyId Id of the strategy.
    /// @dev Admin function.
    function removeStrategy(uint256 _strategyId) external onlyOwner {
        if (strategies.length < 2) revert CantRemoveLastStrategy();
        StrategyInfo memory removedStrategyInfo = strategies[_strategyId];
        IStrategy removedStrategy = IStrategy(removedStrategyInfo.strategyAddress);
        address removedDepositToken = removedStrategyInfo.depositToken;

        uint256 len = strategies.length - 1;
        strategies[_strategyId] = strategies[len];
        strategies.pop();

        // compound removed strategy
        removedStrategy.compound();

        // withdraw all from removed strategy
        uint256 withdrawnAmount = removedStrategy.withdrawAll();

        // compound all strategies
        for (uint256 i; i < len; i++) {
            IStrategy(strategies[i].strategyAddress).compound();
        }

        // deposit withdrawn funds into other strategies
        for (uint256 i; i < len; i++) {
            uint256 depositAmount = (withdrawnAmount * getStrategyPercentWeight(i)) / PRECISION;
            address strategyDepositToken = strategies[i].depositToken;

            depositAmount = StrategyRouterLib.trySwap(
                exchange,
                depositAmount,
                removedDepositToken,
                strategyDepositToken
            );
            IERC20(strategyDepositToken).transfer(strategies[i].strategyAddress, depositAmount);
            IStrategy(strategies[i].strategyAddress).deposit(depositAmount);
        }
        Ownable(address(removedStrategy)).transferOwnership(msg.sender);
    }

    /// @notice Rebalance batch, so that token balances will match strategies weight.
    /// @return balances Batch token balances after rebalancing.
    /// @dev Admin function.
    function rebalanceBatch() external onlyOwner returns (uint256[] memory balances) {
        return batch.rebalance();
    }

    /// @notice Rebalance strategies, so that their balances will match their weights.
    /// @return balances Balances of the strategies after rebalancing.
    /// @dev Admin function.
    function rebalanceStrategies() external onlyOwner returns (uint256[] memory balances) {
        return StrategyRouterLib.rebalanceStrategies(exchange, strategies);
    }

    /// @notice Checkes weither upkeep method is ready to be called.
    /// Method is compatible with AutomationCompatibleInterface from ChainLink smart contracts
    /// @return upkeepNeeded Returns weither upkeep method needs to be executed
    /// @dev Automation function
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = currentCycleFirstDepositAt > 0 && currentCycleFirstDepositAt + allocationWindowTime < block.timestamp;
    }

    function timestamp() external view returns (uint256 upkeepNeeded) {
        upkeepNeeded = block.timestamp;
    }

    /// @notice Execute upkeep routine that proxies to allocateToStrategies
    /// Method is compatible with AutomationCompatibleInterface from ChainLink smart contracts
    /// @dev Automation function
    function performUpkeep(bytes calldata) external override {
        this.allocateToStrategies();
    }

    // @dev Returns cycle data
    function getCycle(uint256 _cycleId) public view returns (
        uint256 startAt,
        uint256 totalDepositedInUsd,
        uint256 receivedByStrategiesInUsd,
        uint256 strategiesBalanceWithCompoundAndBatchDepositsInUsd,
        uint256 pricePerShare
    ) {
        Cycle storage requestedCycle = cycles[_cycleId];

        startAt = requestedCycle.startAt;
        totalDepositedInUsd = requestedCycle.totalDepositedInUsd;
        receivedByStrategiesInUsd = requestedCycle.receivedByStrategiesInUsd;
        strategiesBalanceWithCompoundAndBatchDepositsInUsd = requestedCycle.strategiesBalanceWithCompoundAndBatchDepositsInUsd;
        pricePerShare = requestedCycle.pricePerShare;
    }

    // Internals

    /// @param withdrawAmountUsd - USD value to withdraw. `UNIFORM_DECIMALS` decimals.
    /// @param withdrawToken Supported token to receive after withdraw.
    /// @param minTokenAmountToWithdraw min amount expected to be withdrawn
    /// @return tokenAmountToWithdraw amount of tokens that were actually withdrawn
    function _withdrawFromStrategies(uint256 withdrawAmountUsd, address withdrawToken, uint256 minTokenAmountToWithdraw)
        private
        returns (uint256 tokenAmountToWithdraw)
    {
        (, uint256[] memory strategyTokenBalancesUsd) = getStrategiesValue();
        uint256 strategiesCount = strategies.length;

        // find token to withdraw requested token without extra swaps
        // otherwise try to find token that is sufficient to fulfill requested amount
        uint256 supportedTokenId = type(uint256).max; // index of strategy, uint.max means not found
        {
            for (uint256 i; i < strategiesCount; i++) {
                address strategyDepositToken = strategies[i].depositToken;
                if (strategyTokenBalancesUsd[i] >= withdrawAmountUsd) {
                    supportedTokenId = i;
                    if (strategyDepositToken == withdrawToken) break;
                }
            }
        }

        if (supportedTokenId != type(uint256).max) {
            address tokenAddress = strategies[supportedTokenId].depositToken;
            (uint256 tokenUsdPrice, uint8 oraclePriceDecimals) = oracle.getTokenUsdPrice(tokenAddress);

            // convert usd to token amount
            tokenAmountToWithdraw = (withdrawAmountUsd * 10**oraclePriceDecimals) / tokenUsdPrice;
            // convert uniform decimals to token decimas
            tokenAmountToWithdraw = StrategyRouterLib.fromUniform(tokenAmountToWithdraw, tokenAddress);

            // withdraw from strategy
            tokenAmountToWithdraw = IStrategy(strategies[supportedTokenId].strategyAddress).withdraw(
                tokenAmountToWithdraw
            );
            // is withdrawn token not the one that's requested?
            if (tokenAddress != withdrawToken) {
                // swap withdrawn token to the requested one
                tokenAmountToWithdraw = StrategyRouterLib.trySwap(
                    exchange,
                    tokenAmountToWithdraw,
                    tokenAddress,
                    withdrawToken
                );
            }
            // we assume that the whole requested amount was withdrawn
            // we on purpose do not adjust for slippage, fees, etc
            // otherwise a user will be able to withdraw on Clip at better rates than on DEXes at other LPs expense
            // if the actual withdrawn amount (tokenAmountToWithdraw) doesn't meet the requested amount
            // then the slippage protection will revert execution at the end of this function
            // with WithdrawnAmountLowerThanExpectedAmount error
            withdrawAmountUsd = 0;
        }

        // if we didn't fulfilled withdraw amount above,
        // swap tokens one by one until withraw amount is fulfilled
        if (withdrawAmountUsd >= WITHDRAWAL_DUST_THRESHOLD_USD) {
            for (uint256 i; i < strategiesCount; i++) {
                address tokenAddress = strategies[i].depositToken;
                uint256 tokenAmountToSwap;
                (uint256 tokenUsdPrice, uint8 oraclePriceDecimals) = oracle.getTokenUsdPrice(tokenAddress);

                // at this moment its in USD
                tokenAmountToSwap = strategyTokenBalancesUsd[i] < withdrawAmountUsd
                    ? strategyTokenBalancesUsd[i]
                    : withdrawAmountUsd;
                unchecked {
                    // we assume that the whole requested amount was withdrawn
                    // we on purpose do not adjust for slippage, fees, etc
                    // otherwise a user will be able to withdraw on Clip at better rates than on DEXes at other LPs expense
                    // if not the whole amount withdrawn from a strategy the slippage protection will sort this out
                    withdrawAmountUsd -= tokenAmountToSwap;
                }

                // convert usd value into token amount
                tokenAmountToSwap = (tokenAmountToSwap * 10**oraclePriceDecimals) / tokenUsdPrice;
                // adjust decimals of the token amount
                tokenAmountToSwap = StrategyRouterLib.fromUniform(tokenAmountToSwap, tokenAddress);
                tokenAmountToSwap = IStrategy(strategies[i].strategyAddress).withdraw(tokenAmountToSwap);
                // swap for requested token
                tokenAmountToWithdraw += StrategyRouterLib.trySwap(
                    exchange,
                    tokenAmountToSwap,
                    tokenAddress,
                    withdrawToken
                );

                if (withdrawAmountUsd < WITHDRAWAL_DUST_THRESHOLD_USD) break;
            }
        }

        if (tokenAmountToWithdraw < minTokenAmountToWithdraw) {
            revert WithdrawnAmountLowerThanExpectedAmount();
        }

        IERC20(withdrawToken).transfer(msg.sender, tokenAmountToWithdraw);
        emit WithdrawFromStrategies(msg.sender, withdrawToken, tokenAmountToWithdraw);

        return tokenAmountToWithdraw;
    }
}