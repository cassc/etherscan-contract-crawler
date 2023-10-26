// contracts/IHighTableVaultETH.sol
// SPDX-License-Identifier: BUSL
// Teahouse Finance

pragma solidity ^0.8.0;

import "./IHighTableVault.sol";

error AssetNotWETH9();          // asset token is not WETH9
error IncorrectETHAmount();     // incorrect amount of ETH sent
error NotAcceptingETH();        // does not accept directly sent ETH

interface IHighTableVaultETH is IHighTableVault {

    // -----------------
    // auditor functions
    // -----------------    

    /// @notice Enter next cycle in ETH
    /// @param _cycleIndex current cycle index (to prevent accidental replay)
    /// @param _fundValue total fund value for this cycle
    /// @param _withdrawAmount amount to withdraw from TeaVaultV2
    /// @param _cycleStartTimestamp starting timestamp of the next cycle
    /// @param _fundingLockTimestamp funding lock timestamp for next cycle
    /// @param _closeFund true to close fund, irreversible
    /// @return platformFee total fee paid to the platform
    /// @return managerFee total fee paid to the manager
    /// @notice Only available to auditors
    /// @notice Use previewNextCycle function to get an estimation of required _withdrawAmount
    /// @notice _cycleStartTimestamp must be later than start timestamp of current cycle
    /// @notice and before the block timestamp when the transaction is confirmed
    /// @notice _fundValue can't be zero or close to zero except for the first first cycle
    function enterNextCycleETH(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint128 _withdrawAmount,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) external returns (uint256 platformFee, uint256 managerFee);

    /// @notice Deposit fund to TeaVaultV2 in ETH
    /// @notice Can not deposit locked assets
    /// @param _value value to deposit
    /// @notice Only available to auditors
    function depositToVaultETH(uint256 _value) external;

    /// @notice Withdraw fund from TeaVaultV2 in ETH
    /// @param _value value to withdraw
    /// @notice Only available to auditors
    function withdrawFromVaultETH(uint256 _value) external;

    // --------------------------
    // functions available to all
    // --------------------------

    /// @notice Request deposits in ETH
    /// @notice ETH sent with the transaction must be the same as _assets
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @notice _receiver need to have the required NFT
    /// @notice Request is disabled when later than fundingLockTimestamp
    function requestDepositETH(uint256 _assets, address _receiver) external payable;

    /// @notice Claim and request deposits in ETH
    /// @notice ETH sent with the transaction plus the claimed assets must be larger or equal to _assets
    /// @notice Any excess ETH will be sent back to the sender
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @return assets amount of owed asset tokens claimed
    /// @notice _receiver need to have the required NFT
    /// @notice Request is disabled when later than fundingLockTimestamp
    /// @notice msg.value + owed assets must be larger than _assets.
    /// @notice The remaining amount are sent back to the sender.
    function claimAndRequestDepositETH(uint256 _assets, address _receiver) external payable returns (uint256 assets);

    /// @notice Cancel deposit requests in ETH
    /// @param _assets amount of asset tokens to cancel deposit
    /// @param _receiver address to receive the asset tokens
    /// @notice Request is disabled when later than fundingLockTimestamp
    function cancelDepositETH(uint256 _assets, address payable _receiver) external;

    /// @notice Claim owed assets in ETH
    /// @param _receiver address to receive the tokens
    /// @return assets amount of owed asset tokens claimed
    function claimOwedAssetsETH(address payable _receiver) external returns (uint256 assets);

    /// @notice Claim owed assets and shares (assets in ETH)
    /// @param _receiver address to receive the tokens
    /// @return assets amount of owed asset tokens claimed
    /// @return shares amount of owed share tokens claimed
    function claimOwedFundsETH(address payable _receiver) external returns (uint256 assets, uint256 shares);

    /// @notice Close positions and claim all assets in ETH
    /// @notice Only available when fund is closed
    /// @param _receiver address to receive ETH
    /// @return assets amount of assets returned    
    function closePositionAndClaimETH(address payable _receiver) external returns (uint256 assets);
}