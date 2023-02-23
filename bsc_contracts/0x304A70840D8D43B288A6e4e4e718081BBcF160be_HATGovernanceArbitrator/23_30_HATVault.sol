// SPDX-License-Identifier: MIT
// Disclaimer https://github.com/hats-finance/hats-contracts/blob/main/DISCLAIMER.md

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./tokenlock/TokenLockFactory.sol";
import "./interfaces/IHATVault.sol";
import "./interfaces/IRewardController.sol";
import "./HATVaultsRegistry.sol";

/** @title A Hats.finance vault which holds the funds for a specific project's
* bug bounties
* @author Hats.finance
* @notice The HATVault can be deposited into in a permissionless manner using
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
* time.
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
* This project is open-source and can be found at:
* https://github.com/hats-finance/hats-contracts
*/
contract HATVault is IHATVault, ERC4626Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using MathUpgradeable for uint256;

    struct Claim {
        bytes32 claimId;
        address beneficiary;
        uint16 bountyPercentage;
        // the address of the committee at the time of the submission, so that this committee will
        // be paid their share of the bounty in case the committee changes before claim approval
        address committee;
        uint32 createdAt;
        uint32 challengedAt;
        uint256 bountyGovernanceHAT;
        uint256 bountyHackerHATVested;
        address arbitrator;
        uint32 challengePeriod;
        uint32 challengeTimeOutPeriod;
        bool arbitratorCanChangeBounty;
    }

    struct PendingMaxBounty {
        uint16 maxBounty;
        uint32 timestamp;
    }

    uint256 public constant MAX_UINT = type(uint256).max;
    uint16 public constant NULL_UINT16 = type(uint16).max;
    uint32 public constant NULL_UINT32 = type(uint32).max;
    address public constant NULL_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint256 public constant HUNDRED_PERCENT = 1e4;
    uint256 public constant HUNDRED_PERCENT_SQRD = 1e8;
    uint256 public constant MAX_BOUNTY_LIMIT = 90e2; // Max bounty can be up to 90%
    uint256 public constant MAX_WITHDRAWAL_FEE = 2e2; // Max fee is 2%
    uint256 public constant MAX_COMMITTEE_BOUNTY = 10e2; // Max committee bounty can be up to 10%

    uint256 public constant MINIMAL_AMOUNT_OF_SHARES = 1e3; // to reduce rounding errors, the number of shares is either 0, or > than this number

    HATVaultsRegistry public registry;
    ITokenLockFactory public tokenLockFactory;

    Claim public activeClaim;

    IRewardController[] public rewardControllers;

    IHATVault.BountySplit public bountySplit;
    uint16 public maxBounty;
    uint32 public vestingDuration;
    uint32 public vestingPeriods;
    address public committee;

    bool public committeeCheckedIn;
    bool public depositPause;
    uint256 public withdrawalFee;

    uint256 internal nonce;

    PendingMaxBounty public pendingMaxBounty;


    // Time of when withdrawal period starts for every user that has an
    // active withdraw request. (time when last withdraw request pending 
    // period ended, or 0 if last action was deposit or withdraw)
    mapping(address => uint256) public withdrawEnableStartTime;

    // the percentage of the total bounty to be swapped to HATs and sent to governance (out of {HUNDRED_PERCENT})
    uint16 internal bountyGovernanceHAT;
    // the percentage of the total bounty to be swapped to HATs and sent to the hacker via vesting contract (out of {HUNDRED_PERCENT})
    uint16 internal bountyHackerHATVested;

    // address of the arbitrator - which can dispute claims and override the committee's decisions
    address internal arbitrator;
    // time during which a claim can be challenged by the arbitrator
    uint32 internal challengePeriod;
    // time after which a challenged claim is automatically dismissed
    uint32 internal challengeTimeOutPeriod;
    // whether the arbitrator can change bounty of claims
    ArbitratorCanChangeBounty internal arbitratorCanChangeBounty;

    bool private _isEmergencyWithdraw;

    modifier onlyRegistryOwner() {
        if (registry.owner() != msg.sender) revert OnlyRegistryOwner();
        _;
    }

    modifier onlyFeeSetter() {
        if (registry.feeSetter() != msg.sender) revert OnlyFeeSetter();
        _;
    }

    modifier onlyCommittee() {
        if (committee != msg.sender) revert OnlyCommittee();
        _;
    }

    modifier notEmergencyPaused() {
        if (registry.isEmergencyPaused()) revert SystemInEmergencyPause();
        _;
    }

    modifier noSafetyPeriod() {
        uint256 _withdrawPeriod = registry.getWithdrawPeriod();
        // disable withdraw for safetyPeriod (e.g 1 hour) after each withdrawPeriod(e.g 11 hours)
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp % (_withdrawPeriod + registry.getSafetyPeriod()) >= _withdrawPeriod)
            revert SafetyPeriod();
        _;
    }

    modifier noActiveClaim() {
        if (activeClaim.createdAt != 0) revert ActiveClaimExists();
        _;
    }

    modifier isActiveClaim(bytes32 _claimId) {
        if (activeClaim.createdAt == 0) revert NoActiveClaimExists();
        if (activeClaim.claimId != _claimId) revert ClaimIdIsNotActive();
        _;
    }

    /** @notice See {IHATVault-initialize}. */
    function initialize(IHATVault.VaultInitParams calldata _params) external initializer {
        if (_params.maxBounty > MAX_BOUNTY_LIMIT)
            revert MaxBountyCannotBeMoreThanMaxBountyLimit();
        _validateSplit(_params.bountySplit);
        __ERC20_init(string.concat("Hats Vault ", _params.name), string.concat("HAT", _params.symbol));
        __ERC4626_init(IERC20MetadataUpgradeable(address(_params.asset)));
        rewardControllers = _params.rewardControllers;
        _setVestingParams(_params.vestingDuration, _params.vestingPeriods);
        HATVaultsRegistry _registry = HATVaultsRegistry(msg.sender);
        maxBounty = _params.maxBounty;
        bountySplit = _params.bountySplit;
        committee = _params.committee;
        depositPause = _params.isPaused;
        registry = _registry;
        __ReentrancyGuard_init();
        _transferOwnership(_params.owner);
        tokenLockFactory = _registry.tokenLockFactory();

        // Set vault to use default registry values where applicable
        arbitrator = NULL_ADDRESS;
        bountyGovernanceHAT = NULL_UINT16;
        bountyHackerHATVested = NULL_UINT16;
        arbitratorCanChangeBounty = ArbitratorCanChangeBounty.DEFAULT;
        challengePeriod = NULL_UINT32;
        challengeTimeOutPeriod = NULL_UINT32;

        emit SetVaultDescription(_params.descriptionHash);
    }


    /* ---------------------------------- Claim --------------------------------------- */

    /** @notice See {IHATVault-submitClaim}. */
    function submitClaim(address _beneficiary, uint16 _bountyPercentage, string calldata _descriptionHash)
        external onlyCommittee noActiveClaim notEmergencyPaused returns (bytes32 claimId) {
        HATVaultsRegistry _registry = registry;
        uint256 withdrawPeriod = _registry.getWithdrawPeriod();
        // require we are in safetyPeriod
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp % (withdrawPeriod + _registry.getSafetyPeriod()) < withdrawPeriod)
            revert NotSafetyPeriod();
        if (_bountyPercentage > maxBounty)
            revert BountyPercentageHigherThanMaxBounty();
        claimId = keccak256(abi.encodePacked(address(this), ++nonce));
        activeClaim = Claim({
            claimId: claimId,
            beneficiary: _beneficiary,
            bountyPercentage: _bountyPercentage,
            committee: msg.sender,
            // solhint-disable-next-line not-rely-on-time
            createdAt: uint32(block.timestamp),
            challengedAt: 0,
            bountyGovernanceHAT: getBountyGovernanceHAT(),
            bountyHackerHATVested: getBountyHackerHATVested(),
            arbitrator: getArbitrator(),
            challengePeriod: getChallengePeriod(),
            challengeTimeOutPeriod: getChallengeTimeOutPeriod(),
            arbitratorCanChangeBounty: getArbitratorCanChangeBounty()
        });

        emit SubmitClaim(
            claimId,
            msg.sender,
            _beneficiary,
            _bountyPercentage,
            _descriptionHash
        );
    }

    function challengeClaim(bytes32 _claimId) external isActiveClaim(_claimId) {
        if (msg.sender != activeClaim.arbitrator && msg.sender != registry.owner())
            revert OnlyArbitratorOrRegistryOwner();
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= activeClaim.createdAt + activeClaim.challengePeriod)
            revert ChallengePeriodEnded();
        if (activeClaim.challengedAt != 0) {
            revert ClaimAlreadyChallenged();
        } 
        // solhint-disable-next-line not-rely-on-time
        activeClaim.challengedAt = uint32(block.timestamp);
        emit ChallengeClaim(_claimId);
    }

    /** @notice See {IHATVault-approveClaim}. */
    function approveClaim(bytes32 _claimId, uint16 _bountyPercentage) external nonReentrant isActiveClaim(_claimId) {
        Claim memory _claim = activeClaim;
        delete activeClaim;
        
        
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= _claim.createdAt + _claim.challengePeriod + _claim.challengeTimeOutPeriod) {
            // cannot approve an expired claim
            revert ClaimExpired();
        } 
        if (_claim.challengedAt != 0) {
            // the claim was challenged, and only the arbitrator can approve it, within the timeout period
            if (
                msg.sender != _claim.arbitrator ||
                // solhint-disable-next-line not-rely-on-time
                block.timestamp >= _claim.challengedAt + _claim.challengeTimeOutPeriod
            )
                revert ChallengedClaimCanOnlyBeApprovedByArbitratorUntilChallengeTimeoutPeriod();
            // the arbitrator can update the bounty if needed
            if (_claim.arbitratorCanChangeBounty && _bountyPercentage != 0) {
                _claim.bountyPercentage = _bountyPercentage;
            }
        } else {
            // the claim can be approved by anyone if the challengePeriod passed without a challenge
            if (
                // solhint-disable-next-line not-rely-on-time
                block.timestamp <= _claim.createdAt + _claim.challengePeriod
            ) 
                revert UnchallengedClaimCanOnlyBeApprovedAfterChallengePeriod();
        }

        address tokenLock;

        IHATVault.ClaimBounty memory claimBounty = _calcClaimBounty(
            _claim.bountyPercentage,
            _claim.bountyGovernanceHAT,
            _claim.bountyHackerHATVested
        );

        IERC20 _asset = IERC20(asset());
        if (claimBounty.hackerVested > 0) {
            //hacker gets part of bounty to a vesting contract
            tokenLock = tokenLockFactory.createTokenLock(
                address(_asset),
                0x0000000000000000000000000000000000000000, //this address as owner, so it can do nothing.
                _claim.beneficiary,
                claimBounty.hackerVested,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp, //start
                // solhint-disable-next-line not-rely-on-time
                block.timestamp + vestingDuration, //end
                vestingPeriods,
                0, //no release start
                0, //no cliff
                ITokenLock.Revocability.Disabled,
                false
            );
            _asset.safeTransfer(tokenLock, claimBounty.hackerVested);
        }

        _asset.safeTransfer(_claim.beneficiary, claimBounty.hacker);
        _asset.safeTransfer(_claim.committee, claimBounty.committee);

        // send to the registry the amount of tokens which should be swapped 
        // to HAT so it could call swapAndSend in a separate tx.
        HATVaultsRegistry _registry = registry;
        _asset.safeApprove(address(_registry), claimBounty.hackerHatVested + claimBounty.governanceHat);
        _registry.addTokensToSwap(
            _asset,
            _claim.beneficiary,
            claimBounty.hackerHatVested,
            claimBounty.governanceHat
        );

        // make sure to reset approval
        _asset.safeApprove(address(_registry), 0);

        emit ApproveClaim(
            _claimId,
            msg.sender,
            _claim.beneficiary,
            _claim.bountyPercentage,
            tokenLock,
            claimBounty
        );
    }

    /** @notice See {IHATVault-dismissClaim}. */
    function dismissClaim(bytes32 _claimId) external isActiveClaim(_claimId) {
        uint256 _challengeTimeOutPeriod = activeClaim.challengeTimeOutPeriod;
        uint256 _challengedAt = activeClaim.challengedAt;
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp <= activeClaim.createdAt + activeClaim.challengePeriod + _challengeTimeOutPeriod) {
            if (_challengedAt == 0) revert OnlyCallableIfChallenged();
            if (
                // solhint-disable-next-line not-rely-on-time
                block.timestamp <= _challengedAt + _challengeTimeOutPeriod && 
                msg.sender != activeClaim.arbitrator
            ) revert OnlyCallableByArbitratorOrAfterChallengeTimeOutPeriod();
        } // else the claim is expired and should be dismissed
        delete activeClaim;

        emit DismissClaim(_claimId);
    }
    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Params -------------------------------------- */

    /** @notice See {IHATVault-setCommittee}. */
    function setCommittee(address _committee) external {
        // vault owner can update committee only if committee was not checked in yet.
        if (msg.sender == owner() && committee != msg.sender) {
            if (committeeCheckedIn)
                revert CommitteeAlreadyCheckedIn();
        } else {
            if (committee != msg.sender) revert OnlyCommittee();
        }

        committee = _committee;

        emit SetCommittee(_committee);
    }

    /** @notice See {IHATVault-setVestingParams}. */
    function setVestingParams(uint32 _duration, uint32 _periods) external onlyOwner {
        _setVestingParams(_duration, _periods);
    }

    /** @notice See {IHATVault-setBountySplit}. */
    function setBountySplit(IHATVault.BountySplit calldata _bountySplit) external onlyOwner noActiveClaim noSafetyPeriod {
        _validateSplit(_bountySplit);
        bountySplit = _bountySplit;
        emit SetBountySplit(_bountySplit);
    }

    /** @notice See {IHATVault-setWithdrawalFee}. */
    function setWithdrawalFee(uint256 _fee) external onlyFeeSetter {
        if (_fee > MAX_WITHDRAWAL_FEE) revert WithdrawalFeeTooBig();
        withdrawalFee = _fee;
        emit SetWithdrawalFee(_fee);
    }

    /** @notice See {IHATVault-committeeCheckIn}. */
    function committeeCheckIn() external onlyCommittee {
        committeeCheckedIn = true;
        emit CommitteeCheckedIn();
    }

    /** @notice See {IHATVault-setPendingMaxBounty}. */
    function setPendingMaxBounty(uint16 _maxBounty) external onlyOwner noActiveClaim {
        if (_maxBounty > MAX_BOUNTY_LIMIT)
            revert MaxBountyCannotBeMoreThanMaxBountyLimit();
        pendingMaxBounty.maxBounty = _maxBounty;
        // solhint-disable-next-line not-rely-on-time
        pendingMaxBounty.timestamp = uint32(block.timestamp);
        emit SetPendingMaxBounty(_maxBounty);
    }

    /** @notice See {IHATVault-setMaxBounty}. */
    function setMaxBounty() external onlyOwner noActiveClaim {
        PendingMaxBounty memory _pendingMaxBounty = pendingMaxBounty;
        if (_pendingMaxBounty.timestamp == 0) revert NoPendingMaxBounty();

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - _pendingMaxBounty.timestamp < registry.getSetMaxBountyDelay())
            revert DelayPeriodForSettingMaxBountyHadNotPassed();

        uint16 _maxBounty = pendingMaxBounty.maxBounty;
        maxBounty = _maxBounty;
        delete pendingMaxBounty;
        emit SetMaxBounty(_maxBounty);
    }

    /** @notice See {IHATVault-setDepositPause}. */
    function setDepositPause(bool _depositPause) external onlyOwner {
        depositPause = _depositPause;
        emit SetDepositPause(_depositPause);
    }

    /** @notice See {IHATVault-setVaultDescription}. */
    function setVaultDescription(string calldata _descriptionHash) external onlyRegistryOwner {
        emit SetVaultDescription(_descriptionHash);
    }

    /** @notice See {IHATVault-addRewardController}. */
    function addRewardController(IRewardController _rewardController) external onlyRegistryOwner noActiveClaim {
        for (uint256 i = 0; i < rewardControllers.length;) { 
            if (_rewardController == rewardControllers[i]) revert DuplicatedRewardController();
            unchecked { ++i; }
        }
        rewardControllers.push(_rewardController);
        emit AddRewardController(_rewardController);
    }
    
    /** @notice See {IHATVault-setHATBountySplit}. */
    function setHATBountySplit(uint16 _bountyGovernanceHAT, uint16 _bountyHackerHATVested) external onlyRegistryOwner {
        bountyGovernanceHAT = _bountyGovernanceHAT;
        bountyHackerHATVested = _bountyHackerHATVested;

        registry.validateHATSplit(getBountyGovernanceHAT(), getBountyHackerHATVested());

        emit SetHATBountySplit(_bountyGovernanceHAT, _bountyHackerHATVested);
    }

    /** @notice See {IHATVault-setArbitrator}. */
    function setArbitrator(address _arbitrator) external onlyRegistryOwner {
        arbitrator = _arbitrator;
        emit SetArbitrator(_arbitrator);
    }

    /** @notice See {IHATVault-setChallengePeriod}. */
    function setChallengePeriod(uint32 _challengePeriod) external onlyRegistryOwner {
        if (_challengePeriod != NULL_UINT32) {
            registry.validateChallengePeriod(_challengePeriod);
        }

        challengePeriod = _challengePeriod;
        
        emit SetChallengePeriod(_challengePeriod);
    }

    /** @notice See {IHATVault-setChallengeTimeOutPeriod}. */
    function setChallengeTimeOutPeriod(uint32 _challengeTimeOutPeriod) external onlyRegistryOwner {
        if (_challengeTimeOutPeriod != NULL_UINT32) {
            registry.validateChallengeTimeOutPeriod(_challengeTimeOutPeriod);
        }

        challengeTimeOutPeriod = _challengeTimeOutPeriod;
        
        emit SetChallengeTimeOutPeriod(_challengeTimeOutPeriod);
    }

    /** @notice See {IHATVault-setArbitratorCanChangeBounty}. */
    function setArbitratorCanChangeBounty(ArbitratorCanChangeBounty _arbitratorCanChangeBounty) external onlyRegistryOwner {
        arbitratorCanChangeBounty = _arbitratorCanChangeBounty;
        emit SetArbitratorCanChangeBounty(_arbitratorCanChangeBounty);
    }

    /* -------------------------------------------------------------------------------- */

    /* ---------------------------------- Vault --------------------------------------- */

    /** @notice See {IHATVault-withdrawRequest}. */
    function withdrawRequest() external nonReentrant {
        // set the withdrawEnableStartTime time to be withdrawRequestPendingPeriod from now
        // solhint-disable-next-line not-rely-on-time
        uint256 _withdrawEnableStartTime = block.timestamp + registry.getWithdrawRequestPendingPeriod();
        address msgSender = _msgSender();
        withdrawEnableStartTime[msgSender] = _withdrawEnableStartTime;
        emit WithdrawRequest(msgSender, _withdrawEnableStartTime);
    }

    /** @notice See {IHATVault-withdrawAndClaim}. */
    function withdrawAndClaim(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        shares = withdraw(assets, receiver, owner);
        for (uint256 i = 0; i < rewardControllers.length;) { 
            rewardControllers[i].claimReward(address(this), owner);
            unchecked { ++i; }
        }
    }

    /** @notice See {IHATVault-redeemAndClaim}. */
    function redeemAndClaim(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        assets = redeem(shares, receiver, owner);
        for (uint256 i = 0; i < rewardControllers.length;) { 
            rewardControllers[i].claimReward(address(this), owner);
            unchecked { ++i; }
        }
    }

    /** @notice See {IHATVault-emergencyWithdraw}. */
    function emergencyWithdraw(address receiver) external returns (uint256 assets) {
        _isEmergencyWithdraw = true;
        address msgSender = _msgSender();
        assets = redeem(balanceOf(msgSender), receiver, msgSender);
        _isEmergencyWithdraw = false;
    }

    /** @notice See {IHATVault-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) 
        public override(IHATVault, ERC4626Upgradeable) virtual returns (uint256) {
        (uint256 _shares, uint256 _fee) = previewWithdrawAndFee(assets);
        _withdraw(_msgSender(), receiver, owner, assets, _shares, _fee);

        return _shares;
    }

    /** @notice See {IHATVault-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) 
        public override(IHATVault, ERC4626Upgradeable) virtual returns (uint256) {
        (uint256 _assets, uint256 _fee) = previewRedeemAndFee(shares);
        _withdraw(_msgSender(), receiver, owner, _assets, shares, _fee);

        return _assets;
    }

    /** @notice See {IHATVault-deposit}. */
    function deposit(uint256 assets, address receiver) public override(IHATVault, ERC4626Upgradeable) virtual returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /** @notice See {IHATVault-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner, uint256 maxShares) public virtual returns (uint256) {
        uint256 shares = withdraw(assets, receiver, owner);
        if (shares > maxShares) revert WithdrawSlippageProtection();
        return shares;
    }

    /** @notice See {IHATVault-redeem}. */
    function redeem(uint256 shares, address receiver, address owner, uint256 minAssets) public virtual returns (uint256) {
        uint256 assets = redeem(shares, receiver, owner);
        if (assets < minAssets) revert RedeemSlippageProtection();
        return assets;
    }

    /** @notice See {IHATVault-withdrawAndClaim}. */
    function withdrawAndClaim(uint256 assets, address receiver, address owner, uint256 maxShares) external returns (uint256 shares) {
        shares = withdraw(assets, receiver, owner, maxShares);
        for (uint256 i = 0; i < rewardControllers.length;) { 
            rewardControllers[i].claimReward(address(this), owner);
            unchecked { ++i; }
        }
    }

    /** @notice See {IHATVault-redeemAndClaim}. */
    function redeemAndClaim(uint256 shares, address receiver, address owner, uint256 minAssets) external returns (uint256 assets) {
        assets = redeem(shares, receiver, owner, minAssets);
        for (uint256 i = 0; i < rewardControllers.length;) { 
            rewardControllers[i].claimReward(address(this), owner);
            unchecked { ++i; }
        }
    }

    /** @notice See {IHATVault-deposit}. */
    function deposit(uint256 assets, address receiver, uint256 minShares) external virtual returns (uint256) {
        uint256 shares = deposit(assets, receiver);
        if (shares < minShares) revert DepositSlippageProtection();
        return shares;
    }

    /** @notice See {IHATVault-mint}. */
    function mint(uint256 shares, address receiver, uint256 maxAssets) external virtual returns (uint256) {
        uint256 assets = mint(shares, receiver);
        if (assets > maxAssets) revert MintSlippageProtection();
        return assets;
    }

    /** @notice See {IERC4626Upgradeable-maxDeposit}. */
    function maxDeposit(address) public view virtual override(IERC4626Upgradeable, ERC4626Upgradeable) returns (uint256) {
        return depositPause ? 0 : MAX_UINT;
    }

    /** @notice See {IERC4626Upgradeable-maxMint}. */
    function maxMint(address) public view virtual override(IERC4626Upgradeable, ERC4626Upgradeable) returns (uint256) {
        return depositPause ? 0 : MAX_UINT;
    }

    /** @notice See {IERC4626Upgradeable-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override(IERC4626Upgradeable, ERC4626Upgradeable) returns (uint256) {
        if (activeClaim.createdAt != 0 || !_isWithdrawEnabledForUser(owner)) return 0;
        return previewRedeem(balanceOf(owner));
    }

    /** @notice See {IERC4626Upgradeable-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override(IERC4626Upgradeable, ERC4626Upgradeable) returns (uint256) {
        if (activeClaim.createdAt != 0 || !_isWithdrawEnabledForUser(owner)) return 0;
        return balanceOf(owner);
    }

    /** @notice See {IERC4626Upgradeable-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override(IERC4626Upgradeable, ERC4626Upgradeable) returns (uint256 shares) {
        (shares,) = previewWithdrawAndFee(assets);
    }

    /** @notice See {IERC4626Upgradeable-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override(IERC4626Upgradeable, ERC4626Upgradeable) returns (uint256 assets) {
        (assets,) = previewRedeemAndFee(shares);
    }

    /** @notice See {IHATVault-previewWithdrawAndFee}. */
    function previewWithdrawAndFee(uint256 assets) public view returns (uint256 shares, uint256 fee) {
        uint256 _withdrawalFee = withdrawalFee;
        fee = assets.mulDiv(_withdrawalFee, (HUNDRED_PERCENT - _withdrawalFee));
        shares = _convertToShares(assets + fee, MathUpgradeable.Rounding.Up);
    }

    /** @notice See {IHATVault-previewRedeemAndFee}. */
    function previewRedeemAndFee(uint256 shares) public view returns (uint256 assets, uint256 fee) {
        uint256 _assetsPlusFee = _convertToAssets(shares, MathUpgradeable.Rounding.Down);
        fee = _assetsPlusFee.mulDiv(withdrawalFee, HUNDRED_PERCENT);
        unchecked { // fee will always be maximun 20% of _assetsPlusFee
            assets = _assetsPlusFee - fee;
        }
    }

    /* -------------------------------------------------------------------------------- */

    /* --------------------------------- Getters -------------------------------------- */

    /** @notice See {IHATVault-getBountyGovernanceHAT}. */
    function getBountyGovernanceHAT() public view returns(uint16) {
        uint16 _bountyGovernanceHAT = bountyGovernanceHAT;
        if (_bountyGovernanceHAT != NULL_UINT16) {
            return _bountyGovernanceHAT;
        } else {
            return registry.defaultBountyGovernanceHAT();
        }
    }

    /** @notice See {IHATVault-getBountyHackerHATVested}. */
    function getBountyHackerHATVested() public view returns(uint16) {
        uint16 _bountyHackerHATVested = bountyHackerHATVested;
        if (_bountyHackerHATVested != NULL_UINT16) {
            return _bountyHackerHATVested;
        } else {
            return registry.defaultBountyHackerHATVested();
        }
    }

    /** @notice See {IHATVault-getArbitrator}. */
    function getArbitrator() public view returns(address) {
        address _arbitrator = arbitrator;
        if (_arbitrator != NULL_ADDRESS) {
            return _arbitrator;
        } else {
            return registry.defaultArbitrator();
        }
    }

    /** @notice See {IHATVault-getChallengePeriod}. */
    function getChallengePeriod() public view returns(uint32) {
        uint32 _challengePeriod = challengePeriod;
        if (_challengePeriod != NULL_UINT32) {
            return _challengePeriod;
        } else {
            return registry.defaultChallengePeriod();
        }
    }

    /** @notice See {IHATVault-getChallengeTimeOutPeriod}. */
    function getChallengeTimeOutPeriod() public view returns(uint32) {
        uint32 _challengeTimeOutPeriod = challengeTimeOutPeriod;
        if (_challengeTimeOutPeriod != NULL_UINT32) {
            return _challengeTimeOutPeriod;
        } else {
            return registry.defaultChallengeTimeOutPeriod();
        }
    }

    /** @notice See {IHATVault-getArbitratorCanChangeBounty}. */
    function getArbitratorCanChangeBounty() public view returns(bool) {
        ArbitratorCanChangeBounty _arbitratorCanChangeBounty = arbitratorCanChangeBounty;
        if (_arbitratorCanChangeBounty != ArbitratorCanChangeBounty.DEFAULT) {
            return _arbitratorCanChangeBounty == ArbitratorCanChangeBounty.YES;
        } else {
            return registry.defaultArbitratorCanChangeBounty();
        }
    }

    /* -------------------------------------------------------------------------------- */

    /* --------------------------------- Helpers -------------------------------------- */

    /**
    * @dev Deposit funds to the vault. Can only be called if the committee had
    * checked in and deposits are not paused.
    * @param caller Caller of the action (msg.sender)
    * @param receiver Reciever of the shares from the deposit
    * @param assets Amount of vault's native token to deposit
    * @param shares Respective amount of shares to be received
    */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override virtual nonReentrant {
        if (!committeeCheckedIn)
            revert CommitteeNotCheckedInYet();
        if (receiver == caller && withdrawEnableStartTime[receiver] != 0 ) {
            // clear withdraw request if caller deposits in her own account
            withdrawEnableStartTime[receiver] = 0;
        }

        super._deposit(caller, receiver, assets, shares);
    }

    // amount of shares correspond with assets + fee
    function _withdraw(
        address _caller,
        address _receiver,
        address _owner,
        uint256 _assets,
        uint256 _shares,
        uint256 _fee
    ) internal nonReentrant {
        if (_assets == 0) revert WithdrawMustBeGreaterThanZero();
        if (_caller != _owner) {
            _spendAllowance(_owner, _caller, _shares);
        }

        _burn(_owner, _shares);

        IERC20 _asset = IERC20(asset());
        if (_fee > 0) {
            _asset.safeTransfer(registry.owner(), _fee);
        }
        _asset.safeTransfer(_receiver, _assets);

        emit Withdraw(_caller, _receiver, _owner, _assets, _shares);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        if (_amount == 0) revert AmountCannotBeZero();
        if (_from == _to) revert CannotTransferToSelf();
        // deposit/mint/transfer
        if (_to != address(0)) {
            HATVaultsRegistry  _registry = registry;
            if (_registry.isEmergencyPaused()) revert SystemInEmergencyPause();
            // Cannot transfer or mint tokens to a user for which an active withdraw request exists
            // because then we would need to reset their withdraw request
            uint256 _withdrawEnableStartTime = withdrawEnableStartTime[_to];
            if (_withdrawEnableStartTime != 0) {
                // solhint-disable-next-line not-rely-on-time
                if (block.timestamp <= _withdrawEnableStartTime + _registry.getWithdrawRequestEnablePeriod())
                    revert CannotTransferToAnotherUserWithActiveWithdrawRequest();
            }

            for (uint256 i = 0; i < rewardControllers.length;) { 
                rewardControllers[i].commitUserBalance(_to, _amount, true);
                unchecked { ++i; }
            }
        }
        // withdraw/redeem/transfer
        if (_from != address(0)) {
            if (_amount > maxRedeem(_from)) revert RedeemMoreThanMax();
            // if all is ok and withdrawal can be made - 
            // reset withdrawRequests[_pid][msg.sender] so that another withdrawRequest
            // will have to be made before next withdrawal
            withdrawEnableStartTime[_from] = 0;

            if (!_isEmergencyWithdraw) {
                for (uint256 i = 0; i < rewardControllers.length;) { 
                    rewardControllers[i].commitUserBalance(_from, _amount, false);
                    unchecked { ++i; }
                }
            }
        }
    }

    function _afterTokenTransfer(address, address, uint256) internal virtual override {
        if (totalSupply() > 0 && totalSupply() < MINIMAL_AMOUNT_OF_SHARES) {
          revert AmountOfSharesMustBeMoreThanMinimalAmount();
        }
    }

    function _setVestingParams(uint32 _duration, uint32 _periods) internal {
        if (_duration > 120 days) revert VestingDurationTooLong();
        if (_periods == 0) revert VestingPeriodsCannotBeZero();
        if (_duration < _periods) revert VestingDurationSmallerThanPeriods();
        vestingDuration = _duration;
        vestingPeriods = _periods;
        emit SetVestingParams(_duration, _periods);
    }

    /**
    * @dev Checks that the given user can perform a withdraw at this time
    * @param _user Address of the user to check
    */
    function _isWithdrawEnabledForUser(address _user)
        internal view
        returns(bool)
    {
        HATVaultsRegistry _registry = registry;
        uint256 _withdrawPeriod = _registry.getWithdrawPeriod();
        // disable withdraw for safetyPeriod (e.g 1 hour) after each withdrawPeriod (e.g 11 hours)
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp % (_withdrawPeriod + _registry.getSafetyPeriod()) >= _withdrawPeriod)
            return false;
        // check that withdrawRequestPendingPeriod had passed
        uint256 _withdrawEnableStartTime = withdrawEnableStartTime[_user];
        // solhint-disable-next-line not-rely-on-time
        return (block.timestamp >= _withdrawEnableStartTime &&
        // check that withdrawRequestEnablePeriod had not passed and that the
        // last action was withdrawRequest (and not deposit or withdraw, which
        // reset withdrawRequests[_user] to 0)
        // solhint-disable-next-line not-rely-on-time
            block.timestamp <= _withdrawEnableStartTime + _registry.getWithdrawRequestEnablePeriod());
    }

    /**
    * @dev calculate the specific bounty payout distribution, according to the
    * predefined bounty split and the given bounty percentage
    * @param _bountyPercentage The percentage of the vault's funds to be paid
    * out as bounty
    * @param _bountyGovernanceHAT The bountyGovernanceHAT at the time the claim was submitted
    * @param _bountyHackerHATVested The bountyHackerHATVested at the time the claim was submitted
    * @return claimBounty The bounty distribution for this specific claim
    */
    function _calcClaimBounty(
        uint256 _bountyPercentage,
        uint256 _bountyGovernanceHAT,
        uint256 _bountyHackerHATVested
    ) internal view returns(IHATVault.ClaimBounty memory claimBounty) {
        uint256 _totalAssets = totalAssets();
        if (_totalAssets == 0) {
          return claimBounty;
        }
        if (_bountyPercentage > maxBounty)
            revert BountyPercentageHigherThanMaxBounty();

        uint256 _totalBountyAmount = _totalAssets * _bountyPercentage;

        uint256 _governanceHatAmount = _totalBountyAmount.mulDiv(_bountyGovernanceHAT, HUNDRED_PERCENT_SQRD);
        uint256 _hackerHatVestedAmount = _totalBountyAmount.mulDiv(_bountyHackerHATVested, HUNDRED_PERCENT_SQRD);

        _totalBountyAmount -= (_governanceHatAmount + _hackerHatVestedAmount) * HUNDRED_PERCENT;

        claimBounty.governanceHat = _governanceHatAmount;
        claimBounty.hackerHatVested = _hackerHatVestedAmount;

        uint256 _hackerVestedAmount = _totalBountyAmount.mulDiv(bountySplit.hackerVested, HUNDRED_PERCENT_SQRD);
        uint256 _hackerAmount = _totalBountyAmount.mulDiv(bountySplit.hacker, HUNDRED_PERCENT_SQRD);

        _totalBountyAmount -= (_hackerVestedAmount + _hackerAmount) * HUNDRED_PERCENT;

        claimBounty.hackerVested = _hackerVestedAmount;
        claimBounty.hacker = _hackerAmount;

        // give all the tokens left to the committee to avoid rounding errors
        claimBounty.committee = _totalBountyAmount / HUNDRED_PERCENT;
    }

    /** 
    * @dev Check that a given bounty split is legal, meaning that:
    *   Each entry is a number between 0 and `HUNDRED_PERCENT`.
    *   Except committee part which is capped at maximum of
    *   `MAX_COMMITTEE_BOUNTY`.
    *   Total splits should be equal to `HUNDRED_PERCENT`.
    * function will revert in case the bounty split is not legal.
    * @param _bountySplit The bounty split to check
    */
    function _validateSplit(IHATVault.BountySplit calldata _bountySplit) internal pure {
        if (_bountySplit.committee > MAX_COMMITTEE_BOUNTY) revert CommitteeBountyCannotBeMoreThanMax();
        if (_bountySplit.hackerVested +
            _bountySplit.hacker +
            _bountySplit.committee != HUNDRED_PERCENT)
            revert TotalSplitPercentageShouldBeHundredPercent();
    }

    /* -------------------------------------------------------------------------------- */
}