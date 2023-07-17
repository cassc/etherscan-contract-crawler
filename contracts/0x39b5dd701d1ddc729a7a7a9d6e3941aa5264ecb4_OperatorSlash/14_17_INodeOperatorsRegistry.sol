// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

/**
 * @title Node Operator registry
 *
 * Registration and management of Node Operator
 */
interface INodeOperatorsRegistry {
    /**
     * @notice Add node operator named `name` with reward address `rewardAddress` and _owner
     * @param _name Human-readable name
     * @param _controllerAddress Ethereum 1 address for the operator's management authority
     * @param _owner operator owner address
     * @param _rewardAddresses reward addresses
     * @param _ratios reward ratios
     * @return id a unique key of the added operator
     */
    function registerOperator(
        string calldata _name,
        address _controllerAddress,
        address _owner,
        address[] calldata _rewardAddresses,
        uint256[] calldata _ratios
    ) external payable returns (uint256 id);

    /**
     * @notice Set an operator as trusted
     * @param _id operator id
     */
    function setTrustedOperator(uint256 _id) external;

    /**
     * @notice Remove an operator as trusted
     * @param _id operator id
     */
    function removeTrustedOperator(uint256 _id) external;

    /**
     * @notice Get information about an operator
     * @param _id operator id
     * @param _fullInfo Get all information
     */
    function getNodeOperator(uint256 _id, bool _fullInfo)
        external
        view
        returns (
            bool trusted,
            string memory name,
            address owner,
            address controllerAddress,
            address vaultContractAddress
        );

    /**
     * @notice Returns total number of node operators
     */
    function getNodeOperatorsCount() external view returns (uint256);

    /**
     * @notice Get information about an operator vault contract address
     * @param _id operator id
     */
    function getNodeOperatorVaultContract(uint256 _id) external view returns (address vaultContractAddress);

    /**
     * @notice Get operator rewardSetting
     * @param operatorId operator id
     */
    function getNodeOperatorRewardSetting(uint256 operatorId)
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
     * @notice Returns whether an operator is trusted
     * @param _id operator id
     */
    function isTrustedOperator(uint256 _id) external view returns (bool);

    /**
     * @notice Returns whether an operator is trusted
     * @param _controllerAddress controller address
     */
    function isTrustedOperatorOfControllerAddress(address _controllerAddress) external view returns (uint256);

    /**
     * @notice operator pledge balance
     * @param _operatorId operator id
     */
    function getPledgeInfoOfOperator(uint256 _operatorId) external view returns (uint256, uint256);

    /**
     * @notice get operator comission rate
     * @param _operatorIds operator id
     */
    function getOperatorCommissionRate(uint256[] memory _operatorIds) external view returns (uint256[] memory);

    /**
     * @notice When a validator run by an operator goes seriously offline, it will be slashed
     * @param _slashType slashType
     * @param _slashIds tokenId or stakingId
     * @param _operatorIds operator id
     * @param _amounts slash amount
     */
    function slash(
        uint256 _slashType,
        uint256[] memory _slashIds,
        uint256[] memory _operatorIds,
        uint256[] memory _amounts
    ) external;

    /**
     * @notice deposit pledge fund for operator
     * @param _operatorId operator Id
     */
    function deposit(uint256 _operatorId) external payable;

    /**
     * @notice Returns whether an operator is Blacklist
     * @param _operatorId operator id
     */
    function isBlacklistOperator(uint256 _operatorId) external view returns (bool);

    /**
     * @notice Returns whether an operator is quit
     * @param _id operator id
     */
    function isQuitOperator(uint256 _id) external view returns (bool);

    /**
     * @notice Determine whether the operator meets the pledge requirements
     * @param _operatorId operator id
     */
    function isConformBasicPledge(uint256 _operatorId) external view returns (bool);

    event NodeOperatorRegistered(
        uint256 _id,
        string _name,
        address _controllerAddress,
        address _vaultContractAddress,
        address[] _rewardAddresses,
        uint256[] _ratios
    );
    event OperatorWithdraw(uint256 _operatorId, uint256 _withdrawAmount, address _to);
    event OperatorQuit(uint256 _operatorId, uint256 _nowVault, address _to);
    event NodeOperatorTrustedSet(uint256 _id, string _name, bool _trusted);
    event NodeOperatorTrustedRemove(uint256 _id, string _name, bool _trusted);
    event NodeOperatorBlacklistSet(uint256 _id);
    event NodeOperatorBlacklistRemove(uint256 _id);
    event NodeOperatorNameSet(uint256 _id, string _name);
    event NodeOperatorRewardAddressSet(uint256 _id, address[] _rewardAddresses, uint256[] _ratios);
    event NodeOperatorControllerAddressSet(uint256 _id, string _name, address _controllerAddress);
    event NodeOperatorOwnerAddressSet(uint256 _id, string _name, address _ownerAddress);
    event Transferred(address _to, uint256 _amount);
    event Slashed(uint256 _operatorId, uint256 _amount);
    event PledgeDeposited(uint256 _amount, uint256 _operatorId);
    event Withdraw(uint256 _amount, uint256 _operatorId, address _to);
    event LiquidStakingChanged(address _from, address _to);
    event DaoAddressChanged(address _oldDao, address _dao);
    event DaoVaultAddressChanged(address _oldDaoVaultAddress, address _daoVaultAddress);
    event RegistrationFeeChanged(uint256 _oldFee, uint256 _fee);
    event PermissionlessBlockNumberSet(uint256 _blockNumber);
    event OperatorClaimRewards(uint256 _operatorId, uint256 _rewards);
    event DaoClaimRewards(uint256 _operatorId, uint256 _rewards);
    event CommissionRateChanged(uint256 _oldRate, uint256 _rate);
    event OperatorArrearsReduce(uint256 _operatorId, uint256 value);
    event OperatorArrearsIncrease(uint256 _operatorId, uint256 value);
    event VaultFactorContractSet(address _vaultFactoryContract, address _vaultFactoryContractAddress);
    event OperatorVaultContractReset(address _oldVaultContractAddress, address _vaultContractAddress);
    event OperatorSlashContractSet(address _oldOperatorSlashContract, address _operatorSlashContractAddress);
    event DefaultOperatorCommissionRateChanged(
        uint256 _oldDefaultOperatorCommission, uint256 _defaultOperatorCommission
    );
    event LargeStakingChanged(address _oldLargeStakingContractAddress, address _largeStakingContractAddress);
}