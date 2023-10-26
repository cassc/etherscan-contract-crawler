// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../interfaces/IOptionFactory.sol";
import "../interfaces/IStakingPools.sol";
import "../interfaces/IDOBStakingPool.sol";
import "../interfaces/IContractGenerator.sol";
import "../interfaces/IOption.sol";

/**
 * @title OptionFactory
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice The OptionFactory contract is the primary control center for creating and managing options and staking pools within the ecosystem. It provides functionalities to set and update various fee ratios, to extend the staking pool end block, to update option funds, and to manage the lifecycle of options.
 * @dev This contract is designated as 'Ownable', meaning it has an owner address, and guards against unauthorized access by checking the 'onlyOwner' modifier. It interfaces with the IOptionFactory, IDOBStakingPool, and IStakingPools contracts to perform various tasks related to option and staking pool management.
 */
contract OptionFactory is OwnableUpgradeable, IOptionFactory {
    using SafeMathUpgradeable for uint256;

    /**
     * @notice The time taken (in seconds) for a block to be mined.
     * @dev This value is public.
     */
    uint8 public blockTime;

    /**
     * @notice The staking reward given per block.
     * @dev This value is public and can be updated by the contract owner.
     */
    uint256 public stakingRewardPerBlock;

    /**
     * @notice The address of the staking pools contract.
     * @dev This value is public and can be updated by the contract owner.
     */
    address public stakingPools;

    /**
     * @notice The address of the DOB Staking Pool contract.
     * @dev This value is public and can be updated by the contract owner.
     */
    address public DOBStakingPool;

    /**
     * @notice The address of the bHODL token contract.
     * @dev This value is public.
     */
    address public bHODL;

    /**
     * @notice The address of the uHODL token contract.
     * @dev This value is public.
     */
    address public uHODL;

    /**
     * @notice The address of the distributions contract.
     * @dev This value is public and can be updated by the contract owner.
     */
    address public override distributions;

    /**
     * @notice The address of the ContractGenerator contract.
     * @dev This value is public and can be updated by the contract owner.
     */
    address public ContractGenerator;

    /**
     * @notice The address of the fund contract.
     * @dev This value is public and can be updated by the contract owner.
     */
    address public fund;

    /**
     * @notice The ID of the last option that was created.
     * @dev This value is private and incremented every time a new option is created.
     */
    uint256 private lastOptionId;

    /**
     * @notice The address of the clone bullet contract.
     * @dev This value is private and updated every time a new bullet is cloned.
     */
    address private cloneBullet;

    /**
     * @notice The address of the clone sniper contract.
     * @dev This value is private and updated every time a new sniper is cloned.
     */
    address private cloneSniper;

    /**
     * @notice The ID of the clone option contract.
     * @dev This value is private and updated every time a new option is cloned.
     */
    uint256 private cloneOptionId;

    /**
     * @notice A structure for storing the addresses of the option, sniper, and bullet contracts.
     * @dev The structure is private and used when a new option is created.
     */
    struct BlankOption {
        address option;
        address sniper;
        address bullet;
    }
    BlankOption[] private blankOptions;

    /**
     * @notice The count of blank options in the factory.
     * @dev This public variable is used to keep track of the number of blank options currently stored in the contract.
     *      It's specifically meant to facilitate easy retrieval of the length of the `blankOptions` array.
     */
    uint256 public blankOptionCount;

    /**
     * @notice A mapping of option ID to option contract address.
     * @dev This mapping is private and updated every time a new option is created.
     */
    mapping(uint256 => address) private allOptions;

    /**
     * @notice A mapping of operator address to their whitelisted status.
     * @dev This mapping is public and can be updated by the contract owner.
     */
    mapping(address => bool) public operatorWhitelist;

    /**
     * @notice Event emitted when a new option is created.
     * @dev Contains details about the option, including its ID, contract addresses, strike price, timestamps, and type.
     */
    event OptionCreated(
        uint256 optionID,
        address indexed option,
        address indexed bullet,
        address indexed sniper,
        uint256 strikePrice,
        uint256 startTimestamp,
        uint256 exerciseTimestamp,
        uint256 optionType
    );

    /**
     * @notice Event emitted when the staking reward per block is updated.
     * @dev Contains the old and new reward values.
     */
    event StakingRewardPerBlockChanged(uint256 oldReward, uint256 newReward);

    /**
     * @notice Event emitted when the staking pool address is updated.
     * @dev Contains the old and new staking pool addresses.
     */
    event StakingPoolChanged(address oldStakingPool, address newStakingPool);

    /**
     * @notice Event emitted when the DOB Staking Pool address is updated.
     * @dev Contains the old and new DOB Staking Pool addresses.
     */
    event DOBStakingChanged(address oldDOBStaking, address newDOBStaking);

    /**
     * @notice Event emitted when the distributions address is updated.
     * @dev Contains the old and new distributions addresses.
     */
    event DistribuionsChanged(address oldDDistribuions, address newDistribuions);

    /**
     * @notice Event emitted when the block time is updated.
     * @dev Contains the old and new block time values.
     */
    event BlockTimeChanged(uint8 oldBlockTime, uint8 newBlocktime);

    /**
     * @notice Event emitted when an operator's whitelist status is updated.
     * @dev Contains the operator's address and their new whitelist status.
     */
    event WhitelistChanged(address operator, bool isWhitelisted);

    /**
     * @notice Modifier that requires the caller to be whitelisted.
     * @dev This modifier is used to restrict certain functions to whitelisted operators.
     */
    modifier onlyWhitelist(address _operator) {
        require(operatorWhitelist[_operator], "OptionFactory: Only whitelist");
        _;
    }

    /**
     * @notice Initializes the OptionFactory contract.
     * @dev This is a public function with the initializer modifier, which ensures that it can only be called once, when the contract is first created.
     * - The function first initializes the contract ownership by calling the __Ownable_init function.
     * - It then verifies that the provided bHODL and uHODL addresses are not the zero address.
     * - The function sets the bHODL and uHODL addresses, and the block time, and the staking reward per block.
     * @param _bHodlAddress The address of the bHODL token.
     * @param _uHodlAddress The address of the uHODL token.
     * @custom:error "OptionFactory: zero address" Error thrown if either the bHODL or uHODL address is the zero address.
     */
    function __OptionFactory_init(address _bHodlAddress, address _uHodlAddress) public initializer {
        __Ownable_init();
        require(_bHodlAddress != address(0), "OptionFactory: zero address");
        require(_uHodlAddress != address(0), "OptionFactory: zero address");

        bHODL = _bHodlAddress;
        uHODL = _uHodlAddress;
        blockTime = 12;
        stakingRewardPerBlock = 1.38 * 1e18; // 1.38 DOB per block
    }

    /**
     * @notice Allows the contract owner to adjust the block time.
     * @dev Sets the block time. Must be called by the contract owner.
     * @param _blockTime The block time needed by the system.
     */
    function setBlockTime(uint8 _blockTime) external onlyOwner {
        require(_blockTime > 0, "OptionFactory: zero blockTime");
        uint8 oldBlockTime = blockTime;
        blockTime = _blockTime;
        emit BlockTimeChanged(oldBlockTime, blockTime);
    }

    /**
     * @notice Allows the contract owner to set the address of the staking pools.
     * @dev Sets the staking pools address. Must be called by the contract owner.
     * @param _stakingPools The address of the new staking pools.
     */
    function setStakingPools(address _stakingPools) external onlyOwner {
        require(_stakingPools != address(0), "OptionFactory: zero address");
        address oldStakingPools = stakingPools;
        stakingPools = _stakingPools;
        emit StakingPoolChanged(oldStakingPools, stakingPools);
    }

    /**
     * @notice Allows the contract owner to set the address of the DOB staking pool.
     * @dev Sets the DOB staking pool address. Must be called by the contract owner.
     * @param _DOBstaking The address of the new DOB staking pool.
     */
    function setDOBStakingPool(address _DOBstaking) external onlyOwner {
        require(_DOBstaking != address(0), "OptionFactory: zero address");
        address oldDOBStaking = DOBStakingPool;
        DOBStakingPool = _DOBstaking;
        emit DOBStakingChanged(oldDOBStaking, DOBStakingPool);
    }

    /**
     * @notice Allows the contract owner to manage the list of authorized operators.
     * @dev Adds or removes an operator from the whitelist. Must be called by the contract owner.
     * @param _operator The address of the operator.
     * @param _isWhitelisted A boolean indicating whether the operator is whitelisted.
     */
    function setWhitelist(address _operator, bool _isWhitelisted) public onlyOwner {
        require(_operator != address(0), "Market: Zero address");
        operatorWhitelist[_operator] = _isWhitelisted;
        emit WhitelistChanged(_operator, _isWhitelisted);
    }

    /**
     * @notice Allows the contract owner to set the address of the distributions contract.
     * @dev Sets the distributions address. Must be called by the contract owner.
     * @param _distributions The address of the new distributions contract.
     */
    function setDistributions(address _distributions) external onlyOwner {
        require(_distributions != address(0), "OptionFactory: zero address");
        address oldistributions = distributions;
        distributions = _distributions;
        emit DistribuionsChanged(oldistributions, _distributions);
    }

    /**
     * @notice Allows the contract owner to set the staking reward per block.
     * @dev Sets the reward per block for staking. Must be called by the contract owner.
     * @param _reward The new staking reward per block.
     */
    function setStakingRewardPerBlock(uint256 _reward) external onlyOwner {
        uint256 oldReward = stakingRewardPerBlock;
        stakingRewardPerBlock = _reward;
        emit StakingRewardPerBlockChanged(oldReward, stakingRewardPerBlock);
    }

    /**
     * @notice Allows the contract owner to set the address of the contract generator.
     * @dev Sets the contract generator address. Must be called by the contract owner.
     * @param _ContractGenerator The address of the new contract generator.
     */
    function setContractGenerator(address _ContractGenerator) external onlyOwner {
        require(_ContractGenerator != address(0), "OptionFactory: zero address");
        ContractGenerator = _ContractGenerator;
    }

    /**
     * @notice Allows the contract owner to set the address of the fund.
     * @dev Sets the fund address. Must be called by the contract owner.
     * @param _fund The address of the new fund.
     */
    function setFund(address _fund) external onlyOwner {
        require(_fund != address(0), "OptionFactory: zero address");
        fund = _fund;
    }

    /**
     * @notice Fetches the last option id created
     * @dev Returns the last option id. Does not require ownership or specific permissions to call.
     * @return lastOptionId The ID of the last created option.
     */
    function getLastOptionId() external view override returns (uint256) {
        return lastOptionId;
    }

    /**
     * @notice Fetches the contract address of a particular option by ID
     * @dev Returns the address of the specified option. Does not require ownership or specific permissions to call.
     * @param _optionID The ID of the option.
     * @return address The address of the option.
     */
    function getOptionByID(uint256 _optionID) external view override returns (address) {
        return allOptions[_optionID];
    }

    /**
     * @notice Fetches the address of the staking pools.
     * @dev Returns the address of the staking pools. Does not require ownership or specific permissions to call.
     * @return stakingPools The address of the staking pools.
     */
    function getStakingPools() external view override returns (address) {
        return stakingPools;
    }

    /**
     * @notice Creates a new option contract with specified parameters. Returns the ID of the newly created option.
     * @dev Must be called by an operator from the whitelist. Initializes the option contract, creates tokens,
     *      sets up option details, and creates a pool in the staking contract. Also adds the option to DOBStakingPool.
     * @param _strikePrice The strike price of the new option.
     * @param _startTimestamp The start timestamp of the new option.
     * @param _exerciseTimestamp The exercise timestamp of the new option.
     * @param _optionType The type of the new option (0 for call, 1 for put).
     * @return optionID The ID of the newly created option.
     */
    function createOption(
        uint256 _strikePrice,
        uint256 _startTimestamp,
        uint256 _exerciseTimestamp,
        uint8 _optionType
    ) external override onlyWhitelist(msg.sender) returns (uint256 optionID) {
        require(_strikePrice > 0, "OptionFactory: zero strike price");
        require(_startTimestamp > block.timestamp, "OptionFactory: Illegal start time");
        require(_exerciseTimestamp > _startTimestamp, "OptionFactory: Illegal exercise time");
        require(_optionType <= 1, "OptionFactory: Illegal type");

        address option;
        address bullet;
        address sniper;

        optionID = ++lastOptionId;

        option = IContractGenerator(ContractGenerator).createOptionContract(
            _strikePrice,
            _exerciseTimestamp,
            _optionType,
            address(this)
        );
        IOption(option).initialize(_strikePrice, _exerciseTimestamp, _optionType);
        (bullet, sniper) = IContractGenerator(ContractGenerator).createToken(optionID, option);
        cloneBullet = bullet;
        cloneSniper = sniper;
        cloneOptionId = optionID;
        allOptions[optionID] = option;

        {
            uint256 startTimestamp = _startTimestamp;
            uint256 startBlock = startTimestamp.sub(block.timestamp).div(uint256(blockTime)).add(block.number);
            IOption(option).setup(optionID, startBlock, uHODL, bHODL, fund, bullet, sniper);

            uint256 exerciseTimestamp = _exerciseTimestamp;
            uint256 endBlock = exerciseTimestamp.sub(block.timestamp).div(uint256(blockTime)).add(block.number);
            IStakingPools(stakingPools).createPool(sniper, option, startBlock, endBlock, stakingRewardPerBlock);
        }
        {
            IDOBStakingPool(DOBStakingPool).addOption(option, bullet, sniper);
        }
        {
            uint256 strikePrice = _strikePrice;
            uint256 startTimestamp = _startTimestamp;
            uint256 exerciseTimestamp = _exerciseTimestamp;
            uint8 optionTpye = _optionType;
            emit OptionCreated(optionID, option, bullet, sniper, strikePrice, startTimestamp, exerciseTimestamp, optionTpye);
        }
    }

    /**
     * @notice Clones an existing option a certain number of times.
     * @dev Clones an existing option and creates tokens for the clones. Must be called by an operator from the whitelist.
     * @param _num The number of clones to create.
     */
    function cloneOption(uint8 _num) external onlyWhitelist(msg.sender) {
        require(_num <= 24, "OptionFactory: number must less than 24");
        address bullet;
        address sniper;
        address clone_option = allOptions[cloneOptionId];
        for (uint8 i = 0; i < _num; i++) {
            address option = IContractGenerator(ContractGenerator).cloneOptionPool(clone_option, address(this));
            (bullet, sniper) = IContractGenerator(ContractGenerator).cloneToken(option, cloneBullet, cloneSniper);

            blankOptions.push(BlankOption({option: option, bullet: bullet, sniper: sniper}));
        }
        blankOptionCount = blankOptions.length;
    }

    /**
     * @notice Activates a set of options with specified parameters.
     * @dev Activates options by initializing them, setting them up, and adding them to DOBStakingPool.
     *      Also creates a pool in the staking contract for each option. Must be called by an operator from the whitelist.
     * @param _strikePrices The strike prices of the options to be activated.
     * @param _startTimestamps The start timestamps of the options to be activated.
     * @param _exerciseTimestamps The exercise timestamps of the options to be activated.
     * @param _optionTypes The types of the options to be activated.
     */
    function activateOption(
        uint256[] memory _strikePrices,
        uint256[] memory _startTimestamps,
        uint256[] memory _exerciseTimestamps,
        uint8[] memory _optionTypes
    ) external onlyWhitelist(msg.sender) {
        require(_strikePrices.length == _startTimestamps.length, "OptionFactory: List length not equal");
        require(_startTimestamps.length == _exerciseTimestamps.length, "OptionFactory: List length not equal");
        require(_exerciseTimestamps.length == _optionTypes.length, "OptionFactory: List Length not equal");
        require(_strikePrices.length <= blankOptions.length, "OptionFactory: Insufficient blank Option");

        uint256 arrayLength = _strikePrices.length;
        uint256 optionID;
        uint256 blankOptionsLen = blankOptions.length;

        for (uint8 i = 0; i < arrayLength; i++) {
            uint256 strikePrice = _strikePrices[i];
            uint256 startTimestamp = _startTimestamps[i];
            uint256 exerciseTimestamp = _exerciseTimestamps[i];
            uint8 optionType = _optionTypes[i];

            require(strikePrice > 0, "OptionFactory: zero strike price");
            require(startTimestamp > block.timestamp, "OptionFactory: Illegal start time");
            require(exerciseTimestamp > startTimestamp, "OptionFactory: Illegal exercise time");
            require(optionType <= 1, "OptionFactory: Illegal type");

            BlankOption memory blankOption = blankOptions[blankOptionsLen - i - 1];
            optionID = ++lastOptionId;
            address option = blankOption.option;
            address bullet = blankOption.bullet;
            address sniper = blankOption.sniper;
            IOption(option).initialize(strikePrice, exerciseTimestamp, optionType);

            allOptions[optionID] = option;

            {
                uint256 startBlock = startTimestamp.sub(block.timestamp).div(uint256(blockTime)).add(block.number);
                IOption(option).setup(optionID, startBlock, uHODL, bHODL, fund, bullet, sniper);

                uint256 endBlock = exerciseTimestamp.sub(block.timestamp).div(uint256(blockTime)).add(block.number);
                IStakingPools(stakingPools).createPool(sniper, option, startBlock, endBlock, stakingRewardPerBlock);
            }
            {
                IDOBStakingPool(DOBStakingPool).addOption(option, bullet, sniper);
            }
            {
                emit OptionCreated(
                    optionID,
                    option,
                    bullet,
                    sniper,
                    strikePrice,
                    startTimestamp,
                    exerciseTimestamp,
                    optionType
                );
            }
        }
        for (uint8 i = 0; i < arrayLength; i++) {
            blankOptions.pop();
        }
        blankOptionCount = blankOptions.length;
    }

    /**
     * @notice Updates the strike prices of the specified options.
     * @dev Must be called by an operator from the whitelist.
     * @param _optionIds The IDs of the options to be updated.
     * @param _strikePrices The new strike prices.
     */
    function updateOptionStrike(uint256[] memory _optionIds, uint256[] memory _strikePrices)
        external
        onlyWhitelist(msg.sender)
    {
        require(_optionIds.length == _strikePrices.length, "OptionFactory:List length not equal");
        uint256 arrayLength = _strikePrices.length;
        for (uint8 i = 0; i < arrayLength; i++) {
            uint256 optionId = _optionIds[i];
            uint256 strikePirce = _strikePrices[i];
            address option = allOptions[optionId];
            IOption(option).updateStrike(strikePirce);
        }
    }

    /**
     * @notice Sets the exercise fee ratio for a specific option.
     * @dev The new fee ratio must be in the range [0, 100].maximum ratio is 10%
     * @param optionId The ID of the option.
     * @param _feeRatio The new exercise fee ratio.
     */
    function setOptionExerciseFeeRatio(uint256 optionId, uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio <= 100, "OptionFactory: Illegal value range");
        address option = allOptions[optionId];
        IOption(option).setOptionExerciseFeeRatio(_feeRatio);
    }

    /**
     * @notice Sets the withdraw fee ratio for a specific option.
     * @dev The new fee ratio must be in the range [0, 100].maximum ratio is 10%
     * @param optionId The ID of the option.
     * @param _feeRatio The new withdraw fee ratio.
     */
    function setOptionWithdrawFeeRatio(uint256 optionId, uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio <= 100, "OptionFactory: Illegal value range");
        address option = allOptions[optionId];
        IOption(option).setOptionWithdrawFeeRatio(_feeRatio);
    }

    /**
     * @notice Sets the redeem fee ratio for a specific option.
     * @dev The new fee ratio must be in the range [0, 100].maximum ratio is 10%
     * @param optionId The ID of the option.
     * @param _feeRatio The new redeem fee ratio.
     */
    function setOptionRedeemFeeRatio(uint256 optionId, uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio <= 100, "OptionFactory: Illegal value range");
        address option = allOptions[optionId];
        IOption(option).setOptionRedeemFeeRatio(_feeRatio);
    }

    /**
     * @notice Sets the bullet to reward ratio for a specific option.
     * @dev The new ratio must be in the range [0, 80].
     * @param optionId The ID of the option.
     * @param _feeRatio The new bullet to reward ratio.
     */
    function setOptionBulletToRewardRatio(uint256 optionId, uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio <= 80, "OptionFactory: Illegal value range");
        address option = allOptions[optionId];
        IOption(option).setOptionBulletToRewardRatio(_feeRatio);
    }

    /**
     * @notice Sets the entry fee ratio for a specific option.
     * @dev The new fee ratio must be in the range [0, 100].maximum ratio is 10%
     * @param optionId The ID of the option.
     * @param _feeRatio The new entry fee ratio.
     */
    function setOptionEntryFeeRatio(uint256 optionId, uint16 _feeRatio) external onlyOwner {
        require(0 <= _feeRatio && _feeRatio <= 100, "OptionFactory: Illegal value range");
        address option = allOptions[optionId];
        IOption(option).setOptionEntryFeeRatio(_feeRatio);
    }

    /**
     * @notice Extends the end block of the staking pool for a specific option.
     * @param optionId The ID of the option.
     * @param newEndBlock The new end block for the staking pool.
     */
    function extendStakingPoolEndBlock(uint256 optionId, uint256 newEndBlock) public onlyOwner {
        IStakingPools(stakingPools).extendEndBlock(optionId, newEndBlock);
    }

    /**
     * @notice Sets all ratios for a specific option.
     * @dev All ratios must be in their respective legal value ranges.
     * @param optionId The ID of the option.
     * @param _entryFeeRatio The new entry fee ratio.
     * @param _exerciseFeeRatio The new exercise fee ratio.
     * @param _withdrawFeeRatio The new withdraw fee ratio.
     * @param _redeemFeeRatio The new redeem fee ratio.
     * @param _bulletToRewardRatio The new bullet to reward ratio.
     */
    function setOptionAllRatio(
        uint256 optionId,
        uint16 _entryFeeRatio,
        uint16 _exerciseFeeRatio,
        uint16 _withdrawFeeRatio,
        uint16 _redeemFeeRatio,
        uint16 _bulletToRewardRatio
    ) external onlyOwner {
        require(0 <= _entryFeeRatio && _entryFeeRatio <= 100, "Option: entryFeeRatio Illegal value range");
        require(0 <= _exerciseFeeRatio && _exerciseFeeRatio <= 100, "Option: exerciseFeeRatio Illegal value range");
        require(0 <= _withdrawFeeRatio && _withdrawFeeRatio <= 100, "Option: withdrawFeeRatio Illegal value range");
        require(0 <= _redeemFeeRatio && _redeemFeeRatio <= 100, "Option: redeemFeeRatio Illegal value range");
        require(0 <= _bulletToRewardRatio && _bulletToRewardRatio <= 80, "Option: bulletToRewardRatio Illegal value range");
        address option = allOptions[optionId];
        IOption(option).setAllRatio(
            _entryFeeRatio,
            _exerciseFeeRatio,
            _withdrawFeeRatio,
            _redeemFeeRatio,
            _bulletToRewardRatio
        );
    }

    /**
     * @notice Updates the fund address for a list of options.
     * @dev The fund address must not be the zero address.
     * @param optionIds The ID of the option.
     * @param _fund The new fund address.
     */
    function updateOptionFund(uint256[] memory optionIds, address _fund) external onlyOwner {
        require(_fund != address(0), "OptionFactory: zero address");
        for (uint256 i = 0; i < optionIds.length; i++) {
            address option = allOptions[optionIds[i]];
            IOption(option).setFund(_fund);
        }
    }

    /**
     * @notice Removes an activated option from the DOBStakingPool.
     * @dev The option address must not be the zero address.
     * @param _optionAddress The address of the option to remove.
     */
    function removeActivatedOptions(address _optionAddress) external onlyOwner {
        require(_optionAddress != address(0), "OptionFactory: zero address");
        IDOBStakingPool(DOBStakingPool).removeOption(_optionAddress);
    }

    /**
     * @notice Removes all options from the blankOptions array.
     * @dev Iterates through the blankOptions array and removes each element.
     */
    function emptyBlankOptions() external onlyOwner {
        uint256 blankOptionsLen = blankOptions.length;
        for (uint8 i = 0; i < blankOptionsLen; i++) {
            blankOptions.pop();
        }
        blankOptionCount = 0;
    }
}