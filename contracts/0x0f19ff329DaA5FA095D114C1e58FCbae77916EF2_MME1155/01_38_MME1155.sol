// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Errors} from "../libraries/Errors.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Pool1155Logic} from "../libraries/Pool1155Logic.sol";
import {Liquidity1155Logic} from "../libraries/Liquidity1155Logic.sol";
import {AMMBase} from "./AMMBase.sol";
import {IMME1155} from "../interfaces/IMME1155.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {IAccessNFT} from "../interfaces/IAccessNFT.sol";
import {IERC20Extended} from "../interfaces/IERC20Extended.sol";

/**
 * @title MME1155
 * @author Souq.Finance
 * @notice The Contract of all Pools sharing MME1155 specification for single collection of shares
 * @notice the tokenDistribution will return 0 if not found
 * @notice The fees inputted should be in wad
 * @notice The F inputted should be in wad
 * @notice the V updated should have the same decimals of the stablecoin and be in terms of the same stablecoin
 * @notice coefficients are in wad
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */

contract MME1155 is Initializable, AMMBase, IMME1155, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using Pool1155Logic for DataTypes.AMMSubPool1155[];

    DataTypes.AMMSubPool1155[] public subPools;
    address public immutable factory;

    ///@notice token id -> pool
    ///@notice subpool is = 0 if token id doesn't exist
    mapping(uint256 => uint256) public tokenDistribution;

    //Liquidity providers have a time waiting period between deposit and withdraw
    DataTypes.Queued1155Withdrawals public queuedWithdrawals;

    constructor(address _factory, address addressRegistry) AMMBase(addressRegistry) {
        require(_factory != address(0), Errors.ADDRESS_IS_ZERO);
        factory = _factory;
    }

    /// @inheritdoc IMME1155
    function initialize(DataTypes.PoolData memory _poolData, string memory symbol, string memory name) external initializer {
        __Pausable_init();
        __Ownable_init();
        poolData = _poolData;
        poolData.fee.royaltiesBalance = 0;
        poolData.fee.royaltiesBalance = 0;
        poolData.poolLPToken = Pool1155Logic.deployLPToken(
            address(this),
            addressesRegistry,
            poolData.tokens,
            symbol,
            name,
            IERC20Extended(poolData.stable).decimals()
        );
        yieldReserve = 0;
    }

    /**
     * @dev modifier for the functions to be called by the timelock contract only
     */
    modifier timelockOnly() {
        if (IAddressesRegistry(addressesRegistry).getAddress("TIMELOCK") != address(0)) {
            require(IAddressesRegistry(addressesRegistry).getAddress("TIMELOCK") == msg.sender, Errors.CALLER_NOT_TIMELOCK);
        }
        _;
    }

    /**
     * @dev modifier for the access token enabled functions
     * @param tokenId the id of the access token
     * @param functionName the name of the function with the modifier
     */
    modifier useAccessNFT(uint256 tokenId, string memory functionName) {
        if (poolData.useAccessToken) {
            require(IAccessNFT(poolData.accessToken).HasAccessNFT(msg.sender, tokenId, functionName), Errors.FUNCTION_REQUIRES_ACCESS_NFT);
        }
        _;
    }

    /**
     * @dev modifier for when the onlyAdminProvisioning is true to restrict liquidity addition to pool admin
     */
    modifier checkAdminProvisioning() {
        if (poolData.liquidityLimit.onlyAdminProvisioning) {
            require(
                IAccessManager(IAddressesRegistry(addressesRegistry).getAccessManager()).isPoolAdmin(msg.sender),
                Errors.ONLY_ADMIN_CAN_ADD_LIQUIDITY
            );
        }
        _;
    }

    /// @inheritdoc IMME1155
    function pause() external onlyPoolAdmin {
        _pause();
        emit PoolPaused(msg.sender);
        ILPToken(poolData.poolLPToken).pause();
    }

    /// @inheritdoc IMME1155
    function unpause() external timelockOnly {
        _unpause();
        emit PoolUnpaused(msg.sender);
        ILPToken(poolData.poolLPToken).unpause();
    }

    /// @inheritdoc IMME1155
    function getTVL() external view returns (uint256) {
        return subPools.getTVL();
    }

    /// @inheritdoc IMME1155
    function getLPPrice() external view returns (uint256) {
        return subPools.getLPPrice(poolData.poolLPToken);
    }

    /// @inheritdoc IMME1155
    function getPool(uint256 subPoolId) external view returns (DataTypes.AMMSubPool1155Details memory subpool) {
        subpool.reserve = subPools[subPoolId].reserve;
        subpool.totalShares = subPools[subPoolId].totalShares;
        subpool.V = subPools[subPoolId].V;
        subpool.F = subPools[subPoolId].F;
        subpool.status = subPools[subPoolId].status;
    }

    /// @inheritdoc IMME1155
    function getQuote(
        uint256[] calldata amounts,
        uint256[] calldata tokenIds,
        bool buy,
        bool useFee
    ) external view returns (DataTypes.Quotation memory quotation) {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        quotation = Liquidity1155Logic.getQuote(
            DataTypes.QuoteParams({buy: buy, useFee: useFee}),
            sharesParams,
            poolData,
            subPools,
            tokenDistribution
        );
    }

    /// @inheritdoc IMME1155
    function swapStable(
        uint256[] memory requiredAmounts,
        uint256[] memory tokenIds,
        uint256 maxStable
    ) external nonReentrant useAccessNFT(1, "swapStable") whenNotPaused {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: requiredAmounts, tokenIds: tokenIds});
        Liquidity1155Logic.swapStable(msg.sender, maxStable, sharesParams, poolData, subPools, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function swapShares(
        uint256[] memory amounts,
        uint256[] memory tokenIds,
        uint256 minStable
    ) external nonReentrant useAccessNFT(1, "swapShares") whenNotPaused {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        Liquidity1155Logic.swapShares(msg.sender, minStable, yieldReserve, sharesParams, poolData, subPools, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function depositInitial(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 stableIn,
        uint256 subPoolId
    ) external nonReentrant onlyPoolAdmin {
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        Liquidity1155Logic.depositInitial(msg.sender, subPoolId, stableIn, sharesParams, poolData, subPools, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function addLiquidityStable(
        uint256 targetLP,
        uint256 maxStable
    ) external nonReentrant useAccessNFT(1, "addLiquidityStable") checkAdminProvisioning whenNotPaused {
        require(poolData.liquidityLimit.addLiqMode != 1, Errors.LIQUIDITY_MODE_RESTRICTED);
        Liquidity1155Logic.addLiquidityStable(msg.sender, targetLP, maxStable, poolData, subPools);
    }

    /// @inheritdoc IMME1155
    function addLiquidityShares(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 targetLP
    ) external nonReentrant useAccessNFT(1, "addLiquidityShares") checkAdminProvisioning whenNotPaused {
        require(poolData.liquidityLimit.addLiqMode != 0, Errors.LIQUIDITY_MODE_RESTRICTED);
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        Liquidity1155Logic.addLiquidityShares(msg.sender, targetLP, sharesParams, poolData, subPools, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function removeLiquidityStable(uint256 targetLP, uint256 minStable) external nonReentrant whenNotPaused {
        require(poolData.liquidityLimit.removeLiqMode != 1, Errors.LIQUIDITY_MODE_RESTRICTED);
        Liquidity1155Logic.removeLiquidityStable(msg.sender, yieldReserve, targetLP, minStable, poolData, subPools, queuedWithdrawals);
    }

    /// @inheritdoc IMME1155
    function removeLiquidityShares(
        uint256 targetLP,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external nonReentrant whenNotPaused {
        require(poolData.liquidityLimit.removeLiqMode != 0, Errors.LIQUIDITY_MODE_RESTRICTED);
        DataTypes.Shares1155Params memory sharesParams = DataTypes.Shares1155Params({amounts: amounts, tokenIds: tokenIds});
        Liquidity1155Logic.removeLiquidityShares(
            msg.sender,
            targetLP,
            sharesParams,
            poolData,
            subPools,
            queuedWithdrawals,
            tokenDistribution
        );
    }

    /// @inheritdoc IMME1155
    function processWithdrawals(uint256 limit) external whenNotPaused returns(uint256 transactions) {
        transactions = Liquidity1155Logic.processWithdrawals(limit, poolData, queuedWithdrawals);
    }

    /// @inheritdoc IMME1155
    function getTokenIdAvailable(uint256 tokenId) external view returns (uint256) {
        return subPools[tokenDistribution[tokenId]].shares[tokenId];
    }

    /// @inheritdoc IMME1155
    function getSubPools(uint256[] memory tokenIds) external view returns (uint256[] memory) {
        return Pool1155Logic.getSubPools(tokenIds, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function getSubPoolsSeq(uint256 startTokenId, uint256 endTokenId) external view returns (uint256[] memory) {
        return Pool1155Logic.getSubPoolsSeq(startTokenId, endTokenId, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function addSubPool(uint256 v, uint256 f) external onlyPoolAdmin {
        Pool1155Logic.addSubPool(v, f, subPools);
    }

    /// @inheritdoc IMME1155
    function updatePoolV(uint256[] calldata subPoolIds, uint256[] calldata vArray) external onlyPoolAdminOrOperations {
        Pool1155Logic.updatePoolV(subPoolIds, vArray, subPools, poolData);
    }

    /// @inheritdoc IMME1155
    function changeSubPoolStatus(uint256[] calldata subPoolIds, bool newStatus) external onlyPoolAdmin {
        Pool1155Logic.changeSubPoolStatus(subPoolIds, newStatus, subPools);
    }

    /// @inheritdoc IMME1155
    function moveReserve(uint256 moverId, uint256 movedId, uint256 amount) external onlyPoolAdmin {
        Pool1155Logic.moveReserve(moverId, movedId, amount, subPools, poolData);
    }

    /// @inheritdoc IMME1155
    function moveShares(uint256 startId, uint256 endId, uint256 newSubPoolId) external onlyPoolAdmin {
        Pool1155Logic.moveShares(startId, endId, newSubPoolId, subPools, poolData, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function moveSharesList(uint256 newSubPoolIds, uint256[] calldata ids) external onlyPoolAdmin {
        Pool1155Logic.moveSharesList(newSubPoolIds, ids, subPools, poolData, tokenDistribution);
    }

    /// @inheritdoc IMME1155
    function depositIntoStableYield(uint256 amount) external onlyPoolAdmin {
        yieldReserve += Pool1155Logic.depositIntoStableYield(amount, addressesRegistry, poolData.stableYieldAddress, yieldReserve);
    }

    /// @inheritdoc IMME1155
    function withdrawFromStableYield(uint256 amount) external onlyPoolAdmin {
        yieldReserve -= Pool1155Logic.withdrawFromStableYield(amount, addressesRegistry, poolData.stableYieldAddress, yieldReserve);
    }

    /// @inheritdoc IMME1155
    function RescueTokens(address token, uint256 amount, address receiver) external onlyPoolAdmin {
        Pool1155Logic.RescueTokens(token, amount, receiver, poolData.stable, poolData.poolLPToken);
    }

    /// @inheritdoc IMME1155
    function WithdrawFees(address to, uint256 amount, DataTypes.FeeType feeType) external {
        Pool1155Logic.withdrawFees(msg.sender, to, amount, feeType, poolData);
    }
}