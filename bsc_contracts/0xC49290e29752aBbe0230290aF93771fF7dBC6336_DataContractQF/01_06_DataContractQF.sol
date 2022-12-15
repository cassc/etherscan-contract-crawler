// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AllContractForDeployment.sol";
import "AccessControl.sol";

contract DataContractQF is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // address public operator;
    // address public transferOutOperator;
    //poolID => seqID => list of levels
    mapping(uint256 => mapping(uint256 => mapping(uint8 => uint256)))
        public lastUpdatedLevelForDeposits;
    //pool-> seq -> DepositInfo
    mapping(uint256 => mapping(uint256 => QueueFinanceLib.DepositInfo))
        public depositInfo;
    // wallet -> poolId
    mapping(address => mapping(uint256 => QueueFinanceLib.UserInfo))
        public userInfo;
    // poolID -> LevelID-> Rate
    QueueFinanceLib.RateInfoStruct[][][] public rateInfo;
    //Pool -> levels
    mapping(uint256 => mapping(uint256 => QueueFinanceLib.LevelInfo))
        public levelsInfo;
    // // Info of each pool.
    QueueFinanceLib.PoolInfo[] public poolInfo;

    mapping(uint256 => bool) poolIsPrivate;

    mapping(address => bool) preApprovedUsers;

    mapping(uint256 => Counters.Counter) public currentSequenceIncrement;
    // // Info of each pool.
    mapping(uint256 => address) public treasury;
    // pool ->levels -> Threshold
    mapping(uint256 => mapping(uint256 => QueueFinanceLib.Threshold))
        public currentThresholds;
    uint256 public withdrawTime = 86400; // 24 hours
    mapping(address => mapping(uint256 => QueueFinanceLib.RequestedClaimInfo[]))
        public requestedClaimInfo;
    Counters.Counter requestedClaimIdIncrementer;
    mapping(uint256 => uint256[]) public taxRates;

    mapping(uint256 => uint256) public poolBalance;

    // address[] public taxAddress;
    bool public initialized;
    mapping(uint256 => address[]) public taxAddress;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ACCESS_ROLE = keccak256("ACCESS_ROLE");

    // Initialize
    function initialize(address _owner) public {
        require(!initialized, "Already Initialized");
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(ADMIN_ROLE, _owner);
        _setupRole(ACCESS_ROLE, _owner);
        initialized = true;
    }

    //=========================Roles=======================================
    function checkRole(address account, bytes32 role) public view {
        require(hasRole(role, account), "Role Does Not Exist");
    }

    function checkEitherACCESSorADMIN(address account) public view {
        require(
            (hasRole(ADMIN_ROLE, account) ||
                hasRole(ACCESS_ROLE, account) ||
                hasRole(DEFAULT_ADMIN_ROLE, account)),
            "Neither ADMIN nor ACCESS"
        );
    }

    function giveRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId <= 2, "Invalid roleId");
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        bytes32 _role;
        if (_roleId == 0) {
            _role = ADMIN_ROLE;
        } else if (_roleId == 1) {
            _role = ACCESS_ROLE;
        }
        grantRole(_role, wallet);
    }

    function revokeRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId <= 2, "Invalid roleId");
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        bytes32 _role;
        if (_roleId == 0) {
            _role = ADMIN_ROLE;
        } else if (_roleId == 1) {
            _role = ACCESS_ROLE;
        }
        revokeRole(_role, wallet);
    }

    function transferRole(
        address wallet,
        address oldWallet,
        uint256 _roleId
    ) public {
        require(_roleId >= 0 && _roleId <= 2, "Invalid roleId");
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        bytes32 _role;
        if (_roleId == 0) {
            _role = ADMIN_ROLE;
        } else if (_roleId == 1) {
            _role = ACCESS_ROLE;
        }
        grantRole(_role, wallet);
        revokeRole(_role, oldWallet);
    }

    function renounceOwnership() public {
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getPoolInfo(uint256 _poolId)
        public
        view
        returns (QueueFinanceLib.PoolInfo memory)
    {
        return poolInfo[_poolId];
    }

    function addPool(QueueFinanceLib.PoolInfo memory poolData) public {
        checkRole(msg.sender, ADMIN_ROLE);
        poolInfo.push(poolData);
    }

    function getPoolInfoLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function setLastUpdatedLevelForDeposits(
        uint256 _poolID,
        uint256 _seqID,
        uint8 _levelID,
        uint256 _amount
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        lastUpdatedLevelForDeposits[_poolID][_seqID][_levelID] = _amount;
    }

    // function setPoolIsPrivate(uint256 _poolID, bool _isPrivate) public {
    //     checkRole(msg.sender, ADMIN_ROLE);
    //     poolIsPrivate[_poolID] = _isPrivate;
    // }

    function setLastUpdatedLevelsForDeposits(
        uint256 _poolID,
        uint256 _seqID,
        uint256[] memory _lastUpdatedLevelAmounts
    ) public {
        checkEitherACCESSorADMIN(msg.sender);
        for (uint8 i = 0; i < poolInfo[_poolID].levels; i++) {
            lastUpdatedLevelForDeposits[_poolID][_seqID][
                i
            ] = _lastUpdatedLevelAmounts[i];
        }
    }

    function setLastUpdatedLevelsForSequences(uint256 _poolID, QueueFinanceLib.FetchLastUpdatedLevelsForDeposits[] memory _lastUpdatedLevels, QueueFinanceLib.LastUpdatedLevelsPendings[] memory _lastUpdatedLevelsPendings) external {
        checkEitherACCESSorADMIN(msg.sender);
        for (uint256 i = 0; i < _lastUpdatedLevels.length; i++) {
            setLastUpdatedLevelsForDeposits(_poolID, _lastUpdatedLevels[i].sequenceId, _lastUpdatedLevels[i].lastUpdatedLevelsForDeposits);
        }
        for (uint256 i = 0; i < _lastUpdatedLevelsPendings.length; i++) {
            depositInfo[_poolID][_lastUpdatedLevelsPendings[i].sequenceId].accuredCoin = depositInfo[_poolID][_lastUpdatedLevelsPendings[i].sequenceId].accuredCoin.add(_lastUpdatedLevelsPendings[i].accruedCoin);
            depositInfo[_poolID][_lastUpdatedLevelsPendings[i].sequenceId].lastUpdated = block.timestamp;
        }
    }

    function setDepositInfo(
        uint256 _poolID,
        uint256 _seqID,
        QueueFinanceLib.DepositInfo memory _depositInfo
    ) public {
        checkEitherACCESSorADMIN(msg.sender);
        depositInfo[_poolID][_seqID] = _depositInfo;
    }

    function getUserInfo(address _sender, uint256 _poolId)
        public
        view
        returns (QueueFinanceLib.UserInfo memory)
    {
        return userInfo[_sender][_poolId];
    }

    function setUserInfoForDeposit(
        address _sender,
        uint256 _poolID,
        uint256 _newSeqId,
        QueueFinanceLib.UserInfo memory _userInfo
    ) public {
        checkEitherACCESSorADMIN(msg.sender);
        userInfo[_sender][_poolID] = _userInfo;
        userInfo[_sender][_poolID].depositSequences.push(_newSeqId);
    }

    function setRateInfoStruct(
        uint256 _poolID,
        uint8 _levelID,
        QueueFinanceLib.RateInfoStruct memory _rateInfoStruct
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        rateInfo[_poolID][_levelID].push(_rateInfoStruct);
    }

    function pushWholeRateInfoStruct(
        QueueFinanceLib.RateInfoStruct memory _rateInfoStruct
    ) external {
        checkRole(msg.sender, ADMIN_ROLE);
        rateInfo.push().push().push(_rateInfoStruct);
    }

    function pushRateInfoStruct(
        uint256 _poolID,
        QueueFinanceLib.RateInfoStruct memory _rateInfoStruct
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        rateInfo[_poolID].push().push(_rateInfoStruct);
    }

    function incrementPoolInfoLevels(uint256 _poolId) external {
        checkEitherACCESSorADMIN(msg.sender);
        poolInfo[_poolId].levels++;
    }

    function getRateInfoByPoolID(uint256 _poolId)
        external
        view
        returns (QueueFinanceLib.RateInfoStruct[][] memory _rateInfo)
    {
        return rateInfo[_poolId];
    }

    function setLevelsInfo(
        uint256 _poolID,
        uint8 _levelID,
        QueueFinanceLib.LevelInfo memory _levelsInfo
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        levelsInfo[_poolID][_levelID] = _levelsInfo;
    }

    function setLevelInfo(
        uint256 _pid,
        uint8 _levelId,
        QueueFinanceLib.LevelInfo memory _levelInfo
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        levelsInfo[_pid][_levelId] = _levelInfo;
    }

    function setCurrentThresholdsForTxn(
        uint256 _poolId,
        QueueFinanceLib.Threshold[] memory _threshold
    ) public {
        checkEitherACCESSorADMIN(msg.sender);
        for (uint256 i = 0; i < poolInfo[_poolId].levels; i++) {
            currentThresholds[_poolId][i] = _threshold[i];
        }
    }

    function getAllLevelInfo(uint256 _poolId)
        public
        view
        returns (QueueFinanceLib.LevelInfo[] memory)
    {
        QueueFinanceLib.LevelInfo[]
            memory levelInfoArr = new QueueFinanceLib.LevelInfo[](
                poolInfo[_poolId].levels
            );
        for (uint256 i = 0; i < poolInfo[_poolId].levels; i++) {
            levelInfoArr[i] = levelsInfo[_poolId][i];
        }
        return levelInfoArr;
    }

    function getAllThresholds(uint256 _poolId)
        public
        view
        returns (QueueFinanceLib.Threshold[] memory)
    {
        QueueFinanceLib.Threshold[]
            memory thresholdInfoArr = new QueueFinanceLib.Threshold[](
                poolInfo[_poolId].levels
            );
        for (uint256 i = 0; i < poolInfo[_poolId].levels; i++) {
            thresholdInfoArr[i] = currentThresholds[_poolId][i];
        }
        return thresholdInfoArr;
    }

    function setPoolInfo(
        uint256 _poolID,
        QueueFinanceLib.PoolInfo memory _poolInfo
    ) public {
        checkEitherACCESSorADMIN(msg.sender);
        poolInfo[_poolID] = _poolInfo;
    }

    function doCurrentSequenceIncrement(uint256 _poolID)
        public
        returns (uint256)
    {
        checkEitherACCESSorADMIN(msg.sender);
        currentSequenceIncrement[_poolID].increment();
        return currentSequenceIncrement[_poolID].current();
    }

    function updatePoolBalance(
        uint256 _poolID,
        uint256 _amount,
        bool isIncrease
    ) public {
        checkRole(msg.sender, ACCESS_ROLE);
        if (isIncrease) {
            poolBalance[_poolID] = poolBalance[_poolID].add(_amount);
        } else {
            poolBalance[_poolID] = poolBalance[_poolID].sub(_amount);
        }
    }

    function setCurrentThresholds(
        uint256 _poolID,
        uint256 _levelID,
        QueueFinanceLib.Threshold memory _threshold
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        currentThresholds[_poolID][_levelID] = _threshold;
    }

    function setTaxAddress(
        uint256 _poolId,
        address _devTaxAddress,
        address _protocalTaxAddress,
        address _introducerAddress,
        address _networkAddress
    ) public {
        checkEitherACCESSorADMIN(msg.sender);
        address[] memory _taxAddress = new address[](4);
        _taxAddress[0] = _devTaxAddress;
        _taxAddress[1] = _protocalTaxAddress;
        _taxAddress[2] = _introducerAddress;
        _taxAddress[3] = _networkAddress;
        taxAddress[_poolId] = _taxAddress;
    }

    function getTaxAddress(uint256 _poolId) public view returns (address[] memory) {
        checkEitherACCESSorADMIN(msg.sender);
        return taxAddress[_poolId];
    }
    function getSequenceIdsFromCurrentThreshold(uint256 _poolId)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory sequenceIds = new uint256[](poolInfo[_poolId].levels);
        for (uint256 i = 0; i < poolInfo[_poolId].levels; i++) {
            sequenceIds[i] = currentThresholds[_poolId][i].sequence;
        }
        return sequenceIds;
    }

    function fetchDepositsBasedonSequences(
        uint256 _poolId,
        uint256[] memory _sequenceIds
    ) public view returns (QueueFinanceLib.DepositsBySequence[] memory) {
        QueueFinanceLib.DepositsBySequence[]
            memory depositsInfo = new QueueFinanceLib.DepositsBySequence[](
                _sequenceIds.length
            );

        for (uint256 i = 0; i < _sequenceIds.length; i++) {
            depositsInfo[i] = QueueFinanceLib.DepositsBySequence({
                sequenceId: _sequenceIds[i],
                depositInfo: depositInfo[_poolId][_sequenceIds[i]]
            });
        }

        return depositsInfo;
    }

    function getPoolStartTime(uint256 _poolId) external view returns (uint256) {
        return poolInfo[_poolId].poolStartTime;
    }

    function getLatestRateInfo(uint256 _pid, uint256 _levelID)
        external
        view
        returns (QueueFinanceLib.RateInfoStruct memory)
    {
        return rateInfo[_pid][_levelID][rateInfo[_pid][_levelID].length - 1];
    }

    function getRateInfoLength(uint256 _pid, uint256 _levelID)
        external
        view
        returns (uint256)
    {
        return rateInfo[_pid][_levelID].length;
    }

    function getLatestRateInfoByPosition(
        uint256 _pid,
        uint256 _levelID,
        uint256 _position
    ) external view returns (QueueFinanceLib.RateInfoStruct memory) {
        return rateInfo[_pid][_levelID][_position];
    }

    function pushRateInfo(
        uint256 _pid,
        uint256 _levelID,
        QueueFinanceLib.RateInfoStruct memory _rateInfo
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        rateInfo[_pid][_levelID].push(_rateInfo);
    }

    function setRateInfoByPosition(
        uint256 _pid,
        uint256 _levelID,
        uint256 _position,
        QueueFinanceLib.RateInfoStruct memory _rateInfo
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        rateInfo[_pid][_levelID][_position].timestamp = _rateInfo.timestamp;
        rateInfo[_pid][_levelID][_position].rate = _rateInfo.rate;
    }

    // @notice Sets the pool end time to extend the gen pools if required.
    function setPoolEndTime(uint256 _poolID, uint256 _pool_end_time) external {
        checkRole(msg.sender, ADMIN_ROLE);
        poolInfo[_poolID].poolEndTime = _pool_end_time;
    }

    function setPoolStartTime(uint256 _poolID, uint256 _pool_start_time)
        external
    {
        checkRole(msg.sender, ADMIN_ROLE);
        poolInfo[_poolID].poolStartTime = _pool_start_time;
    }

    function setEInvestValue(uint256 _poolID, uint256 _eInvestCoinValue)
        external
    {
        checkRole(msg.sender, ADMIN_ROLE);
        poolInfo[_poolID].eInvestCoinValue = _eInvestCoinValue;
    }

    function addReplenishReward(uint256 _poolID, uint256 _value) external {
        checkRole(msg.sender, ADMIN_ROLE);
        poolInfo[_poolID].rewardsBalance += _value;
    }

    function getRewardToken(uint256 _poolId) external view returns (IERC20) {
        return poolInfo[_poolId].rewardToken;
    }

    // // @notice sets a pool's isStarted to true and increments total allocated points
    // function startPool(uint256 _pid) public {
    //     checkRole(msg.sender, ADMIN_ROLE);
    //     if (!poolInfo[_pid].isStarted) {
    //         poolInfo[_pid].isStarted = true;
    //     }
    // }

    function setTreasury(uint256 _pId, address _treasury) external {
        checkRole(msg.sender, ADMIN_ROLE);
        treasury[_pId] = _treasury;
    }

    function setWithdrawTime(uint256 _timeSpan) external {
        checkRole(msg.sender, ADMIN_ROLE);
        withdrawTime = _timeSpan;
    }

    function getWithdrawTime() external view returns (uint256) {
        return withdrawTime;
    }

    function setTaxRates(uint256 _poolID, uint256[] memory _taxRates) external {
        checkEitherACCESSorADMIN(msg.sender);
        taxRates[_poolID] = _taxRates;
    }

    function getTaxRates(uint256 _poolID)
        external
        view
        returns (uint256[] memory)
    {
        return taxRates[_poolID];
    }

    function addPreApprovedUser(address[] memory userAddress) external {
        checkEitherACCESSorADMIN(msg.sender);
        for (uint256 i = 0; i < userAddress.length; i++) {
            if (!preApprovedUsers[userAddress[i]]) {
                preApprovedUsers[userAddress[i]] = true;
            }
        }
    }

    function setMaximumStakingAllowed(
        uint256 _pid,
        uint256 _maximumStakingAllowed
    ) external {
        checkRole(msg.sender, ADMIN_ROLE);
        poolInfo[_pid].maximumStakingAllowed = _maximumStakingAllowed;
    }

    function returnDepositSeqList(uint256 _poodID, address _sender)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[_sender][_poodID].depositSequences;
    }

    function fetchLastUpdatatedLevelsBySequenceIds(
        uint256 _poolID,
        uint256[] memory sequenceIds
    )
        external
        view
        returns (QueueFinanceLib.FetchLastUpdatedLevelsForDeposits[] memory)
    {
        QueueFinanceLib.FetchLastUpdatedLevelsForDeposits[]
            memory LULD = new QueueFinanceLib.FetchLastUpdatedLevelsForDeposits[](
                sequenceIds.length
            );
        for (uint256 i = 0; i < sequenceIds.length; i++) {
            uint256[] memory lastUpdatedLevels = new uint256[](
                poolInfo[_poolID].levels
            );
            for (uint8 j = 0; j < poolInfo[_poolID].levels; j++) {
                lastUpdatedLevels[j] = lastUpdatedLevelForDeposits[_poolID][
                    sequenceIds[i]
                ][j];
            }
            LULD[i] = QueueFinanceLib.FetchLastUpdatedLevelsForDeposits({
                sequenceId: sequenceIds[i],
                lastUpdatedLevelsForDeposits: lastUpdatedLevels
            });
        }
        return LULD;
    }

    function pushRequestedClaimInfo(
        address _sender,
        uint256 _poolId,
        QueueFinanceLib.RequestedClaimInfo memory _requestedClaimInfo
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        requestedClaimInfo[_sender][_poolId].push(_requestedClaimInfo);
        requestedClaimIdIncrementer.increment();
    }

    function getRequestedClaimInfoIncrementer()
        external
        view
        returns (uint256)
    {
        checkEitherACCESSorADMIN(msg.sender);
        return requestedClaimIdIncrementer.current();
    }

    function getPoolIsPrivateForUser(uint256 _pid, address _user) public view returns (bool, bool){
        checkEitherACCESSorADMIN(msg.sender);
        return (poolIsPrivate[_pid], preApprovedUsers[_user]);
    }

    function getDepositBySequenceId(uint256 _poolId, uint256 _seqId)
        external
        view
        returns (QueueFinanceLib.DepositInfo memory)
    {
        return depositInfo[_poolId][_seqId];
    }

    function removeSeqAndUpdateUserInfo(
        uint256 _poolId,
        uint256 _seqId,
        address _sender,
        uint256 _amount,
        uint256 _interest
    ) internal {
        (uint256 removeIndexForSequences, bool isThere) = QueueFinanceLib
            .getRemoveIndex(
                _seqId,
                userInfo[_sender][_poolId].depositSequences
            );
        if (isThere) {
            // swapping with last element and then pop
            userInfo[_sender][_poolId].depositSequences[
                removeIndexForSequences
            ] = userInfo[_sender][_poolId].depositSequences[
                userInfo[_sender][_poolId].depositSequences.length - 1
            ];
            userInfo[_sender][_poolId].depositSequences.pop();
        }

        userInfo[_sender][_poolId].initialStakedAmount = userInfo[_sender][
            _poolId
        ].initialStakedAmount.sub(_amount);
        userInfo[_sender][_poolId].totalAmount = userInfo[_sender][_poolId]
            .totalAmount
            .sub(_amount);
        userInfo[_sender][_poolId].totalAccrued = userInfo[_sender][_poolId]
            .totalAccrued
            .add(_interest);
        userInfo[_sender][_poolId].totalClaimedCoin = userInfo[_sender][_poolId]
            .totalAccrued;
        userInfo[_sender][_poolId].lastAccrued = block.timestamp;
    }

    function updateAddressOnUserInfo(
        uint256 _pid,
        address _sender,
        address _referral
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        
        if (userInfo[_sender][_pid].referral == address(0)) {
            if (_referral == address(0)) {
                _referral = taxAddress[_pid][3];
            }
            userInfo[_sender][_pid].referral = _referral;
        }
    }

    function getWithdrawRequestedClaimInfo(address _sender, uint256 _pid)
        external
        view
        returns (QueueFinanceLib.RequestedClaimInfo[] memory)
    {
        return requestedClaimInfo[_sender][_pid];
    }

    function fetchWithdrawLength(uint256 _pid, address user)
        external
        view
        returns (uint256)
    {
        return requestedClaimInfo[user][_pid].length;
    }

    function swapAndPopForWithdrawal(
        uint256 _pid,
        address user,
        uint256 clearIndex
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        //  swapping with last element and then pop
        requestedClaimInfo[user][_pid][clearIndex] = requestedClaimInfo[user][
            _pid
        ][requestedClaimInfo[user][_pid].length - 1];
        requestedClaimInfo[user][_pid].pop();
    }

    function doTransfer(
        uint256 amount,
        address to,
        IERC20 depositToken
    ) external {
        checkEitherACCESSorADMIN(msg.sender);
        IERC20(depositToken).safeTransfer(to, amount);
    }
    function addDepositDetailsToDataContract(
        QueueFinanceLib.AddDepositModule memory _addDepositData
    ) public {
        checkRole(msg.sender, ACCESS_ROLE);
        poolInfo[_addDepositData.addDepositData.poolId]
            .totalStaked = _addDepositData.addDepositData.poolTotalStaked;

        poolInfo[_addDepositData.addDepositData.poolId]
            .lastActiveSequence = _addDepositData
            .addDepositData
            .poolLastActiveSequence;
        poolInfo[_addDepositData.addDepositData.poolId]
            .currentSequence = _addDepositData.addDepositData.seqId;

        depositInfo[_addDepositData.addDepositData.poolId][
            _addDepositData.addDepositData1.updateDepositInfo.sequenceId
        ] = _addDepositData.addDepositData1.updateDepositInfo.depositInfo;
        
        depositInfo[_addDepositData.addDepositData.poolId][
            _addDepositData.addDepositData.prevSeqId
        ].nextSequenceID = _addDepositData.addDepositData.seqId;

        userInfo[_addDepositData.addDepositData.sender][
            _addDepositData.addDepositData.poolId
        ].initialStakedAmount = userInfo[_addDepositData.addDepositData.sender][
            _addDepositData.addDepositData.poolId
        ].initialStakedAmount.add(
                _addDepositData
                    .addDepositData1
                    .updateDepositInfo
                    .depositInfo
                    .stakedAmount
            );
        userInfo[_addDepositData.addDepositData.sender][
            _addDepositData.addDepositData.poolId
        ].totalAmount = userInfo[_addDepositData.addDepositData.sender][
            _addDepositData.addDepositData.poolId
        ].totalAmount.add(
                _addDepositData
                    .addDepositData1
                    .updateDepositInfo
                    .depositInfo
                    .stakedAmount
            );
        userInfo[_addDepositData.addDepositData.sender][
            _addDepositData.addDepositData.poolId
        ].lastAccrued = _addDepositData.addDepositData.blockTime;
        userInfo[_addDepositData.addDepositData.sender][
            _addDepositData.addDepositData.poolId
        ].depositSequences.push(_addDepositData.addDepositData.seqId);
        
        for (
            uint8 i = 0;
            i < _addDepositData.addDepositData1.levelsAffected.length;
            i++
        ) {
            lastUpdatedLevelForDeposits[_addDepositData.addDepositData.poolId][
                _addDepositData.addDepositData.seqId
            ][
                _addDepositData.addDepositData1.levelsAffected[i]
            ] = _addDepositData.addDepositData1.updatedLevelsForDeposit[
                _addDepositData.addDepositData1.levelsAffected[i]
            ];

            currentThresholds[_addDepositData.addDepositData.poolId][
                _addDepositData.addDepositData1.levelsAffected[i]
            ] = _addDepositData.addDepositData1.threshold[
                _addDepositData.addDepositData1.levelsAffected[i]
            ];
            levelsInfo[_addDepositData.addDepositData.poolId][
                _addDepositData.addDepositData1.levelsAffected[i]
            ] = _addDepositData.addDepositData1.levelsInfo[
                _addDepositData.addDepositData1.levelsAffected[i]
            ];
            currentThresholds[_addDepositData.addDepositData.poolId][
                _addDepositData.addDepositData1.levelsAffected[i]
            ] = _addDepositData.addDepositData1.threshold[
                _addDepositData.addDepositData1.levelsAffected[i]
            ];
        }
    }

    function updateWithDrawDetails(
        QueueFinanceLib.UpdateWithdrawDataInALoop memory _withdrawData
    ) external {
        checkRole(msg.sender, ACCESS_ROLE);
         QueueFinanceLib.DepositInfo memory _currentDeposit = depositInfo[
            _withdrawData.poolId
        ][_withdrawData.currSeqId];


         removeSeqAndUpdateUserInfo(
            _withdrawData.poolId,
            _withdrawData.currSeqId,
            _withdrawData.user,
            _currentDeposit.stakedAmount,
            _withdrawData.interest
        );

        depositInfo[_withdrawData.poolId][_withdrawData.curDepositPrevSeqId]
            .nextSequenceID = _withdrawData.depositPreviousNextSequenceID;

       
        if (_currentDeposit.nextSequenceID > _withdrawData.currSeqId) {
            depositInfo[_withdrawData.poolId][_withdrawData.curDepositNextSeqId]
                .previousSequenceID = _withdrawData
                .depositNextPreviousSequenceID;
        }

        _currentDeposit.accuredCoin += _withdrawData.interest;
        _currentDeposit.claimedCoin = _currentDeposit.accuredCoin;
        _currentDeposit.lastUpdated = block.timestamp;

        poolInfo[_withdrawData.poolId].totalStaked = poolInfo[
            _withdrawData.poolId
        ].totalStaked.sub(_currentDeposit.stakedAmount);

        if (
            _withdrawData.currSeqId ==
            poolInfo[_withdrawData.poolId].lastActiveSequence
        ) {
            poolInfo[_withdrawData.poolId].lastActiveSequence = _currentDeposit
                .previousSequenceID;
        }

        _currentDeposit.nextSequenceID = 0;
        _currentDeposit.previousSequenceID = 0;
        _currentDeposit.inactive = 1;

        depositInfo[_withdrawData.poolId][
            _withdrawData.currSeqId
        ] = _currentDeposit;

        for (uint256 i = 0; i < poolInfo[_withdrawData.poolId].levels; i++) {
            currentThresholds[_withdrawData.poolId][i] = _withdrawData.thresholds[i];
            levelsInfo[_withdrawData.poolId][i] = _withdrawData.levelsInfo[i];
        }

       
    }
}