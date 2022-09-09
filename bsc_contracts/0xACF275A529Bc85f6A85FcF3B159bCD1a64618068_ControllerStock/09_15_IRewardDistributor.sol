//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRewardDistributor {
    function _setRewardToken(address newRewardToken) external;

    /// @notice Emitted reward token address is changed by admin
    event NewRewardToken(address oldRewardToken, address newRewardToken);

    function _addRecipient(address _iToken, uint256 _distributionFactor)
        external;

    event NewRecipient(address iToken, uint256 distributionFactor);

    /// @notice Emitted when mint is paused/unpaused by admin
    event Paused(bool paused);

    function _pause() external;

    function _unpause(uint256 _borrowSpeed, uint256 _supplySpeed) external;

    /// @notice Emitted when Global Distribution speed for both supply and borrow are updated
    event GlobalDistributionSpeedsUpdated(
        uint256 borrowSpeed,
        uint256 supplySpeed
    );

    function _setGlobalDistributionSpeeds(
        uint256 borrowSpeed,
        uint256 supplySpeed
    ) external;

    /// @notice Emitted when iToken's Distribution speed is updated
    event DistributionSpeedsUpdated(
        address iToken,
        uint256 borrowSpeed,
        uint256 supplySpeed
    );

    function updateDistributionSpeed() external;

    /// @notice Emitted when iToken's Distribution factor is changed by admin
    event NewDistributionFactor(
        address iToken,
        uint256 oldDistributionFactorMantissa,
        uint256 newDistributionFactorMantissa
    );

    function _setDistributionFactors(
        address[] calldata iToken,
        uint256[] calldata distributionFactors
    ) external;

    function updateDistributionState(address _iToken, bool _isBorrow) external;

    function updateReward(
        address _iToken,
        address _account,
        bool _isBorrow
    ) external;

    function updateRewardBatch(
        address[] memory _holders,
        address[] memory _iTokens
    ) external;

    function claimReward(address[] memory _holders, address[] memory _iTokens)
        external;

    function claimAllReward(address[] memory _holders) external;

    /// @notice Emitted when reward of amount is distributed into account
    event RewardDistributed(
        address iToken,
        address account,
        uint256 amount,
        uint256 accountIndex
    );
}