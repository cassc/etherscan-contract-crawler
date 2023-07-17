// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "src/interfaces/IELRewardFactory.sol";
import "src/interfaces/INodeOperatorsRegistry.sol";
import "src/interfaces/IDepositContract.sol";
import "src/interfaces/IELReward.sol";
import "src/interfaces/IOperatorSlash.sol";
import "src/interfaces/ILargeStaking.sol";
import {CLStakingExitInfo, CLStakingSlashInfo} from "src/library/ConsensusStruct.sol";

/**
 * @title Large Staking
 *
 * Non-custodial large-amount pledge, supporting the migration of verifiers
 */
contract LargeStaking is
    ILargeStaking,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    IOperatorSlash public operatorSlashContract;
    INodeOperatorsRegistry public nodeOperatorRegistryContract;
    address public largeOracleContractAddr;
    IELRewardFactory public elRewardFactory;
    IDepositContract public depositContract;

    struct StakingInfo {
        bool isELRewardSharing; // Whether to share the execution layer reward pool
        uint256 stakingId; // Staking order id
        uint256 operatorId; // Specify which operator operates the validator
        uint256 stakingAmount; // The total amount of user stake
        uint256 alreadyUsedAmount; // Amount deposited into Eth2 or unstake
        uint256 unstakeRequestAmount; // The amount the user requested to withdraw
        uint256 unstakeAmount; // Amount the user has withdrawn
        address owner; // The owner of the staking order，used for claim execution layer reward
        address elRewardAddr; // Address to receive el rewards
        bytes32 withdrawCredentials; // Withdrawal certificate
    }

    mapping(uint256 => StakingInfo) public largeStakings; // Staking order
    uint256 public totalLargeStakingCounts;
    mapping(uint256 => uint256) internal totalLargeStakeAmounts; // key is operatorId

    uint256 public MIN_STAKE_AMOUNT;
    uint256 public MAX_SLASH_AMOUNT;

    mapping(uint256 => bytes[]) internal validators; // key is stakingId

    struct ValidatorInfo {
        uint256 stakingId;
        uint256 registerBlock;
        uint256 exitBlock;
        uint256 slashAmount;
    }

    mapping(bytes => ValidatorInfo) public validatorInfo; // key is pubkey

    // dao address
    address public dao;
    // dao treasury address
    address public daoVaultAddress;
    // dao el commisssionRate
    uint256 public daoElCommissionRate;

    mapping(uint256 => address) public elPrivateRewardPool; // key is stakingId
    mapping(uint256 => address) public elSharedRewardPool; // key is operatorId

    // share reward pool
    struct SettleInfo {
        uint256 valuePerSharePoint;
        uint256 rewardBalance;
    }

    mapping(uint256 => SettleInfo) public eLSharedRewardSettleInfo; // key is stakingId
    mapping(uint256 => uint256) public unclaimedSharedRewards; // key is operatorId
    mapping(uint256 => uint256) public operatorSharedRewards; // key is operatorId
    mapping(uint256 => uint256) public daoSharedRewards; // key is operatorId
    mapping(uint256 => uint256) public totalShares; // key is operatorId
    mapping(uint256 => uint256) public valuePerShare; // key is operatorId
    uint256 private constant UNIT = 1e18;

    // private reward pool
    mapping(uint256 => uint256) public operatorPrivateRewards; // key is stakingId
    mapping(uint256 => uint256) public daoPrivateRewards; // key is stakingId
    mapping(uint256 => uint256) public unclaimedPrivateRewards; // key is stakingId

    error PermissionDenied();
    error InvalidParameter();
    error InvalidAddr();
    error InvalidAmount();
    error SharedRewardPoolOpened();
    error SharedRewardPoolNotOpened();
    error RequireOperatorTrusted();
    error InvalidWithdrawalCredentials();
    error InsufficientFunds();
    error InsufficientMargin();
    error InvalidRewardAddr();
    error DuplicatePubKey();
    error InvalidRewardRatio();
    error InvalidReport();

    modifier onlyDao() {
        if (msg.sender != dao) revert PermissionDenied();
        _;
    }

    modifier onlyLargeOracle() {
        if (msg.sender != largeOracleContractAddr) revert PermissionDenied();
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice initialize LargeStaking Contract
     */
    function initialize(
        address _dao,
        address _daoVaultAddress,
        address _nodeOperatorRegistryAddress,
        address _operatorSlashContract,
        address _largeOracleContractAddr,
        address _elRewardFactory,
        address _depositContract
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        if (
            _nodeOperatorRegistryAddress == address(0) || _largeOracleContractAddr == address(0)
                || _elRewardFactory == address(0) || _dao == address(0) || _daoVaultAddress == address(0)
                || _depositContract == address(0) || _operatorSlashContract == address(0)
        ) {
            revert InvalidAddr();
        }

        nodeOperatorRegistryContract = INodeOperatorsRegistry(_nodeOperatorRegistryAddress);
        elRewardFactory = IELRewardFactory(_elRewardFactory);
        depositContract = IDepositContract(_depositContract);
        operatorSlashContract = IOperatorSlash(_operatorSlashContract);
        largeOracleContractAddr = _largeOracleContractAddr;
        dao = _dao;
        daoVaultAddress = _daoVaultAddress;
        daoElCommissionRate = 1000;
        MIN_STAKE_AMOUNT = 32 ether;
        MAX_SLASH_AMOUNT = 2 ether;
    }

    /**
     * @notice The operator starts the shared revenue pool. If the operator is not started,
     * users cannot use the shared revenue pool for pledge
     */
    function startupSharedRewardPool(uint256 _operatorId) public {
        (,, address owner,,) = nodeOperatorRegistryContract.getNodeOperator(_operatorId, false);
        if (msg.sender != owner) revert PermissionDenied();

        address elRewardPoolAddr = elSharedRewardPool[_operatorId];
        if (elRewardPoolAddr != address(0)) revert SharedRewardPoolOpened();

        elRewardPoolAddr = elRewardFactory.create(_operatorId, address(this));
        elSharedRewardPool[_operatorId] = elRewardPoolAddr;

        emit SharedRewardPoolStart(_operatorId, elRewardPoolAddr);
    }

    /**
     * @notice The user initiates a large amount of pledge,
     * allowing the user to set the owner, withdrawal certificate,
     * whether to use the shared revenue pool.
     * Once set, cannot be changed
     */
    function largeStake(
        uint256 _operatorId,
        address _elRewardAddr,
        address _withdrawCredentials,
        bool _isELRewardSharing
    ) public payable {
        if (msg.value < MIN_STAKE_AMOUNT || msg.value % 32 ether != 0) revert InvalidAmount();
        // operatorId must be a trusted operator
        if (!nodeOperatorRegistryContract.isTrustedOperator(_operatorId)) revert RequireOperatorTrusted();

        if (_isELRewardSharing) {
            settleElSharedReward(_operatorId);
        }

        uint256 curStakingId;
        address elRewardPoolAddr;
        (curStakingId, elRewardPoolAddr) =
            _stake(_operatorId, msg.sender, _elRewardAddr, _withdrawCredentials, _isELRewardSharing, msg.value, false);
        totalLargeStakeAmounts[_operatorId] += msg.value;
        emit LargeStake(
            _operatorId, curStakingId, msg.value, msg.sender, _elRewardAddr, _withdrawCredentials, _isELRewardSharing
            );
    }

    /**
     * @notice The user adds pledge funds to an existing pledge order.
     * Check through the owner and withdrawal certificate to prevent pledge errors
     */
    function appendLargeStake(uint256 _stakingId, address _owner, address _withdrawCredentials) public payable {
        if (msg.value < 32 ether || msg.value % 32 ether != 0 || _stakingId < 1 || _stakingId > totalLargeStakingCounts)
        {
            revert InvalidAmount();
        }
        StakingInfo memory stakingInfo = largeStakings[_stakingId];
        bytes32 userWithdrawalCredentials = getWithdrawCredentials(_withdrawCredentials);

        if (stakingInfo.owner != _owner || stakingInfo.withdrawCredentials != userWithdrawalCredentials) {
            revert InvalidParameter();
        }

        if (stakingInfo.isELRewardSharing) {
            settleElSharedReward(stakingInfo.operatorId);
            _updateShare(
                _stakingId,
                stakingInfo.operatorId,
                stakingInfo.stakingAmount - stakingInfo.unstakeAmount,
                msg.value,
                true
            );
        }

        largeStakings[_stakingId].stakingAmount += msg.value;
        totalLargeStakeAmounts[stakingInfo.operatorId] += msg.value;

        emit AppendStake(_stakingId, msg.value);
    }

    /**
     * @notice Users can unstake.
     * If the funds have not been pledged, the funds will be withdrawn synchronously.
     * If the funds have been recharged to eth2, the funds will be withdrawn asynchronously and automatically to the withdrawal certificate address
     */
    function largeUnstake(uint256 _stakingId, uint256 _amount) public nonReentrant {
        StakingInfo storage stakingInfo = largeStakings[_stakingId];
        if (
            _amount < 32 ether || _amount % 32 ether != 0
                || _amount > stakingInfo.stakingAmount - stakingInfo.unstakeRequestAmount
        ) revert InvalidAmount();

        if (msg.sender != stakingInfo.owner) revert PermissionDenied();

        uint256 _unstakeAmount = 0;
        if (stakingInfo.stakingAmount > stakingInfo.alreadyUsedAmount) {
            uint256 fastAmount = stakingInfo.stakingAmount - stakingInfo.alreadyUsedAmount;
            if (fastAmount > _amount) {
                _unstakeAmount = _amount;
            } else {
                _unstakeAmount = fastAmount;
            }

            if (stakingInfo.isELRewardSharing) {
                settleElSharedReward(stakingInfo.operatorId);
                _updateShare(
                    _stakingId,
                    stakingInfo.operatorId,
                    stakingInfo.stakingAmount - stakingInfo.unstakeAmount,
                    _unstakeAmount,
                    false
                );
            }

            // _unstakeAmount is not equal to 0, which means that the unstake is completed synchronously
            stakingInfo.unstakeAmount += _unstakeAmount;
            stakingInfo.alreadyUsedAmount += _unstakeAmount;
            totalLargeStakeAmounts[stakingInfo.operatorId] -= _unstakeAmount;

            payable(stakingInfo.owner).transfer(_unstakeAmount);
            emit FastUnstake(_stakingId, _unstakeAmount);
        }

        stakingInfo.unstakeRequestAmount += _amount;

        emit LargeUnstake(_stakingId, _amount);
    }

    /**
     * @notice Allows the operator to migrate already running validators into the protocol.
     */
    function migrateStake(
        address _owner,
        address _elRewardAddr,
        address _withdrawCredentials,
        bool _isELRewardSharing,
        bytes[] calldata _pubKeys
    ) public {
        uint256 operatorId = nodeOperatorRegistryContract.isTrustedOperatorOfControllerAddress(msg.sender);
        if (operatorId == 0) revert RequireOperatorTrusted();

        if (_isELRewardSharing) {
            settleElSharedReward(operatorId);
        }

        uint256 curStakingId;
        address elRewardPoolAddr;
        uint256 stakeAmounts = _pubKeys.length * 32 ether;
        (curStakingId, elRewardPoolAddr) =
            _stake(operatorId, _owner, _elRewardAddr, _withdrawCredentials, _isELRewardSharing, stakeAmounts, true);
        for (uint256 i = 0; i < _pubKeys.length; ++i) {
            _savePubKey(curStakingId, _pubKeys[i]);
        }
        totalLargeStakeAmounts[operatorId] += stakeAmounts;

        emit MigretaStake(
            operatorId, curStakingId, stakeAmounts, _owner, _elRewardAddr, _withdrawCredentials, _isELRewardSharing
            );
    }

    /**
     * @notice Allows the operator to migrate already running validators into existing stake orders.
     */
    function appendMigrateStake(
        uint256 _stakingId,
        address _owner,
        address _withdrawCredentials,
        bytes[] calldata _pubKeys
    ) public {
        StakingInfo memory stakingInfo = largeStakings[_stakingId];
        bytes32 userWithdrawalCredentials = getWithdrawCredentials(_withdrawCredentials);

        if (
            stakingInfo.owner != _owner || stakingInfo.withdrawCredentials != userWithdrawalCredentials
                || _stakingId < 1 || _stakingId > totalLargeStakingCounts
        ) {
            revert InvalidParameter();
        }

        uint256 stakeAmounts = _pubKeys.length * 32 ether;

        if (stakingInfo.isELRewardSharing) {
            settleElSharedReward(stakingInfo.operatorId);
            _updateShare(
                _stakingId,
                stakingInfo.operatorId,
                stakingInfo.stakingAmount - stakingInfo.unstakeAmount,
                stakeAmounts,
                true
            );
        }

        largeStakings[_stakingId].stakingAmount += stakeAmounts;
        largeStakings[_stakingId].alreadyUsedAmount += stakeAmounts;
        totalLargeStakeAmounts[stakingInfo.operatorId] += stakeAmounts;

        for (uint256 i = 0; i < _pubKeys.length; ++i) {
            _savePubKey(_stakingId, _pubKeys[i]);
        }

        emit AppendMigretaStake(_stakingId, stakeAmounts);
    }

    function _stake(
        uint256 _operatorId,
        address _owner,
        address _elRewardAddr,
        address _withdrawCredentials,
        bool _isELRewardSharing,
        uint256 _stakingAmount,
        bool isMigrate
    ) internal returns (uint256, address) {
        if (_withdrawCredentials == address(0) || _withdrawCredentials.balance < 1 wei) {
            revert InvalidWithdrawalCredentials();
        }

        uint256 curStakingId = totalLargeStakingCounts + 1;
        totalLargeStakingCounts = curStakingId;

        bytes32 userWithdrawalCredentials = getWithdrawCredentials(_withdrawCredentials);
        largeStakings[totalLargeStakingCounts] = StakingInfo({
            isELRewardSharing: _isELRewardSharing,
            stakingId: curStakingId,
            operatorId: _operatorId,
            stakingAmount: _stakingAmount,
            alreadyUsedAmount: isMigrate ? _stakingAmount : 0,
            unstakeRequestAmount: 0,
            unstakeAmount: 0,
            owner: _owner,
            elRewardAddr: _elRewardAddr,
            withdrawCredentials: userWithdrawalCredentials
        });

        address elRewardPoolAddr;
        if (!_isELRewardSharing) {
            elRewardPoolAddr = elRewardFactory.create(_operatorId, address(this));
            elPrivateRewardPool[curStakingId] = elRewardPoolAddr;
        } else {
            elRewardPoolAddr = elSharedRewardPool[_operatorId];
            if (address(0) == elRewardPoolAddr) revert SharedRewardPoolNotOpened();

            _updateShare(curStakingId, _operatorId, 0, _stakingAmount, true);
        }

        return (curStakingId, elRewardPoolAddr);
    }

    function _updateShare(
        uint256 _stakingId,
        uint256 _operatorId,
        uint256 _curAmount,
        uint256 _updataAmount,
        bool _isStake
    ) internal {
        SettleInfo storage info = eLSharedRewardSettleInfo[_stakingId];

        info.rewardBalance += (valuePerShare[_operatorId] - info.valuePerSharePoint) * (_curAmount) / UNIT;
        info.valuePerSharePoint = valuePerShare[_operatorId];

        if (_isStake) {
            totalShares[_operatorId] += _updataAmount;
        } else {
            totalShares[_operatorId] -= _updataAmount;
        }
    }

    /**
     * @notice Calculate WithdrawCredentials based on address
     */
    function getWithdrawCredentials(address _withdrawCredentials) public pure returns (bytes32) {
        return abi.decode(abi.encodePacked(hex"010000000000000000000000", _withdrawCredentials), (bytes32));
    }

    /**
     * @notice operator registration validators
     */
    function registerValidator(
        uint256 _stakingId,
        bytes[] calldata _pubkeys,
        bytes[] calldata _signatures,
        bytes32[] calldata _depositDataRoots
    ) external nonReentrant {
        // must be a trusted operator
        uint256 operatorId = nodeOperatorRegistryContract.isTrustedOperatorOfControllerAddress(msg.sender);
        if (operatorId == 0) revert RequireOperatorTrusted();

        uint256 depositAmount = _pubkeys.length * 32 ether;
        StakingInfo memory stakingInfo = largeStakings[_stakingId];
        if ((stakingInfo.stakingAmount - stakingInfo.alreadyUsedAmount) < depositAmount) {
            revert InsufficientFunds();
        }

        bytes memory withdrawCredentials = abi.encodePacked(stakingInfo.withdrawCredentials);

        for (uint256 i = 0; i < _pubkeys.length; ++i) {
            depositContract.deposit{value: 32 ether}(
                _pubkeys[i], withdrawCredentials, _signatures[i], _depositDataRoots[i]
            );
            emit ValidatorRegistered(operatorId, _stakingId, _pubkeys[i]);
            _savePubKey(_stakingId, _pubkeys[i]);
        }

        largeStakings[_stakingId].alreadyUsedAmount += depositAmount;
    }

    function _savePubKey(uint256 _stakingId, bytes memory _pubkey) internal {
        if (validatorInfo[_pubkey].stakingId != 0) revert DuplicatePubKey();
        validators[_stakingId].push(_pubkey);
        validatorInfo[_pubkey] =
            ValidatorInfo({stakingId: _stakingId, registerBlock: block.number, exitBlock: 0, slashAmount: 0});
    }

    /**
     * @notice Get pending rewards
     */
    function reward(uint256 _stakingId) public view returns (uint256 userReward) {
        StakingInfo memory stakingInfo = largeStakings[_stakingId];
        (uint256 operatorId,, uint256 rewards) = getRewardPoolInfo(_stakingId);

        if (stakingInfo.isELRewardSharing) {
            SettleInfo memory settleInfo = eLSharedRewardSettleInfo[_stakingId];
            userReward = settleInfo.rewardBalance;

            if (totalShares[operatorId] == 0) {
                return (userReward);
            }

            uint256 unsettledPoolReward;
            if (rewards != 0) {
                (,, unsettledPoolReward) = _calcElReward(rewards, operatorId);
            }

            uint256 unsettledUserReward = (
                valuePerShare[operatorId] + unsettledPoolReward * UNIT / totalShares[operatorId]
                    - settleInfo.valuePerSharePoint
            ) * (stakingInfo.stakingAmount - stakingInfo.unstakeAmount) / UNIT;
            userReward += unsettledUserReward;
        } else {
            userReward =
                unclaimedPrivateRewards[_stakingId] - daoPrivateRewards[_stakingId] - operatorPrivateRewards[_stakingId];
            if (rewards != 0) {
                (,, uint256 unsettledPoolReward) = _calcElReward(rewards, operatorId);
                userReward += unsettledPoolReward;
            }
        }

        return (userReward);
    }

    /**
     * @notice Get reward pool information
     */
    function getRewardPoolInfo(uint256 _stakingId)
        public
        view
        returns (uint256 operatorId, address rewardPoolAddr, uint256 rewards)
    {
        StakingInfo memory stakingInfo = largeStakings[_stakingId];
        operatorId = stakingInfo.operatorId;
        if (stakingInfo.isELRewardSharing) {
            rewardPoolAddr = elSharedRewardPool[operatorId];
            rewards = rewardPoolAddr.balance - unclaimedSharedRewards[operatorId];
        } else {
            rewardPoolAddr = elPrivateRewardPool[_stakingId];
            rewards = rewardPoolAddr.balance - unclaimedPrivateRewards[_stakingId];
        }
        return (operatorId, rewardPoolAddr, rewards);
    }

    /**
     * @notice Settle the shared reward pool. Each operator has only one shared reward pool
     */
    function settleElSharedReward(uint256 _operatorId) public {
        address rewardPoolAddr = elSharedRewardPool[_operatorId];
        if (address(0) == rewardPoolAddr) revert SharedRewardPoolNotOpened();

        uint256 rewards = rewardPoolAddr.balance - unclaimedSharedRewards[_operatorId];
        if (rewards == 0) return;
        (uint256 daoReward, uint256 operatorReward, uint256 poolReward) = _calcElReward(rewards, _operatorId);

        operatorSharedRewards[_operatorId] += operatorReward;
        daoSharedRewards[_operatorId] += daoReward;
        unclaimedSharedRewards[_operatorId] = rewardPoolAddr.balance;

        valuePerShare[_operatorId] += poolReward * UNIT / totalShares[_operatorId]; // settle

        emit ELShareingRewardSettle(_operatorId, daoReward, operatorReward, poolReward);
    }

    /**
     * @notice Settle the private reward pool.
     * Each pledge sheet of a private reward pool has its own private reward pool
     */
    function settleElPrivateReward(uint256 _stakingId) public {
        if (_stakingId < 1 || _stakingId > totalLargeStakingCounts) revert InvalidParameter();

        address rewardPoolAddr = elPrivateRewardPool[_stakingId];
        uint256 _operatorId = largeStakings[_stakingId].operatorId;
        uint256 rewards = rewardPoolAddr.balance - unclaimedPrivateRewards[_stakingId];
        if (rewards == 0) return;

        (uint256 daoReward, uint256 operatorReward, uint256 poolReward) = _calcElReward(rewards, _operatorId);
        unclaimedPrivateRewards[_stakingId] = rewardPoolAddr.balance;
        operatorPrivateRewards[_stakingId] += operatorReward;
        daoPrivateRewards[_stakingId] += daoReward;

        emit ElPrivateRewardSettle(_stakingId, _operatorId, daoReward, operatorReward, poolReward);
    }

    function _calcElReward(uint256 rewards, uint256 _operatorId)
        internal
        view
        returns (uint256 daoReward, uint256 operatorReward, uint256 poolReward)
    {
        uint256[] memory _operatorIds = new uint256[] (1);
        _operatorIds[0] = _operatorId;
        uint256[] memory operatorElCommissionRate;
        operatorElCommissionRate = nodeOperatorRegistryContract.getOperatorCommissionRate(_operatorIds);
        operatorReward = (rewards * operatorElCommissionRate[0]) / 10000;
        daoReward = (rewards * daoElCommissionRate) / 10000;
        poolReward = rewards - operatorReward - daoReward;
        return (daoReward, operatorReward, poolReward);
    }

    /**
     * @notice Users claim benefits of the execution layer
     */
    function claimRewardsOfUser(uint256 _stakingId, uint256 rewards) public nonReentrant {
        StakingInfo memory stakingInfo = largeStakings[_stakingId];
        SettleInfo storage settleInfo = eLSharedRewardSettleInfo[_stakingId];

        address rewardPoolAddr;
        if (stakingInfo.isELRewardSharing) {
            settleElSharedReward(stakingInfo.operatorId);

            rewardPoolAddr = elSharedRewardPool[stakingInfo.operatorId];

            uint256 totalRewards = settleInfo.rewardBalance
                + (valuePerShare[stakingInfo.operatorId] - settleInfo.valuePerSharePoint)
                    * (stakingInfo.stakingAmount - stakingInfo.unstakeAmount) / UNIT;

            settleInfo.valuePerSharePoint = valuePerShare[stakingInfo.operatorId];

            settleInfo.rewardBalance = totalRewards - rewards;
            unclaimedSharedRewards[stakingInfo.operatorId] -= rewards;
        } else {
            settleElPrivateReward(_stakingId);
            rewardPoolAddr = elPrivateRewardPool[_stakingId];
            if (
                rewards + operatorPrivateRewards[_stakingId] + daoPrivateRewards[_stakingId]
                    > unclaimedPrivateRewards[_stakingId]
            ) {
                revert InvalidAmount();
            }
            unclaimedPrivateRewards[_stakingId] -= rewards;
        }

        _transfer(rewardPoolAddr, stakingInfo.elRewardAddr, rewards);
        emit UserRewardClaimed(_stakingId, stakingInfo.elRewardAddr, rewards);

        uint256[] memory _stakingIds = new uint256[] (1);
        _stakingIds[0] = _stakingId;
        operatorSlashContract.claimCompensatedOfLargeStaking(_stakingIds, stakingInfo.elRewardAddr);
    }

    /**
     * @notice The operator claim the reward commission
     */
    function claimRewardsOfOperator(uint256 _operatorId, uint256[] memory _privatePoolStakingIds)
        external
        nonReentrant
    {
        StakingInfo memory stakingInfo;
        (uint256 pledgeBalance, uint256 requirBalance) =
            nodeOperatorRegistryContract.getPledgeInfoOfOperator(_operatorId);
        if (pledgeBalance < requirBalance) revert InsufficientMargin();

        address operatorElSharedRewardPool = elSharedRewardPool[_operatorId];
        if (operatorElSharedRewardPool != address(0)) {
            settleElSharedReward(_operatorId);
            uint256 operatorRewards = operatorSharedRewards[_operatorId];
            if (operatorRewards != 0) {
                operatorSharedRewards[_operatorId] = 0;
                unclaimedSharedRewards[_operatorId] -= operatorRewards;
                emit OperatorSharedRewardClaimed(stakingInfo.operatorId, operatorRewards);
                _distributeOperatorRewards(operatorElSharedRewardPool, operatorRewards, _operatorId);
            }
        }

        for (uint256 i = 0; i < _privatePoolStakingIds.length; ++i) {
            uint256 stakingId = _privatePoolStakingIds[i];
            stakingInfo = largeStakings[stakingId];
            if (stakingInfo.isELRewardSharing || stakingInfo.operatorId != _operatorId) {
                continue;
            }

            settleElPrivateReward(stakingId);

            uint256 operatorRewards = operatorPrivateRewards[stakingId];
            if (operatorRewards == 0) continue;

            operatorPrivateRewards[stakingId] = 0;
            unclaimedPrivateRewards[stakingId] -= operatorRewards;
            emit OperatorPrivateRewardClaimed(stakingId, stakingInfo.operatorId, operatorRewards);
            _distributeOperatorRewards(elPrivateRewardPool[stakingId], operatorRewards, stakingInfo.operatorId);
        }
    }

    function _distributeOperatorRewards(address _elRewardContract, uint256 _operatorRewards, uint256 _operatorId)
        internal
    {
        address[] memory rewardAddresses;
        uint256[] memory ratios;
        uint256 totalAmount = 0;
        uint256 totalRatios = 0;

        (rewardAddresses, ratios) = nodeOperatorRegistryContract.getNodeOperatorRewardSetting(_operatorId);
        if (rewardAddresses.length == 0) revert InvalidRewardAddr();
        uint256[] memory rewardAmounts = new uint256[] (rewardAddresses.length);

        totalAmount = 0;
        totalRatios = 0;
        for (uint256 i = 0; i < rewardAddresses.length; ++i) {
            uint256 ratio = ratios[i];
            totalRatios += ratio;

            // If it is the last reward address, calculate by subtraction
            if (i == rewardAddresses.length - 1) {
                rewardAmounts[i] = _operatorRewards - totalAmount;
            } else {
                uint256 amount = _operatorRewards * ratio / 100;
                rewardAmounts[i] = amount;
                totalAmount += amount;
            }
        }

        if (totalRatios != 100) revert InvalidRewardRatio();

        for (uint256 j = 0; j < rewardAddresses.length; ++j) {
            _transfer(_elRewardContract, rewardAddresses[j], rewardAmounts[j]);
            emit OperatorRewardClaimed(_operatorId, rewardAddresses[j], rewardAmounts[j]);
        }
    }

    /**
     * @notice The Dao claim the reward commission
     */
    function claimRewardsOfDao(uint256[] memory _stakingIds) external nonReentrant {
        StakingInfo memory stakingInfo;
        for (uint256 i = 0; i < _stakingIds.length; ++i) {
            uint256 stakingId = _stakingIds[i];
            stakingInfo = largeStakings[stakingId];
            if (stakingInfo.isELRewardSharing) {
                settleElSharedReward(stakingInfo.operatorId);
                uint256 daoRewards = daoSharedRewards[stakingInfo.operatorId];
                if (daoRewards == 0) continue;

                daoSharedRewards[stakingInfo.operatorId] = 0;
                unclaimedSharedRewards[stakingInfo.operatorId] -= daoRewards;

                _transfer(elSharedRewardPool[stakingInfo.operatorId], daoVaultAddress, daoRewards);
                emit DaoSharedRewardClaimed(stakingInfo.operatorId, daoVaultAddress, daoRewards);
            } else {
                settleElPrivateReward(stakingId);
                uint256 daoRewards = daoPrivateRewards[stakingId];
                if (daoRewards == 0) continue;

                daoPrivateRewards[stakingId] = 0;
                unclaimedPrivateRewards[stakingId] -= daoRewards;

                _transfer(elPrivateRewardPool[stakingId], daoVaultAddress, daoRewards);
                emit DaoPrivateRewardClaimed(stakingId, daoVaultAddress, daoRewards);
            }
        }
    }

    function _transfer(address _poolAddr, address _to, uint256 _amounts) internal {
        IELReward(_poolAddr).transfer(_amounts, _to);
    }

    /**
     * @notice The oracle reports the verifier's exit and slash information.
     */
    function reportCLStakingData(
        CLStakingExitInfo[] memory _clStakingExitInfo,
        CLStakingSlashInfo[] memory _clStakingSlashInfo
    ) external onlyLargeOracle {
        StakingInfo memory stakingInfo;
        for (uint256 i = 0; i < _clStakingExitInfo.length; ++i) {
            CLStakingExitInfo memory sInfo = _clStakingExitInfo[i];
            ValidatorInfo memory vInfo = validatorInfo[sInfo.pubkey];

            if (vInfo.stakingId != sInfo.stakingId || vInfo.exitBlock != 0) {
                revert InvalidReport();
            }
            validatorInfo[sInfo.pubkey].exitBlock = block.number;

            stakingInfo = largeStakings[sInfo.stakingId];
            uint256 newUnstakeAmount = stakingInfo.unstakeAmount + 32 ether;
            if (newUnstakeAmount > stakingInfo.stakingAmount) revert InvalidReport();

            if (stakingInfo.isELRewardSharing) {
                settleElSharedReward(stakingInfo.operatorId);
                _updateShare(
                    sInfo.stakingId,
                    stakingInfo.operatorId,
                    stakingInfo.stakingAmount - stakingInfo.unstakeAmount,
                    32 ether,
                    false
                );
            }

            largeStakings[sInfo.stakingId].unstakeAmount = newUnstakeAmount;
            // The operator actively withdraws from the validator
            if (newUnstakeAmount > stakingInfo.unstakeRequestAmount) {
                // When unstakeRequestAmount > unstakeAmount, the operator will exit the validator
                largeStakings[sInfo.stakingId].unstakeRequestAmount = newUnstakeAmount;
            }

            emit ValidatorExitReport(stakingInfo.operatorId, sInfo.pubkey);
        }

        totalLargeStakeAmounts[stakingInfo.operatorId] -= 32 ether * _clStakingExitInfo.length;

        uint256[] memory _stakingIds = new uint256[] (_clStakingSlashInfo.length);
        uint256[] memory _operatorIds = new uint256[] (_clStakingSlashInfo.length);
        uint256[] memory _amounts = new uint256[] (_clStakingSlashInfo.length);
        for (uint256 i = 0; i < _clStakingSlashInfo.length; ++i) {
            CLStakingSlashInfo memory sInfo = _clStakingSlashInfo[i];
            ValidatorInfo memory vInfo = validatorInfo[sInfo.pubkey];

            if (vInfo.stakingId != sInfo.stakingId || vInfo.slashAmount + sInfo.slashAmount > MAX_SLASH_AMOUNT) {
                revert InvalidReport();
            }

            _stakingIds[i] = sInfo.stakingId;
            _operatorIds[i] = largeStakings[sInfo.stakingId].operatorId;
            _amounts[i] = sInfo.slashAmount;
            validatorInfo[sInfo.pubkey].slashAmount += sInfo.slashAmount;
            emit LargeStakingSlash(_stakingIds[i], _operatorIds[i], sInfo.pubkey, _amounts[i]);
        }

        if (_clStakingSlashInfo.length != 0) {
            operatorSlashContract.slashOperatorOfLargeStaking(_stakingIds, _operatorIds, _amounts);
        }
    }

    /**
     * @notice Get the number of verifiers of the operator,
     * including those who have recharged and those who are waiting for recharge
     */
    function getOperatorValidatorCounts(uint256 _operatorId) external view returns (uint256) {
        return totalLargeStakeAmounts[_operatorId] / 32 ether;
    }

    /**
     * @notice Get all the pledge orders of the user
     */
    function getStakingInfoOfOwner(address _owner) public view returns (StakingInfo[] memory) {
        uint256 number = 0;
        for (uint256 i = 1; i <= totalLargeStakingCounts; ++i) {
            if (largeStakings[i].owner == _owner) {
                number += 1;
            }
        }
        StakingInfo[] memory userStakings = new StakingInfo[] (number);
        uint256 index = 0;
        for (uint256 i = 1; i <= totalLargeStakingCounts; ++i) {
            if (largeStakings[i].owner == _owner) {
                userStakings[index++] = largeStakings[i];
            }
        }

        return userStakings;
    }

    /**
     * @notice Get all validators under the pledge order
     */
    function getValidatorsOfStakingId(uint256 _stakingId) public view returns (bytes[] memory) {
        return validators[_stakingId];
    }

    /**
     * @notice set staking el reward
     */
    function changeElRewardAddress(uint256 _stakingId, address _elRewardAddr) public {
        StakingInfo memory stakingInfo = largeStakings[_stakingId];
        if (stakingInfo.owner != msg.sender) {
            revert PermissionDenied();
        }

        if (_elRewardAddr == address(0)) {
            revert InvalidAddr();
        }

        emit ElRewardAddressChanged(stakingInfo.elRewardAddr, _elRewardAddr);
        largeStakings[_stakingId].elRewardAddr = _elRewardAddr;
    }

    /**
     * @notice set contract setting
     */
    function setLargeStakingSetting(
        address _dao,
        address _daoVaultAddress,
        uint256 _daoElCommissionRate,
        uint256 _MIN_STAKE_AMOUNT,
        uint256 _MAX_SLASH_AMOUNT,
        address _nodeOperatorRegistryAddress,
        address _largeOracleContractAddr,
        address _elRewardFactory,
        address _operatorSlashContract
    ) public onlyDao {
        if (_dao != address(0)) {
            emit DaoAddressChanged(dao, _dao);
            dao = _dao;
        }

        if (_daoVaultAddress != address(0)) {
            emit DaoVaultAddressChanged(daoVaultAddress, _daoVaultAddress);
            daoVaultAddress = _daoVaultAddress;
        }

        if (_daoElCommissionRate != 0) {
            emit DaoELCommissionRateChanged(daoElCommissionRate, _daoElCommissionRate);
            daoElCommissionRate = _daoElCommissionRate;
        }

        if (_MIN_STAKE_AMOUNT != 0) {
            emit MinStakeAmountChanged(MIN_STAKE_AMOUNT, _MIN_STAKE_AMOUNT);
            MIN_STAKE_AMOUNT = _MIN_STAKE_AMOUNT;
        }

        if (_MAX_SLASH_AMOUNT != 0) {
            emit MaxSlashAmountChanged(MAX_SLASH_AMOUNT, _MAX_SLASH_AMOUNT);
            MAX_SLASH_AMOUNT = _MAX_SLASH_AMOUNT;
        }

        if (_nodeOperatorRegistryAddress != address(0)) {
            emit NodeOperatorsRegistryChanged(address(nodeOperatorRegistryContract), _nodeOperatorRegistryAddress);
            nodeOperatorRegistryContract = INodeOperatorsRegistry(_nodeOperatorRegistryAddress);
        }

        if (_largeOracleContractAddr != address(0)) {
            emit ConsensusOracleChanged(largeOracleContractAddr, _largeOracleContractAddr);
            largeOracleContractAddr = _largeOracleContractAddr;
        }

        if (_elRewardFactory != address(0)) {
            emit ELRewardFactoryChanged(address(elRewardFactory), _elRewardFactory);
            elRewardFactory = IELRewardFactory(_elRewardFactory);
        }

        if (_operatorSlashContract != address(0)) {
            emit OperatorSlashChanged(address(operatorSlashContract), _operatorSlashContract);
            operatorSlashContract = IOperatorSlash(_operatorSlashContract);
        }
    }
}