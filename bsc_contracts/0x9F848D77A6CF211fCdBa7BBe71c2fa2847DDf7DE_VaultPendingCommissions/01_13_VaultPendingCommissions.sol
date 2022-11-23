// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IGymVault.sol";
import "./PendingCommissions.sol";

contract VaultPendingCommissions is PendingCommissions, OwnableUpgradeable {
    address public bankAddress;

    mapping(address => bool) private whitelist;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Whitelisted(address indexed wallet, bool whitelist);
    event AddNewPool(uint256 allocPoint);
    event SetGymMLMAddress(address indexed _address);
    event SetGymMLMQualificationsAddress(address indexed _address);
    event SetGymVaultsBankAddress(address indexed _address);

    event SetStartBlock(uint256 startBlock);
    event SetPoolAllocationPoint(uint256 indexed _pid, uint256 _allocPoint);
    event ResetStrategy(uint256 indexed _pid, address indexed _strategy);

    function initialize(
        uint256 _startBlock,
        uint256 _rewardPerBlock,
        uint256 _rewardUpdateBlocksInterval,
        address _mlmAddress,
        address _rewardToken,
        address _mlmQualificationsAddress,
        address _bankAddress
    ) external initializer {
        bankAddress = _bankAddress;

        __Ownable_init();
        __PendingCommissions_init(
            _startBlock,
            _rewardPerBlock,
            _rewardUpdateBlocksInterval,
            _mlmAddress,
            _rewardToken,
            _mlmQualificationsAddress
        );

        emit Initialized(msg.sender, block.number);
    }

    modifier onlyWhitelisted() {
        require(
            whitelist[msg.sender] || msg.sender == owner(),
            "GymVaultBank: not whitelisted or owner"
        );
        _;
    }

    modifier onlyWithInvestment(address _user) override {
        require(
            IGymVault(bankAddress).getUserDepositDollarValue(_user) > 0,
            "VaultPendingCommissions:: Only with investment"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function setRewardConfiguration(
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _rewardUpdateBlocksInterval
    ) external onlyOwner {
        massUpdatePools();

        rewardToken = _rewardToken;

        _setRewardConfiguration(_rewardPerBlock, _rewardUpdateBlocksInterval);
    }

    function setStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;

        emit SetStartBlock(_startBlock);
    }

    function setMLMAddress(address _address) external onlyOwner {
        mlmAddress = _address;

        emit SetGymMLMAddress(_address);
    }

    function setBankAddress(address _address) external onlyOwner {
        bankAddress = _address;

        emit SetGymVaultsBankAddress(_address);
    }

    function setMLMQualificationsAddress(address _address) external onlyOwner {
        mlmQualificationsAddress = _address;

        emit SetGymMLMQualificationsAddress(_address);
    }

    function setUpdateLastRewardBlock(
        uint256 _pid,
        uint256 _lastRewardBlock,
        uint256 _accRewardPerShare
    ) external onlyOwner {
        poolInfo[_pid].lastRewardBlock = _lastRewardBlock;
        poolInfo[_pid].accRewardPerShare = _accRewardPerShare;
    }

    /**
     * @notice Add or remove wallet to/from whitelist, callable only by contract owner
     *         whitelisted wallet will be able to call functions
     *         marked with onlyWhitelisted modifier
     * @param _wallet wallet to whitelist
     * @param _whitelist boolean flag, add or remove to/from whitelist
     */
    function whitelistWallet(address _wallet, bool _whitelist) external onlyOwner {
        whitelist[_wallet] = _whitelist;

        emit Whitelisted(_wallet, _whitelist);
    }

    /**
     * @notice Update the given pool's reward allocation point. Can only be called by the owner
     * @param _pid: Pool id that will be updated
     * @param _allocPoint: New allocPoint for pool
     */
    function setPoolAllocationPoint(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;

        emit SetPoolAllocationPoint(_pid, _allocPoint);
    }

    /**
     * @notice Function to Add pool
     * @param _allocPoint: AllocPoint for new pool
     */
    function addPool(uint256 _allocPoint) external onlyOwner {
        massUpdatePools();

        _updateRewardPerBlock();

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                sharesTotal: 0,
                totalClaims: 0
            })
        );

        emit AddNewPool(_allocPoint);
    }
}