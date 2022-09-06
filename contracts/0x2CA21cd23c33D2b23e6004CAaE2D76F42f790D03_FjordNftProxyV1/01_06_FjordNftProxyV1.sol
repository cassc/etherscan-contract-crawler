// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

enum LBPType {
    NORMAL,
    NFT
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface LBPFactory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    ) external returns (address);
}

interface Vault {
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256 amountCalculated);
}

interface LBP {
    function updateWeightsGradually(
        uint256 startTime,
        uint256 endTime,
        uint256[] memory endWeights
    ) external;

    function setSwapEnabled(bool swapEnabled) external;

    function getPoolId() external returns (bytes32 poolID);
}

interface Blocklist {
    function isNotBlocked(address _address) external view returns (bool);
}

/// @title FjordNftProxyV1
/// @notice This contract allows for simplified creation and management of Balancer NFT LBPs
/// It currently supports:
/// - LBPs with 2 tokens
/// - Withdrawl of the full liquidity at once
/// - Having multiple fee recipients
/// - IPFS support
contract FjordNftProxyV1 is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PoolData {
        address owner;
        bool isCorrectOrder;
        uint256 fundTokenInputAmount;
        string metadataIpfsHash;
        LBPType lbpType;
    }

    mapping(address => PoolData) private _poolData;
    EnumerableSet.AddressSet private _pools;
    mapping(address => uint256) private _feeRecipientsBPS;
    EnumerableSet.AddressSet private _recipientAddresses;

    uint256 private constant _TEN_THOUSAND_BPS = 10_000;
    address public immutable VaultAddress;
    address public immutable LBPFactoryAddress;
    uint256 public immutable platformAccessFeeBPS;
    address public blockListAddress;

    constructor(
        uint256 _platformAccessFeeBPS,
        address _LBPFactoryAddress,
        address _vaultAddress
    ) {
        platformAccessFeeBPS = _platformAccessFeeBPS;
        LBPFactoryAddress = _LBPFactoryAddress;
        VaultAddress = _vaultAddress;
        // set initial fee recipient to owner of contract
        _recipientAddresses.add(owner());
        _feeRecipientsBPS[owner()] = _TEN_THOUSAND_BPS;
    }

    // Events
    event PoolCreated(
        address indexed pool,
        bytes32 poolId,
        string name,
        string symbol,
        address[] tokens,
        uint256[] weights,
        uint256 swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    );

    event JoinedPool(address indexed pool, address[] tokens, uint256[] amounts, bytes userData);

    event GradualWeightUpdateScheduled(address indexed pool, uint256 startTime, uint256 endTime, uint256[] endWeights);

    event SwapEnabledSet(address indexed pool, bool swapEnabled);

    event IPFSChanged(address indexed pool, string oldIpfs, string newIpfs);

    event TransferredPoolOwnership(address indexed pool, address previousOwner, address newOwner);

    event TransferredFee(address indexed pool, address token, address feeRecipient, uint256 feeAmount);

    event TransferredToken(address indexed pool, address token, address to, uint256 amount);

    event RecipientsUpdated(address[] recipients, uint256[] recipientShareBPS);

    event Skimmed(address token, address to, uint256 balance);

    // Pool access control
    modifier onlyPoolOwner(address pool) {
        require(msg.sender == _poolData[pool].owner, "!owner");
        _;
    }

    /**
     * @dev Checks if the pool address was created in this smart contract
     */
    function isPool(address pool) external view returns (bool valid) {
        return _pools.contains(pool);
    }

    /**
     * @dev Returns the total amount of pools created in the contract
     */
    function poolCount() external view returns (uint256 count) {
        return _pools.length();
    }

    /**
     * @dev Returns a pool for a specific index
     */
    function getPoolAt(uint256 index) external view returns (address pool) {
        return _pools.at(index);
    }

    /**
     * @dev Returns all the pool values
     */
    function getPools() external view returns (address[] memory pools) {
        return _pools.values();
    }

    /**
     * @dev Returns the pool's data saved during creation
     */
    function getPoolData(address pool) external view returns (PoolData memory poolData) {
        return _poolData[pool];
    }

    /**
     * @dev Returns the total amount of LBP Tokens for a pool. These tokens are burned when exit
     */
    function getBPTTokenBalance(address pool) external view returns (uint256 bptBalance) {
        return IERC20(pool).balanceOf(address(this));
    }

    /**
     * @dev Returns all the fee recipients
     */
    function getFeeRecipients() external view returns (address[] memory recipients) {
        return _recipientAddresses.values();
    }

    /**
     * @dev Returns the fee share percentage in BPS for a fee recipient
     */
    function getRecipientShareBPS(address recipientAddress) external view returns (uint256 shareSize) {
        if (_recipientAddresses.contains(recipientAddress)) {
            return _feeRecipientsBPS[recipientAddress];
        }
        return uint256(0);
    }

    /**
     * @dev Change the IPFS hash for a pool address
     */
    function changeIpfsRecordByPoolAddress(address pool, string memory newIpfsHash) external onlyOwner {
        emit IPFSChanged(pool, _poolData[pool].metadataIpfsHash, newIpfsHash);
        _poolData[pool].metadataIpfsHash = newIpfsHash;
    }

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
        string metadataIpfsHash;
    }

    /**
     * @dev Creates a pool and return the contract address of the new pool
     */
    function createLBP(PoolConfig memory poolConfig) external returns (address) {
        // 1: deposit tokens and approve vault
        require(poolConfig.tokens.length == 2, "Fjord Drops must have exactly two tokens");
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
            false
        );

        // 3: store pool data
        _poolData[pool] = PoolData(
            msg.sender,
            poolConfig.isCorrectOrder,
            poolConfig.amounts[poolConfig.isCorrectOrder ? 0 : 1],
            poolConfig.metadataIpfsHash,
            LBPType.NFT
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
    function setSwapEnabled(address pool, bool swapEnabled) external onlyPoolOwner(pool) {
        LBP(pool).setSwapEnabled(swapEnabled);
        emit SwapEnabledSet(pool, swapEnabled);
    }

    /**
     * @dev Transfer ownership of the pool to a new owner
     */
    function transferPoolOwnership(address pool, address newOwner) external onlyPoolOwner(pool) {
        require(blockListAddress != address(0), "no blocklist address set");
        bool newOwnerIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(msg.sender);
        require(newOwnerIsNotBlocked, "newOwner is blocked");

        address previousOwner = _poolData[pool].owner;
        _poolData[pool].owner = newOwner;
        emit TransferredPoolOwnership(pool, previousOwner, newOwner);
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT
    }

    /**
     * @dev calculate the amount of BPToken to burn.
     * - if maxBPTTokenOut is 0, everything will be burned
     * - else it will burn only the amount passed
     */
    function _calcBPTokenToBurn(address pool, uint256 maxBPTTokenOut) internal view returns (uint256) {
        uint256 bptBalance = IERC20(pool).balanceOf(address(this));
        require(maxBPTTokenOut <= bptBalance, "Specifed BPT out amount out exceeds owner balance");
        require(bptBalance > 0, "Pool owner BPT balance is less than zero");
        return maxBPTTokenOut == 0 ? bptBalance : maxBPTTokenOut;
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
    ) external onlyPoolOwner(pool) {
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
    ) internal {
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

    /**
     * @dev Transfer token to pool owner
     */
    function _transferTokenToPoolOwner(
        address pool,
        address token,
        uint256 amount
    ) private {
        TransferHelper.safeTransfer(token, msg.sender, amount);
        emit TransferredToken(pool, token, msg.sender, amount);
    }

    /**
     * @dev Send fee to owner of contract.
     *      Only used for exits where there was a transfer error between fee recipients
     */
    function _distributeSafeFee(
        address pool,
        address fundToken,
        uint256 totalFeeAmount
    ) private {
        TransferHelper.safeTransfer(fundToken, owner(), totalFeeAmount);
        emit TransferredFee(pool, fundToken, owner(), totalFeeAmount);
    }

    /**
     * @dev Distribute fee between recipients
     */
    function _distributePlatformAccessFee(
        address pool,
        address fundToken,
        uint256 totalFeeAmount
    ) private {
        uint256 recipientsLength = _recipientAddresses.length();
        for (uint256 i = 0; i < recipientsLength; i++) {
            address recipientAddress = _recipientAddresses.at(i);
            // calculate amount for each recipient based on the their _feeRecipientsBPS
            uint256 proportionalAmount = (totalFeeAmount * _feeRecipientsBPS[recipientAddress]) / _TEN_THOUSAND_BPS;
            TransferHelper.safeTransfer(fundToken, recipientAddress, proportionalAmount);
            emit TransferredFee(pool, fundToken, recipientAddress, proportionalAmount);
        }
    }

    /**
     * @dev Resets _recipientAddresses mapping and _feeRecipientsBPS.
     * Note this should only be used in updateRecipients.
     *      None of these mapping/array should be empty
     */
    function _resetRecipients() private {
        uint256 recipientsLength = _recipientAddresses.length();
        address[] memory recipientValues = _recipientAddresses.values();
        for (uint256 i = 0; i < recipientsLength; i++) {
            address recipientAddress = recipientValues[i];
            delete _feeRecipientsBPS[recipientAddress];
            _recipientAddresses.remove(recipientAddress);
        }
    }

    /**
     * @dev Updates recipients and share.
     * NOTE: the first recipient will be the one used for emergency safeDistributeFee
     */
    function updateRecipients(address[] calldata recipients, uint256[] calldata recipientShareBPS) external onlyOwner {
        require(recipients.length > 0, "recipients must have values");
        require(recipientShareBPS.length > 0, "recipientShareBPS must have values");
        require(
            recipients.length == recipientShareBPS.length,
            "'recipients' and 'recipientShareBPS' arrays must have the same length"
        );
        _resetRecipients();
        require(blockListAddress != address(0), "no blocklist address set");
        uint256 sumBPS = 0;
        uint256 arraysLength = recipientShareBPS.length;
        for (uint256 i = 0; i < arraysLength; i++) {
            require(recipientShareBPS[i] > uint256(0), "Share BPS size must be greater than 0");
            bool recipientIsNotBlocked = Blocklist(blockListAddress).isNotBlocked(recipients[i]);
            require(recipientIsNotBlocked, "recipient is blocked");
            sumBPS += recipientShareBPS[i];
            _recipientAddresses.add(recipients[i]);
            _feeRecipientsBPS[recipients[i]] = recipientShareBPS[i];
        }
        require(sumBPS == _TEN_THOUSAND_BPS, "Invalid recipients BPS sum");
        require(_recipientAddresses.length() == recipientShareBPS.length, "Fee recipient address must be unique");
        // emit event
        emit RecipientsUpdated(recipients, recipientShareBPS);
    }

    /**
     * @dev Transfer any token that is not LBPT to the given address
     */
    function skim(address token, address recipient) external onlyOwner {
        require(!_pools.contains(token), "can't skim BPT tokens");
        uint256 balance = IERC20(token).balanceOf(address(this));
        TransferHelper.safeTransfer(token, recipient, balance);
        emit Skimmed(token, recipient, balance);
    }

    function updateBlocklistAddress(address contractAddress) external onlyOwner {
        blockListAddress = contractAddress;
    }
}