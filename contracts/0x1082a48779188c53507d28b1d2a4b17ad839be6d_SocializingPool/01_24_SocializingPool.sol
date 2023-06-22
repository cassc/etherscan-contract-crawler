// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './interfaces/ISocializingPool.sol';
import './interfaces/IStaderStakePoolManager.sol';
import './interfaces/IPermissionlessNodeRegistry.sol';

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SocializingPool is
    ISocializingPool,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IStaderConfig public override staderConfig;
    uint256 public override totalOperatorETHRewardsRemaining;
    uint256 public override totalOperatorSDRewardsRemaining;
    uint256 public override initialBlock;

    mapping(address => mapping(uint256 => bool)) public override claimedRewards;
    mapping(uint256 => bool) public handledRewards;
    RewardsData public lastReportedRewardsData;
    mapping(uint256 => RewardsData) public rewardsDataMap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        staderConfig = IStaderConfig(_staderConfig);
        initialBlock = block.number;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice Allows the contract to receive ETH
     * @dev execution layer rewards may be sent as plain ETH transfers
     */
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    function handleRewards(RewardsData calldata _rewardsData) external override nonReentrant {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.STADER_ORACLE());

        if (handledRewards[_rewardsData.index]) {
            revert RewardAlreadyHandled();
        }
        if (
            _rewardsData.operatorETHRewards + _rewardsData.userETHRewards + _rewardsData.protocolETHRewards >
            address(this).balance - totalOperatorETHRewardsRemaining
        ) {
            revert InsufficientETHRewards();
        }
        if (
            _rewardsData.operatorSDRewards >
            IERC20(staderConfig.getStaderToken()).balanceOf(address(this)) - totalOperatorSDRewardsRemaining
        ) {
            revert InsufficientSDRewards();
        }

        handledRewards[_rewardsData.index] = true;
        totalOperatorETHRewardsRemaining += _rewardsData.operatorETHRewards;
        totalOperatorSDRewardsRemaining += _rewardsData.operatorSDRewards;

        lastReportedRewardsData = _rewardsData;
        rewardsDataMap[_rewardsData.index] = _rewardsData;

        IStaderStakePoolManager(staderConfig.getStakePoolManager()).receiveExecutionLayerRewards{
            value: _rewardsData.userETHRewards
        }();

        (bool success, ) = payable(staderConfig.getStaderTreasury()).call{value: _rewardsData.protocolETHRewards}('');
        if (!success) {
            revert ETHTransferFailed(staderConfig.getStaderTreasury(), _rewardsData.protocolETHRewards);
        }

        emit OperatorRewardsUpdated(
            _rewardsData.operatorETHRewards,
            totalOperatorETHRewardsRemaining,
            _rewardsData.operatorSDRewards,
            totalOperatorSDRewardsRemaining
        );

        emit UserETHRewardsTransferred(_rewardsData.userETHRewards);
        emit ProtocolETHRewardsTransferred(_rewardsData.protocolETHRewards);
    }

    function claim(
        uint256[] calldata _index,
        uint256[] calldata _amountSD,
        uint256[] calldata _amountETH,
        bytes32[][] calldata _merkleProof
    ) external override nonReentrant whenNotPaused {
        address operator = msg.sender;
        (uint256 totalAmountSD, uint256 totalAmountETH) = _claim(_index, operator, _amountSD, _amountETH, _merkleProof);

        address operatorRewardsAddr = UtilLib.getOperatorRewardAddress(operator, staderConfig);

        bool success;
        if (totalAmountETH > 0) {
            totalOperatorETHRewardsRemaining -= totalAmountETH;
            (success, ) = payable(operatorRewardsAddr).call{value: totalAmountETH}('');
            if (!success) {
                revert ETHTransferFailed(operatorRewardsAddr, totalAmountETH);
            }
        }

        if (totalAmountSD > 0) {
            totalOperatorSDRewardsRemaining -= totalAmountSD;
            if (!IERC20(staderConfig.getStaderToken()).transfer(operatorRewardsAddr, totalAmountSD)) {
                revert SDTransferFailed();
            }
        }

        emit OperatorRewardsClaimed(operatorRewardsAddr, totalAmountETH, totalAmountSD);
    }

    function _claim(
        uint256[] calldata _index,
        address _operator,
        uint256[] calldata _amountSD,
        uint256[] calldata _amountETH,
        bytes32[][] calldata _merkleProof
    ) internal returns (uint256 _totalAmountSD, uint256 _totalAmountETH) {
        uint256 indexLength = _index.length;
        for (uint256 i; i < indexLength; i++) {
            if (_amountSD[i] == 0 && _amountETH[i] == 0) {
                revert InvalidAmount();
            }
            if (claimedRewards[_operator][_index[i]]) {
                revert RewardAlreadyClaimed(_operator, _index[i]);
            }

            _totalAmountSD += _amountSD[i];
            _totalAmountETH += _amountETH[i];
            claimedRewards[_operator][_index[i]] = true;

            if (!verifyProof(_index[i], _operator, _amountSD[i], _amountETH[i], _merkleProof[i])) {
                revert InvalidProof(_index[i], _operator);
            }
        }
    }

    function verifyProof(
        uint256 _index,
        address _operator,
        uint256 _amountSD,
        uint256 _amountETH,
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        if (_index == 0 || _index > lastReportedRewardsData.index) {
            revert InvalidCycleIndex();
        }
        bytes32 merkleRoot = rewardsDataMap[_index].merkleRoot;
        bytes32 node = keccak256(abi.encodePacked(_operator, _amountSD, _amountETH));
        return MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node);
    }

    // SETTERS
    function updateStaderConfig(address _staderConfig) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused.
     */
    function pause() external {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // GETTERS

    function getCurrentRewardsIndex() public view returns (uint256 index) {
        index = lastReportedRewardsData.index + 1;
    }

    function getRewardDetails()
        external
        view
        override
        returns (
            uint256 currentIndex,
            uint256 currentStartBlock,
            uint256 currentEndBlock
        )
    {
        currentIndex = getCurrentRewardsIndex();
        (currentStartBlock, currentEndBlock) = getRewardCycleDetails(currentIndex);
    }

    /// @param _index reward cycle index for which details is required
    function getRewardCycleDetails(uint256 _index) public view returns (uint256 _startBlock, uint256 _endBlock) {
        if (_index == 0) {
            revert InvalidCycleIndex();
        }

        // past cycles
        if (rewardsDataMap[_index].reportingBlockNumber != 0) {
            _startBlock = rewardsDataMap[_index - 1].reportingBlockNumber + 1;
            _endBlock = rewardsDataMap[_index].reportingBlockNumber;
            return (_startBlock, _endBlock);
        }

        // for current cycle

        uint256 cycleDuration = staderConfig.getSocializingPoolCycleDuration();
        if (_index == 1) {
            return (initialBlock, initialBlock + cycleDuration - 1);
        }
        if (rewardsDataMap[_index - 1].reportingBlockNumber != 0) {
            _startBlock = rewardsDataMap[_index - 1].reportingBlockNumber + 1;
            _endBlock = rewardsDataMap[_index - 1].reportingBlockNumber + cycleDuration;
            return (_startBlock, _endBlock);
        }

        // everything else is a future cycle
        revert FutureCycleIndex();
    }
}