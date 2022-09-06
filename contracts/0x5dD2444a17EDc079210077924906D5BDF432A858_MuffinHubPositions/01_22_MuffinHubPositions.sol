// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./interfaces/hub/positions/IMuffinHubPositions.sol";
import "./interfaces/IMuffinHubCallbacks.sol";
import "./libraries/utils/SafeTransferLib.sol";
import "./libraries/math/Math.sol";
import "./libraries/Positions.sol";
import "./libraries/Pools.sol";
import "./libraries/Settlement.sol";
import "./MuffinHubBase.sol";

/**
 * @dev "Implementation" contract for position-related functions, governance functions and various view functions, called
 * using DELEGATECALL. Codes are offloaded from the primary contract to here for reducing the primary contract's bytecode size.
 */
contract MuffinHubPositions is IMuffinHubPositions, MuffinHubBase {
    using Math for uint96;
    using Math for uint256;
    using Pools for Pools.Pool;
    using Pools for mapping(bytes32 => Pools.Pool);

    /*===============================================================
     *                          POSITIONS
     *==============================================================*/

    /// @inheritdoc IMuffinHubPositionsActions
    function mint(MintParams calldata params) external returns (uint256 amount0, uint256 amount1) {
        (Pools.Pool storage pool, bytes32 poolId) = pools.getPoolAndId(params.token0, params.token1);
        (amount0, amount1, , ) = pool.updateLiquidity(
            params.recipient,
            params.positionRefId,
            params.tierId,
            params.tickLower,
            params.tickUpper,
            params.liquidityD8.toInt96(),
            false
        );
        uint256 _amt0 = amount0;
        uint256 _amt1 = amount1;
        if (params.senderAccRefId != 0) {
            bytes32 accHash = getAccHash(msg.sender, params.senderAccRefId);
            (accounts[params.token0][accHash], _amt0) = accounts[params.token0][accHash].subUntilZero(_amt0);
            (accounts[params.token1][accHash], _amt1) = accounts[params.token1][accHash].subUntilZero(_amt1);
        }
        if (_amt0 != 0 || _amt1 != 0) {
            uint256 balance0Before = getBalanceAndLock(params.token0);
            uint256 balance1Before = getBalanceAndLock(params.token1);
            IMuffinHubCallbacks(msg.sender).muffinMintCallback(params.token0, params.token1, _amt0, _amt1, params.data);
            checkBalanceAndUnlock(params.token0, balance0Before + _amt0);
            checkBalanceAndUnlock(params.token1, balance1Before + _amt1);
        }
        emit Mint(
            poolId,
            params.recipient,
            params.positionRefId,
            params.tierId,
            params.tickLower,
            params.tickUpper,
            msg.sender,
            params.senderAccRefId,
            params.liquidityD8,
            amount0,
            amount1
        );
        pool.unlock();
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function burn(BurnParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        )
    {
        (Pools.Pool storage pool, bytes32 poolId) = pools.getPoolAndId(params.token0, params.token1);
        (amount0, amount1, feeAmount0, feeAmount1) = pool.updateLiquidity(
            msg.sender,
            params.positionRefId,
            params.tierId,
            params.tickLower,
            params.tickUpper,
            -params.liquidityD8.toInt96(),
            params.collectAllFees
        );
        bytes32 accHash = getAccHash(msg.sender, params.accRefId);
        accounts[params.token0][accHash] += amount0 + feeAmount0;
        accounts[params.token1][accHash] += amount1 + feeAmount1;
        emit Burn(
            poolId,
            msg.sender,
            params.positionRefId,
            params.tierId,
            params.tickLower,
            params.tickUpper,
            params.accRefId,
            params.liquidityD8,
            amount0,
            amount1,
            feeAmount0,
            feeAmount1
        );
        pool.unlock();
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function setLimitOrderType(
        address token0,
        address token1,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint256 positionRefId,
        uint8 limitOrderType
    ) external {
        (Pools.Pool storage pool, bytes32 poolId) = pools.getPoolAndId(token0, token1);
        pool.setLimitOrderType(msg.sender, positionRefId, tierId, tickLower, tickUpper, limitOrderType);
        emit SetLimitOrderType(poolId, msg.sender, positionRefId, tierId, tickLower, tickUpper, limitOrderType);
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function collectSettled(BurnParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmount0,
            uint256 feeAmount1
        )
    {
        (Pools.Pool storage pool, bytes32 poolId) = pools.getPoolAndId(params.token0, params.token1);
        (amount0, amount1, feeAmount0, feeAmount1) = pool.collectSettled(
            msg.sender,
            params.positionRefId,
            params.tierId,
            params.tickLower,
            params.tickUpper,
            params.liquidityD8,
            params.collectAllFees
        );
        bytes32 accHash = getAccHash(msg.sender, params.accRefId);
        accounts[params.token0][accHash] += amount0 + feeAmount0;
        accounts[params.token1][accHash] += amount1 + feeAmount1;
        emit CollectSettled(
            poolId,
            msg.sender,
            params.positionRefId,
            params.tierId,
            params.tickLower,
            params.tickUpper,
            params.accRefId,
            params.liquidityD8,
            amount0,
            amount1,
            feeAmount0,
            feeAmount1
        );
        pool.unlock();
    }

    /*===============================================================
     *                         VIEW FUNCTIONS
     *==============================================================*/

    /// @inheritdoc IMuffinHubPositionsView
    function getDefaultAllowedSqrtGammas() external view returns (uint24[] memory) {
        return defaultAllowedSqrtGammas;
    }

    /// @inheritdoc IMuffinHubPositionsView
    function getPoolAllowedSqrtGammas(bytes32 poolId) external view returns (uint24[] memory) {
        return poolAllowedSqrtGammas[poolId];
    }

    /// @inheritdoc IMuffinHubPositionsView
    function getPoolDefaultTickSpacing(bytes32 poolId) external view returns (uint8) {
        return poolDefaultTickSpacing[poolId];
    }

    /// @inheritdoc IMuffinHubPositionsView
    function getAllTiers(bytes32 poolId) external view returns (Tiers.Tier[] memory) {
        return pools[poolId].tiers;
    }

    /// @inheritdoc IMuffinHubPositionsView
    function getPositionFeeGrowthInside(
        bytes32 poolId,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint80 feeGrowthInside0, uint80 feeGrowthInside1) {
        return pools[poolId].getPositionFeeGrowthInside(owner, positionRefId, tierId, tickLower, tickUpper);
    }

    /// @inheritdoc IMuffinHubPositionsView
    function getSettlement(
        bytes32 poolId,
        uint8 tierId,
        int24 tick,
        bool zeroForOne
    )
        external
        view
        returns (
            uint96 liquidityD8,
            uint16 tickSpacing,
            uint32 nextSnapshotId
        )
    {
        Settlement.Info storage settlement = pools[poolId].settlements[tierId][tick][zeroForOne ? 1 : 0];
        return (settlement.liquidityD8, settlement.tickSpacing, settlement.nextSnapshotId);
    }

    /// @inheritdoc IMuffinHubPositionsView
    function getSettlementSnapshot(
        bytes32 poolId,
        uint8 tierId,
        int24 tick,
        bool zeroForOne,
        uint32 snapshotId
    ) external view returns (Settlement.Snapshot memory) {
        Settlement.Info storage settlement = pools[poolId].settlements[tierId][tick][zeroForOne ? 1 : 0];
        return settlement.snapshots[snapshotId];
    }

    /// @inheritdoc IMuffinHubPositionsView
    function getLimitOrderTickSpacingMultipliers(bytes32 poolId) external view returns (uint8[] memory) {
        return pools[poolId].getLimitOrderTickSpacingMultipliers();
    }

    function getTickMapBlockMap(bytes32 poolId, uint8 tierId) external view returns (uint256) {
        return pools[poolId].tickMaps[tierId].blockMap;
    }

    function getTickMapBlock(
        bytes32 poolId,
        uint8 tierId,
        uint256 blockIdx
    ) external view returns (uint256) {
        return pools[poolId].tickMaps[tierId].blocks[blockIdx];
    }

    function getTickMapWord(
        bytes32 poolId,
        uint8 tierId,
        uint256 wordIdx
    ) external view returns (uint256) {
        return pools[poolId].tickMaps[tierId].words[wordIdx];
    }

    /*===============================================================
     *                          GOVERNANCE
     *==============================================================*/

    /// @inheritdoc IMuffinHubPositionsActions
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit GovernanceUpdated(_governance);
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function setDefaultParameters(uint8 tickSpacing, uint8 protocolFee) external onlyGovernance {
        require(tickSpacing > 0);
        defaultTickSpacing = tickSpacing;
        defaultProtocolFee = protocolFee;
        emit UpdateDefaultParameters(tickSpacing, protocolFee);
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function setPoolParameters(
        bytes32 poolId,
        uint8 tickSpacing,
        uint8 protocolFee
    ) external onlyGovernance {
        pools[poolId].setPoolParameters(tickSpacing, protocolFee);
        emit UpdatePool(poolId, tickSpacing, protocolFee);
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function setTierParameters(
        bytes32 poolId,
        uint8 tierId,
        uint24 sqrtGamma,
        uint8 limitOrderTickSpacingMultiplier
    ) external onlyGovernance {
        Pools.Pool storage pool = pools[poolId];
        pool.setTierParameters(tierId, sqrtGamma, limitOrderTickSpacingMultiplier);
        emit UpdateTier(poolId, tierId, sqrtGamma, pool.tiers[tierId].sqrtPrice, limitOrderTickSpacingMultiplier);
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function setDefaultAllowedSqrtGammas(uint24[] calldata sqrtGammas) external onlyGovernance {
        defaultAllowedSqrtGammas = sqrtGammas;
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function setPoolAllowedSqrtGammas(bytes32 poolId, uint24[] calldata sqrtGammas) external onlyGovernance {
        poolAllowedSqrtGammas[poolId] = sqrtGammas;
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function setPoolDefaultTickSpacing(bytes32 poolId, uint8 tickSpacing) external onlyGovernance {
        poolDefaultTickSpacing[poolId] = tickSpacing;
    }

    /// @inheritdoc IMuffinHubPositionsActions
    function collectProtocolFee(address token, address recipient) external onlyGovernance returns (uint256 amount) {
        amount = tokens[token].protocolFeeAmt;
        tokens[token].protocolFeeAmt = 0;
        SafeTransferLib.safeTransfer(token, recipient, amount);
        emit CollectProtocol(recipient, token, amount);
    }
}