//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

contract Events {
    /// @notice Emitted when rebalancer is added or removed.
    event LogUpdateRebalancer(
        address indexed rebalancer,
        bool indexed isRebalancer
    );

    /// @notice Emitted when vault's functionality is paused or resumed.
    event LogChangeStatus(uint8 indexed status);

    /// @notice Emitted when the revenue or withdrawal fee is updated.
    event LogUpdateFees(
        uint256 indexed revenueFeePercentage,
        uint256 indexed withdrawalFeePercentage,
        uint256 indexed withdrawFeeAbsoluteMin
    );

    /// @notice Emitted when the protocol's risk ratio is updated.
    event LogUpdateMaxRiskRatio(uint8 indexed protocolId, uint256 newRiskRatio);

    /// @notice Emitted whenever the address collecting the revenue is updated.
    event LogUpdateTreasury(
        address indexed oldTreasury,
        address indexed newTreasury
    );

    /// @notice Emitted when secondary auth is updated.
    event LogUpdateSecondaryAuth(
        address indexed oldSecondaryAuth,
        address indexed secondaryAuth
    );

    /// @notice Emitted when max vault ratio is updated.
    event LogUpdateAggrMaxVaultRatio(
        uint256 indexed oldAggrMaxVaultRatio,
        uint256 indexed aggrMaxVaultRatio
    );

    /// @notice Emitted when max leverage wsteth per weth unit amount is updated.
    event LogUpdateLeverageMaxUnitAmountLimit(
        uint256 indexed oldLimit,
        uint256 indexed newLimit
    );
}