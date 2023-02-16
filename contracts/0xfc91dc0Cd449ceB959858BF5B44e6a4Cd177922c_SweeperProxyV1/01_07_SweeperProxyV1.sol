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
    bool isCorrectOrder;
    uint256 swapFeePercentage;
    uint256 startTime;
    uint256 endTime;
}

struct PoolData {
    address owner;
    bool isCorrectOrder;
    uint256 fundTokenInputAmount;
    LBPType lbpType;
}

/// @title SweeperProxyV1
/// @notice This contract allows for simplified creation and management of Balancer LBPs
/// It currently supports:
/// - LBPs with 2 tokens
/// - Withdrawl of the full liquidity at once
/// - Having multiple fee recipients
contract SweeperProxyV1 is FjordLbpAbstractV1 {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => PoolData) private _poolData;
    address public immutable VaultAddress;
    address public immutable LBPFactoryAddress;
    uint256 public immutable platformAccessFeeBPS;

    constructor(
        uint256 _platformAccessFeeBPS,
        address _LBPFactoryAddress,
        address _vaultAddress
    ) {
        require(_platformAccessFeeBPS <= 10_000, "LBP Fee cannot be greater than 10.000 (100%)");
        lbpType = LBPType.SWEEPER;
        platformAccessFeeBPS = _platformAccessFeeBPS;
        LBPFactoryAddress = _LBPFactoryAddress;
        VaultAddress = _vaultAddress;
        // set initial fee recipient to owner of contract
        _recipientAddresses.add(owner());
        _feeRecipientsBPS[owner()] = _TEN_THOUSAND_BPS;
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
     * @dev Returns the pool's data saved during creation
     */
    function getPoolData(address pool) external view returns (PoolData memory poolData) {
        return _poolData[pool];
    }

    /**
     * @dev Creates a pool and return the contract address of the new pool
     */
    function createLBP(PoolConfig memory poolConfig) external returns (address) {
        // 1: deposit tokens and approve vault
        require(poolConfig.tokens.length == 2, "Fjord LBPs must have exactly two tokens");
        require(poolConfig.tokens[0] != poolConfig.tokens[1], "LBP tokens must be unique");
        require(poolConfig.startTime > block.timestamp, "LBP start time must be in the future");
        require(poolConfig.endTime > poolConfig.startTime, "LBP end time must be greater than start time");
        require(blockListAddress != address(0), "no blocklist address set");
        bool msgSenderIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(msg.sender);
        require(msgSenderIsNotBlocked, "msg.sender is blocked");
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
        _poolData[pool] = PoolData(
            msg.sender,
            poolConfig.isCorrectOrder,
            poolConfig.amounts[poolConfig.isCorrectOrder ? 0 : 1],
            lbpType
        );
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
    function exitPool(
        address pool,
        uint256 maxBPTTokenOut,
        bool isStandardFee
    ) external onlyLBPPoolOwner(pool) {
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
        uint256 fundTokenIndex = poolData.isCorrectOrder ? 0 : 1;

        // 5. Distribute tokens and fees
        _distributeTokens(
            pool,
            poolTokens,
            poolData,
            balances[fundTokenIndex] - balancesAfterExit[fundTokenIndex],
            isStandardFee
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
        bool isStandardFee
    ) private {
        address mainToken = poolTokens[poolData.isCorrectOrder ? 1 : 0];
        address fundToken = poolTokens[poolData.isCorrectOrder ? 0 : 1];
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
}