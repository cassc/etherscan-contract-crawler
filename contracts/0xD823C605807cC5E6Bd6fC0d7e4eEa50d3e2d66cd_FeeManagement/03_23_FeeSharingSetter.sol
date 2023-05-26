// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {FeeSharingSystem} from './FeeSharingSystem.sol';
import {TokenDistributor} from './TokenDistributor.sol';

import {IRewardConvertor} from './IRewardConvertor.sol';
import {IMintableERC20} from './IMintableERC20.sol';

import {ITokenStaked} from './ITokenStaked.sol';

/**
 * @title FeeSharingSetter
 * @notice It receives exchange fees and owns the FeeSharingSystem contract.
 * It can plug to AMMs for converting all received currencies to WETH.
 */
contract FeeSharingSetter is ReentrancyGuard, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // Operator role
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    // Min duration for each fee-sharing period (in blocks)
    uint256 public immutable MIN_REWARD_DURATION_IN_BLOCKS;

    // Max duration for each fee-sharing period (in blocks)
    uint256 public immutable MAX_REWARD_DURATION_IN_BLOCKS;

    IERC20 public immutable x2y2Token;

    IERC20 public immutable rewardToken;

    FeeSharingSystem public feeSharingSystem;

    TokenDistributor public immutable tokenDistributor;

    // Reward convertor (tool to convert other currencies to rewardToken)
    IRewardConvertor public rewardConvertor;

    // Last reward block of distribution
    uint256 public lastRewardDistributionBlock;

    // Next reward duration in blocks
    uint256 public nextRewardDurationInBlocks;

    // Reward duration in blocks
    uint256 public rewardDurationInBlocks;

    // Set of addresses that are staking only the fee sharing
    EnumerableSet.AddressSet private _feeStakingAddresses;
    mapping(address => bool) public feeStakingAddressIStaked;

    event ConversionToRewardToken(
        address indexed token,
        uint256 amountConverted,
        uint256 amountReceived
    );
    event FeeStakingAddressesAdded(address[] feeStakingAddresses);
    event FeeStakingAddressesRemoved(address[] feeStakingAddresses);
    event NewRewardDurationInBlocks(uint256 rewardDurationInBlocks);
    event NewRewardConvertor(address rewardConvertor);

    /**
     * @notice Constructor
     * @param _feeSharingSystem address of the fee sharing system
     * @param _minRewardDurationInBlocks minimum reward duration in blocks
     * @param _maxRewardDurationInBlocks maximum reward duration in blocks
     * @param _rewardDurationInBlocks reward duration between two updates in blocks
     */
    constructor(
        address _feeSharingSystem,
        uint256 _minRewardDurationInBlocks,
        uint256 _maxRewardDurationInBlocks,
        uint256 _rewardDurationInBlocks
    ) {
        require(
            (_rewardDurationInBlocks <= _maxRewardDurationInBlocks) &&
                (_rewardDurationInBlocks >= _minRewardDurationInBlocks),
            'Owner: Reward duration in blocks outside of range'
        );

        MIN_REWARD_DURATION_IN_BLOCKS = _minRewardDurationInBlocks;
        MAX_REWARD_DURATION_IN_BLOCKS = _maxRewardDurationInBlocks;

        feeSharingSystem = FeeSharingSystem(_feeSharingSystem);

        rewardToken = feeSharingSystem.rewardToken();
        x2y2Token = feeSharingSystem.x2y2Token();
        tokenDistributor = feeSharingSystem.tokenDistributor();

        rewardDurationInBlocks = _rewardDurationInBlocks;
        nextRewardDurationInBlocks = _rewardDurationInBlocks;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev It automatically retrieves the number of pending WETH and adjusts
     * based on the balance of X2Y2 in fee-staking addresses that exist in the set.
     */
    function updateRewards() external onlyRole(OPERATOR_ROLE) {
        if (lastRewardDistributionBlock > 0) {
            require(
                block.number > (rewardDurationInBlocks + lastRewardDistributionBlock),
                'Reward: Too early to add'
            );
        }

        // Adjust for this period
        if (rewardDurationInBlocks != nextRewardDurationInBlocks) {
            rewardDurationInBlocks = nextRewardDurationInBlocks;
        }

        lastRewardDistributionBlock = block.number;

        // Calculate the reward to distribute as the balance held by this address
        uint256 reward = rewardToken.balanceOf(address(this));

        require(reward != 0, 'Reward: Nothing to distribute');

        // Check if there is any address eligible for fee-sharing only
        uint256 numberAddressesForFeeStaking = _feeStakingAddresses.length();

        // If there are eligible addresses for fee-sharing only, calculate their shares
        if (numberAddressesForFeeStaking > 0) {
            uint256[] memory x2y2Balances = new uint256[](numberAddressesForFeeStaking);
            (uint256 totalAmountStaked, ) = tokenDistributor.userInfo(address(feeSharingSystem));

            for (uint256 i = 0; i < numberAddressesForFeeStaking; i++) {
                address a = _feeStakingAddresses.at(i);
                uint256 balance = x2y2Token.balanceOf(a);
                if (feeStakingAddressIStaked[a]) {
                    balance = ITokenStaked(a).getTotalStaked();
                }
                totalAmountStaked += balance;
                x2y2Balances[i] = balance;
            }

            // Only apply the logic if the totalAmountStaked > 0 (to prevent division by 0)
            if (totalAmountStaked > 0) {
                uint256 adjustedReward = reward;

                for (uint256 i = 0; i < numberAddressesForFeeStaking; i++) {
                    uint256 amountToTransfer = (x2y2Balances[i] * reward) / totalAmountStaked;
                    if (amountToTransfer > 0) {
                        adjustedReward -= amountToTransfer;
                        rewardToken.safeTransfer(_feeStakingAddresses.at(i), amountToTransfer);
                    }
                }

                // Adjust reward accordingly
                reward = adjustedReward;
            }
        }

        // Transfer tokens to fee sharing system
        rewardToken.safeTransfer(address(feeSharingSystem), reward);

        // Update rewards
        feeSharingSystem.updateRewards(reward, rewardDurationInBlocks);
    }

    /**
     * @notice Convert currencies to reward token
     * @dev Function only usable only for whitelisted currencies (where no potential side effect)
     * @param token address of the token to sell
     * @param additionalData additional data (e.g., slippage)
     */
    function convertCurrencyToRewardToken(address token, bytes calldata additionalData)
        external
        nonReentrant
        onlyRole(OPERATOR_ROLE)
    {
        require(address(rewardConvertor) != address(0), 'Convert: RewardConvertor not set');
        require(token != address(rewardToken), 'Convert: Cannot be reward token');

        uint256 amountToConvert = IERC20(token).balanceOf(address(this));
        require(amountToConvert != 0, 'Convert: Amount to convert must be > 0');

        // Adjust allowance for this transaction only
        IERC20(token).safeIncreaseAllowance(address(rewardConvertor), amountToConvert);

        // Exchange token to reward token
        uint256 amountReceived = rewardConvertor.convert(
            token,
            address(rewardToken),
            amountToConvert,
            additionalData
        );

        emit ConversionToRewardToken(token, amountToConvert, amountReceived);
    }

    /**
     * @notice Add staking addresses
     * @param _stakingAddresses array of addresses eligible for fee-sharing only
     */
    function addFeeStakingAddresses(
        address[] calldata _stakingAddresses,
        bool[] calldata _addressIStaked
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_stakingAddresses.length == _addressIStaked.length, 'Owner: param length error');
        for (uint256 i = 0; i < _stakingAddresses.length; i++) {
            require(
                !_feeStakingAddresses.contains(_stakingAddresses[i]),
                'Owner: Address already registered'
            );
            _feeStakingAddresses.add(_stakingAddresses[i]);
            if (_addressIStaked[i]) {
                feeStakingAddressIStaked[_stakingAddresses[i]] = true;
            }
        }

        emit FeeStakingAddressesAdded(_stakingAddresses);
    }

    /**
     * @notice Remove staking addresses
     * @param _stakingAddresses array of addresses eligible for fee-sharing only
     */
    function removeFeeStakingAddresses(address[] calldata _stakingAddresses)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _stakingAddresses.length; i++) {
            require(
                _feeStakingAddresses.contains(_stakingAddresses[i]),
                'Owner: Address not registered'
            );
            _feeStakingAddresses.remove(_stakingAddresses[i]);
            if (feeStakingAddressIStaked[_stakingAddresses[i]]) {
                delete feeStakingAddressIStaked[_stakingAddresses[i]];
            }
        }

        emit FeeStakingAddressesRemoved(_stakingAddresses);
    }

    /**
     * @notice Set new reward duration in blocks for next update
     * @param _newRewardDurationInBlocks number of blocks for new reward period
     */
    function setNewRewardDurationInBlocks(uint256 _newRewardDurationInBlocks)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            (_newRewardDurationInBlocks <= MAX_REWARD_DURATION_IN_BLOCKS) &&
                (_newRewardDurationInBlocks >= MIN_REWARD_DURATION_IN_BLOCKS),
            'Owner: New reward duration in blocks outside of range'
        );

        nextRewardDurationInBlocks = _newRewardDurationInBlocks;

        emit NewRewardDurationInBlocks(_newRewardDurationInBlocks);
    }

    /**
     * @notice Set reward convertor contract
     * @param _rewardConvertor address of the reward convertor (set to null to deactivate)
     */
    function setRewardConvertor(address _rewardConvertor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardConvertor = IRewardConvertor(_rewardConvertor);

        emit NewRewardConvertor(_rewardConvertor);
    }

    /**
     * @notice See addresses eligible for fee-staking
     */
    function viewFeeStakingAddresses() external view returns (address[] memory) {
        uint256 length = _feeStakingAddresses.length();

        address[] memory feeStakingAddresses = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            feeStakingAddresses[i] = _feeStakingAddresses.at(i);
        }

        return (feeStakingAddresses);
    }
}