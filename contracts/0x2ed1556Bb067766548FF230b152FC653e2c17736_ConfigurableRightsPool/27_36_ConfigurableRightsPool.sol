// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
// Needed to handle structures externally
pragma experimental ABIEncoderV2;

import "./PCToken.sol";
import "../utils/DesynReentrancyGuard.sol";
import "../utils/DesynOwnable.sol";
import "../interfaces/IBFactory.sol";
import {RightsManager} from "../libraries/RightsManager.sol";
import "../libraries/SmartPoolManager.sol";
import "../libraries/SafeApprove.sol";
import "./WhiteToken.sol";

import "../libraries/SafeERC20.sol";
/**
 * @author Desyn Labs
 * @title Smart Pool with customizable features
 * @notice PCToken is the "Desyn Smart Pool" token (transferred upon finalization)
 * @dev Rights are defined as follows (index values into the array)
 * Note that functions called on bPool and bFactory may look like internal calls,
 *   but since they are contracts accessed through an interface, they are really external.
 * To make this explicit, we could write "IBPool(address(bPool)).function()" everywhere,
 *   instead of "bPool.function()".
 */
contract ConfigurableRightsPool is PCToken, DesynOwnable, DesynReentrancyGuard, WhiteToken {
    using DesynSafeMath for uint;
    using SafeERC20 for IERC20;

    // State variables
    IBFactory public bFactory;
    IBPool public bPool;

    // Struct holding the rights configuration
    RightsManager.Rights public rights;

    SmartPoolManager.Status public etfStatus;

    // Fee is initialized on creation, and can be changed if permission is set
    // Only needed for temporary storage between construction and createPool
    // Thereafter, the swap fee should always be read from the underlying pool
    uint private _initialSwapFee;

    // Store the list of tokens in the pool, and balances
    // NOTE that the token list is *only* used to store the pool tokens between
    //   construction and createPool - thereafter, use the underlying BPool's list
    //   (avoids synchronization issues)
    address[] private _initialTokens;
    uint[] private _initialBalances;
    uint[] private _initialWeights;

    // Whitelist of LPs (if configured)
    mapping(address => bool) private _liquidityProviderWhitelist;

    // Cap on the pool size (i.e., # of tokens minted when joining)
    // Limits the risk of experimental pools; failsafe/backup for fixed-size pools
    // uint public claimPeriod = 60 * 60 * 24 * 30;
    uint public claimPeriod = 30 days;

    address public vaultAddress;
    address public oracleAddress;

    bool hasSetWhiteTokens;
    bool public initBool;
    bool public isCompletedCollect;

    mapping(address => SmartPoolManager.Fund) public beginFund;
    mapping(address => SmartPoolManager.Fund) public endFund;
    SmartPoolManager.Etypes public etype;

    // Event declarations
    // Anonymous logger event - can only be filtered by contract address
    event LogCall(bytes4 indexed sig, address indexed caller, bytes data) anonymous;
    event LogJoin(address indexed caller, address indexed tokenIn, uint tokenAmountIn);
    event LogExit(address indexed caller, address indexed tokenOut, uint tokenAmountOut);
    event SizeChanged(address indexed caller, string indexed sizeType, uint oldSize, uint newSize);
    event PoolTokenInit(address indexed caller, address pool, address initToken, uint initTokenTotal, uint initShare);
    // event FloorChanged(address indexed caller, uint oldFloor, uint newFloor);
    // event setRangeOfToken(address indexed caller, address pool, address token, uint floor, uint cap);
    event SetManagerFee(uint indexed managerFee, uint indexed issueFee, uint indexed redeemFee, uint perfermanceFee);
    // event CloseETFColletdCompleted(address indexed caller, address indexed pool, uint monent);

    // Modifiers
    modifier logs() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    // Mark functions that require delegation to the underlying Pool
    modifier needsBPool() {
        require(address(bPool) != address(0), "ERR_NOT_CREATED");
        _;
    }

    modifier notPaused() {
        require(!bFactory.isPaused(), "!paused");
        _;
    }

    // modifier lockUnderlyingPool() {
    //     // Turn off swapping on the underlying pool during joins
    //     // Otherwise tokens with callbacks would enable attacks involving simultaneous swaps and joins
    //     bool origSwapState = bPool.isPublicSwap();
    //     bPool.setPublicSwap(false);
    //     _;
    //     bPool.setPublicSwap(origSwapState);
    // }

    constructor(string memory tokenSymbol, string memory tokenName) public PCToken(tokenSymbol, tokenName) {}

    /**
     * @notice Construct a new Configurable Rights Pool (wrapper around BPool)
     * @dev _initialTokens and _swapFee are only used for temporary storage between construction
     *      and create pool, and should not be used thereafter! _initialTokens is destroyed in
     *      createPool to prevent this, and _swapFee is kept in sync (defensively), but
     *      should never be used except in this constructor and createPool()
     * @param factoryAddress - the BPoolFactory used to create the underlying pool
     * @param poolParams - struct containing pool parameters
     * @param rightsStruct - Set of permissions we are assigning to this smart pool
     */

    function init(
        address factoryAddress,
        SmartPoolManager.PoolParams memory poolParams,
        RightsManager.Rights memory rightsStruct
    ) public {
        SmartPoolManager.initRequire(
            poolParams.swapFee,
            poolParams.managerFee,
            poolParams.issueFee,
            poolParams.redeemFee,
            poolParams.perfermanceFee,
            poolParams.tokenBalances.length,
            poolParams.tokenWeights.length,
            poolParams.constituentTokens.length,
            initBool
        );
        initBool = true;
        rights = rightsStruct;
        _initialTokens = poolParams.constituentTokens;
        _initialBalances = poolParams.tokenBalances;
        _initialWeights = poolParams.tokenWeights;

        etfStatus = SmartPoolManager.Status({
            collectPeriod: 0,
            collectEndTime: 0,
            closurePeriod: 0,
            closureEndTime: 0,
            upperCap: DesynConstants.MAX_UINT,
            floorCap: 0,
            managerFee: poolParams.managerFee,
            redeemFee: poolParams.redeemFee,
            issueFee: poolParams.issueFee,
            perfermanceFee: poolParams.perfermanceFee,
            startClaimFeeTime: block.timestamp
        });

        etype = poolParams.etype;

        bFactory = IBFactory(factoryAddress);
        oracleAddress = bFactory.getOracleAddress();
        vaultAddress = bFactory.getVault();
        emit SetManagerFee(etfStatus.managerFee, etfStatus.issueFee, etfStatus.redeemFee, etfStatus.perfermanceFee);
    }

    /**
     * @notice Set the cap (max # of pool tokens)
     * @dev _bspCap defaults in the constructor to unlimited
     *      Can set to 0 (or anywhere below the current supply), to halt new investment
     *      Prevent setting it before creating a pool, since createPool sets to intialSupply
     *      (it does this to avoid an unlimited cap window between construction and createPool)
     *      Therefore setting it before then has no effect, so should not be allowed
     * @param newCap - new value of the cap
     */
    function setCap(uint newCap) external logs lock needsBPool onlyOwner {
        require(etype == SmartPoolManager.Etypes.OPENED, "ERR_MUST_OPEN_ETF");
        // emit CapChanged(msg.sender, etfStatus.upperCap, newCap);
        emit SizeChanged(msg.sender, "UPPER", etfStatus.upperCap, newCap);
        etfStatus.upperCap = newCap;
    }

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external logs lock needsBPool returns (bytes memory _returnValue) {
        require(bFactory.getModuleStatus(address(this), msg.sender), "MODULE IS NOT REGISTER");

        _returnValue = bPool.execute(_target, _value, _data);
    }

    function couldClaimManagerFee() public view returns(bool state,uint timePoint ,uint timeElapsed){
        bool isCloseETF = etype == SmartPoolManager.Etypes.CLOSED;
        timePoint = block.timestamp;
        if(isCloseETF && timePoint > etfStatus.closureEndTime) timePoint = etfStatus.closureEndTime;
        timeElapsed = DesynSafeMath.bsub(timePoint, etfStatus.startClaimFeeTime);
        if(timeElapsed >= claimPeriod) state = true;
        if(isCloseETF && !isCompletedCollect) state = false;
    }

    function claimManagerFee() external virtual logs lock onlyAdmin needsBPool {
        (bool state, uint timePoint ,uint timeElapsed) = couldClaimManagerFee();
        if(state){
            address[] memory poolTokens = bPool.getCurrentTokens();
            uint[] memory tokensAmount = SmartPoolManager.handleClaim(
                IConfigurableRightsPool(address(this)),
                bPool,
                poolTokens,
                etfStatus.managerFee,
                timeElapsed,
                claimPeriod
            );
            IVault(vaultAddress).depositManagerToken(poolTokens, tokensAmount);
            etfStatus.startClaimFeeTime = timePoint;
        }
    }

    /**
     * @notice Create a new Smart Pool
     * @dev Delegates to internal function
     * @param initialSupply starting token balance
     * @param closurePeriod the etf closure period
     */
    function createPool(
        uint initialSupply,
        uint collectPeriod,
        SmartPoolManager.Period closurePeriod,
        SmartPoolManager.PoolTokenRange memory tokenRange
    ) external virtual onlyOwner logs lock notPaused {
        if (etype == SmartPoolManager.Etypes.CLOSED) {
            // require(collectPeriod <= DesynConstants.MAX_COLLECT_PERIOD, "ERR_EXCEEDS_FUND_RAISING_PERIOD");
            // require(etfStatus.upperCap >= initialSupply, "ERR_CAP_BIGGER_THAN_INITSUPPLY");
            SmartPoolManager.createPoolHandle(collectPeriod, etfStatus.upperCap, initialSupply);

            uint oldCap = etfStatus.upperCap;
            uint oldFloor = etfStatus.floorCap;
            etfStatus.upperCap = initialSupply.bmul(tokenRange.bspCap).bdiv(_initialBalances[0]);
            etfStatus.floorCap = initialSupply.bmul(tokenRange.bspFloor).bdiv(_initialBalances[0]);
            emit PoolTokenInit(msg.sender, address(this),_initialTokens[0], _initialBalances[0], initialSupply);
            emit SizeChanged(msg.sender, "UPPER", oldCap, etfStatus.upperCap);
            emit SizeChanged(msg.sender, "FLOOR", oldFloor, etfStatus.floorCap);

            uint period;
            uint collectEndTime = block.timestamp + collectPeriod;
            if (closurePeriod == SmartPoolManager.Period.HALF) {
                period = 90 days;
            } else if (closurePeriod == SmartPoolManager.Period.ONE) {
                period = 180 days;
            } else {
                period = 360 days;
            }
            uint closureEndTime = collectEndTime + period;
            //   (uint period,uint collectEndTime,uint closureEndTime) = SmartPoolManager.createPoolHandle(collectPeriod, closurePeriod == Period.HALF, closurePeriod == Period.ONE);

            // etfStatus = SmartPoolManager.Status(collectPeriod, collectEndTime, period, closureEndTime);
            etfStatus.collectPeriod = collectPeriod;
            etfStatus.collectEndTime = collectEndTime;
            etfStatus.closurePeriod = period;
            etfStatus.closureEndTime = closureEndTime;

            // _addPoolRangeConfig(poolRange);

            uint totalBegin = Oracles(oracleAddress).getAllPrice(_initialTokens, _initialBalances);
            IUserVault(bFactory.getUserVault()).recordTokenInfo(msg.sender, msg.sender, _initialTokens, _initialBalances);
            if (totalBegin > 0) {
                SmartPoolManager.Fund storage fund = beginFund[msg.sender];
                fund.etfAmount = initialSupply;
                fund.fundAmount = totalBegin;
            }
        }

        createPoolInternal(initialSupply);
    }

    function rebalance(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external virtual logs lock onlyAdmin needsBPool notPaused {
        SmartPoolManager.rebalanceHandle(bPool, isCompletedCollect, etype == SmartPoolManager.Etypes.CLOSED, etfStatus.collectEndTime, etfStatus.closureEndTime, rights.canChangeWeights, tokenA, tokenB);

        _verifyWhiteToken(tokenB);
        bool bools = IVault(vaultAddress).getManagerClaimBool(address(this));
        if (bools) {
            IVault(vaultAddress).managerClaim(address(this));
        }

        // Delegate to library to save space
        SmartPoolManager.rebalance(IConfigurableRightsPool(address(this)), bPool, tokenA, tokenB, deltaWeight, minAmountOut);
    }

    /**
     * @notice Join a pool
     * @dev Emits a LogJoin event (for each token)
     *      bPool is a contract interface; function calls on it are external
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     */
    function joinPool(
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        address kol
    ) external logs lock needsBPool notPaused {
        SmartPoolManager.joinPoolHandle(rights.canWhitelistLPs, this.canProvideLiquidity(msg.sender), etype == SmartPoolManager.Etypes.CLOSED, etfStatus.collectEndTime);
        
        if(rights.canTokenWhiteLists) {
            require(_initWhiteTokenState(),"ERR_SHOULD_SET_WHITETOKEN");
        }
        // Delegate to library to save space

        // Library computes actualAmountsIn, and does many validations
        // Cannot call the push/pull/min from an external library for
        // any of these pool functions. Since msg.sender can be anybody,
        // they must be internal
        uint[] memory actualAmountsIn = SmartPoolManager.joinPool(IConfigurableRightsPool(address(this)), bPool, poolAmountOut, maxAmountsIn, etfStatus.issueFee);

        // After createPool, token list is maintained in the underlying BPool
        address[] memory poolTokens = bPool.getCurrentTokens();
        uint[] memory issueFeesReceived = new uint[](poolTokens.length);

        uint totalBegin;
        uint _actualIssueFee = etfStatus.issueFee;
        if (etype == SmartPoolManager.Etypes.CLOSED) {
            totalBegin = Oracles(oracleAddress).getAllPrice(poolTokens, actualAmountsIn);
            IUserVault(bFactory.getUserVault()).recordTokenInfo(kol, msg.sender, poolTokens, actualAmountsIn);
            if (isCompletedCollect == false) {
                _actualIssueFee = 0;
            }
        }

        for (uint i = 0; i < poolTokens.length; i++) {
            uint issueFeeReceived = SmartPoolManager.handleTransferInTokens(
                IConfigurableRightsPool(address(this)),
                bPool,
                poolTokens[i],
                actualAmountsIn[i],
                _actualIssueFee
            );

            emit LogJoin(msg.sender, poolTokens[i], actualAmountsIn[i]);
            issueFeesReceived[i] = issueFeeReceived;
        }

        if (_actualIssueFee != 0) {
            IVault(vaultAddress).depositIssueRedeemPToken(poolTokens, issueFeesReceived, issueFeesReceived, false);
        }
        // uint actualPoolAmountOut = DesynSafeMath.bsub(poolAmountOut, DesynSafeMath.bmul(poolAmountOut, etfStatus.issueFee));
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        if (totalBegin > 0) {
            SmartPoolManager.Fund storage fund = beginFund[msg.sender];
            fund.etfAmount = DesynSafeMath.badd(beginFund[msg.sender].etfAmount, poolAmountOut);
            fund.fundAmount = DesynSafeMath.badd(beginFund[msg.sender].fundAmount, totalBegin);
        }

        // checkout the state that elose ETF collect completed and claime fee.
        bool isCompletedMoment = etype == SmartPoolManager.Etypes.CLOSED && this.totalSupply() >= etfStatus.floorCap && isCompletedCollect == false;
        if (isCompletedMoment) {
            isCompletedCollect = true;
            SmartPoolManager.handleCollectionCompleted(
                IConfigurableRightsPool(address(this)), bPool,
                poolTokens,
                etfStatus.issueFee
            );
        }
    }

    // @notice Claime issueFee fee when close ETF collect completed moment.
    // function _closeEtfCollectCompletedToClaimeIssueFee() internal {
    //     if (etfStatus.issueFee != 0) {
    //         address[] memory poolTokens = bPool.getCurrentTokens(); // get all token
    //         uint[] memory tokensAmount = new uint[](poolTokens.length); // all amount temp

    //         for (uint i = 0; i < poolTokens.length; i++) {
    //             address t = poolTokens[i];
    //             uint currentAmount = bPool.getBalance(t);
    //             uint currentAmountFee = DesynSafeMath.bmul(currentAmount, etfStatus.issueFee);

    //             _pushUnderlying(t, address(this), currentAmountFee);
    //             tokensAmount[i] = currentAmountFee;
    //             IERC20(t).safeApprove(vaultAddress, currentAmountFee);
    //         }

    //         IVault(vaultAddress).depositIssueRedeemPToken(poolTokens, tokensAmount, tokensAmount, false);
    //     }
    // }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @dev Emits a LogExit event for each token
     *      bPool is a contract interface; function calls on it are external
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     */
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external logs lock needsBPool notPaused {
        uint actualPoolAmountIn;
        (beginFund[msg.sender].etfAmount, beginFund[msg.sender].fundAmount, actualPoolAmountIn) = SmartPoolManager.exitPoolHandleB(
            IConfigurableRightsPool(address(this)),
            etype == SmartPoolManager.Etypes.CLOSED,
            isCompletedCollect,
            etfStatus.closureEndTime,
            etfStatus.collectEndTime,
            beginFund[msg.sender].etfAmount,
            beginFund[msg.sender].fundAmount,
            poolAmountIn
        );
        // Library computes actualAmountsOut, and does many validations
        uint[] memory actualAmountsOut = SmartPoolManager.exitPool(IConfigurableRightsPool(address(this)), bPool, actualPoolAmountIn, minAmountsOut);
        _pullPoolShare(msg.sender, actualPoolAmountIn);
        _burnPoolShare(actualPoolAmountIn);

        // After createPool, token list is maintained in the underlying BPool
        address[] memory poolTokens = bPool.getCurrentTokens();
        uint[] memory redeemAndPerformanceFeesReceived = new uint[](poolTokens.length);
        //perfermance fee
        uint totalEnd;
        uint profitRate;

        uint _actualRedeemFee = etfStatus.redeemFee;
        if (etype == SmartPoolManager.Etypes.CLOSED) {
            bool isCloseEtfCollectEndWithFailure = isCompletedCollect == false && block.timestamp >= etfStatus.collectEndTime;
            if (isCloseEtfCollectEndWithFailure) {
                _actualRedeemFee = 0; // collect failure
            } else {
                totalEnd = Oracles(oracleAddress).getAllPrice(poolTokens, actualAmountsOut); // collect success && after closure
            }
        }

        if (totalEnd > 0) {
            uint _poolAmountIn = actualPoolAmountIn;
            (endFund[msg.sender].etfAmount, endFund[msg.sender].fundAmount, profitRate) = SmartPoolManager.exitPoolHandle(
                endFund[msg.sender].etfAmount,
                endFund[msg.sender].fundAmount,
                beginFund[msg.sender].etfAmount,
                beginFund[msg.sender].fundAmount,
                _poolAmountIn,
                totalEnd
            );
        }
        uint[] memory redeemFeesReceived = new uint[](poolTokens.length);
        for (uint i = 0; i < poolTokens.length; i++) {
            (uint redeemAndPerformanceFeeReceived, uint finalAmountOut, uint redeemFeeReceived) = SmartPoolManager.exitPoolHandleA(
                IConfigurableRightsPool(address(this)),
                bPool,
                poolTokens[i],
                actualAmountsOut[i],
                _actualRedeemFee,
                profitRate,
                etfStatus.perfermanceFee
            );
            redeemFeesReceived[i] = redeemFeeReceived;
            redeemAndPerformanceFeesReceived[i] = redeemAndPerformanceFeeReceived;

            emit LogExit(msg.sender, poolTokens[i], finalAmountOut);
            // _pushUnderlying(t, msg.sender, finalAmountOut);

            // if (_actualRedeemFee != 0 || (profitRate > 0 && etfStatus.perfermanceFee != 0)) {
            //     _pushUnderlying(t, address(this), redeemAndPerformanceFeeReceived);
            //     IERC20(t).safeApprove(vaultAddress, redeemAndPerformanceFeeReceived);
            //     redeemAndPerformanceFeesReceived[i] = redeemAndPerformanceFeeReceived;
            // }
        }

        if (_actualRedeemFee != 0 || (profitRate > 0 && etfStatus.perfermanceFee != 0)) {
            IVault(vaultAddress).depositIssueRedeemPToken(poolTokens, redeemAndPerformanceFeesReceived, redeemFeesReceived, true);
        }
    }

    /**
     * @notice Add to the whitelist of liquidity providers (if enabled)
     * @param provider - address of the liquidity provider
     */
    function whitelistLiquidityProvider(address provider) external onlyOwner lock logs {
        SmartPoolManager.WhitelistHandle(rights.canWhitelistLPs, true, provider);
        //  require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        // require(provider != address(0), "ERR_INVALID_ADDRESS");
        _liquidityProviderWhitelist[provider] = true;
    }

    /**
     * @notice Remove from the whitelist of liquidity providers (if enabled)
     * @param provider - address of the liquidity provider
     */
    function removeWhitelistedLiquidityProvider(address provider) external onlyOwner lock logs {
        SmartPoolManager.WhitelistHandle(rights.canWhitelistLPs, _liquidityProviderWhitelist[provider], provider);
        //  require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        // require(_liquidityProviderWhitelist[provider], "ERR_LP_NOT_WHITELISTED");
        // require(provider != address(0), "ERR_INVALID_ADDRESS");
        _liquidityProviderWhitelist[provider] = false;
    }

    /**
     * @notice Check if an address is a liquidity provider
     * @dev If the whitelist feature is not enabled, anyone can provide liquidity (assuming finalized)
     * @return boolean value indicating whether the address can join a pool
     */
    function canProvideLiquidity(address provider) external view returns (bool) {
        if (rights.canWhitelistLPs) {
            return _liquidityProviderWhitelist[provider] || provider == this.getController() ;
        } else {
            // Probably don't strictly need this (could just return true)
            // But the null address can't provide funds
            return provider != address(0);
        }
    }

    /**
     * @notice Getter for specific permissions
     * @dev value of the enum is just the 0-based index in the enumeration
     *      For instance canPauseSwapping is 0; canChangeWeights is 2
     * @return token boolean true if we have the given permission
     */
    function hasPermission(RightsManager.Permissions permission) external view virtual returns (bool) {
        return RightsManager.hasPermission(rights, permission);
    }

    /**
     * @notice Getter for the RightsManager contract
     * @dev Convenience function to get the address of the RightsManager library (so clients can check version)
     * @return address of the RightsManager library
     */
    function getRightsManagerVersion() external pure returns (address) {
        return address(RightsManager);
    }

    /**
     * @notice Getter for the DesynSafeMath contract
     * @dev Convenience function to get the address of the DesynSafeMath library (so clients can check version)
     * @return address of the DesynSafeMath library
     */
    function getDesynSafeMathVersion() external pure returns (address) {
        return address(DesynSafeMath);
    }

    /**
     * @notice Getter for the SmartPoolManager contract
     * @dev Convenience function to get the address of the SmartPoolManager library (so clients can check version)
     * @return address of the SmartPoolManager library
     */
    function getSmartPoolManagerVersion() external pure returns (address) {
        return address(SmartPoolManager);
    }

    // "Public" versions that can safely be called from SmartPoolManager
    // Allows only the contract itself to call them (not the controller or any external account)

    function mintPoolShareFromLib(uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _mint(amount);
    }

    function pushPoolShareFromLib(address to, uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _push(to, amount);
    }

    function pullPoolShareFromLib(address from, uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _pull(from, amount);
    }

    function burnPoolShareFromLib(uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _burn(amount);
    }

    /**
     * @notice Create a new Smart Pool
     * @dev Initialize the swap fee to the value provided in the CRP constructor
     *      Can be changed if the canChangeSwapFee permission is enabled
     * @param initialSupply starting token balance
     */
    function createPoolInternal(uint initialSupply) internal {
        require(address(bPool) == address(0), "ERR_IS_CREATED");
        // require(initialSupply >= DesynConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        // require(initialSupply <= DesynConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");

        // require(DesynConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");

        // To the extent possible, modify state variables before calling functions
        _mintPoolShare(initialSupply);
        _pushPoolShare(msg.sender, initialSupply);

        // Deploy new BPool (bFactory and bPool are interfaces; all calls are external)
        bPool = bFactory.newLiquidityPool();
        // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
        //   require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        SmartPoolManager.createPoolInternalHandle(bPool, initialSupply);
        for (uint i = 0; i < _initialTokens.length; i++) {
            address t = _initialTokens[i];
            uint bal = _initialBalances[i];
            uint denorm = _initialWeights[i];

            // require(this.isTokenWhitelisted(t), "ERR_TOKEN_NOT_IN_WHITELIST");
            _verifyWhiteToken(t);

            IERC20(t).safeTransferFrom(msg.sender, address(this), bal);
            IERC20(t).safeApprove(address(bPool), 0);
            IERC20(t).safeApprove(address(bPool), DesynConstants.MAX_UINT);

            bPool.bind(t, bal, denorm);
        }

        while (_initialTokens.length > 0) {
            // Modifying state variable after external calls here,
            // but not essential, so not dangerous
            _initialTokens.pop();
        }
    }

    function addTokenToWhitelist(uint[] memory sort, address[] memory token) external onlyOwner {
        require(rights.canTokenWhiteLists && hasSetWhiteTokens == false, "ERR_NO_RIGHTS");
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < token.length; i++) {
            bool inRange = bFactory.isTokenWhitelistedForVerify(sort[i], token[i]);
            require(inRange, "TOKEN_MUST_IN_WHITE_LISTS");
            _addTokenToWhitelist(sort[i], token[i]);
        }
        hasSetWhiteTokens = true;
    }

    function _verifyWhiteToken(address token) internal view {
        require(bFactory.isTokenWhitelistedForVerify(token), "ERR_NOT_WHITE_TOKEN_IN_FACTORY");

        if (hasSetWhiteTokens) {
            require(_queryIsTokenWhitelisted(token), "ERR_NOT_WHITE_TOKEN_IN_POOL");
        }
    }

    // Rebind BPool and pull tokens from address
    // bPool is a contract interface; function calls on it are external
    function _pullUnderlying(
        address erc20,
        address from,
        uint amount
    ) internal needsBPool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        IERC20(erc20).safeTransferFrom(from, address(this), amount);
        bPool.rebind(erc20, DesynSafeMath.badd(tokenBalance, amount), tokenWeight);
    }

    // Rebind BPool and push tokens to address
    // bPool is a contract interface; function calls on it are external
    function _pushUnderlying(
        address erc20,
        address to,
        uint amount
    ) internal needsBPool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, DesynSafeMath.bsub(tokenBalance, amount), tokenWeight);

        IERC20(erc20).safeTransfer(to, amount);
    }

    // Wrappers around corresponding core functions

    function _mint(uint amount) internal override {
        super._mint(amount);
        require(varTotalSupply <= etfStatus.upperCap, "ERR_CAP_LIMIT_REACHED");
    }

    function _mintPoolShare(uint amount) internal {
        _mint(amount);
    }

    function _pushPoolShare(address to, uint amount) internal {
        _push(to, amount);
    }

    function _pullPoolShare(address from, uint amount) internal {
        _pull(from, amount);
    }

    function _burnPoolShare(uint amount) internal {
        _burn(amount);
    }
}