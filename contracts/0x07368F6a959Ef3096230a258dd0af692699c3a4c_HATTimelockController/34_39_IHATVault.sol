// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "./IRewardController.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title Interface for Hats.finance Vaults
 * @author Hats.finance
 * @notice A HATVault holds the funds for a specific project's bug bounties.
 * Anyone can permissionlessly deposit into the HATVault using
 * the vault’s native token. When a bug is submitted and approved, the bounty 
 * is paid out using the funds in the vault. Bounties are paid out as a
 * percentage of the vault. The percentage is set according to the severity of
 * the bug. Vaults have regular safety periods (typically for an hour twice a
 * day) which are time for the committee to make decisions.
 *
 * In addition to the roles defined in the HATVaultsRegistry, every HATVault 
 * has the roles:
 * Committee - The only address which can submit a claim for a bounty payout
 * and set the maximum bounty.
 * User - Anyone can deposit the vault's native token into the vault and 
 * recieve shares for it. Shares represent the user's relative part in the
 * vault, and when a bounty is paid out, users lose part of their deposits
 * (based on percentage paid), but keep their share of the vault.
 * Users also receive rewards for their deposits, which can be claimed at any
 *  time.
 * To withdraw previously deposited tokens, a user must first send a withdraw
 * request, and the withdrawal will be made available after a pending period.
 * Withdrawals are not permitted during safety periods or while there is an 
 * active claim for a bounty payout.
 *
 * Bounties are payed out distributed between a few channels, and that 
 * distribution is set upon creation (the hacker gets part in direct transfer,
 * part in vested reward and part in vested HAT token, part gets rewarded to
 * the committee, part gets swapped to HAT token and burned and/or sent to Hats
 * governance).
 *
 * NOTE: Vaults should not use tokens which do not guarantee that the amount
 * specified is the amount transferred
 *
 * This project is open-source and can be found at:
 * https://github.com/hats-finance/hats-contracts
 */
interface IHATVault is IERC4626Upgradeable {

    enum ArbitratorCanChangeBounty{ NO, YES, DEFAULT }

    // How to divide the bounty - after deducting the part that is swapped to
    // HAT tokens (and then sent to governance and vested to the hacker)
    // values are in percentages and should add up to 100% (defined as 10000)
    struct BountySplit {
        // the percentage of reward sent to the hacker via vesting contract
        uint16 hackerVested;
        // the percentage of tokens that are sent directly to the hacker
        uint16 hacker;
        // the percentage sent to the committee
        uint16 committee;
    }

    // How to divide a bounty for a claim that has been approved
    // used to keep track of payouts, amounts are in vault's native token
    struct ClaimBounty {
        uint256 hacker;
        uint256 hackerVested;
        uint256 committee;
        uint256 hackerHatVested;
        uint256 governanceHat;
    }

    /**
    * @notice Initialization parameters for the vault
    * @param name The vault's name (concatenated as "Hats Vault " + name)
    * @param symbol The vault's symbol (concatenated as "HAT" + symbol)
    * @param rewardController The reward controller for the vault
    * @param vestingDuration Duration of the vesting period of the vault's
    * token vested part of the bounty
    * @param vestingPeriods The number of vesting periods of the vault's token
    * vested part of the bounty
    * @param maxBounty The maximum percentage of the vault that can be paid
    * out as a bounty
    * @param bountySplit The way to split the bounty between the hacker, 
    * hacker vested, and committee.
    *   Each entry is a number between 0 and `HUNDRED_PERCENT`.
    *   Total splits should be equal to `HUNDRED_PERCENT`.
    * @param asset The vault's native token
    * @param owner The address of the vault's owner 
    * @param committee The address of the vault's committee 
    * @param isPaused Whether to initialize the vault with deposits disabled
    * @dev Needed to avoid a "stack too deep" error
    */
    struct VaultInitParams {
        string name;
        string symbol;
        IRewardController[] rewardControllers;
        uint32 vestingDuration;
        uint32 vestingPeriods;
        uint16 maxBounty;
        IHATVault.BountySplit bountySplit;
        IERC20 asset;
        address owner;
        address committee;
        bool isPaused;
        string descriptionHash;
    }

