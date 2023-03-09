// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./FjordLbpAbstractV1.sol";

struct PoolConfig {
    string name;
    string symbol;
    address[] tokens;
    uint256[] amounts;
    uint256[] weights;
    uint256[] endWeights;
    uint256 swapFeePercentage;
    uint256 startTime;
    uint256 endTime;
}

struct WeightedPoolConfig {
    string name;
    string symbol;
    address[] tokens;
    uint256[] amounts;
    uint256[] weights;
    uint256 swapFeePercentage;
}

struct PoolData {
    address owner;
    uint256 fundTokenInputAmount;
    LBPType lbpType;
    address weightedPoolAddress;
}

interface IRateProvider {
    /**
     * @dev Returns an 18 decimal fixed point number that is the exchange rate of the token to some other underlying
     * token. The meaning of this rate depends on the context.
     */
    function getRate() external view returns (uint256);
}

interface WeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IERC20[] memory tokens,
        uint256[] memory normalizedWeights,
        IRateProvider[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

/// @title FjordLbpProxyV6
/// @notice This contract allows for simplified creation and management of Balancer LBPs
/// It currently supports:
/// - LBPs with 2 tokens
/// - Withdrawal of the full liquidity at once
/// - Having multiple fee recipients
/// - Weighted Pools with 2 tokens
contract FjordLbpProxyV6 is FjordLbpAbstractV1 {
    address ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet internal _weightedPools;
    EnumerableSet.AddressSet internal _fundTokenAddresses;

    mapping(address => PoolData) private _poolData;
    address public immutable VaultAddress;
    address public immutable LBPFactoryAddress;
    address public immutable WeightedPoolFactoryAddress;
    uint256 public immutable platformAccessFeeBPS;

    event WeightedPoolCreated(
        address indexed pool,
        bytes32 poolId,
        string name,
        string symbol,
        address[] tokens,
        uint256[] weights,
        uint256 swapFeePercentage,
        address owner
    );

    event JoinedWeightedPool(address indexed pool, address[] tokens, uint256[] amounts, bytes userData);

    constructor(
        uint256 _platformAccessFeeBPS,
        address _LBPFactoryAddress,
        address _WeightedPoolFactoryAddress,
        address _vaultAddress,
        address[] memory fundTokenAddresses
    ) {
        require(_platformAccessFeeBPS <= 10_000, "LBP Fee cannot be greater than 10.000 (100%)");
        require(fundTokenAddresses.length > 0, "At least 1 fund needs to be used");
        lbpType = LBPType.NORMAL;
        platformAccessFeeBPS = _platformAccessFeeBPS;
        LBPFactoryAddress = _LBPFactoryAddress;
        WeightedPoolFactoryAddress = _WeightedPoolFactoryAddress;
        VaultAddress = _vaultAddress;
        // set initial fee recipient to owner of contract
        _recipientAddresses.add(owner());
        _feeRecipientsBPS[owner()] = _TEN_THOUSAND_BPS;
        addFundTokenOptions(fundTokenAddresses);
    }

    /**
     * Pool access control.
     * @dev Modifier to ensure only pool owners can perform actions
     */
    modifier onlyLBPPoolOwner(address pool) {
        require(msg.sender == _poolData[pool].owner, "!owner");
        _;
    }

    /**
     * Returns the list of allowed collateral tokens
     */
    function allowedFundTokens() external view returns (address[] memory fundTokens) {
        return _fundTokenAddresses.values();
    }

    /**
     * Returns whether a collateral token is allowed or not
     */
    function isAllowedFund(address tokenAddress) external view returns (bool) {
        return _fundTokenAddresses.contains(tokenAddress);
    }

    /**
     * @dev Checks if the weighted pool address was created in this smart contract
     */
    function isWeightedPool(address pool) external view returns (bool valid) {
        return _weightedPools.contains(pool);
    }

    /**
     * @dev Returns all the weighted pool values
     */
    function getWeightedPools() external view returns (address[] memory pools) {
        return _weightedPools.values();
    }

    /**
     * @dev Returns the total amount of weighted pools created in the contract
     */
    function weightedPoolCount() external view returns (uint256 count) {
        return _weightedPools.length();
    }

    /**
     * @dev Returns the pool's data saved during creation
     */
    function getPoolData(address pool) external view returns (PoolData memory poolData) {
        return _poolData[pool];
    }

    /**
     * @dev Creates a pool and return the contract address of the new pool
     * - poolConfig.tokens: tokens must be sorted ASC
     * - poolConfig.amounts: the index of each amount should be the same as the index of the token in Tokens
     * - poolConfig.weights: the index of each weight should be the same as the index of the token in Tokens
     */
    function createLBP(PoolConfig memory poolConfig) external returns (address) {
        // 1: deposit tokens and approve vault
        require(poolConfig.tokens.length == 2, "Copper LBPs must have exactly two tokens");
        require(poolConfig.tokens[0] != poolConfig.tokens[1], "LBP tokens must be unique");
        require(poolConfig.startTime > block.timestamp, "LBP start time must be in the future");
        require(poolConfig.endTime > poolConfig.startTime, "LBP end time must be greater than start time");
        require(blockListAddress != address(0), "no blocklist address set");
        bool msgSenderIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(msg.sender);
        require(msgSenderIsNotBlocked, "msg.sender is blocked");
        int256 indexOfFundToken = _findIndexOfFund(poolConfig.tokens);
        TransferHelper.safeTransferFrom(poolConfig.tokens[0], msg.sender, address(this), poolConfig.amounts[0]);
        TransferHelper.safeTransferFrom(poolConfig.tokens[1], msg.sender, address(this), poolConfig.amounts[1]);
        TransferHelper.safeApprove(poolConfig.tokens[0], VaultAddress, poolConfig.amounts[0]);
        TransferHelper.safeApprove(poolConfig.tokens[1], VaultAddress, poolConfig.amounts[1]);

        // 2: pool creation
        address pool = LBPFactory(LBPFactoryAddress).create(
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.tokens,
            poolConfig.weights,
            poolConfig.swapFeePercentage,
            address(this), // owner set to this proxy
            false // swaps disabled on start
        );

        bytes32 poolId = LBP(pool).getPoolId();
        emit PoolCreated(
            pool,
            poolId,
            poolConfig.name,
            poolConfig.symbol,
            poolConfig.tokens,
            poolConfig.weights,
            poolConfig.swapFeePercentage,
            address(this),
            false,
            lbpType
        );

        // 3: store pool data
        _poolData[pool] = PoolData(msg.sender, poolConfig.amounts[uint256(indexOfFundToken)], lbpType, address(0));
        require(_pools.add(pool), "exists already");

        bytes memory userData = abi.encode(0, poolConfig.amounts); // JOIN_KIND_INIT = 0
        // 4: deposit tokens into pool
        Vault(VaultAddress).joinPool(
            poolId,
            address(this), // sender
            address(this), // recipient
            Vault.JoinPoolRequest(poolConfig.tokens, poolConfig.amounts, userData, false)
        );
        emit JoinedPool(pool, poolConfig.tokens, poolConfig.amounts, userData);

        // 5: configure weights
        LBP(pool).updateWeightsGradually(poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);
        emit GradualWeightUpdateScheduled(pool, poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);

        return pool;
    }

    /**
     * @dev Enable or disables swaps.
     * Note: LBPs are created with trading disabled by default.
     */
    function setSwapEnabled(address pool, bool swapEnabled) external onlyLBPPoolOwner(pool) {
        LBP(pool).setSwapEnabled(swapEnabled);
        emit SwapEnabledSet(pool, swapEnabled);
    }

    /**
     * @dev Transfer ownership of the pool to a new owner
     */
    function transferPoolOwnership(address pool, address newOwner) external onlyLBPPoolOwner(pool) {
        require(blockListAddress != address(0), "no blocklist address set");
        bool newOwnerIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(msg.sender);
        require(newOwnerIsNotBlocked, "newOwner is blocked");

        address previousOwner = _poolData[pool].owner;
        _poolData[pool].owner = newOwner;
        emit TransferredPoolOwnership(pool, previousOwner, newOwner);
    }

    /**
     * @dev Exit a pool, burn the BPT token and transfer back the tokens.
     * - If maxBPTTokenOut is passed as 0, the function will use the total balance available for the BPT token.
     * - If maxBPTTokenOut is between 0 and the total of BPT available, that will be the amount used to burn.
     * maxBPTTokenOut must be greater than or equal to 0
     * - isStandardFee value should be true unless there is an issue with safeTransfer, in which case it can be passed
     * as false, and the fee will stay in the contract and later on distributed manualy to mitigate errors
     */
    function exitPool(address pool, uint256 maxBPTTokenOut, bool isStandardFee) external onlyLBPPoolOwner(pool) {
        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = uint256(0);
        minAmountsOut[1] = uint256(0);

        // 1. Get pool data
        bytes32 poolId = LBP(pool).getPoolId();
        (address[] memory poolTokens, uint256[] memory balances, ) = Vault(VaultAddress).getPoolTokens(poolId);
        require(poolTokens.length == minAmountsOut.length, "invalid input length");
        PoolData memory poolData = _poolData[pool];

        // 2. Specify the exact BPT amount to burn
        uint256 bptToBurn = _calcBPTokenToBurn(pool, maxBPTTokenOut);

        // 3. Exit pool and keep tokens in contract
        Vault(VaultAddress).exitPool(
            poolId,
            address(this),
            payable(address(this)),
            Vault.ExitPoolRequest(
                poolTokens,
                minAmountsOut,
                abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptToBurn),
                false
            )
        );

        // 4. Get the amount of Fund token from the pool that was left behind after exit (dust)
        (, uint256[] memory balancesAfterExit, ) = Vault(VaultAddress).getPoolTokens(poolId);
        int256 indexOfFundToken = _findIndexOfFund(poolTokens);

        // 5. Distribute tokens and fees
        _distributeTokens(
            pool,
            poolTokens,
            poolData,
            balances[uint256(indexOfFundToken)] - balancesAfterExit[uint256(indexOfFundToken)],
            isStandardFee,
            indexOfFundToken
        );
    }

    /**
     * @dev Distributes the tokens to the owner and the fee to the fee recipients
     */
    function _distributeTokens(
        address pool,
        address[] memory poolTokens,
        PoolData memory poolData,
        uint256 fundTokenFromPool,
        bool isStandardFee,
        int256 indexOfFundToken
    ) private {
        require(indexOfFundToken >= 0, "No valid collateral token found");

        address mainToken = poolTokens[indexOfFundToken == 0 ? 1 : 0];
        address fundToken = poolTokens[uint256(indexOfFundToken)];
        uint256 mainTokenBalance = IERC20(mainToken).balanceOf(address(this));
        uint256 remainingFundBalance = fundTokenFromPool;

        // if the amount of fund token increased during the LBP
        if (fundTokenFromPool > poolData.fundTokenInputAmount) {
            uint256 totalPlatformAccessFeeAmount = ((fundTokenFromPool - poolData.fundTokenInputAmount) *
                platformAccessFeeBPS) / _TEN_THOUSAND_BPS;
            // Fund amount after substracting the fee
            remainingFundBalance = fundTokenFromPool - totalPlatformAccessFeeAmount;

            if (isStandardFee == true) {
                _distributePlatformAccessFee(pool, fundToken, totalPlatformAccessFeeAmount);
            } else {
                _distributeSafeFee(pool, fundToken, totalPlatformAccessFeeAmount);
            }
        }

        // Transfer the balance of the main token
        _transferTokenToPoolOwner(pool, mainToken, mainTokenBalance);
        // Transfer the balanace of fund token excluding the platform access fee
        _transferTokenToPoolOwner(pool, fundToken, remainingFundBalance);
    }

    /**
     * @dev Creates a weighted pool for an existing LBP.
     * - The owner of the LBP must be the creator of the weighted pool
     * - Only one can be created for each LBP
     */
    function createWeightedPoolForLBP(
        address lbpPool,
        WeightedPoolConfig memory weightedPoolConfig
    ) external onlyLBPPoolOwner(lbpPool) returns (address) {
        // 1: deposit tokens and approve vault
        require(weightedPoolConfig.tokens.length == 2, "Weighted pool must have exactly two tokens");
        require(weightedPoolConfig.tokens[0] != weightedPoolConfig.tokens[1], "Tokens must be unique");
        require(blockListAddress != address(0), "no blocklist address set");
        require(Blocklist(blockListAddress).isNotBlocked(msg.sender), "msg.sender is blocked");
        require(_poolData[lbpPool].weightedPoolAddress == address(0), "Weighted pool already exists for this LBP");

        TransferHelper.safeTransferFrom(
            weightedPoolConfig.tokens[0],
            msg.sender,
            address(this),
            weightedPoolConfig.amounts[0]
        );
        TransferHelper.safeTransferFrom(
            weightedPoolConfig.tokens[1],
            msg.sender,
            address(this),
            weightedPoolConfig.amounts[1]
        );
        TransferHelper.safeApprove(weightedPoolConfig.tokens[0], VaultAddress, weightedPoolConfig.amounts[0]);
        TransferHelper.safeApprove(weightedPoolConfig.tokens[1], VaultAddress, weightedPoolConfig.amounts[1]);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = IERC20(weightedPoolConfig.tokens[0]);
        tokens[1] = IERC20(weightedPoolConfig.tokens[1]);
        IRateProvider[] memory rateProviders = new IRateProvider[](2);
        rateProviders[0] = IRateProvider(ZERO_ADDRESS);
        rateProviders[1] = IRateProvider(ZERO_ADDRESS);

        // 2: pool creation
        address weightedPool = WeightedPoolFactory(WeightedPoolFactoryAddress).create(
            weightedPoolConfig.name,
            weightedPoolConfig.symbol,
            tokens,
            weightedPoolConfig.weights,
            rateProviders,
            weightedPoolConfig.swapFeePercentage,
            msg.sender
        );

        bytes32 poolId = WeightedPool(weightedPool).getPoolId();
        emit WeightedPoolCreated(
            weightedPool,
            poolId,
            weightedPoolConfig.name,
            weightedPoolConfig.symbol,
            weightedPoolConfig.tokens,
            weightedPoolConfig.weights,
            weightedPoolConfig.swapFeePercentage,
            msg.sender
        );

        // 3: store pool data
        _poolData[lbpPool].weightedPoolAddress = weightedPool;
        require(_weightedPools.add(weightedPool), "exists already");

        bytes memory userData = abi.encode(0, weightedPoolConfig.amounts); // JOIN_KIND_INIT = 0
        // 4: deposit tokens into pool and send Weighted Pool Tokens to creator
        Vault(VaultAddress).joinPool(
            poolId,
            address(this), // sender
            msg.sender, // recipient
            Vault.JoinPoolRequest(weightedPoolConfig.tokens, weightedPoolConfig.amounts, userData, false)
        );
        emit JoinedWeightedPool(weightedPool, weightedPoolConfig.tokens, weightedPoolConfig.amounts, userData);
        return weightedPool;
    }

    /**
     * @dev Returns the total amount of weighted Tokens for a pool. These tokens are burned when exit
     */
    function getWeightedTokenBalance(address weightedPool) external view returns (uint256 weightedBalance) {
        return IERC20(weightedPool).balanceOf(msg.sender);
    }

    /**
     * Finds the id of the fund token and returns the index
     * If only one fund token is not found an error is thrown
     */
    function _findIndexOfFund(address[] memory tokens) internal view returns (int256) {
        bool isToken1Fund = _fundTokenAddresses.contains(tokens[0]);
        bool isToken2Fund = _fundTokenAddresses.contains(tokens[1]);

        // 1 of the tokens must be a fund token
        require(isToken1Fund == true || isToken2Fund == true, "At least one token must be a collateral token");
        // 1 of the tokens must not be a fund token
        require(
            isToken1Fund == false || isToken2Fund == false,
            "At least one of the token must not be a collateral token"
        );

        return isToken1Fund == true ? int256(0) : int256(1);
    }

    /**
     * Adds a list of token addresses as options for fund tokens
     */
    function addFundTokenOptions(address[] memory tokens) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            _fundTokenAddresses.add(tokens[i]);
        }
    }
}