// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

/**
 * @title Interface for OperatorSlash
 * @notice OperatorSlash contract
 */
interface IOperatorSlash {
    /**
     * @notice Receive slash fund, Because the operator may have insufficient margin, _slashAmounts may be less than or equal to _requireAmounts
     * @param _exitTokenIds exit tokenIds
     * @param _slashAmounts slash amount
     * @param _requireAmounts require slas amount
     */
    function slashReceive(
        uint256[] memory _exitTokenIds,
        uint256[] memory _slashAmounts,
        uint256[] memory _requireAmounts
    ) external payable;

    function claimCompensated(uint256[] memory _tokenIds, address _owner) external returns (uint256);
    /**
     * @notice According to the report results of the oracle machine, the operator who has reduced nft will be punished
     * @param _exitTokenIds token id
     * @param _amounts slash amounts
     */
    function slashOperator(uint256[] memory _exitTokenIds, uint256[] memory _amounts) external;

    /**
     * @notice According to the report result of the oracle machine, punish the operator who fails to exit in time
     * @param _nftExitDelayedTokenIds exit delayed tokenIds
     * @param _largeExitDelayedRequestIds large exit delayed requestIds
     */
    function slashOfExitDelayed(uint256[] memory _nftExitDelayedTokenIds, uint256[] memory _largeExitDelayedRequestIds)
        external;

    /**
     * @notice The receiving function of the penalty, used for the automatic transfer after the operator recharges the margin
     * @param _operatorId operator Id
     * @param _amount slash amount
     */
    function slashArrearsReceive(uint256 _operatorId, uint256 _amount) external payable;

    event ArrearsReceiveOfSlash(uint256 _operatorId, uint256 _amount);
    event SlashReceive(uint256 _operatorId, uint256 tokenId, uint256 _slashAmount, uint256 _requirAmounts);
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
    event DaoAddressChanged(address oldDao, address _dao);
    event CompensatedClaimed(address _owner, uint256 _totalCompensated);
}