    // Only committee
    error OnlyCommittee();
    // Active claim exists
    error ActiveClaimExists();
    // Safety period
    error SafetyPeriod();
    // Not safety period
    error NotSafetyPeriod();
    // Bounty percentage is higher than the max bounty
    error BountyPercentageHigherThanMaxBounty();
    // Only callable by arbitrator or after challenge timeout period
    error OnlyCallableByArbitratorOrAfterChallengeTimeOutPeriod();
    // No active claim exists
    error NoActiveClaimExists();
    // Claim Id specified is not the active claim Id
    error ClaimIdIsNotActive();
    // Not enough fee paid
    error NotEnoughFeePaid();
    // No pending max bounty
    error NoPendingMaxBounty();
    // Delay period for setting max bounty had not passed
    error DelayPeriodForSettingMaxBountyHadNotPassed();
    // Committee already checked in
    error CommitteeAlreadyCheckedIn();
    // Total bounty split % should be `HUNDRED_PERCENT`
    error TotalSplitPercentageShouldBeHundredPercent();
    // Vesting duration is too long
    error VestingDurationTooLong();
    // Vesting periods cannot be zero
    error VestingPeriodsCannotBeZero();
    // Vesting duration smaller than periods
    error VestingDurationSmallerThanPeriods();
    // Max bounty cannot be more than `MAX_BOUNTY_LIMIT`
    error MaxBountyCannotBeMoreThanMaxBountyLimit();
    // Committee bounty split cannot be more than `MAX_COMMITTEE_BOUNTY`
    error CommitteeBountyCannotBeMoreThanMax();
    // Only registry owner
    error OnlyRegistryOwner();
    // Only fee setter
    error OnlyFeeSetter();
    // Fee must be less than or equal to 2%
    error WithdrawalFeeTooBig();
    // Set shares arrays must have same length
    error SetSharesArraysMustHaveSameLength();
    // Committee not checked in yet
    error CommitteeNotCheckedInYet();
    // Not enough user balance
    error NotEnoughUserBalance();
    // Only arbitrator or registry owner
    error OnlyArbitratorOrRegistryOwner();
    // Unchalleged claim can only be approved if challenge period is over
    error UnchallengedClaimCanOnlyBeApprovedAfterChallengePeriod();
    // Challenged claim can only be approved by arbitrator before the challenge timeout period
    error ChallengedClaimCanOnlyBeApprovedByArbitratorUntilChallengeTimeoutPeriod();
    // Claim has expired
    error ClaimExpired();
    // Challenge period is over
    error ChallengePeriodEnded();
    // Claim can be challenged only once
    error ClaimAlreadyChallenged();
    // Only callable if challenged
    error OnlyCallableIfChallenged();
    // Cannot deposit to another user with withdraw request
    error CannotTransferToAnotherUserWithActiveWithdrawRequest();
    // Withdraw amount must be greater than zero
    error WithdrawMustBeGreaterThanZero();
    // Redeem amount cannot be more than maximum for user
    error RedeemMoreThanMax();
    // System is in an emergency pause
    error SystemInEmergencyPause();
    // Cannot set a reward controller that was already used in the past
    error CannotSetToPerviousRewardController();
    // Cannot mint burn or transfer 0 amount of shares
    error AmountCannotBeZero();
    // Cannot transfer shares to self
    error CannotTransferToSelf();
    // First deposit must return at least MINIMAL_AMOUNT_OF_SHARES
    error AmountOfSharesMustBeMoreThanMinimalAmount();
    // Deposit passed max slippage
    error DepositSlippageProtection();
    // Mint passed max slippage
    error MintSlippageProtection();
    // Withdraw passed max slippage
    error WithdrawSlippageProtection();
    // Redeem passed max slippage
    error RedeemSlippageProtection();
    // Cannot add the same reward controller more than once
    error DuplicatedRewardController();


