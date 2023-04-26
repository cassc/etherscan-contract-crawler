// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./../../../utils/UpgradeableBase.sol";
import "./../../../interfaces/IXToken.sol";
import "./../../../interfaces/ICompound.sol";
import "./../../../interfaces/IMultiLogicProxy.sol";
import "./../../../interfaces/ILogicContract.sol";
import "./../../../interfaces/IStrategyStatistics.sol";
import "./../../../interfaces/IStrategyContract.sol";

contract OlaStrategy is UpgradeableBase, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RewardsTokenPriceInfo {
        uint256 latestAnswer;
        uint256 timestamp;
    }

    address internal constant ZERO_ADDRESS = address(0);
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant BASE = 10**DECIMALS;

    address public logic;
    address public blid;
    address public strategyXToken;
    address public strategyToken;
    address public comptroller;
    address public rewardsToken;

    // Strategy Parameter
    uint8 public circlesCount;
    uint8 public avoidLiquidationFactor;

    uint256 private minStorageAvailable;
    uint256 public borrowRateMin;
    uint256 public borrowRateMax;

    address public multiLogicProxy;
    address public strategyStatistics;

    // RewardsTokenPrice kill switch
    uint256 public rewardsTokenPriceDeviationLimit; // percentage, decimal = 18
    RewardsTokenPriceInfo private rewardsTokenPriceInfo;

    // Swap Rewards to BLID
    address public swapRouter_RewardsToBLID;
    address[] public path_RewardsToBLID;

    // Swap Rewards to StrategyToken
    address public swapRouter_RewardsToStrategyToken;
    address[] public path_RewardsToStrategyToken;

    // Swap StrategyToken to BLID
    address public swapRouter_StrategyTokenToBLID;
    address[] public path_StrategyTokenToBLID;

    uint256 minimumBLIDPerRewardToken;
    uint256 minRewardsSwapLimit;

    event SetBLID(address blid);
    event SetCirclesCount(uint8 circlesCount);
    event SetAvoidLiquidationFactor(uint8 avoidLiquidationFactor);
    event SetMinRewardsSwapLimit(uint256 _minRewardsSwapLimit);
    event SetStrategyXToken(address strategyXToken);
    event SetMinStorageAvailable(uint256 minStorageAvailable);
    event SetRebalanceParameter(uint256 borrowRateMin, uint256 borrowRateMax);
    event SetRewardsTokenPriceDeviationLimit(uint256 deviationLimit);
    event SetRewardsTokenPriceInfo(uint256 latestAnser, uint256 timestamp);
    event BuildCircle(address token, uint256 amount, uint256 circlesCount);
    event DestroyCircle(
        address token,
        uint256 circlesCount,
        uint256 destroyAmountLimit
    );
    event DestroyAll(address token, uint256 destroyAmount, uint256 blidAmount);
    event ClaimRewards(uint256 amount);
    event UseToken(address token, uint256 amount);
    event ReleaseToken(address token, uint256 amount);

    function __OlaStrategy_init(address _comptroller, address _logic)
        public
        initializer
    {
        UpgradeableBase.initialize();
        comptroller = _comptroller;
        rewardsToken = IDistributionOla(
            IComptrollerOla(comptroller).rainMaker()
        ).lnIncentiveTokenAddress();
        logic = _logic;

        rewardsTokenPriceDeviationLimit = (1 ether) / uint256(86400); // limit is 100% within 1 day, 50% within 1 day = (1 ether) * 50 / (100 * 86400)
        minRewardsSwapLimit = 20 * (1 ether); // 1.5 USD is required
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "OL1");
        _;
    }

    modifier onlyStrategyPaused() {
        require(_checkStrategyPaused(), "OL2");
        _;
    }

    /*** Public Initialize Function ***/

    /**
     * @notice Set blid in contract
     * @param _blid Address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        require(blid == address(0), "OL3");
        blid = _blid;
        emit SetBLID(_blid);
    }

    /**
     * @notice Set MultiLogicProxy, you can call the function once
     * @param _multiLogicProxy Address of Multilogic Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        require(multiLogicProxy == address(0), "OL5");
        multiLogicProxy = _multiLogicProxy;
    }

    /**
     * @notice Set StrategyStatistics
     * @param _strategyStatistics Address of StrategyStatistics
     */
    function setStrategyStatistics(address _strategyStatistics)
        external
        onlyOwner
    {
        strategyStatistics = _strategyStatistics;

        // Save RewardsTokenPriceInfo
        rewardsTokenPriceInfo.latestAnswer = IStrategyStatistics(
            _strategyStatistics
        ).getRewardsTokenPrice(comptroller, rewardsToken);
        rewardsTokenPriceInfo.timestamp = block.timestamp;
    }

    /**
     * @notice Set circlesCount
     * @param _circlesCount Count number
     */
    function setCirclesCount(uint8 _circlesCount) external onlyOwner {
        circlesCount = _circlesCount;

        emit SetCirclesCount(_circlesCount);
    }

    /**
     * @notice Set min Rewards swap limit
     * @param _minRewardsSwapLimit minimum swap amount for rewards token
     */
    function setMinRewardsSwapLimit(uint256 _minRewardsSwapLimit)
        external
        onlyOwner
    {
        minRewardsSwapLimit = _minRewardsSwapLimit;

        emit SetMinRewardsSwapLimit(_minRewardsSwapLimit);
    }

    /**
     * @notice Set Rewards -> BLID swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     * @param _minimumBLIDPerRewardToken minimum BLID for RewardsToken
     */
    function setRewardsToBLID(
        address swapRouter,
        address[] calldata path,
        uint256 _minimumBLIDPerRewardToken
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "OL6");
        require(path[0] == rewardsToken, "OL7");
        require(path[length - 1] == blid, "OL8");

        swapRouter_RewardsToBLID = swapRouter;
        path_RewardsToBLID = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_RewardsToBLID[i] = path[i];

            unchecked {
                ++i;
            }
        }

        minimumBLIDPerRewardToken = _minimumBLIDPerRewardToken;
    }

    /**
     * @notice Set Rewards to StrategyToken swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     */
    function setRewardsToStrategyToken(
        address swapRouter,
        address[] calldata path
    ) external onlyOwner {
        uint256 length = path.length;
        require(length >= 2, "OL6");
        require(path[0] == rewardsToken, "OL7");
        require(
            strategyToken == ZERO_ADDRESS ||
                (strategyToken != ZERO_ADDRESS &&
                    path[length - 1] == strategyToken),
            "OL8"
        );

        swapRouter_RewardsToStrategyToken = swapRouter;
        path_RewardsToStrategyToken = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_RewardsToStrategyToken[i] = path[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set StrategyToken to BLID swap information
     * @param swapRouter : address of swap Router
     * @param path path to rewards to BLID
     */
    function setStrategyTokenToBLID(address swapRouter, address[] calldata path)
        external
        onlyOwner
    {
        uint256 length = path.length;
        require(length >= 2, "OL6");
        require(
            strategyToken == ZERO_ADDRESS ||
                (strategyToken != ZERO_ADDRESS && path[0] == strategyToken),
            "OL7"
        );
        require(path[length - 1] == blid, "OL8");

        swapRouter_StrategyTokenToBLID = swapRouter;
        path_StrategyTokenToBLID = new address[](length);
        for (uint256 i = 0; i < length; ) {
            path_StrategyTokenToBLID[i] = path[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set avoidLiquidationFactor
     * @param _avoidLiquidationFactor factor value (0-99)
     */
    function setAvoidLiquidationFactor(uint8 _avoidLiquidationFactor)
        external
        onlyOwner
    {
        require(_avoidLiquidationFactor < 100, "OL4");

        avoidLiquidationFactor = _avoidLiquidationFactor;
        emit SetAvoidLiquidationFactor(_avoidLiquidationFactor);
    }

    /**
     * @notice Set MinStorageAvailable
     * @param amount amount of min storage available for token using : decimals = token decimals
     */
    function setMinStorageAvailable(uint256 amount) external onlyOwner {
        minStorageAvailable = amount;
        emit SetMinStorageAvailable(amount);
    }

    /**
     * @notice Set RebalanceParameter
     * @param _borrowRateMin borrowRate min : decimals = 18
     * @param _borrowRateMax borrowRate max : deciamls = 18
     */
    function setRebalanceParameter(
        uint256 _borrowRateMin,
        uint256 _borrowRateMax
    ) external onlyOwner {
        require(_borrowRateMin < BASE, "OL4");
        require(_borrowRateMax < BASE, "OL4");
        borrowRateMin = _borrowRateMin;
        borrowRateMax = _borrowRateMax;
        emit SetRebalanceParameter(_borrowRateMin, _borrowRateMin);
    }

    /**
     * @notice Set RewardsTokenPriceDeviationLimit
     * @param _rewardsTokenPriceDeviationLimit price Diviation per seccond limit
     */
    function setRewardsTokenPriceDeviationLimit(
        uint256 _rewardsTokenPriceDeviationLimit
    ) external onlyOwner {
        rewardsTokenPriceDeviationLimit = _rewardsTokenPriceDeviationLimit;

        emit SetRewardsTokenPriceDeviationLimit(
            _rewardsTokenPriceDeviationLimit
        );
    }

    /**
     * @notice Force update rewardsTokenPrice
     * @param latestAnswer new latestAnswer
     */
    function setRewardsTokenPrice(uint256 latestAnswer) external onlyOwner {
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;

        emit SetRewardsTokenPriceInfo(latestAnswer, block.timestamp);
    }

    /*** Public Automation Check view function ***/

    /**
     * @notice Check wheather storageAvailable is bigger enough
     * @return canUseToken true : useToken is possible
     */
    function checkUseToken() public view override returns (bool canUseToken) {
        if (
            IMultiLogicProxy(multiLogicProxy).getTokenAvailable(
                strategyToken,
                logic
            ) < minStorageAvailable
        ) {
            canUseToken = false;
        } else {
            canUseToken = true;
        }
    }

    /**
     * @notice Check whether borrow rate is ok
     * @return canRebalance true : rebalance is possible, borrow rate is abnormal
     */
    function checkRebalance() public view override returns (bool canRebalance) {
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(strategyXToken, logic);

        // If no lending, can't rebalance
        if (xTokenInfo.totalSupply == 0) return false;

        uint256 borrowRate = xTokenInfo.borrowLimit == 0
            ? 0
            : (xTokenInfo.borrowAmount * BASE) / xTokenInfo.borrowLimit;

        if (borrowRate > borrowRateMax || borrowRate < borrowRateMin) {
            canRebalance = true;
        } else {
            canRebalance = false;
        }
    }

    /*** Public Strategy Function ***/

    /**
     * @notice Set StrategyXToken
     * Add XToken in Contract and approve token
     * entermarkets to lending system
     * @param _xToken Address of XToken
     */
    function setStrategyXToken(address _xToken)
        external
        onlyOwner
        onlyStrategyPaused
    {
        require(strategyXToken != _xToken, "OL10");

        address _logic = logic;
        address _strategyToken = IXToken(_xToken).underlying();
        if (_strategyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            _strategyToken = ZERO_ADDRESS;

        // Add token/iToken to Logic
        ILogic(_logic).addXTokens(_strategyToken, _xToken);

        // Entermarkets with token/iToken
        address[] memory tokens = new address[](1);
        tokens[0] = _xToken;
        ILogic(_logic).enterMarkets(tokens);

        strategyXToken = _xToken;
        strategyToken = _strategyToken;
        emit SetStrategyXToken(_xToken);
    }

    function useToken() external override {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _strategyToken = strategyToken;

        // Check if storageAvailable is bigger enough
        uint256 availableAmount = IMultiLogicProxy(multiLogicProxy)
            .getTokenAvailable(_strategyToken, _logic);
        if (availableAmount < minStorageAvailable) return;

        // Take token from storage
        ILogic(_logic).takeTokenFromStorage(availableAmount, _strategyToken);

        // Mint
        ILogic(_logic).mint(_strategyXToken, availableAmount);

        emit UseToken(_strategyToken, availableAmount);
    }

    function rebalance() external override {
        address _logic = logic;
        address _strategyXToken = strategyXToken;
        uint8 _circlesCount = circlesCount;
        uint256 _borrowRateMin = borrowRateMin;
        uint256 _borrowRateMax = borrowRateMax;
        uint256 targetBorrowRate = _borrowRateMin +
            (_borrowRateMax - _borrowRateMin) /
            2;
        (
            uint256 collateralFactor,
            uint256 collateralFactorApplied
        ) = _getCollateralFactor(_strategyXToken);

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // get statistics
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);

        uint256 borrowRate = xTokenInfo.borrowLimit == 0
            ? 0
            : (xTokenInfo.borrowAmount * BASE) / xTokenInfo.borrowLimit;

        // Build
        if (borrowRate < _borrowRateMin) {
            uint256 Y = 0;
            uint256 accLTV = BASE;
            for (uint256 i = 0; i < _circlesCount; ) {
                Y = Y + accLTV;
                accLTV = (accLTV * collateralFactorApplied) / BASE;
                unchecked {
                    ++i;
                }
            }
            uint256 buildAmount = ((((((xTokenInfo.totalSupply *
                targetBorrowRate) / BASE) * collateralFactor) / BASE) -
                xTokenInfo.borrowAmount) * BASE) /
                ((Y * (BASE - (targetBorrowRate * collateralFactor) / BASE)) /
                    BASE);
            if (buildAmount > 0) {
                createCircles(_strategyXToken, buildAmount, _circlesCount);

                emit BuildCircle(_strategyXToken, buildAmount, _circlesCount);
            }
        }

        // Destroy
        if (borrowRate > _borrowRateMax) {
            uint256 LTV = collateralFactor; // don't apply avoidLiquidationFactor
            uint256 destroyAmount = ((xTokenInfo.borrowAmount -
                (((xTokenInfo.totalSupply * targetBorrowRate) / BASE) * LTV) /
                BASE) * BASE) / (BASE - (targetBorrowRate * LTV) / BASE);

            destructCircles(_strategyXToken, _circlesCount, destroyAmount);

            emit DestroyCircle(_strategyXToken, _circlesCount, destroyAmount);
        }
    }

    /**
     * @notice Destroy circle strategy
     * destroy circle and return all tokens to storage
     */
    function destroyAll() external override onlyOwnerAndAdmin {
        address _logic = logic;
        address _rewardsToken = rewardsToken;
        address _strategyXToken = strategyXToken;
        address _strategyToken = strategyToken;
        uint256 amountBLID = 0;

        // Destruct circle
        destructCircles(_strategyXToken, circlesCount, 0);

        // Claim Rewards token
        ILogic(_logic).claim();

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            strategyStatistics,
            _rewardsToken
        );
        uint256 amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken)
            .balanceOf(_logic);
        if (amountRewardsToken <= minRewardsSwapLimit) rewardsTokenKill = true;

        // swap rewardsToken to StrategyToken
        if (
            rewardsTokenKill == false &&
            IERC20MetadataUpgradeable(_rewardsToken).balanceOf(_logic) > 0
        ) {
            ILogic(_logic).swap(
                swapRouter_RewardsToStrategyToken,
                IERC20MetadataUpgradeable(_rewardsToken).balanceOf(_logic),
                0,
                path_RewardsToStrategyToken,
                true,
                block.timestamp + 300
            );
        }

        // Get strategy amount, current balance of underlying
        uint256 amountStrategy = IMultiLogicProxy(multiLogicProxy)
            .getTokenTaken(_strategyToken, _logic);
        uint256 balanceToken = _strategyToken == ZERO_ADDRESS
            ? address(_logic).balance
            : IERC20Upgradeable(_strategyToken).balanceOf(_logic);

        // If we have extra, swap StrategyToken to BLID
        if (balanceToken > amountStrategy) {
            ILogic(_logic).swap(
                swapRouter_StrategyTokenToBLID,
                balanceToken - amountStrategy,
                0,
                path_StrategyTokenToBLID,
                true,
                block.timestamp + 300
            );

            // Add BLID earn to storage
            amountBLID = _addEarnToStorage();
        } else {
            amountStrategy = balanceToken;
        }

        // Return all tokens to strategy
        ILogic(_logic).returnTokenToStorage(amountStrategy, _strategyToken);

        emit DestroyAll(_strategyXToken, amountStrategy, amountBLID);
    }

    /**
     * @notice claim distribution rewards USDT both borrow and lend swap banana token to BLID
     */
    function claimRewards() public override onlyOwnerAndAdmin {
        require(path_RewardsToBLID.length >= 2, "OL6");

        address _logic = logic;
        address _strategyXToken = strategyXToken;
        address _rewardsToken = rewardsToken;
        address _strategyStatistics = strategyStatistics;
        uint256 amountRewardsToken;

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // Claim Rewards token
        ILogic(_logic).claim();

        // RewardsToken Price/Amount Kill Switch
        bool rewardsTokenKill = _rewardsPriceKillSwitch(
            _strategyStatistics,
            _rewardsToken
        );
        amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken).balanceOf(
                _logic
            );
        if (amountRewardsToken <= minRewardsSwapLimit) rewardsTokenKill = true;

        /**** Supply / Redeem adjustment with lending amount ****/
        // Get remained amount
        XTokenInfo memory xTokenInfo = IStrategyStatistics(_strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);
        int256 diff = int256(xTokenInfo.lendingAmount) -
            int256(xTokenInfo.totalSupply) +
            int256(xTokenInfo.borrowAmount);

        // If we need to lending,  swap Rewards to StrategyToken -> repay
        if (diff > 0 && rewardsTokenKill == false) {
            ILogic(_logic).swap(
                swapRouter_RewardsToStrategyToken,
                amountRewardsToken,
                uint256(diff),
                path_RewardsToStrategyToken,
                false,
                block.timestamp + 300
            );
            ILogic(_logic).repayBorrow(_strategyXToken, uint256(diff));
        }

        // swap Rewards to BLID
        if (rewardsTokenKill == false) {
            amountRewardsToken = IERC20MetadataUpgradeable(_rewardsToken)
                .balanceOf(_logic);
            ILogic(_logic).swap(
                swapRouter_RewardsToBLID,
                amountRewardsToken,
                (amountRewardsToken * minimumBLIDPerRewardToken) / BASE,
                path_RewardsToBLID,
                true,
                block.timestamp + 300
            );
        }

        // If we need to redeem, redeem -> swap StrategyToken to BLID
        if (diff < 0) {
            ILogic(_logic).redeemUnderlying(_strategyXToken, uint256(0 - diff));
            ILogic(_logic).swap(
                swapRouter_StrategyTokenToBLID,
                uint256(0 - diff),
                0,
                path_StrategyTokenToBLID,
                true,
                block.timestamp + 300
            );
        }

        // Add BLID earn to storage
        uint256 amountBLID = _addEarnToStorage();

        emit ClaimRewards(amountBLID);
    }

    /**
     * @notice Frees up tokens for the user, but Storage doesn't transfer token for the user,
     * only Storage can this function, after calling this function Storage transfer
     * from Logic to user token.
     * @param amount Amount of token
     * @param token Address of token
     */
    function releaseToken(uint256 amount, address token)
        external
        override
        onlyMultiLogicProxy
    {
        address _strategyXToken = strategyXToken;
        address _logic = logic;
        uint8 _circlesCount = circlesCount;
        require(token == strategyToken, "OL13");

        // Call mint with 0 amount to accrueInterest
        ILogic(_logic).mint(_strategyXToken, 0);

        // Calculate destroy amount
        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, _logic);

        uint256 destroyAmount = (xTokenInfo.borrowAmount * amount) /
            (xTokenInfo.totalSupply - xTokenInfo.borrowAmount);

        // destruct circle
        destructCircles(_strategyXToken, _circlesCount, destroyAmount);

        // Redeem for release token
        ILogic(_logic).redeemUnderlying(_strategyXToken, amount);

        uint256 balance;

        if (token == ZERO_ADDRESS) {
            balance = address(_logic).balance;
        } else {
            balance = IERC20Upgradeable(token).balanceOf(_logic);
        }

        if (balance < amount) {
            revert("no money");
        } else if (token == ZERO_ADDRESS) {
            ILogic(_logic).returnETHToMultiLogicProxy(amount);
        }

        emit ReleaseToken(token, amount);
    }

    /**
     * @notice multicall to Logic
     */
    function multicall(bytes[] memory callDatas)
        public
        onlyOwnerAndAdmin
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 length = callDatas.length;
        returnData = new bytes[](length);
        for (uint256 i = 0; i < length; ) {
            (bool success, bytes memory ret) = address(logic).call(
                callDatas[i]
            );
            require(success, "F99");
            returnData[i] = ret;

            unchecked {
                ++i;
            }
        }
    }

    /*** Private Function ***/

    /**
     * @notice creates circle (borrow-lend) of the base token
     * token (of amount) should be mint before start build
     * @param xToken xToken address
     * @param amount amount to build (borrowAmount)
     * @param iterateCount the number circles to
     */
    function createCircles(
        address xToken,
        uint256 amount,
        uint8 iterateCount
    ) private {
        address _logic = logic;
        uint256 _amount = amount;

        require(amount > 0, "OL12");

        // Get collateralFactor, the maximum proportion of borrow/lend
        // apply avoidLiquidationFactor
        (, uint256 collateralFactorApplied) = _getCollateralFactor(xToken);
        require(collateralFactorApplied > 0, "OL11");

        for (uint256 i = 0; i < iterateCount; ) {
            ILogic(_logic).borrow(xToken, _amount);
            ILogic(_logic).mint(xToken, _amount);
            _amount = (_amount * collateralFactorApplied) / BASE;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice unblock all the money
     * @param xToken xToken address
     * @param _iterateCount the number circles to : maximum iterates to do, the real number might be less then iterateCount
     * @param destroyAmountLimit if > 0, stop destroy if total repay is destroyAmountLimit
     */
    function destructCircles(
        address xToken,
        uint8 _iterateCount,
        uint256 destroyAmountLimit
    ) private {
        uint256 collateralFactorApplied;
        uint8 iterateCount = _iterateCount + 3; // additional iteration to repay all borrowed
        address _logic = logic;
        uint256 _destroyAmountLimit = destroyAmountLimit;

        // Get collateralFactor, apply avoidLiquidationFactor
        (, collateralFactorApplied) = _getCollateralFactor(xToken);
        require(collateralFactorApplied > 0, "OL11");

        for (uint256 i = 0; i < iterateCount; ) {
            uint256 xTokenBalance; // balance of xToken
            uint256 borrowBalance; // balance of borrowed amount
            uint256 exchangeRateMantissa; //conversion rate from iToken to token

            // get infromation of account
            (, xTokenBalance, borrowBalance, exchangeRateMantissa) = IXToken(
                xToken
            ).getAccountSnapshot(_logic);

            // calculates of supplied balance, divided by 10^18 to safe digits correctly
            uint256 supplyBalance = (xTokenBalance * exchangeRateMantissa) /
                BASE;

            // if nothing to repay
            if (borrowBalance == 0) {
                if (xTokenBalance > 0) {
                    // redeem and exit
                    ILogic(_logic).redeem(xToken, xTokenBalance);
                    return;
                }
            }
            // if already redeemed
            if (supplyBalance == 0) {
                return;
            }

            // calculates how much percents could be borrowed and not to be liquidated, then multiply fo supply balance to calculate the amount
            uint256 withdrawBalance = ((collateralFactorApplied -
                ((BASE * borrowBalance) / supplyBalance)) * supplyBalance) /
                BASE;

            // If we have destroylimit, redeem only limit
            if (
                destroyAmountLimit > 0 && withdrawBalance > _destroyAmountLimit
            ) {
                withdrawBalance = _destroyAmountLimit;
            }

            // if redeem tokens
            ILogic(_logic).redeemUnderlying(xToken, withdrawBalance);
            uint256 repayAmount = strategyToken == ZERO_ADDRESS
                ? address(_logic).balance
                : IERC20Upgradeable(strategyToken).balanceOf(_logic);

            // if there is something to repay
            if (repayAmount > 0) {
                // if borrow balance more then we have on account
                if (borrowBalance <= repayAmount) {
                    repayAmount = borrowBalance;
                }
                ILogic(_logic).repayBorrow(xToken, repayAmount);
            }

            // Stop destroy if destroyAmountLimit < sumRepay
            if (destroyAmountLimit > 0) {
                if (_destroyAmountLimit <= repayAmount) break;
                _destroyAmountLimit = _destroyAmountLimit - repayAmount;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice check if strategy distroy circles
     * @return paused true : strategy is empty, false : strategy has some lending token
     */
    function _checkStrategyPaused() private view returns (bool paused) {
        address _strategyXToken = strategyXToken;
        if (_strategyXToken == address(0)) return true;

        XTokenInfo memory xTokenInfo = IStrategyStatistics(strategyStatistics)
            .getStrategyXTokenInfo(_strategyXToken, logic);

        if (xTokenInfo.totalSupply > 0 || xTokenInfo.borrowAmount > 0) {
            paused = false;
        } else {
            paused = true;
        }
    }

    /**
     * @notice get CollateralFactor from market
     * Apply avoidLiquidationFactor
     * @param xToken : address of xToken
     * @return collateralFactor decimal = 18
     */
    function _getCollateralFactor(address xToken)
        private
        view
        returns (uint256 collateralFactor, uint256 collateralFactorApplied)
    {
        // get collateralFactor from market
        (, collateralFactor, , , , ) = IComptrollerOla(comptroller).markets(
            xToken
        );

        // Apply avoidLiquidationFactor to collateralFactor
        collateralFactorApplied =
            collateralFactor -
            avoidLiquidationFactor *
            10**16;
    }

    /**
     * @notice Send all BLID to storage
     * @return amountBLID BLID amount
     */
    function _addEarnToStorage() private returns (uint256 amountBLID) {
        address _logic = logic;
        amountBLID = IERC20Upgradeable(blid).balanceOf(_logic);
        if (amountBLID > 0) {
            ILogic(_logic).addEarnToStorage(amountBLID);
        }
    }

    /**
     * @notice Process RewardsTokenPrice kill switch
     * @param _strategyStatistics : stratgyStatistics
     * @param _rewardsToken : rewardsToken
     * @return killSwitch true : Rewards price should be protected, false : Rewards price is ok
     */
    function _rewardsPriceKillSwitch(
        address _strategyStatistics,
        address _rewardsToken
    ) private returns (bool killSwitch) {
        RewardsTokenPriceInfo
            memory _rewardsTokenPriceInfo = rewardsTokenPriceInfo;
        killSwitch = false;

        // Calculate delta
        uint256 latestAnswer = IStrategyStatistics(_strategyStatistics)
            .getRewardsTokenPrice(comptroller, _rewardsToken);
        int256 delta = int256(_rewardsTokenPriceInfo.latestAnswer) -
            int256(latestAnswer);
        if (delta < 0) delta = 0 - delta;

        // Check deviation
        if (
            block.timestamp == _rewardsTokenPriceInfo.timestamp ||
            _rewardsTokenPriceInfo.latestAnswer == 0
        ) {
            delta = 0;
        } else {
            delta =
                (delta * (1 ether)) /
                (int256(_rewardsTokenPriceInfo.latestAnswer) *
                    (int256(block.timestamp) -
                        int256(_rewardsTokenPriceInfo.timestamp)));
        }
        if (uint256(delta) > rewardsTokenPriceDeviationLimit) {
            killSwitch = true;
        }

        // Keep current status
        rewardsTokenPriceInfo.latestAnswer = latestAnswer;
        rewardsTokenPriceInfo.timestamp = block.timestamp;
    }
}