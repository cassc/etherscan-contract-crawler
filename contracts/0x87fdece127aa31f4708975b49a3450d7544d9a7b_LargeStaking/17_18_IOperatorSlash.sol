// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

/**
 * @title Interface for OperatorSlash
 * @notice OperatorSlash contract
 */
interface IOperatorSlash {
    /**
     * @notice Receive slash fund, Because the operator may have insufficient margin, _slashAmounts may be less than or equal to _requireAmounts
     * @param _slashType slashType
     * @param _slashIds exit tokenIds
     * @param _operatorIds operator
     * @param _slashAmounts slash amount
     * @param _requireAmounts require slas amount
     */
    function slashReceive(
        uint256 _slashType,
        uint256[] memory _slashIds,
        uint256[] memory _operatorIds,
        uint256[] memory _slashAmounts,
        uint256[] memory _requireAmounts
    ) external payable;

    function claimCompensated(uint256[] memory _tokenIds, address _owner) external returns (uint256);

    function claimCompensatedOfLargeStaking(uint256[] memory _stakingIds, address _owner) external returns (uint256);
    /**
     * @notice According to the report results of the oracle machine, the operator who has reduced nft will be punished
     * @param _exitTokenIds token id
     * @param _amounts slash amounts
     */
    function slashOperator(uint256[] memory _exitTokenIds, uint256[] memory _amounts) external;
    function slashOperatorOfLargeStaking(
        uint256[] memory _stakingIds,
        uint256[] memory _operatorIds,
        uint256[] memory _amounts
    ) external;

    /**
     * @notice The receiving function of the penalty, used for the automatic transfer after the operator recharges the margin
     * @param _operatorId operator Id
     * @param _amount slash amount
     */
    function slashArrearsReceive(uint256 _operatorId, uint256 _amount) external payable;

    event SlashArrearsReceive(uint256 _operatorId, uint256 _amount);
    event SlashArrearsReceiveOfNft(uint256 _operatorId, uint256 _tokenId, uint256 _amount);
    event SlashArrearsReceiveOfLargeStaking(uint256 _operatorId, uint256 stakingId, uint256 _amount);
    event SlashReceiveOfNft(uint256 _operatorId, uint256 tokenId, uint256 _slashAmount, uint256 _requirAmounts);
    event SlashReceiveOfLargeStaking(
        uint256 _operatorId, uint256 stakingId, uint256 _slashAmount, uint256 _requirAmounts
    );
    event SlashAmountPerBlockPerValidatorSet(
        uint256 _oldSlashAmountPerBlockPerValidator, uint256 _slashAmountPerBlockPerValidator
    );

    event NodeOperatorRegistryContractSet(
        address _oldNodeOperatorRegistryContract, address _nodeOperatorRegistryContract
    );
    event VaultManagerContractSet(address _oldVaultManagerContractAddress, address _vaultManagerContract);
    event WithdrawalRequestContractSet(
        address _oldWithdrawalRequestContract, address _withdrawalRequestContractAddress
    );
    event LiquidStakingChanged(address _oldLiquidStakingContract, address _liquidStakingContractAddress);
    event LargeStakingChanged(address _oldLargeStakingContractAddress, address _largeStakingContractAddress);
    event DaoAddressChanged(address oldDao, address _dao);
    event CompensatedClaimedOfNft(address _owner, uint256 _tokenId, uint256 _compensated);
    event CompensatedClaimedOfLargeStaking(address _owner, uint256 _stakingId, uint256 _compensated);
}