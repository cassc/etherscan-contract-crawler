// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/UnitConverter.sol";
import "./AdminPrivileges.sol";
import "./AdminWallet.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingService.sol";

/**
 * @title StakingService
 * @author Tim Loh
 * @notice Provides staking functionalities
 */
contract StakingService is
    Pausable,
    AdminPrivileges,
    AdminWallet,
    IStakingService
{
    using SafeERC20 for IERC20;
    using UnitConverter for uint256;

    struct StakeInfo {
        uint256 stakeAmountWei;
        uint256 stakeTimestamp;
        uint256 stakeMaturityTimestamp; // timestamp when stake matures
        uint256 estimatedRewardAtMaturityWei; // estimated reward at maturity in Wei
        uint256 rewardClaimedWei; // reward claimed in Wei
        bool isActive; // true if allow claim rewards and unstake
        bool isInitialized; // true if stake info has been initialized
    }

    struct StakingPoolStats {
        uint256 totalRewardWei; // total pool reward in Wei
        uint256 totalStakedWei; // total staked inside pool in Wei
        uint256 rewardToBeDistributedWei; // allocated pool reward to be distributed in Wei
        uint256 totalRevokedStakeWei; // total revoked stake in Wei
    }

    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant PERCENT_100_WEI = 100 ether;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant TOKEN_MAX_DECIMALS = 18;

    address public stakingPoolContract;

    mapping(bytes => StakeInfo) private _stakes;
    mapping(bytes32 => StakingPoolStats) private _stakingPoolStats;

    constructor(address stakingPoolContract_) {
        require(stakingPoolContract_ != address(0), "SSvcs: staking pool");

        stakingPoolContract = stakingPoolContract_;
    }

    /**
     * @inheritdoc IStakingService
     */
    function claimReward(bytes32 poolId)
        external
        virtual
        override
        whenNotPaused
    {
        (
            ,
            ,
            ,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,
            bool isPoolActive
        ) = _getStakingPoolInfo(poolId);
        require(isPoolActive, "SSvcs: pool suspended");

        bytes memory stakekey = _getStakeKey(poolId, msg.sender);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");
        require(_stakes[stakekey].isActive, "SSvcs: stake suspended");
        require(_isStakeMaturedByStakekey(stakekey), "SSvcs: not mature");

        uint256 rewardAmountWei = _getClaimableRewardWeiByStakekey(stakekey);
        require(rewardAmountWei > 0, "SSvcs: zero reward");

        _stakingPoolStats[poolId].totalRewardWei -= rewardAmountWei;
        _stakingPoolStats[poolId].rewardToBeDistributedWei -= rewardAmountWei;
        _stakes[stakekey].rewardClaimedWei += rewardAmountWei;

        emit RewardClaimed(
            poolId,
            msg.sender,
            rewardTokenAddress,
            rewardAmountWei
        );

        _transferTokensToAccount(
            rewardTokenAddress,
            rewardTokenDecimals,
            rewardAmountWei,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function stake(bytes32 poolId, uint256 stakeAmountWei)
        external
        virtual
        override
        whenNotPaused
    {
        require(stakeAmountWei > 0, "SSvcs: stake amount");

        (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            ,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isPoolOpen,

        ) = _getStakingPoolInfo(poolId);
        require(isPoolOpen, "SSvcs: closed");

        uint256 stakeMaturityTimestamp = _calculateStakeMaturityTimestamp(
            stakeDurationDays,
            block.timestamp
        );
        require(
            stakeMaturityTimestamp > block.timestamp,
            "SSvcs: maturity timestamp"
        );

        uint256 truncatedStakeAmountWei = _truncatedAmountWei(
            stakeAmountWei,
            stakeTokenDecimals
        );
        require(truncatedStakeAmountWei > 0, "SSvcs: truncated stake amount");

        uint256 estimatedRewardAtMaturityWei = _truncatedAmountWei(
            _estimateRewardAtMaturityWei(
                stakeDurationDays,
                poolAprWei,
                truncatedStakeAmountWei
            ),
            rewardTokenDecimals
        );
        require(estimatedRewardAtMaturityWei > 0, "SSvcs: zero reward");
        require(
            estimatedRewardAtMaturityWei <=
                _calculatePoolRemainingRewardWei(poolId),
            "SSvcs: insufficient"
        );

        bytes memory stakekey = _getStakeKey(poolId, msg.sender);
        if (_stakes[stakekey].isInitialized) {
            uint256 stakeDurationAtAddStakeDays = (block.timestamp -
                _stakes[stakekey].stakeTimestamp) / SECONDS_IN_DAY;
            uint256 earnedRewardAtAddStakeWei = _truncatedAmountWei(
                _estimateRewardAtMaturityWei(
                    stakeDurationAtAddStakeDays,
                    poolAprWei,
                    _stakes[stakekey].stakeAmountWei
                ),
                rewardTokenDecimals
            );
            estimatedRewardAtMaturityWei += earnedRewardAtAddStakeWei;
            require(
                estimatedRewardAtMaturityWei <=
                    _calculatePoolRemainingRewardWei(poolId),
                "SSvcs: insufficient"
            );

            _stakes[stakekey].stakeAmountWei += truncatedStakeAmountWei;
            _stakes[stakekey].stakeTimestamp = block.timestamp;
            _stakes[stakekey].stakeMaturityTimestamp = stakeMaturityTimestamp;
            _stakes[stakekey]
                .estimatedRewardAtMaturityWei += estimatedRewardAtMaturityWei;
        } else {
            _stakes[stakekey] = StakeInfo({
                stakeAmountWei: truncatedStakeAmountWei,
                stakeTimestamp: block.timestamp,
                stakeMaturityTimestamp: stakeMaturityTimestamp,
                estimatedRewardAtMaturityWei: estimatedRewardAtMaturityWei,
                rewardClaimedWei: 0,
                isActive: true,
                isInitialized: true
            });
        }

        _stakingPoolStats[poolId].totalStakedWei += truncatedStakeAmountWei;
        _stakingPoolStats[poolId]
            .rewardToBeDistributedWei += estimatedRewardAtMaturityWei;

        emit Staked(
            poolId,
            msg.sender,
            stakeTokenAddress,
            truncatedStakeAmountWei,
            block.timestamp,
            stakeMaturityTimestamp,
            _stakes[stakekey].estimatedRewardAtMaturityWei
        );

        _transferTokensToContract(
            stakeTokenAddress,
            stakeTokenDecimals,
            truncatedStakeAmountWei,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function unstake(bytes32 poolId) external virtual override whenNotPaused {
        (
            ,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,
            bool isPoolActive
        ) = _getStakingPoolInfo(poolId);
        require(isPoolActive, "SSvcs: pool suspended");

        bytes memory stakekey = _getStakeKey(poolId, msg.sender);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");
        require(_stakes[stakekey].isActive, "SSvcs: stake suspended");
        require(_isStakeMaturedByStakekey(stakekey), "SSvcs: not mature");

        uint256 stakeAmountWei = _stakes[stakekey].stakeAmountWei;
        require(stakeAmountWei > 0, "SSvcs: zero stake");

        uint256 rewardAmountWei = _getClaimableRewardWeiByStakekey(stakekey);

        _stakingPoolStats[poolId].totalStakedWei -= stakeAmountWei;
        _stakingPoolStats[poolId].totalRewardWei -= rewardAmountWei;
        _stakingPoolStats[poolId].rewardToBeDistributedWei -= rewardAmountWei;

        _stakes[stakekey] = StakeInfo({
            stakeAmountWei: 0,
            stakeTimestamp: 0,
            stakeMaturityTimestamp: 0,
            estimatedRewardAtMaturityWei: 0,
            rewardClaimedWei: 0,
            isActive: false,
            isInitialized: false
        });

        emit Unstaked(
            poolId,
            msg.sender,
            stakeTokenAddress,
            stakeAmountWei,
            rewardTokenAddress,
            rewardAmountWei
        );

        if (
            stakeTokenAddress == rewardTokenAddress &&
            stakeTokenDecimals == rewardTokenDecimals
        ) {
            _transferTokensToAccount(
                stakeTokenAddress,
                stakeTokenDecimals,
                stakeAmountWei + rewardAmountWei,
                msg.sender
            );
        } else {
            _transferTokensToAccount(
                stakeTokenAddress,
                stakeTokenDecimals,
                stakeAmountWei,
                msg.sender
            );

            if (rewardAmountWei > 0) {
                _transferTokensToAccount(
                    rewardTokenAddress,
                    rewardTokenDecimals,
                    rewardAmountWei,
                    msg.sender
                );
            }
        }
    }

    /**
     * @inheritdoc IStakingService
     */
    function addStakingPoolReward(bytes32 poolId, uint256 rewardAmountWei)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        require(rewardAmountWei > 0, "SSvcs: reward amount");

        (
            ,
            ,
            ,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        uint256 truncatedRewardAmountWei = rewardTokenDecimals <
            TOKEN_MAX_DECIMALS
            ? rewardAmountWei
                .scaleWeiToDecimals(rewardTokenDecimals)
                .scaleDecimalsToWei(rewardTokenDecimals)
            : rewardAmountWei;

        _stakingPoolStats[poolId].totalRewardWei += truncatedRewardAmountWei;

        emit StakingPoolRewardAdded(
            poolId,
            msg.sender,
            rewardTokenAddress,
            truncatedRewardAmountWei
        );

        _transferTokensToContract(
            rewardTokenAddress,
            rewardTokenDecimals,
            truncatedRewardAmountWei,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function removeRevokedStakes(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        (
            ,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            ,
            ,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        require(
            _stakingPoolStats[poolId].totalRevokedStakeWei > 0,
            "SSvcs: no revoked"
        );

        uint256 totalRevokedStakeWei = _stakingPoolStats[poolId]
            .totalRevokedStakeWei;
        _stakingPoolStats[poolId].totalRevokedStakeWei = 0;

        emit RevokedStakesRemoved(
            poolId,
            msg.sender,
            adminWallet(),
            stakeTokenAddress,
            totalRevokedStakeWei
        );

        _transferTokensToAccount(
            stakeTokenAddress,
            stakeTokenDecimals,
            totalRevokedStakeWei,
            adminWallet()
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function removeUnallocatedStakingPoolReward(bytes32 poolId)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        (
            ,
            ,
            ,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        uint256 unallocatedRewardWei = _calculatePoolRemainingRewardWei(poolId);
        require(unallocatedRewardWei > 0, "SSvcs: no unallocated");

        _stakingPoolStats[poolId].totalRewardWei -= unallocatedRewardWei;

        emit StakingPoolRewardRemoved(
            poolId,
            msg.sender,
            adminWallet(),
            rewardTokenAddress,
            unallocatedRewardWei
        );

        _transferTokensToAccount(
            rewardTokenAddress,
            rewardTokenDecimals,
            unallocatedRewardWei,
            adminWallet()
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function resumeStake(bytes32 poolId, address account)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        require(!_stakes[stakekey].isActive, "SSvcs: stake active");

        _stakes[stakekey].isActive = true;

        emit StakeResumed(poolId, msg.sender, account);
    }

    /**
     * @inheritdoc IStakingService
     */
    function revokeStake(bytes32 poolId, address account)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        uint256 stakeAmountWei = _stakes[stakekey].stakeAmountWei;
        uint256 rewardAmountWei = _stakes[stakekey]
            .estimatedRewardAtMaturityWei - _stakes[stakekey].rewardClaimedWei;

        _stakingPoolStats[poolId].totalStakedWei -= stakeAmountWei;
        _stakingPoolStats[poolId].totalRevokedStakeWei += stakeAmountWei;
        _stakingPoolStats[poolId].rewardToBeDistributedWei -= rewardAmountWei;

        _stakes[stakekey] = StakeInfo({
            stakeAmountWei: 0,
            stakeTimestamp: 0,
            stakeMaturityTimestamp: 0,
            estimatedRewardAtMaturityWei: 0,
            rewardClaimedWei: 0,
            isActive: false,
            isInitialized: false
        });

        (
            ,
            address stakeTokenAddress,
            ,
            address rewardTokenAddress,
            ,
            ,
            ,

        ) = _getStakingPoolInfo(poolId);

        emit StakeRevoked(
            poolId,
            msg.sender,
            account,
            stakeTokenAddress,
            stakeAmountWei,
            rewardTokenAddress,
            rewardAmountWei
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function suspendStake(bytes32 poolId, address account)
        external
        virtual
        override
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        require(_stakes[stakekey].isActive, "SSvcs: stake suspended");

        _stakes[stakekey].isActive = false;

        emit StakeSuspended(poolId, msg.sender, account);
    }

    /**
     * @inheritdoc IStakingService
     */
    function pauseContract()
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        _pause();
    }

    /**
     * @inheritdoc IStakingService
     */
    function setAdminWallet(address newWallet)
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        _setAdminWallet(newWallet);
    }

    /**
     * @inheritdoc IStakingService
     */
    function setStakingPoolContract(address newStakingPool)
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        require(newStakingPool != address(0), "SSvcs: new staking pool");

        address oldStakingPool = stakingPoolContract;
        stakingPoolContract = newStakingPool;

        emit StakingPoolContractChanged(
            oldStakingPool,
            newStakingPool,
            msg.sender
        );
    }

    /**
     * @inheritdoc IStakingService
     */
    function unpauseContract()
        external
        virtual
        override
        onlyRole(GOVERNANCE_ROLE)
    {
        _unpause();
    }

    /**
     * @inheritdoc IStakingService
     */
    function getClaimableRewardWei(bytes32 poolId, address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        (, , , , , , , bool isPoolActive) = _getStakingPoolInfo(poolId);

        if (!isPoolActive) {
            return 0;
        }

        return _getClaimableRewardWeiByStakekey(stakekey);
    }

    /**
     * @inheritdoc IStakingService
     */
    function getStakeInfo(bytes32 poolId, address account)
        external
        view
        virtual
        override
        returns (
            uint256 stakeAmountWei,
            uint256 stakeTimestamp,
            uint256 stakeMaturityTimestamp,
            uint256 estimatedRewardAtMaturityWei,
            uint256 rewardClaimedWei,
            bool isActive
        )
    {
        bytes memory stakekey = _getStakeKey(poolId, account);
        require(_stakes[stakekey].isInitialized, "SSvcs: uninitialized");

        stakeAmountWei = _stakes[stakekey].stakeAmountWei;
        stakeTimestamp = _stakes[stakekey].stakeTimestamp;
        stakeMaturityTimestamp = _stakes[stakekey].stakeMaturityTimestamp;
        estimatedRewardAtMaturityWei = _stakes[stakekey]
            .estimatedRewardAtMaturityWei;
        rewardClaimedWei = _stakes[stakekey].rewardClaimedWei;
        isActive = _stakes[stakekey].isActive;
    }

    /**
     * @inheritdoc IStakingService
     */
    function getStakingPoolStats(bytes32 poolId)
        external
        view
        virtual
        override
        returns (
            uint256 totalRewardWei,
            uint256 totalStakedWei,
            uint256 rewardToBeDistributedWei,
            uint256 totalRevokedStakeWei,
            uint256 poolSizeWei,
            bool isOpen,
            bool isActive
        )
    {
        uint256 stakeDurationDays;
        uint256 stakeTokenDecimals;
        uint256 poolAprWei;

        (
            stakeDurationDays,
            ,
            stakeTokenDecimals,
            ,
            ,
            poolAprWei,
            isOpen,
            isActive
        ) = _getStakingPoolInfo(poolId);

        poolSizeWei = _getPoolSizeWei(
            stakeDurationDays,
            poolAprWei,
            _stakingPoolStats[poolId].totalRewardWei,
            stakeTokenDecimals
        );

        totalRewardWei = _stakingPoolStats[poolId].totalRewardWei;
        totalStakedWei = _stakingPoolStats[poolId].totalStakedWei;
        rewardToBeDistributedWei = _stakingPoolStats[poolId]
            .rewardToBeDistributedWei;
        totalRevokedStakeWei = _stakingPoolStats[poolId].totalRevokedStakeWei;
    }

    /**
     * @dev Transfer ERC20 tokens from this contract to the given account
     * @param tokenAddress The address of the ERC20 token to be transferred
     * @param tokenDecimals The ERC20 token decimal places
     * @param amountWei The amount to transfer in Wei
     * @param account The account to receive the ERC20 tokens
     */
    function _transferTokensToAccount(
        address tokenAddress,
        uint256 tokenDecimals,
        uint256 amountWei,
        address account
    ) internal virtual {
        require(tokenAddress != address(0), "SSvcs: token address");
        require(tokenDecimals <= TOKEN_MAX_DECIMALS, "SSvcs: token decimals");
        require(amountWei > 0, "SSvcs: amount");
        require(account != address(0), "SSvcs: account");

        uint256 amountDecimals = amountWei.scaleWeiToDecimals(tokenDecimals);

        IERC20(tokenAddress).safeTransfer(account, amountDecimals);
    }

    /**
     * @dev Transfer tokens from the given account to this contract
     * @param tokenAddress The address of the ERC20 token to be transferred
     * @param tokenDecimals The ERC20 token decimal places
     * @param amountWei The amount to transfer in Wei
     * @param account The account to transfer the ERC20 tokens from
     */
    function _transferTokensToContract(
        address tokenAddress,
        uint256 tokenDecimals,
        uint256 amountWei,
        address account
    ) internal virtual {
        require(tokenAddress != address(0), "SSvcs: token address");
        require(tokenDecimals <= TOKEN_MAX_DECIMALS, "SSvcs: token decimals");
        require(amountWei > 0, "SSvcs: amount");
        require(account != address(0), "SSvcs: account");

        uint256 amountDecimals = amountWei.scaleWeiToDecimals(tokenDecimals);

        IERC20(tokenAddress).safeTransferFrom(
            account,
            address(this),
            amountDecimals
        );
    }

    /**
     * @dev Returns the remaining reward for the given staking pool in Wei
     * @param poolId The staking pool identifier
     * @return calculatedRemainingRewardWei The calculaated remaining reward in Wei
     */
    function _calculatePoolRemainingRewardWei(bytes32 poolId)
        internal
        view
        virtual
        returns (uint256 calculatedRemainingRewardWei)
    {
        calculatedRemainingRewardWei =
            _stakingPoolStats[poolId].totalRewardWei -
            _stakingPoolStats[poolId].rewardToBeDistributedWei;
    }

    /**
     * @dev Returns the calculated timestamp when the stake matures given the stake duration and timestamp
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param stakeTimestamp The timestamp as seconds since unix epoch when the stake was placed
     * @return calculatedStakeMaturityTimestamp The timestamp as seconds since unix epoch when the stake matures
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function _calculateStakeMaturityTimestamp(
        uint256 stakeDurationDays,
        uint256 stakeTimestamp
    ) internal view virtual returns (uint256 calculatedStakeMaturityTimestamp) {
        calculatedStakeMaturityTimestamp =
            stakeTimestamp +
            stakeDurationDays *
            SECONDS_IN_DAY;
    }

    /**
     * @dev Returns the estimated reward in Wei at maturity for the given stake duration, pool APR and stake amount
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @param stakeAmountWei The amount of tokens staked in Wei
     * @return estimatedRewardAtMaturityWei The estimated reward in Wei at maturity
     */
    function _estimateRewardAtMaturityWei(
        uint256 stakeDurationDays,
        uint256 poolAprWei,
        uint256 stakeAmountWei
    ) internal view virtual returns (uint256 estimatedRewardAtMaturityWei) {
        estimatedRewardAtMaturityWei =
            (poolAprWei * stakeDurationDays * stakeAmountWei) /
            (DAYS_IN_YEAR * PERCENT_100_WEI);
    }

    /**
     * @dev Returns the claimable reward in Wei for the given stake key, returns zero if stake has been suspended
     * @param stakekey The stake identifier
     * @return claimableRewardWei The claimable reward in Wei
     */
    function _getClaimableRewardWeiByStakekey(bytes memory stakekey)
        internal
        view
        virtual
        returns (uint256 claimableRewardWei)
    {
        if (!_stakes[stakekey].isActive) {
            return 0;
        }

        if (_isStakeMaturedByStakekey(stakekey)) {
            claimableRewardWei =
                _stakes[stakekey].estimatedRewardAtMaturityWei -
                _stakes[stakekey].rewardClaimedWei;
        } else {
            claimableRewardWei = 0;
        }
    }

    /**
     * @dev Returns the staking pool size in Wei for the given parameters
     * @param stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @param poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @param totalRewardWei The total amount of staking pool reward in Wei
     * @param stakeTokenDecimals The ERC20 stake token decimal places
     * @return poolSizeWei The staking pool size in Wei
     */
    function _getPoolSizeWei(
        uint256 stakeDurationDays,
        uint256 poolAprWei,
        uint256 totalRewardWei,
        uint256 stakeTokenDecimals
    ) internal view virtual returns (uint256 poolSizeWei) {
        poolSizeWei = _truncatedAmountWei(
            (DAYS_IN_YEAR * PERCENT_100_WEI * totalRewardWei) /
                (stakeDurationDays * poolAprWei),
            stakeTokenDecimals
        );
    }

    /**
     * @dev Returns the staking pool info for the given staking pool
     * @param poolId The staking pool identifier
     * @return stakeDurationDays The duration in days that user stakes will be locked in staking pool
     * @return stakeTokenAddress The address of the ERC20 stake token for staking pool
     * @return stakeTokenDecimals The ERC20 stake token decimal places
     * @return rewardTokenAddress The address of the ERC20 reward token for staking pool
     * @return rewardTokenDecimals The ERC20 reward token decimal places
     * @return poolAprWei The APR (Annual Percentage Rate) in Wei for staking pool
     * @return isOpen True if staking pool is open to accept user stakes
     * @return isPoolActive True if user is allowed to claim reward and unstake from staking pool
     */
    function _getStakingPoolInfo(bytes32 poolId)
        internal
        view
        virtual
        returns (
            uint256 stakeDurationDays,
            address stakeTokenAddress,
            uint256 stakeTokenDecimals,
            address rewardTokenAddress,
            uint256 rewardTokenDecimals,
            uint256 poolAprWei,
            bool isOpen,
            bool isPoolActive
        )
    {
        (
            stakeDurationDays,
            stakeTokenAddress,
            stakeTokenDecimals,
            rewardTokenAddress,
            rewardTokenDecimals,
            poolAprWei,
            isOpen,
            isPoolActive
        ) = IStakingPool(stakingPoolContract).getStakingPoolInfo(poolId);
        require(stakeDurationDays > 0, "SSvcs: stake duration");
        require(stakeTokenAddress != address(0), "SSvcs: stake token");
        require(
            stakeTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SSvcs: stake decimals"
        );
        require(rewardTokenAddress != address(0), "SSvcs: reward token");
        require(
            rewardTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SSvcs: reward decimals"
        );
        require(poolAprWei > 0, "SSvcs: pool APR");
    }

    /**
     * @dev Returns whether stake has matured for given stake key
     * @param stakekey The stake identifier
     * @return True if stake has matured
     */
    function _isStakeMaturedByStakekey(bytes memory stakekey)
        internal
        view
        virtual
        returns (bool)
    {
        return
            _stakes[stakekey].stakeMaturityTimestamp > 0 &&
            block.timestamp >= _stakes[stakekey].stakeMaturityTimestamp;
    }

    /**
     * @dev Returns the stake identifier for the given staking pool identifier and account
     * @param poolId The staking pool identifier
     * @param account The address of the user wallet that placed the stake
     * @return stakekey The stake identifier which is the ABI-encoded value of account and poolId
     */
    function _getStakeKey(bytes32 poolId, address account)
        internal
        pure
        virtual
        returns (bytes memory stakekey)
    {
        require(account != address(0), "SSvcs: account");

        stakekey = abi.encode(account, poolId);
    }

    /**
     * @dev Returns the given amount in Wei truncated to the given number of decimals
     * @param amountWei The amount in Wei
     * @param tokenDecimals The number of decimal places
     * @return truncatedAmountWei The truncated amount in Wei
     */
    function _truncatedAmountWei(uint256 amountWei, uint256 tokenDecimals)
        internal
        pure
        virtual
        returns (uint256 truncatedAmountWei)
    {
        truncatedAmountWei = tokenDecimals < TOKEN_MAX_DECIMALS
            ? amountWei.scaleWeiToDecimals(tokenDecimals).scaleDecimalsToWei(
                tokenDecimals
            )
            : amountWei;
    }
}