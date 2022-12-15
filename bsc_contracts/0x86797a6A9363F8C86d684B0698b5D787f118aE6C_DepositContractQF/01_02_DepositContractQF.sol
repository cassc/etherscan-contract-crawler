// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AllContractForDeployment.sol";

contract DepositContractQF {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    IDataContractQF public iDataContractQF;

    uint8[] levelsAffected;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    constructor(address _accessContract) {
        iDataContractQF = IDataContractQF(_accessContract);
    }

    function setDataContractAddress(address _dataContract) external {
        iDataContractQF.checkRole(msg.sender, keccak256("ADMIN_ROLE"));
        iDataContractQF = IDataContractQF(_dataContract);
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referral
    ) external {
         iDataContractQF.updateAddressOnUserInfo(
                _pid,
                msg.sender,
                _referral
            );

        (bool poolIsPrivate, bool isUserThere) = iDataContractQF.getPoolIsPrivateForUser(_pid, msg.sender);
        if (poolIsPrivate) {
             require(
                isUserThere,
                "User does not have pre-approval"
            );
            depositInternal(_pid, _amount, false, msg.sender);
        } else {
            depositInternal(_pid, _amount, false, msg.sender);
        }


           
    }

    function depositFromWithdraw(
        uint256 _pid,
        uint256 _amount,
        bool isInternal,
        address _sender
    ) external {
        iDataContractQF.checkRole(msg.sender, keccak256("ACCESS_ROLE"));
        depositInternal(_pid, _amount, isInternal, _sender);
    }

    function depositInternal(
        uint256 _pid,
        uint256 _amount,
        bool isInternal,
        address _sender
    ) internal {
        QueueFinanceLib.AllDepositData memory _allDepositData = getDepositData(_pid, _sender);

        require(
            block.timestamp >= _allDepositData.poolInfo.poolStartTime,
            "Pool has not started yet!"
        );

        require(
            block.timestamp < _allDepositData.poolInfo.poolEndTime,
            "Pool has ended already!"
        );

        require(
            _allDepositData.userInfo.totalAmount + _amount <=
                _allDepositData.poolInfo.maximumStakingAllowed,
            "Maximum staking limit reached"
        );


        // Financial transaction
        // 1. Transfer Deposit token to treasury from the user
        if (!isInternal) {
            IERC20(_allDepositData.poolInfo.depositToken).safeTransferFrom(
                _sender,
                address(iDataContractQF),
                _amount
            );
            _amount = getTaxedAmount(
                _pid,
                _allDepositData.poolInfo.depositToken,
                _amount,
                _allDepositData.userInfo.referral
            );

            iDataContractQF.doTransfer(
                _amount,
                iDataContractQF.treasury(_pid),
                _allDepositData.poolInfo.depositToken
            );
        }

        //1. Blindly add to depositInfo after creating sequence
        QueueFinanceLib.AddDepositInfo memory _updatedForLevelDeposits;
        (
            _allDepositData.poolInfo,
            _updatedForLevelDeposits
        ) = addDepositInfoAndUpdateChain(
            _pid,
            _allDepositData.poolInfo,
            _sender,
            _amount
        );

        //2. Calculate amountsplit
        uint256[] memory depositSplit = calculateAmountSplitAcrossLevels(
            _allDepositData.poolInfo,
            _allDepositData.levelInfo,
            _amount
        );


        for (uint8 i = 0; i < depositSplit.length; i++) {
            if (depositSplit[i] != 0) {
                levelsAffected.push(i);
            }
        }

        iDataContractQF.addDepositDetailsToDataContract(
            QueueFinanceLib.AddDepositModule({
                addDepositData: QueueFinanceLib.AddDepositData({
                    poolId: _pid,
                    seqId: _allDepositData.poolInfo.currentSequence,
                    sender: _sender,
                    prevSeqId: _updatedForLevelDeposits.depositInfo.previousSequenceID,
                    poolTotalStaked: _allDepositData.poolInfo.totalStaked,
                    poolLastActiveSequence: _allDepositData.poolInfo.lastActiveSequence,
                    blockTime: block.timestamp
                }),
                addDepositData1: QueueFinanceLib.AddDepositData1({
                    levelsAffected: levelsAffected,
                    updateDepositInfo: _updatedForLevelDeposits,
                    updatedLevelsForDeposit: updateLevelsForDeposit(
                        _allDepositData.poolInfo,
                        depositSplit
                    ),
                    levelsInfo: updateLevelInfo(
                        _allDepositData.levelInfo,
                        depositSplit
                    ),
                    threshold: updateThresholdsForDeposit(
                        _allDepositData.poolInfo,
                        _allDepositData.thresholdInfo,
                        depositSplit
                    )
                })
            })
        );

        uint8[] memory clear;
        levelsAffected = clear;

        emit Deposit(msg.sender, _pid, _pid);
    }

    function getTaxedAmount(
        uint256 _pid,
        IERC20 depositToken,
        uint256 _amount,
        address _referral
    ) internal returns (uint256) {
        uint256[] memory _taxRates = iDataContractQF.getTaxRates(_pid);
        address[] memory taxAddress = iDataContractQF.getTaxAddress(_pid);
        uint256 _calculatedAmount = 0;

        for (uint256 i = 0; i < 5; i++) {
            uint256 tax = 0;
            if (_taxRates[i] == 0) {
                continue;
            }

            tax = ((SafeMath.mul(_amount, _taxRates[i])).div(100)).div(
                1000000000000000000
            );
            _calculatedAmount = _calculatedAmount.add(tax);
            if (i == 4) {
                iDataContractQF.doTransfer(tax, _referral, depositToken);
            } else {
                iDataContractQF.doTransfer(tax, taxAddress[i], depositToken);
            }
            tax = 0;
        }
        _calculatedAmount = SafeMath.sub(_amount, _calculatedAmount);
        return _calculatedAmount;
    }

    function addDepositInfoAndUpdateChain(
        uint256 _pid,
        QueueFinanceLib.PoolInfo memory _pool,
        address _sender,
        uint256 _amount
    )
        internal
        returns (
            QueueFinanceLib.PoolInfo memory,
            QueueFinanceLib.AddDepositInfo memory updatedDepositList
        )
    {
        // new entry for current deposit
        uint256 _currentSequenceIncrement = iDataContractQF
            .doCurrentSequenceIncrement(_pid);
        _pool.currentSequence = _currentSequenceIncrement;
        updatedDepositList.sequenceId = _pool.currentSequence;
        updatedDepositList.depositInfo = QueueFinanceLib.DepositInfo({
            wallet: _sender,
            depositDateTime: block.timestamp, // UTC
            initialStakedAmount: _amount,
            iCoinValue: _pool.eInvestCoinValue,
            stakedAmount: _amount,
            lastUpdated: block.timestamp,
            nextSequenceID: 0,
            previousSequenceID: _pool.lastActiveSequence,
            accuredCoin: 0,
            claimedCoin: 0,
            inactive: 0
        });

        // update the lastActiveSequence and basically pool data
        
        _pool.lastActiveSequence = _pool.currentSequence;
        _pool.totalStaked = _pool.totalStaked.add(_amount);

        return (_pool, updatedDepositList);
    }

    function updateThresholdsForDeposit(
        QueueFinanceLib.PoolInfo memory _poolInfoByPoolID,
        QueueFinanceLib.Threshold[] memory _currentThreshold,
        uint256[] memory depositSplit
    ) internal pure returns (QueueFinanceLib.Threshold[] memory) {
        //     There will be n-1 currentThresholds
        //     elements are added already; n - no of levels
        //     process seperately for n = 1; 0 -> poolInfo.lastActiveSequence with 100% amount
        if (_poolInfoByPoolID.levels == 1) {
            _currentThreshold[0] = QueueFinanceLib.Threshold({
                sequence: _poolInfoByPoolID.lastActiveSequence,
                amount: depositSplit[0]
            });
        }

        //In a loop i from 0 to n-2
        for (uint256 i = 0; i <= depositSplit.length - 1; i++) {
            //        Case 1: 100% amount is in ith level  => move threshold to current block
            if (depositSplit[i] != 0) {
                _currentThreshold[i] = QueueFinanceLib.Threshold({
                    sequence: _poolInfoByPoolID.lastActiveSequence,
                    amount: depositSplit[i]
                });
            }
        }

        return _currentThreshold;
    }

    function calculateAmountSplitAcrossLevels(
        QueueFinanceLib.PoolInfo memory _pool,
        QueueFinanceLib.LevelInfo[] memory _levelsInfo,
        uint256 _amount
    ) internal pure returns (uint256[] memory) {
        uint256[] memory _levels = new uint256[](_pool.levels);
        uint256 next_level_transaction_amount = _amount;
        uint256 current_level_availability;

        for (uint256 i = 0; i < _pool.levels; i++) {
            current_level_availability = SafeMath.sub(
                _levelsInfo[i].levelStakingLimit,
                _levelsInfo[i].levelStaked
            );
            if (next_level_transaction_amount <= current_level_availability) {
                // push only if greater than zero
                if (next_level_transaction_amount > 0) {
                    _levels[i] = next_level_transaction_amount;
                }
                break;
            }
            if (i == _pool.levels - 1) {
                require(
                    next_level_transaction_amount <= current_level_availability,
                    "Could not deposit complete amount"
                );
            }
            // push only if greater than zero
            if (current_level_availability > 0) {
                _levels[i] = current_level_availability;
            }
            next_level_transaction_amount = SafeMath.sub(
                next_level_transaction_amount,
                current_level_availability
            );
        }

        return _levels;
    }

    function updateLevelsForDeposit(
        QueueFinanceLib.PoolInfo memory _pool,
        uint256[] memory _depositSplit
    ) internal pure returns (uint256[] memory) {
        uint256[] memory _lastUpdatedLevelsForDeposit = new uint256[](
            _pool.levels
        );
        for (uint8 i = 0; i < _depositSplit.length; i++) {
            _lastUpdatedLevelsForDeposit[i] = _depositSplit[i];
        }
        return _lastUpdatedLevelsForDeposit;
    }

    function updateLevelInfo(
        QueueFinanceLib.LevelInfo[] memory _levelsInfo,
        uint256[] memory depositSplit
    ) internal pure returns (QueueFinanceLib.LevelInfo[] memory) {
        for (uint256 i = 0; i < depositSplit.length; i++) {
            _levelsInfo[i].levelStaked = _levelsInfo[i].levelStaked.add(
                depositSplit[i]
            );
        }
        return _levelsInfo;
    }

    function getDepositData(uint256 _poolId, address _sender)
        internal
        view
        returns (QueueFinanceLib.AllDepositData memory)
    {
        QueueFinanceLib.PoolInfo memory _pool = iDataContractQF.getPoolInfo(
            _poolId
        );

        QueueFinanceLib.AddDepositInfo
            memory addDepositInfoData = QueueFinanceLib.AddDepositInfo({
                sequenceId: _pool.lastActiveSequence,
                depositInfo: iDataContractQF.getDepositBySequenceId(_poolId, _pool.lastActiveSequence)
            });

        return (
            QueueFinanceLib.AllDepositData({
                poolInfo: _pool,
                sequenceId: 0,
                depositInfo: addDepositInfoData,
                levelInfo: iDataContractQF.getAllLevelInfo(_poolId),
                userInfo: iDataContractQF.getUserInfo(_sender, _poolId),
                thresholdInfo: iDataContractQF.getAllThresholds(_poolId)
            })
        );
    }
}