// contracts/IHighTableVault.sol
// SPDX-License-Identifier: BUSL
// Teahouse Finance

pragma solidity ^0.8.0;

import "./ITeaVaultV2.sol";

error OnlyAvailableToAdmins();              // operation is available only to admins
error OnlyAvailableToAuditors();            // operation is available only to auditors
error ReceiverDoNotHasNFT();                // receiver does not have required NFT to deposit
error IncorrectVaultAddress();              // TeaVaultV2, managerVault, or platformVault is 0
error IncorrectReceiverAddress();           // receiver address is 0
error NotEnoughAssets();                    // does not have enough asset tokens
error FundingLocked();                      // deposit and withdraw are not allowed in locked period
error ExceedDepositLimit();                 // requested deposit exceeds current deposit limit
error DepositDisabled();                    // deposit request is disabled
error WithdrawDisabled();                   // withdraw request is disabled
error NotEnoughDeposits();                  // user does not have enough deposit requested to cancel
error NotEnoughWithdrawals();               // user does not have enough withdrawals requested to cancel
error InvalidInitialPrice();                // invalid initial price
error FundIsClosed();                       // fund is closed, requests are not allowed
error FundIsNotClosed();                    // fund is not closed, can't close position
error InvalidFeePercentage();               // incorrect fee percentage
error IncorrectCycleIndex();                // incorrect cycle index
error IncorrectCycleStartTimestamp();       // incorrect cycle start timestamp (before previous cycle start timestamp or later than current time)
error InvalidFundValue();                   // incorrect fund value (zero or very close to zero)
error NoDeposits();                         // can not enter next cycle if there's no share and no requested deposits
error CancelDepositDisabled();              // canceling deposit is disabled
error CancelWithdrawDisabled();             // canceling withdraw is disabled

interface IHighTableVault {

    struct Price {
        uint128 numerator;              // numerator of the price
        uint128 denominator;            // denominator of the price
    }

    struct FeeConfig {
        address platformVault;          // platform fee goes here
        address managerVault;           // manager fee goes here
        uint24 platformEntryFee;        // platform entry fee in 0.0001% (collected when depositing)
        uint24 managerEntryFee;         // manager entry fee in 0.0001% (colleceted when depositing)
        uint24 platformExitFee;         // platform exit fee (collected when withdrawing)
        uint24 managerExitFee;          // manager exit fee (collected when withdrawing)
        uint24 platformPerformanceFee;  // platform performance fee (collected for each cycle, from profits)
        uint24 managerPerformanceFee;   // manager performance fee (collected for each cycle, from profits)
        uint24 platformManagementFee;   // platform yearly management fee (collected for each cycle, from total value)
        uint24 managerManagementFee;    // manager yearly management fee (collected for each cycle, from total value)
    }

    struct FundConfig {
        ITeaVaultV2 teaVaultV2;         // TeaVaultV2 address
        bool disableNFTChecks;          // allow everyone to access the vault
        bool disableDepositing;         // disable requesting depositing
        bool disableWithdrawing;        // disable requesting withdrawing
        bool disableCancelDepositing;   // disable canceling depositing
        bool disableCancelWithdrawing;  // disable canceling withdrawing
    }

    struct GlobalState {
        uint128 depositLimit;           // deposit limit (in asset)
        uint128 lockedAssets;           // locked assets (assets waiting to be withdrawn, or deposited by users but not converted to shares yet)

        uint32 cycleIndex;              // current cycle index
        uint64 cycleStartTimestamp;     // start timestamp of current cycle
        uint64 fundingLockTimestamp;    // timestamp for locking depositing/withdrawing
        bool fundClosed;                // fund is closed
    }

    struct CycleState {
        uint128 totalFundValue;         // total fund value in asset tokens, at the end of the cycle
        uint128 fundValueAfterRequests; // fund value after requests are processed in asset tokens, at the end of the cycle
        uint128 requestedDeposits;      // total requested deposits during this cycle (in assets)
        uint128 convertedDeposits;      // converted deposits at the end of the cycle (in shares)
        uint128 requestedWithdrawals;   // total requested withdrawals during this cycle (in shares)
        uint128 convertedWithdrawals;   // converted withdrawals at the end of the cycle (in assets)
    }

    struct UserState {
        uint128 requestedDeposits;      // deposits requested but not converted (in assets)
        uint128 owedShares;             // shares available to be withdrawn
        uint128 requestedWithdrawals;   // withdrawals requested but not converted (in shares)
        uint128 owedAssets;             // assets available to be withdrawn
        uint32 requestCycleIndex;       // cycle index for requests (for both deposits and withdrawals)
    }