    event SubmitClaim(
        bytes32 indexed _claimId,
        address indexed _committee,
        address indexed _beneficiary,
        uint256 _bountyPercentage,
        string _descriptionHash
    );
    event ChallengeClaim(bytes32 indexed _claimId);
    event ApproveClaim(
        bytes32 indexed _claimId,
        address indexed _committee,
        address indexed _beneficiary,
        uint256 _bountyPercentage,
        address _tokenLock,
        ClaimBounty _claimBounty
    );
    event DismissClaim(bytes32 indexed _claimId);
    event SetCommittee(address indexed _committee);
    event SetVestingParams(
        uint256 _duration,
        uint256 _periods
    );
    event SetBountySplit(BountySplit _bountySplit);
    event SetWithdrawalFee(uint256 _newFee);
    event CommitteeCheckedIn();
    event SetPendingMaxBounty(uint256 _maxBounty);
    event SetMaxBounty(uint256 _maxBounty);
    event AddRewardController(IRewardController indexed _newRewardController);
    event SetDepositPause(bool _depositPause);
    event SetVaultDescription(string _descriptionHash);
    event SetHATBountySplit(uint256 _bountyGovernanceHAT, uint256 _bountyHackerHATVested);
    event SetArbitrator(address indexed _arbitrator);
    event SetChallengePeriod(uint256 _challengePeriod);
    event SetChallengeTimeOutPeriod(uint256 _challengeTimeOutPeriod);
    event SetArbitratorCanChangeBounty(ArbitratorCanChangeBounty _arbitratorCanChangeBounty);
    event WithdrawRequest(
        address indexed _beneficiary,
        uint256 _withdrawEnableTime
    );

    /**
    * @notice Initialize a vault instance
    * @param _params The vault initialization parameters
    * @dev See {IHATVault-VaultInitParams} for more details
    * @dev Called when the vault is created in {IHATVaultsRegistry-createVault}
    */
    function initialize(VaultInitParams calldata _params) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Claim --------------------------------------- */

    /**
     * @notice Called by the committee to submit a claim for a bounty payout.
     * This function should be called only on a safety period, when withdrawals
     * are disabled, and while there's no other active claim. Cannot be called
     * when the registry is in an emergency pause.
     * Upon a call to this function by the committee the vault's withdrawals
     * will be disabled until the claim is approved or dismissed. Also from the
     * time of this call the arbitrator will have a period of 
     * {HATVaultsRegistry.challengePeriod} to challenge the claim.
     * @param _beneficiary The submitted claim's beneficiary
     * @param _bountyPercentage The submitted claim's bug requested reward percentage
     */
    function submitClaim(
        address _beneficiary, 
        uint16 _bountyPercentage, 
        string calldata _descriptionHash
    )
        external
        returns (bytes32 claimId);

   
    /**
    * @notice Called by the arbitrator or governance to challenge a claim for a bounty
    * payout that had been previously submitted by the committee.
    * Can only be called during the challenge period after submission of the
    * claim.
    * @param _claimId The claim ID
    */
    function challengeClaim(bytes32 _claimId) external;

    /**
    * @notice Approve a claim for a bounty submitted by a committee, and
    * pay out bounty to hacker and committee. Also transfer to the 
    * HATVaultsRegistry the part of the bounty that will be swapped to HAT 
    * tokens.
    * If the claim had been previously challenged, this is only callable by
    * the arbitrator. Otherwise, callable by anyone after challengePeriod had
    * passed.
    * @param _claimId The claim ID
    * @param _bountyPercentage The percentage of the vault's balance that will
    * be sent as a bounty. This value will be ignored if the caller is not the
    * arbitrator.
    */
    function approveClaim(bytes32 _claimId, uint16 _bountyPercentage)
        external;

