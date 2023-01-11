// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

interface IVault {
    /// @dev Emitted when a new epoch is started
    /// @param newEpoch number of the new epoch
    /// @param initiator address of the user who initiated the new epoch
    /// @param startTime timestamp of the start of this new epoch
    event NextEpochStarted(uint256 indexed newEpoch, address indexed initiator, uint256 startTime);

    /// @dev Emitted upon a new deposit request
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    /// @param user address of the user who made the deposit request
    /// @param amount amount of the asset in deposit request
    /// @param epoch epoch of the deposit request
    event DepositScheduled(bytes32 indexed assetCode, address indexed user, uint256 amount, uint256 indexed epoch);

    /// @dev Emitted upon a new withdraw request
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    /// @param user address of the user who made the withdraw request
    /// @param amountDay0 amount of the asset (day 0) in withdraw request
    /// @param epoch epoch of the withdraw request
    event WithdrawScheduled(bytes32 indexed assetCode, address indexed user, uint256 amountDay0, uint256 indexed epoch);

    /// @dev Emitted upon a user claiming their tokens after a withdraw request is processed
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    /// @param user address of the user who is claiming their assets
    /// @param amount amount of the assets (day 0) claimed
    event AssetsClaimed(bytes32 indexed assetCode, address indexed user, uint256 amount);

    /// @dev Emitted upon a guardian rescuing funds
    /// @param guardian address of the guardian who rescued the funds
    event FundsRescued(address indexed guardian);

    /// @dev Emitted upon a strategist updating the token0 floor
    /// @param newFloor the new floor returns on TOKEN0 (out of `RAY`)
    event Token0FloorUpdated(uint256 newFloor);

    /// @dev Emitted upon a strategist updating the token1 floor
    /// @param newFloor the new floor returns on TOKEN1 (out of `RAY`)
    event Token1FloorUpdated(uint256 newFloor);

    event EpochDurationUpdated(uint256 newEpochDuration);

    /// ------------------- Vault Interface -------------------

    function depositToken0(uint256 _amount) external payable;

    function depositToken1(uint256 _amount) external;

    function withdrawToken0(uint256 _amount) external;

    function withdrawToken1(uint256 _amount) external;

    function claimToken0() external;

    function claimToken1() external;

    function token0Balance(address user)
        external
        view
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        );

    function token1Balance(address user)
        external
        view
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        );

    function nextEpoch(uint256 expectedPoolToken0, uint256 expectedPoolToken1) external;

    function rescueTokens(address[] calldata tokens, uint256[] calldata amounts) external;

    function collectFees() external;

    function unstakeLiquidity() external;

    /// ------------------- Getters -------------------

    function token0ValueLocked() external view returns (uint256);

    function token1ValueLocked() external view returns (uint256);

    function token0BalanceDay0(address user) external view returns (uint256);

    function epochToToken0Rate(uint256 _epoch) external view returns (uint256);

    function token0WithdrawRequests(address user) external view returns (uint256);

    function token1BalanceDay0(address user) external view returns (uint256);

    function epochToToken1Rate(uint256 _epoch) external view returns (uint256);

    function token1WithdrawRequests(address user) external view returns (uint256);

    function feesAccrued() external view returns (uint256, uint256);

    /// ------------------- Setters -------------------

    function setToken0Floor(uint256 _token0FloorNum) external;

    function setToken1Floor(uint256 _token1FloorNum) external;

    function setEpochDuration(uint256 _epochDuration) external;

    function setDepositsEnabled() external;
    
    function setDepositsDisabled() external;
}