    // ------
    // events
    // ------

    event FundInitialized(address indexed caller, uint256 priceNumerator, uint256 priceDenominator, uint64 startTimestamp, address admin);
    event NFTEnabled(address indexed caller, uint32 indexed cycleIndex, address[] nfts);
    event DisableNFTChecks(address indexed caller, uint32 indexed cycleIndex, bool disableChecks);
    event FeeConfigChanged(address indexed caller, uint32 indexed cycleIndex, FeeConfig feeConfig);
    event EnterNextCycle(address indexed caller, uint32 indexed cycleIndex, uint256 fundValue, uint256 priceNumerator, uint256 priceDenominator, uint256 depositLimit, uint64 startTimestamp, uint64 lockTimestamp, bool fundClosed, uint256 platformFee, uint256 managerFee);
    event FundLockingTimestampUpdated(address indexed caller, uint32 indexed cycleIndex, uint64 lockTimestamp);
    event DepositLimitUpdated(address indexed caller, uint32 indexed cycleIndex, uint256 depositLimit);
    event UpdateTeaVaultV2(address indexed caller, uint32 indexed cycleIndex, address teaVaultV2);
    event DepositToVault(address indexed caller, uint32 indexed cycleIndex, address teaVaultV2, uint256 value);
    event WithdrawFromVault(address indexed caller, uint32 indexed cycleIndex, address teaVaultV2, uint256 value);
    event FundingChanged(address indexed caller, uint32 indexed cycleIndex, bool disableDepositing, bool disableWithdrawing, bool disableCancelDepositing, bool disableCancelWithdrawing);
    event DepositRequested(address indexed caller, uint32 indexed cycleIndex, address indexed receiver, uint256 assets);
    event DepositCanceled(address indexed caller, uint32 indexed cycleIndex, address indexed receiver, uint256 assets);
    event WithdrawalRequested(address indexed caller, uint32 indexed cycleIndex, address indexed owner, uint256 shares);
    event WithdrawalCanceled(address indexed caller, uint32 indexed cycleIndex, address indexed receiver, uint256 shares);
    event ClaimOwedAssets(address indexed caller, address indexed receiver, uint256 assets);
    event ClaimOwedShares(address indexed caller, address indexed receiver, uint256 shares);
    event ConvertToShares(address indexed owner, uint32 indexed cycleIndex, uint256 assets, uint256 shares);
    event ConvertToAssets(address indexed owner, uint32 indexed cycleIndex, uint256 shares, uint256 assets);

    // ---------------
    // admin functions
    // ---------------

    /// @notice Set the list of NFTs for allowing depositing
    /// @param _nfts addresses of the NFTs
    /// @notice Only available to admins
    function setEnabledNFTs(address[] memory _nfts) external;

    /// @notice Disable/enable NFT checks
    /// @param _checks true to disable NFT checks, false to enable
    /// @notice Only available to admins
    function setDisableNFTChecks(bool _checks) external;

    /// @notice Set fee structure and platform/manager vault addresses
    /// @param _feeConfig fee structure settings
    /// @notice Only available to admins
    function setFeeConfig(FeeConfig calldata _feeConfig) external;

    /// @notice Set TeaVaultV2 address
    /// @param _teaVaultV2 address to TeaVaultV2
    /// @notice Only available to admins
    function setTeaVaultV2(address _teaVaultV2) external;

    // -----------------
    // auditor functions
    // -----------------

    /// @notice Enter next cycle
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
    function enterNextCycle(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint128 _withdrawAmount,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) external returns (uint256 platformFee, uint256 managerFee);
    
    /// @notice Update fund locking timestamp
    /// @param _fundLockingTimestamp new timestamp for locking withdraw/deposits
    /// @notice Only available to auditors    
    function setFundLockingTimestamp(uint64 _fundLockingTimestamp) external;

    /// @notice Update deposit limit
    /// @param _depositLimit new deposit limit
    /// @notice Only available to auditors
    function setDepositLimit(uint128 _depositLimit) external;

    /// @notice Allowing/disabling depositing/withdrawing
    /// @param _disableDepositing true to allow depositing, false to disallow
    /// @param _disableWithdrawing true to allow withdrawing, false to disallow
    /// @param _disableCancelDepositing true to allow withdrawing, false to disallow
    /// @param _disableCancelWithdrawing true to allow withdrawing, false to disallow
    /// @notice Only available to auditors    
    function setDisableFunding(bool _disableDepositing, bool _disableWithdrawing, bool _disableCancelDepositing, bool _disableCancelWithdrawing) external;