    /**
    * @notice Dismiss the active claim for bounty payout submitted by the
    * committee.
    * Called either by the arbitrator, or by anyone if the claim has timed out.
    * @param _claimId The claim ID
    */
    function dismissClaim(bytes32 _claimId) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Params -------------------------------------- */

    /**
    * @notice Set new committee address. Can be called by existing committee,
    * or by the the vault's owner in the case that the committee hadn't checked in
    * yet.
    * @param _committee The address of the new committee 
    */
    function setCommittee(address _committee) external;

    /**
    * @notice Called by the vault's owner to set the vesting params for the
    * part of the bounty that the hacker gets vested in the vault's native
    * token
    * @param _duration Duration of the vesting period. Must be smaller than
    * 120 days and bigger than `_periods`
    * @param _periods Number of vesting periods. Cannot be 0.
    */
    function setVestingParams(uint32 _duration, uint32 _periods) external;

    /**
    * @notice Called by the vault's owner to set the vault token bounty split
    * upon an approval.
    * Can only be called if is no active claim and not during safety periods.
    * @param _bountySplit The bounty split
    */
    function setBountySplit(BountySplit calldata _bountySplit) external;

    /**
    * @notice Called by the registry's fee setter to set the fee for 
    * withdrawals from the vault.
    * @param _fee The new fee. Must be smaller than or equal to `MAX_WITHDRAWAL_FEE`
    */
    function setWithdrawalFee(uint256 _fee) external;

    /**
    * @notice Called by the vault's committee to claim it's role.
    * Deposits are enabled only after committee check in.
    */
    function committeeCheckIn() external;

    /**
    * @notice Called by the vault's owner to set a pending request for the
    * maximum percentage of the vault that can be paid out as a bounty.
    * Cannot be called if there is an active claim that has been submitted.
    * Max bounty should be less than or equal to 90% (defined as 9000).
    * The pending value can be set by the owner after the time delay (of 
    * {HATVaultsRegistry.generalParameters.setMaxBountyDelay}) had passed.
    * @param _maxBounty The maximum bounty percentage that can be paid out
    */
    function setPendingMaxBounty(uint16 _maxBounty) external;

    /**
    * @notice Called by the vault's owner to set the vault's max bounty to
    * the already pending max bounty.
    * Cannot be called if there are active claims that have been submitted.
    * Can only be called if there is a max bounty pending approval, and the
    * time delay since setting the pending max bounty had passed.
    */
    function setMaxBounty() external;

    /**
    * @notice Called by the vault's owner to disable all deposits to the vault
    * @param _depositPause Are deposits paused
    */
    function setDepositPause(bool _depositPause) external;

    /**
    * @notice Called by the registry's owner to change the description of the
    * vault in the Hats.finance UI
    * @param _descriptionHash the hash of the vault's description
    */
    function setVaultDescription(string calldata _descriptionHash) external;

    /**
    * @notice Called by the registry's owner to add a reward controller to the vault
    * @param _newRewardController The new reward controller to add
    */
    function addRewardController(IRewardController _newRewardController) external;

    /**
    * @notice Called by the registry's owner to set the vault HAT token bounty 
    * split upon an approval.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _bountyGovernanceHAT The HAT bounty for governance
    * @param _bountyHackerHATVested The HAT bounty vested for the hacker
    */
    function setHATBountySplit(
        uint16 _bountyGovernanceHAT,
        uint16 _bountyHackerHATVested
    ) 
        external;

    /**
    * @notice Called by the registry's owner to set the vault arbitrator
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _arbitrator The address of vault's arbitrator
    */
    function setArbitrator(address _arbitrator) external;

    /**
    * @notice Called by the registry's owner to set the period of time after
    * a claim for a bounty payout has been submitted that it can be challenged
    * by the arbitrator.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _challengePeriod The vault's challenge period
    */
    function setChallengePeriod(uint32 _challengePeriod) external;

