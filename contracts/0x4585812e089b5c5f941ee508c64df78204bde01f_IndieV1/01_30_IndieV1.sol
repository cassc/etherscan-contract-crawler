// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {AccessControlUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {ERC20Upgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {Initializable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {CountersUpgradeable} from "../lib/openzeppelin-contracts-upgradeable/contracts/utils/CountersUpgradeable.sol";

import {MerkleProofUpgradeable} from
    "../lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol";

import {IUSDC} from "../ref/IUSDC.sol";

import {IIndieV1} from "./IIndieV1.sol";
import {DEFAULT_WITHHOLDING, MAX_BATCH, MAX_SUPPLY, MAX_WITHHOLDING} from "./IndieV1Constants.sol";

contract IndieV1 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IIndieV1,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @notice Minor version
    uint256 public immutable minorVersion = 1;

    /// @notice Owner role
    bytes32 public constant OWNER_ROLE = DEFAULT_ADMIN_ROLE;

    /// @notice Admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Treasury address
    address public treasuryAddress;

    /// @notice Tax withholding address
    address public withholdingAddress;

    /// @notice USDC contract reference
    IUSDC public usdc;

    /// @notice Maximum supply of $INDIE
    uint256 public immutable maxSupply = MAX_SUPPLY;

    /// @notice Membership claim merkle root
    bytes32 internal _membershipClaimMerkleRoot;

    /// @notice Indie Status enum
    enum MemberStatus {
        UNASSIGNED,
        ACTIVE,
        INACTIVE,
        RESIGNED,
        TERMINATED
    }

    /// @notice Each indie member’s status by address
    mapping(address => MemberStatus) public statusByIndie;

    /// @notice The default withholding percentage for indie members
    uint256 internal _defaultWithholding;

    /// @notice Each indie member’s withholding by address
    mapping(address => uint256) public withholdingPercentageByIndie;

    /// @notice Tracks total USDC dividends on a seasonal basis
    mapping(uint256 => uint256) public dividendsBySeason;

    /// @notice Tracks most recent season for which there are dividends
    CountersUpgradeable.Counter internal _mostRecentSeasonId;

    /// @notice Tracks USDC net dividends held on a seasonal basis per indie member
    mapping(uint256 => mapping(address => uint256)) internal _dividendsBySeasonByIndie;

    /// @notice Tracks USDC dividends claimed on a seasonal basis per indie member
    mapping(uint256 => mapping(address => bool)) internal _dividendsClaimedBySeasonByIndie;

    /// @notice Tracks total USDC allocated to indie members
    uint256 internal _totalUnclaimedDividendsHeldForMembers;

    /**
     * @notice Disable direct initialization
     * @dev See: https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes INDIE
     * @param owner_ The owner address
     * @param admin_ The admin address
     * @param treasuryAddress_ The treasury address
     * @param withholdingAddress_ The withholding address
     * @param usdc_ The IUSDC reference
     */
    function initialize(
        address owner_,
        address admin_,
        address treasuryAddress_,
        address withholdingAddress_,
        IUSDC usdc_
    ) public virtual initializer {
        // No zeros please
        if (
            owner_ == address(0) || admin_ == address(0) || treasuryAddress_ == address(0)
                || withholdingAddress_ == address(0)
        ) {
            revert ZeroAddress();
        }

        // Inits
        __ERC20_init("Indie", "INDIE");
        __ERC20Burnable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        // Set defaults
        treasuryAddress = treasuryAddress_;
        withholdingAddress = withholdingAddress_;
        usdc = usdc_;
        _membershipClaimMerkleRoot = 0x0;
        _defaultWithholding = DEFAULT_WITHHOLDING;

        // Grant roles
        _grantRole(OWNER_ROLE, owner_);
        _grantRole(ADMIN_ROLE, admin_);
    }

    /* --------------------------- Utility -------------------------- */

    /// @inheritdoc AccessControlUpgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IIndieV1).interfaceId || super.supportsInterface(interfaceId);
    }

    /* --------------------------- Ownership -------------------------- */

    /// @inheritdoc IIndieV1
    function renounceOwnership() external virtual onlyRole(OWNER_ROLE) {
        _grantRole(OWNER_ROLE, address(0));
        _revokeRole(OWNER_ROLE, _msgSender());

        emit OwnershipRenounced(_msgSender());
    }

    /// @inheritdoc IIndieV1
    function transferOwnership(address newOwner) external virtual onlyRole(OWNER_ROLE) {
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        if (newOwner == _msgSender()) {
            revert CannotTransferOwnershipToSelf();
        }

        _grantRole(OWNER_ROLE, newOwner);
        _revokeRole(OWNER_ROLE, _msgSender());

        emit OwnershipTransferred(_msgSender(), newOwner);
    }

    /* --------------------------- Roles -------------------------- */

    /**
     * @inheritdoc AccessControlUpgradeable
     * @dev Adds an additional condition to prevent granting the owner role.
     * Ownership changes should use `transferOwnership`.
     *
     * Additional Requirements:
     *
     * - the role to be granted cannot be the owner role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        if (role == OWNER_ROLE) {
            revert CannotGrantRoleOwner();
        }

        _grantRole(role, account);
    }

    /**
     * @inheritdoc AccessControlUpgradeable
     * @dev Adds an additional condition to prevent revoking the owner role.
     * Ownership changes should use `transferOwnership` or `renounceOwnership`.
     *
     * Additional Requirements:
     *
     * - the role to be revoked cannot be the owner role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        if (role == OWNER_ROLE) {
            revert CannotRevokeRoleOwner();
        }

        _revokeRole(role, account);
    }

    /* --------------------------- Address Change -------------------------- */

    /**
     * @notice Allows the owner role to set the treasury address
     * @param newTreasuryAddress The new address to be assigned
     */
    function setTreasuryAddress(address newTreasuryAddress) external virtual onlyRole(OWNER_ROLE) {
        if (newTreasuryAddress == address(0)) {
            revert ZeroAddress();
        }

        emit TreasuryAddressChanged(treasuryAddress, newTreasuryAddress);
        treasuryAddress = newTreasuryAddress;
    }

    /**
     * @notice Allows the admin role to set the tax withholding address
     * @param newWithholdingAddress The new tax withholding address
     */
    function setWithholdingAddress(address newWithholdingAddress) external virtual onlyRole(ADMIN_ROLE) {
        if (newWithholdingAddress == address(0)) {
            revert ZeroAddress();
        }

        emit WithholdingAddressChanged(withholdingAddress, newWithholdingAddress);
        withholdingAddress = newWithholdingAddress;
    }

    /* --------------------------- Pause / Unpause -------------------------- */

    /**
     * @notice Allows the admin role to pause selected contract functions
     */
    function pause() external virtual onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Allows the admin role to pause selected contract functions
     */
    function unpause() external virtual onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /* --------------------------- Membership Claim -------------------------- */

    /**
     * @notice Allows the admin role to set the merkle root for the membership claim
     * @param merkleRoot The merkle root to be assigned
     * @dev To disable any claiming, the owner may set the root to 0x0
     */
    function setMembershipMerkleRoot(bytes32 merkleRoot) external virtual onlyRole(ADMIN_ROLE) {
        emit MembershipMerkleRootChanged(_membershipClaimMerkleRoot, merkleRoot);
        _membershipClaimMerkleRoot = merkleRoot;
    }

    /**
     * @notice Allows anyone to get the current merkle root
     * @return merkleRoot The merkle root currently assigned
     */
    function getMembershipMerkleRoot() external view virtual returns (bytes32) {
        return _membershipClaimMerkleRoot;
    }

    /**
     * @notice Allows any sender with a valid amount and proof to claim initial tokens
     * @param amount The number of tokens to claim
     * @param proof The merkle proof for the leaf that corresponds to the sender and claim amount
     * @dev Emits Claimed event
     */
    function claimMembership(uint256 amount, bytes32[] calldata proof) external virtual nonReentrant whenNotPaused {
        if (_membershipClaimMerkleRoot == 0x0) {
            revert MembershipClaimDisabled();
        }

        if (balanceOf(_msgSender()) > 0) {
            revert MembershipAlreadyClaimed();
        }

        if (amount > _remainingSupply()) {
            revert MintExceedsMaxSupply();
        }

        if (!_verified(_msgSender(), amount, proof)) {
            revert UnableToVerifyClaim();
        }

        // perform mint to new member
        emit Claimed(_msgSender(), amount);
        _mint(_msgSender(), amount);

        // update member status and set defaults
        emit MemberStatusActive(_msgSender());
        statusByIndie[_msgSender()] = MemberStatus.ACTIVE;

        emit MemberWithholdingPercentageChanged(_msgSender(), _defaultWithholding);
        withholdingPercentageByIndie[_msgSender()] = _defaultWithholding;
    }

    /* --------------------------- Indie Member Status -------------------------- */

    /**
     * @notice Allows the admin role to set indie member statuses in batches
     * @param memberAddresses An array of member addresses (token owners)
     * @param statuses An equal-length array containing the corresponding token amounts
     * @dev Batches are by batches of MAX_BATCH addresses or less
     */
    function setIndieMemberStatuses(address[] calldata memberAddresses, MemberStatus[] calldata statuses)
        external
        virtual
        onlyRole(ADMIN_ROLE)
    {
        uint256 memberLen = memberAddresses.length;

        if (memberLen != statuses.length) {
            revert UnequalArrayLengths();
        }

        // Batch to ensure that this function does not exceed ability to process
        if (memberLen > MAX_BATCH) {
            revert ArrayTooLarge();
        }

        for (uint256 i = 0; i < memberLen;) {
            if (memberAddresses[i] == address(0)) {
                revert ZeroAddress();
            }

            if (statuses[i] == MemberStatus.UNASSIGNED) {
                revert CannotUnsetMemberStatus();
            }

            if (statuses[i] == MemberStatus.RESIGNED) {
                revert CannotSetMemberStatusAsResigned();
            }

            if (statuses[i] == MemberStatus.TERMINATED) {
                revert CannotSetMemberStatusAsTerminated();
            }

            // Prevents the use of batchMint to create members without defaults
            if (balanceOf(memberAddresses[i]) == 0) {
                revert CannotSetMemberStatusForNonMember();
            }

            // Skips changes that are no difference, so that events are not emitted more than once
            if (statusByIndie[memberAddresses[i]] == statuses[i]) {
                unchecked {
                    i++;
                }
                continue;
            }

            if (statuses[i] == MemberStatus.ACTIVE) {
                emit MemberStatusActive(memberAddresses[i]);
                statusByIndie[memberAddresses[i]] = MemberStatus.ACTIVE;
            }

            if (statuses[i] == MemberStatus.INACTIVE) {
                emit MemberStatusInactive(memberAddresses[i]);
                statusByIndie[memberAddresses[i]] = MemberStatus.INACTIVE;
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Allows a member to resign their membership
     * @dev emits a MemberStatusResigned event when successful
     */
    function resign() external virtual nonReentrant {
        if (statusByIndie[_msgSender()] == MemberStatus.UNASSIGNED) {
            revert CannotSetMemberStatusAsResigned();
        }

        // Prevent resigning members from leaving orphaned dividends
        for (uint256 i = 1; i <= _mostRecentSeasonId.current();) {
            if (
                _dividendsBySeasonByIndie[i][_msgSender()] > 0
                    && _dividendsClaimedBySeasonByIndie[i][_msgSender()] != true
            ) {
                revert CannotResignWhenUnclaimedDividends();
            }

            unchecked {
                i++;
            }
        }

        emit MemberStatusResigned(_msgSender());
        _liquidate(_msgSender(), MemberStatus.RESIGNED);
    }

    /**
     * @notice Admin action to terminate a member’s membership
     * @param memberAddress The address of the member to terminate
     * @dev emits a MemberStatusTerminated event when successful
     */
    function terminate(address memberAddress) external virtual onlyRole(ADMIN_ROLE) {
        if (memberAddress == address(0)) {
            revert ZeroAddress();
        }

        uint256 unclaimedDividends = 0;

        for (uint256 i = 1; i <= _mostRecentSeasonId.current();) {
            if (
                _dividendsBySeasonByIndie[i][memberAddress] > 0
                    && _dividendsClaimedBySeasonByIndie[i][memberAddress] != true
            ) {
                unclaimedDividends = unclaimedDividends + _dividendsBySeasonByIndie[i][memberAddress];
            }

            unchecked {
                i++;
            }
        }

        emit MemberStatusTerminated(memberAddress);
        _liquidate(memberAddress, MemberStatus.TERMINATED);

        // Terminated members with unclaimed dividends forfeit them back to the treasury
        if (unclaimedDividends > 0) {
            emit TerminatedMemberDividendsReturnedToTreasury(memberAddress, unclaimedDividends);
            usdc.transfer(treasuryAddress, unclaimedDividends);
        }
    }

    /* --------------------------- Withholding -------------------------- */

    /**
     * @notice Allows the admin role to set indie member withholding percentages in batches
     * @param memberAddresses An array of member addresses to which to mint tokens
     * @param percentages An equal-length array containing the corresponding withholding percentages
     * @dev Batches are by batches of MAX_BATCH addresses or less
     */
    function setIndieWithholdingPercentages(address[] calldata memberAddresses, uint256[] calldata percentages)
        external
        virtual
        onlyRole(ADMIN_ROLE)
    {
        if (memberAddresses.length != percentages.length) {
            revert UnequalArrayLengths();
        }

        // Batch to ensure that this function does not exceed ability to process
        if (memberAddresses.length > MAX_BATCH) {
            revert ArrayTooLarge();
        }

        for (uint256 i = 0; i < memberAddresses.length;) {
            if (memberAddresses[i] == address(0)) {
                revert ZeroAddress();
            }

            if (
                statusByIndie[memberAddresses[i]] != MemberStatus.ACTIVE
                    && statusByIndie[memberAddresses[i]] != MemberStatus.INACTIVE
            ) {
                revert CannotSetIndieWithholdingForNonMember();
            }

            if (percentages[i] > MAX_WITHHOLDING) {
                revert WithholdingPercentageExceedsMaximum();
            }

            // Skips changes that are no difference, so that events are not emitted more than once
            if (withholdingPercentageByIndie[memberAddresses[i]] == percentages[i]) {
                unchecked {
                    i++;
                }
                continue;
            }

            emit MemberWithholdingPercentageChanged(memberAddresses[i], percentages[i]);
            withholdingPercentageByIndie[memberAddresses[i]] = percentages[i];

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Allows the admin role to get the default member withholding percentage
     * @return percentage The default withholding percentage
     */
    function getDefaultWithholdingPercentage() external view virtual returns (uint256) {
        return _defaultWithholding;
    }

    /**
     * @notice Allows the admin role to set the default member withholding percentage
     * @param percentage The default withholding percentage
     */
    function setDefaultWithholdingPercentage(uint256 percentage) external virtual onlyRole(ADMIN_ROLE) {
        if (percentage > MAX_WITHHOLDING) {
            revert WithholdingPercentageExceedsMaximum();
        }

        emit DefaultWithholdingPercentageChanged(_defaultWithholding, percentage);
        _defaultWithholding = percentage;
    }

    /* --------------------------- Seasonal Mint -------------------------- */

    /**
     * @notice Allows the admin role to mint tokens in batches
     * @param memberAddresses An array of member addresses to which to mint tokens
     * @param amounts An equal-length array containing the corresponding token amounts
     * @dev Batches are by batches of MAX_BATCH addresses or less
     */
    function batchMint(address[] calldata memberAddresses, uint256[] calldata amounts)
        external
        virtual
        onlyRole(ADMIN_ROLE)
    {
        if (memberAddresses.length != amounts.length) {
            revert UnequalArrayLengths();
        }

        // Batch to ensure that this function does not exceed ability to process
        if (memberAddresses.length > MAX_BATCH) {
            revert ArrayTooLarge();
        }

        for (uint256 i = 0; i < memberAddresses.length;) {
            if (memberAddresses[i] == address(0)) {
                revert ZeroAddress();
            }

            if (balanceOf(memberAddresses[i]) == 0) {
                revert CannotMintToNonMember();
            }

            if (amounts[i] == 0) {
                revert CannotMintZeroTokens();
            }

            if (amounts[i] > _remainingSupply()) {
                revert MintExceedsMaxSupply();
            }

            // ERC20 transfer event issued
            _mint(memberAddresses[i], amounts[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Returns the indie member balance, taking indie member status into account
     * @dev See {IERC20-balanceOf}.
     */
    function votingBalanceOf(address account) public view virtual returns (uint256) {
        if (statusByIndie[account] != MemberStatus.ACTIVE) {
            return 0;
        }

        return super.balanceOf(account);
    }

    /**
     * @notice Provides the number of tokens that may yet be minted
     * @return supply The remaining mintable token count
     */
    function remainingSupply() external view virtual returns (uint256 supply) {
        return _remainingSupply();
    }

    /* --------------------------- Seasonal Snapshot -------------------------- */

    /**
     * @notice Allows the admin role to create a seasonal snapshot, setting dividends
     *         and allocating them to indie members
     * @param amount The seasonal dividends to be stored and allocated
     * @param memberAddresses An array of member addresses to allocate dividends
     */
    function createSeasonSnapshot(uint256 amount, address[] calldata memberAddresses)
        external
        virtual
        onlyRole(ADMIN_ROLE)
    {
        _mostRecentSeasonId.increment();

        uint256 totalTokens = totalSupply();

        if (totalTokens == 0) {
            revert DivideByZero();
        }

        // Require at least one whole USDC token
        if (amount < 1e6) {
            revert SeasonalDividendAmountTooSmall();
        }

        // Require that the contract has already been transferred the funds
        if (amount > _getUnallocatedDividends()) {
            revert InsufficentFundsToCreateSeasonalSnapshot();
        }

        uint256 seasonId = _mostRecentSeasonId.current();
        uint256 totalSeasonalDividend = 0;
        uint256 totalSeasonalWithholding = 0;

        for (uint256 i = 0; i < memberAddresses.length;) {
            if (memberAddresses[i] == address(0)) {
                revert ZeroAddress();
            }

            uint256 memberTokenBalance = balanceOf(memberAddresses[i]);

            if (memberTokenBalance == 0) {
                revert NonMemberIncludedInSeasonalSnapshot();
            }

            if (_dividendsBySeasonByIndie[seasonId][memberAddresses[i]] > 0) {
                revert MemberDuplicatedInSeasonalSnapshot();
            }

            // We multiply before dividing to get the most accurate percentage;
            // the result is floored so we might not fully allocate the total seasonal dividend,
            // but we are then guaranteed to not exceed the total either
            uint256 memberDividend = amount * memberTokenBalance / totalTokens;

            if (memberDividend == 0) {
                // if the member dividend is zero, emit the event and skip the rest
                emit SeasonalMemberDividend(seasonId, memberAddresses[i], 0, 0);
                unchecked {
                    i++;
                }
                continue;
            }

            // We multiply before dividing to get the most accurate percentage;
            // the result is floored so we technically might not withhold quite enough,
            // but the IRS does not count decimals anyway
            uint256 memberWithholding = memberDividend * withholdingPercentageByIndie[memberAddresses[i]] / 100_00;
            uint256 memberNetDividend = memberDividend - memberWithholding;

            totalSeasonalDividend = totalSeasonalDividend + memberDividend;
            totalSeasonalWithholding = totalSeasonalWithholding + memberWithholding;

            emit SeasonalMemberDividend(seasonId, memberAddresses[i], memberNetDividend, memberWithholding);
            _dividendsBySeasonByIndie[seasonId][memberAddresses[i]] = memberNetDividend;

            unchecked {
                i++;
            }
        }

        dividendsBySeason[seasonId] = amount;

        emit SeasonalDividend(seasonId, totalSeasonalDividend, totalSeasonalWithholding);
        _totalUnclaimedDividendsHeldForMembers =
            _totalUnclaimedDividendsHeldForMembers + totalSeasonalDividend - totalSeasonalWithholding;

        if (totalSeasonalWithholding > 0) {
            usdc.transfer(withholdingAddress, totalSeasonalWithholding);
        }
    }

    /**
     * @notice Allows the admin role to get the most recent completed season
     * @return seasonId The most recent completed season for which dividends have been allocated
     */
    function getMostRecentSeason() external view virtual returns (uint256) {
        return _mostRecentSeasonId.current();
    }

    /* --------------------------- Dividends -------------------------- */

    /**
     * @notice Allows the admin role to get the total USDC allocated and held by the contract
     * @return unclaimedDividends The total USDC allocated to indie members still held by the contract
     */
    function getUnclaimedDividends() external view virtual returns (uint256) {
        return _totalUnclaimedDividendsHeldForMembers;
    }

    /**
     * @notice Allows the admin role to get the total USDC held by the contract that is unallocated
     * @return unallocatedDividends The total USDC in the contract available to allocate
     */
    function getUnallocatedDividends() external view virtual returns (uint256) {
        return _getUnallocatedDividends();
    }

    /**
     * @notice Allows the admin role to get the USDC held by the contract for a season for a member
     * @param seasonId The season id
     * @param memberAddress The address of the indie member
     * @return seasonalDividends The USDC held by the contract for a season for a member
     */
    function dividendsHeldBySeasonByMember(uint256 seasonId, address memberAddress)
        external
        view
        virtual
        returns (uint256)
    {
        return _dividendsHeldBySeasonByMember(seasonId, memberAddress);
    }

    /**
     * @notice Allows a member to claim their dividends held by the contract for a season
     * @param seasonId The season id
     */
    function claimDividendsForSeason(uint256 seasonId) external virtual nonReentrant whenNotPaused {
        if (seasonId == 0 || seasonId > _mostRecentSeasonId.current()) {
            revert SeasonIdOutOfRange();
        }

        if (statusByIndie[_msgSender()] != MemberStatus.ACTIVE) {
            revert CannotClaimDividendsWhenNotActive();
        }

        if (_dividendsClaimedBySeasonByIndie[seasonId][_msgSender()] == true) {
            revert DividendsAlreadyClaimed();
        }

        // Mark that the claim has been made
        _dividendsClaimedBySeasonByIndie[seasonId][_msgSender()] = true;

        // Emit an event and execute the transfer
        emit SeasonalMemberClaimedDividend(seasonId, _msgSender(), _dividendsBySeasonByIndie[seasonId][_msgSender()]);

        if (_dividendsBySeasonByIndie[seasonId][_msgSender()] > 0) {
            // Update the amount of dividends being held in the contract for indie members
            _totalUnclaimedDividendsHeldForMembers =
                _totalUnclaimedDividendsHeldForMembers - _dividendsBySeasonByIndie[seasonId][_msgSender()];

            usdc.transfer(_msgSender(), _dividendsBySeasonByIndie[seasonId][_msgSender()]);
        }
    }

    /* --------------------------- Transfer -------------------------- */

    /**
     * @notice Disallows all transfers between token owners
     * @dev See {ERC20Upgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0) && to != address(0) && amount > 0) {
            revert MemberToMemberTokenTransfersAreNotAllowed();
        }
    }

    /* --------------------------- Withdrawal -------------------------- */

    /**
     * @notice Withdraw ETH funds
     * @param amount The amount to withdraw
     * @param recipient The address to send the withdrawn amount to
     */
    function withdrawETH(uint256 amount, address payable recipient)
        external
        virtual
        nonReentrant
        onlyRole(OWNER_ROLE)
    {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }

        // Due to delegation, address(this) is the proxy, not the implementation
        if (recipient == address(this) || recipient == address(usdc)) {
            revert WithdrawRecipientInvalid();
        }

        if (amount <= 0 || amount > address(this).balance) {
            revert WithdrawAmountOutOfRange();
        }

        emit ETHWithdrawn(recipient, amount);

        payable(recipient).transfer(amount);
    }

    /**
     * @notice Withdraw USDC funds
     * @param amount The amount to withdraw
     * @param recipient The address to send the withdrawn amount to
     */
    function withdrawUSDC(uint256 amount, address recipient) external virtual nonReentrant onlyRole(OWNER_ROLE) {
        if (recipient == address(0)) {
            revert ZeroAddress();
        }

        // Due to delegation, address(this) is the proxy, not the implementation
        if (recipient == address(this) || recipient == address(usdc)) {
            revert WithdrawRecipientInvalid();
        }

        if (amount <= 0 || amount > usdc.balanceOf(address(this))) {
            revert WithdrawAmountOutOfRange();
        }

        emit USDCWithdrawn(recipient, amount);

        usdc.transfer(recipient, amount);
    }

    /* --------------------------- Internal -------------------------- */

    /**
     * @notice Limits upgradeability to the owner role
     * @param newImplementation The new implementation address
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(OWNER_ROLE) {}

    /**
     * @notice Tests if the sender and amount can be validated against the current merkle root
     * @param sender The sender address
     * @param amount The amount being claimed
     * @param proof The proof
     */
    function _verified(address sender, uint256 amount, bytes32[] calldata proof) internal view virtual returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(sender, amount))));

        return MerkleProofUpgradeable.verifyCalldata(proof, _membershipClaimMerkleRoot, leaf);
    }

    /**
     * @notice Provides the number of tokens that may yet be minted
     * @return supply The remaining mintable token count
     */
    function _remainingSupply() internal view virtual returns (uint256 supply) {
        return maxSupply - totalSupply();
    }

    /**
     * @notice Burns all of an indie member’s tokens and sets their status as requested
     * @param memberAddress The member address to change the status for
     * @param status The status that should be set (either RESIGNED or TERMINATED)
     */
    function _liquidate(address memberAddress, MemberStatus status) internal virtual {
        if (status != MemberStatus.RESIGNED && status != MemberStatus.TERMINATED) {
            revert CannotLiquidateUnlessResignOrTerminate();
        }

        // Do not allow indie members to resign or terminate from either
        if (
            statusByIndie[memberAddress] == MemberStatus.RESIGNED
                || statusByIndie[memberAddress] == MemberStatus.TERMINATED
        ) {
            if (status == MemberStatus.RESIGNED) {
                revert CannotSetMemberStatusAsResigned();
            }

            if (status == MemberStatus.TERMINATED) {
                revert CannotSetMemberStatusAsTerminated();
            }
        }

        // Get their current INDIE token balance and burn the tokens
        uint256 balance = balanceOf(memberAddress);

        if (balance > 0) {
            _burn(memberAddress, balance);
        }

        // And finally update their status
        statusByIndie[memberAddress] = status;
    }

    /**
     * @notice Returns the amount of USDC available for seasonal distribution as dividends
     * @return unallocatedDividends The USDC not being held for members
     */
    function _getUnallocatedDividends() internal view virtual returns (uint256) {
        return usdc.balanceOf(address(this)) - _totalUnclaimedDividendsHeldForMembers;
    }

    /**
     * @notice Returns the unclaimed dividends for the season for the member
     * @param seasonId The season to get the dividend for
     * @param memberAddress The member address
     * @return dividendAmount The USDC being held for this member for this season
     */
    function _dividendsHeldBySeasonByMember(uint256 seasonId, address memberAddress)
        internal
        view
        virtual
        returns (uint256)
    {
        if (_dividendsClaimedBySeasonByIndie[seasonId][memberAddress] == true) {
            return 0;
        }

        return _dividendsBySeasonByIndie[seasonId][memberAddress];
    }
}