    /// @notice Deposit fund to TeaVaultV2
    /// @notice Can not deposit locked assets
    /// @param _value value to deposit
    /// @notice Only available to auditors
    function depositToVault(uint256 _value) external;

    /// @notice Withdraw fund from TeaVaultV2
    /// @param _value value to withdraw
    /// @notice Only available to auditors
    function withdrawFromVault(uint256 _value) external;

    // --------------------------
    // functions available to all
    // --------------------------

    /// @notice Returns address of the asset token
    /// @return assetTokenAddress address of the asset token
    function asset() external view returns (address assetTokenAddress);

    /// @notice Request deposits
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @notice _receiver need to have the required NFT
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function requestDeposit(uint256 _assets, address _receiver) external;

    /// @notice Claim owed assets and request deposits
    /// @notice Actual deposits will be executed when entering the next cycle
    /// @param _assets amount of asset tokens to deposit
    /// @param _receiver address where the deposit is credited
    /// @return assets amount of owed asset tokens claimed
    /// @notice _receiver need to have the required NFT
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function claimAndRequestDeposit(uint256 _assets, address _receiver) external returns (uint256 assets);

    /// @notice Cancel deposit requests
    /// @param _assets amount of asset tokens to cancel deposit
    /// @param _receiver address to receive the asset tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function cancelDeposit(uint256 _assets, address _receiver) external;

    /// @notice Request withdrawals
    /// @notice Actual withdrawals will be executed when entering the next cycle
    /// @param _shares amount of share tokens to withdraw
    /// @param _owner owner address of share tokens
    /// @notice If _owner is different from msg.sender, _owner must approve msg.sender to spend share tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function requestWithdraw(uint256 _shares, address _owner) external;

    /// @notice Claim owed shares and request withdrawals
    /// @notice Actual withdrawals will be executed when entering the next cycle
    /// @param _shares amount of share tokens to withdraw
    /// @param _owner owner address of share tokens
    /// @return shares amount of owed share tokens claimed
    /// @notice If _owner is different from msg.sender, _owner must approve msg.sender to spend share tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function claimAndRequestWithdraw(uint256 _shares, address _owner) external returns (uint256 shares);

    /// @notice Cancel withdrawal requests
    /// @param _shares amount of share tokens to cancel withdrawal
    /// @param _receiver address to receive the share tokens
    /// @notice Request is disabled when time is later than fundingLockTimestamp
    function cancelWithdraw(uint256 _shares, address _receiver) external;

    /// @notice Returns currently requested deposits and withdrawals
    /// @param _owner address of the owner
    /// @return assets amount of asset tokens requested to be deposited
    /// @return shares amount of asset tokens requested to be withdrawn    
    function requestedFunds(address _owner) external view returns (uint256 assets, uint256 shares);

    /// @notice Claim owed assets
    /// @param _receiver address to receive the tokens
    /// @return assets amount of owed asset tokens claimed
    function claimOwedAssets(address _receiver) external returns (uint256 assets);

    /// @notice Claim owed shares
    /// @param _receiver address to receive the tokens
    /// @return shares amount of owed share tokens claimed
    function claimOwedShares(address _receiver) external returns (uint256 shares);

    /// @notice Claim owed assets and shares
    /// @param _receiver address to receive the tokens
    /// @return assets amount of owed asset tokens claimed
    /// @return shares amount of owed share tokens claimed
    function claimOwedFunds(address _receiver) external returns (uint256 assets, uint256 shares);

    /// @notice Close positions
    /// @notice Converted assets are added to owed assets
    /// @notice Only available when fund is closed
    /// @param _shares amount of share tokens to close
    /// @param _owner owner address of share tokens
    /// @return assets amount of assets converted
    /// @notice If _owner is different from msg.sender, _owner must approve msg.sender to spend share tokens
    function closePosition(uint256 _shares, address _owner) external returns (uint256 assets);

    /// @notice Close positions and claim all assets
    /// @notice Only available when fund is closed
    /// @param _receiver address to receive asset tokens
    /// @return assets amount of asset tokens withdrawn
    function closePositionAndClaim(address _receiver) external returns (uint256 assets);

    /// @notice Preview how much assets is required for entering next cycle
    /// @param _fundValue total fund value for this cycle
    /// @param _timestamp predicted timestamp for start of next cycle
    /// @return withdrawAmount amount of assets required
    function previewNextCycle(uint128 _fundValue, uint64 _timestamp) external view returns (uint256 withdrawAmount);
}