    /**
    * @notice Called by the registry's owner to set the period of time after
    * which a claim for a bounty payout can be dismissed by anyone.
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _challengeTimeOutPeriod The vault's challenge timeout period
    */
    function setChallengeTimeOutPeriod(uint32 _challengeTimeOutPeriod)
        external;

    /**
    * @notice Called by the registry's owner to set whether the arbitrator
    * can change a claim bounty percentage
    * If the value passed is the special "null" value the vault will use the
    * registry's default value.
    * @param _arbitratorCanChangeBounty Whether the arbitrator can change a claim bounty percentage
    */
    function setArbitratorCanChangeBounty(ArbitratorCanChangeBounty _arbitratorCanChangeBounty) external;

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Vault --------------------------------------- */

    /**
    * @notice Submit a request to withdraw funds from the vault.
    * The request will only be approved if there is no previous active
    * withdraw request.
    * The request will be pending for a period of
    * {HATVaultsRegistry.generalParameters.withdrawRequestPendingPeriod},
    * after which a withdraw will be possible for a duration of
    * {HATVaultsRegistry.generalParameters.withdrawRequestEnablePeriod}
    */
    function withdrawRequest() external;

    /** 
    * @notice Withdraw previously deposited funds from the vault and claim
    * the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds
    * @param owner Address of owner of the funds
    * @dev See {IERC4626-withdraw}.
    */
    function withdrawAndClaim(uint256 assets, address receiver, address owner)
        external 
        returns (uint256 shares);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets and claim the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-redeem}.
    */
    function redeemAndClaim(uint256 shares, address receiver, address owner)
        external 
        returns (uint256 assets);

    /** 
    * @notice Redeem all of the user's shares in the vault for the respective amount
    * of underlying assets without calling the reward controller, meaning user renounces
    * their uncommited part of the reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param receiver Address of receiver of the funds 
    */
    function emergencyWithdraw(address receiver) external returns (uint256 assets);

    /** 
    * @notice Withdraw previously deposited funds from the vault, without
    * transferring the accumulated rewards.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-withdraw}.
    */
    function withdraw(uint256 assets, address receiver, address owner)
        external 
        returns (uint256);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets, without transferring the accumulated reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds 
    * @dev See {IERC4626-redeem}.
    */
    function redeem(uint256 shares, address receiver, address owner)
        external  
        returns (uint256);

    /**
    * @dev Deposit funds to the vault. Can only be called if the committee had
    * checked in and deposits are not paused, and the registry is not in an emergency pause.
    * @param receiver Reciever of the shares from the deposit
    * @param assets Amount of vault's native token to deposit
    * @dev See {IERC4626-deposit}.
    */
    function deposit(uint256 assets, address receiver) 
        external
        returns (uint256);

    /**
    * @dev Deposit funds to the vault. Can only be called if the committee had
    * checked in and deposits are not paused, and the registry is not in an emergency pause.
    * Allows to specify minimum shares to be minted for slippage protection.
    * @param receiver Reciever of the shares from the deposit
    * @param assets Amount of vault's native token to deposit
    * @param minShares Minimum amount of shares to minted for the assets
    */
    function deposit(uint256 assets, address receiver, uint256 minShares) 
        external
        returns (uint256);

    /**
    * @dev Deposit funds to the vault based on the amount of shares to mint specified.
    * Can only be called if the committee had checked in and deposits are not paused,
    * and the registry is not in an emergency pause.
    * Allows to specify maximum assets to be deposited for slippage protection.
    * @param receiver Reciever of the shares from the deposit
    * @param shares Amount of vault's shares to mint
    * @param maxAssets Maximum amount of assets to deposit for the shares
    */
    function mint(uint256 shares, address receiver, uint256 maxAssets) 
        external
        returns (uint256);

    /** 
    * @notice Withdraw previously deposited funds from the vault, without
    * transferring the accumulated HAT reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify maximum shares to be burnt for slippage protection.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds
    * @param maxShares Maximum amount of shares to burn for the assets
    */
    function withdraw(uint256 assets, address receiver, address owner, uint256 maxShares)
        external 
        returns (uint256);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets, without transferring the accumulated reward.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify minimum assets to be received for slippage protection.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds
    * @param minAssets Minimum amount of assets to receive for the shares
    */
    function redeem(uint256 shares, address receiver, address owner, uint256 minAssets)
        external  
        returns (uint256);

    /** 
    * @notice Withdraw previously deposited funds from the vault and claim
    * the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify maximum shares to be burnt for slippage protection.
    * @param assets Amount of tokens to withdraw
    * @param receiver Address of receiver of the funds
    * @param owner Address of owner of the funds
    * @param maxShares Maximum amount of shares to burn for the assets
    * @dev See {IERC4626-withdraw}.
    */
    function withdrawAndClaim(uint256 assets, address receiver, address owner, uint256 maxShares)
        external 
        returns (uint256 shares);

    /** 
    * @notice Redeem shares in the vault for the respective amount
    * of underlying assets and claim the HAT reward that the user has earned.
    * Can only be performed if a withdraw request has been previously
    * submitted, and the pending period had passed, and while the withdraw
    * enabled timeout had not passed. Withdrawals are not permitted during
    * safety periods or while there is an active claim for a bounty payout.
    * Allows to specify minimum assets to be received for slippage protection.
    * @param shares Amount of shares to redeem
    * @param receiver Address of receiver of the funds 
    * @param owner Address of owner of the funds
    * @param minAssets Minimum amount of assets to receive for the shares
    * @dev See {IERC4626-redeem}.
    */
    function redeemAndClaim(uint256 shares, address receiver, address owner, uint256 minAssets)
        external 
        returns (uint256 assets);

    /* -------------------------------------------------------------------------------- */

    /* --------------------------------- Getters -------------------------------------- */

    /** 
    * @notice Returns the vault HAT bounty split part that goes to the governance
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's HAT bounty split part that goes to the governance
    */
    function getBountyGovernanceHAT() external view returns(uint16);
    
    /** 
    * @notice Returns the vault HAT bounty split part that is vested for the hacker
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's HAT bounty split part that is vested for the hacker
    */
    function getBountyHackerHATVested() external view returns(uint16);

    /** 
    * @notice Returns the address of the vault's arbitrator
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The address of the vault's arbitrator
    */
    function getArbitrator() external view returns(address);

    /** 
    * @notice Returns the period of time after a claim for a bounty payout has
    * been submitted that it can be challenged by the arbitrator.
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's challenge period
    */
    function getChallengePeriod() external view returns(uint32);

    /** 
    * @notice Returns the period of time after which a claim for a bounty
    * payout can be dismissed by anyone.
    * If no specific value for this vault has been set, the registry's default
    * value will be returned.
    * @return The vault's challenge timeout period
    */
    function getChallengeTimeOutPeriod() external view returns(uint32);

    /** 
    * @notice Returns the amount of shares to be burned to give the user the exact
    * amount of assets requested plus cover for the fee. Also returns the amount assets
    * to be paid as fee.
    * @return shares The amount of shares to be burned to get the requested amount of assets
    * @return fee The amount of assets that will be paid as fee
    */
    function previewWithdrawAndFee(uint256 assets) external view returns (uint256 shares, uint256 fee);


    /** 
    * @notice Returns the amount of assets to be sent to the user for the exact
    * amount of shares to redeem. Also returns the amount assets to be paid as fee.
    * @return assets amount of assets to be sent in exchange for the amount of shares specified
    * @return fee The amount of assets that will be paid as fee
    */
    function previewRedeemAndFee(uint256 shares) external view returns (uint256 assets, uint256 fee);
}