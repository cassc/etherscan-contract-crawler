// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {ReceiptVaultConfig, VaultConfig, ReceiptVault, ShareAction, InvalidId} from "../receipt/ReceiptVault.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@rainprotocol/rain-protocol/contracts/tier/ITierV2.sol";
import "../receipt/IReceiptV1.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/// Thrown when the asset is NOT address zero.
error NonZeroAsset();

/// Thrown when the admin is address zero.
error ZeroAdmin();

/// Thrown when a certification reference a block number in the future that
/// cannot possibly have been seen yet.
/// @param account The certifier that attempted the certify.
/// @param referenceBlockNumber The future block number.
error FutureReferenceBlock(address account, uint256 referenceBlockNumber);

/// Thrown when a 0 certification time is attempted.
/// @param account The certifier that attempted the certify.
error ZeroCertifyUntil(address account);

/// Thrown when the `from` of a token transfer does not have the minimum tier.
/// @param from The token was transferred from this account.
/// @param reportTime The from account had this time in the tier report.
error UnauthorizedSenderTier(address from, uint256 reportTime);

/// Thrown when the `to` of a token transfer does not have the minimum tier.
/// @param to The token was transferred to this account.
/// @param reportTime The to account had this time in the tier report.
error UnauthorizedRecipientTier(address to, uint256 reportTime);

/// Thrown when a transfer is attempted by an unpriviledged account during system
/// freeze due to certification lapse.
/// @param from The account the transfer is from.
/// @param to The account the transfer is to.
/// @param certifiedUntil The (lapsed) certification time justifying the system
/// freeze.
/// @param timestamp Block timestamp of the transaction that is outside
/// certification.
error CertificationExpired(
    address from,
    address to,
    uint256 certifiedUntil,
    uint256 timestamp
);

/// All data required to configure an offchain asset vault except the receipt.
/// Typically the factory should build a receipt contract and transfer ownership
/// to the vault atomically during initialization so there is no opportunity for
/// an attacker to corrupt the initialzation process.
/// @param admin as per `OffchainAssetReceiptVaultConfig`.
/// @param vaultConfig MUST be used by the factory to build a
/// `ReceiptVaultConfig` once the receipt address is known and ownership has been
/// transferred to the vault contract (before initialization).
struct OffchainAssetVaultConfig {
    address admin;
    VaultConfig vaultConfig;
}

/// All data required to construct `OffchainAssetReceiptVault`.
/// @param admin The initial admin has ALL ROLES. It is up to the admin to
/// appropriately delegate and renounce roles or to be a smart contract with
/// formal governance processes. In general a single EOA holding all admin roles
/// is completely insecure and counterproductive as it allows a single address
/// to both mint and audit assets (and many other things).
/// @param receiptVaultConfig Forwarded to ReceiptVault.
struct OffchainAssetReceiptVaultConfig {
    address admin;
    ReceiptVaultConfig receiptVaultConfig;
}

/// @title OffchainAssetReceiptVault
/// @notice Enables curators of offchain assets to create a token that they can
/// arbitrage offchain assets against onchain assets. This allows them to
/// maintain a peg between offchain and onchain markets.
///
/// At a high level this works because the custodian can always profitably trade
/// the peg against offchain markets in both directions.
///
/// Price is higher onchain: Custodian can buy/produce assets offchain and mint
/// tokens then sell the tokens for more than the assets would sell for offchain
/// thus making a profit. The sale of the tokens brings the onchain price down.
/// Price is higher offchain: Custodian can sell assets offchain and
/// buyback+burn tokens onchain for less than the offchain sale, thus making a
/// profit. The token purchase brings the onchain price up.
///
/// In contrast to pure algorithmic tokens and sentiment based stablecoins, a
/// competent custodian can profit "infinitely" to maintain the peg no matter
/// how badly the peg breaks. As long as every token is fully collateralised by
/// liquid offchain assets, tokens can be profitably bought and burned by the
/// custodian all the way to 0 token supply.
///
/// This model is contingent on existing onchain and offchain liquidity
/// and the custodian being competent. These requirements are non-trivial. There
/// are far more incompetent and malicious custodians than competent ones. Only
/// so many bars of gold can fit in a vault, and only so many trees that can
/// live in a forest.
///
/// This contract does not attempt to solve for liquidity and trustworthyness,
/// it only seeks to provide baseline functionality that a competent custodian
/// will need to tackle the problem. The implementation provides:
///
/// - `ReceiptVault` base that allows transparent onchain/offchain audit history
/// - Certifier role that allows for audits of offchain assets that can fail
/// - KYC/membership lists that can restrict who can hold/transfer assets as
///   any Rain `ITierV2` interface
/// - Ability to comply with sanctions/regulators by confiscating assets
/// - `ERC20` shares in the vault that can be traded minted/burned to track a peg
/// - `ERC4626` compliant vault interface (inherited from `ReceiptVault`)
/// - Fine grained standard Open Zeppelin access control for all system roles
/// - Snapshots from `ReceiptVault` exposed under a role to ease potential
///   future migrations or disaster recovery plans.
contract OffchainAssetReceiptVault is ReceiptVault, AccessControl {
    using Math for uint256;

    /// Snapshot event similar to Open Zeppelin `Snapshot` event but with
    /// additional associated data as provided by the snapshotter.
    /// @param sender The `msg.sender` that triggered the snapshot.
    /// @param id The ID of the snapshot that was triggered.
    /// @param data Associated data for the snapshot that was triggered.
    event SnapshotWithData(address sender, uint256 id, bytes data);

    /// Contract has initialized.
    /// @param sender The `msg.sender` constructing the contract.
    /// @param config All initialization config.
    event OffchainAssetReceiptVaultInitialized(
        address sender,
        OffchainAssetReceiptVaultConfig config
    );

    /// A new certification time has been set.
    /// @param sender The certifier setting the new time.
    /// @param certifyUntil The time the system is newly certified until.
    /// Normally this will be a future time but certifiers MAY set it to a time
    /// in the past which will immediately freeze all transfers.
    /// @param referenceBlockNumber The block number that the auditor referenced
    /// to justify the certification.
    /// @param forceUntil Whether the certifier forced the certification time.
    /// @param data The certifier MAY provide additional supporting data such
    /// as an auditor's report/comments etc.
    event Certify(
        address sender,
        uint256 certifyUntil,
        uint256 referenceBlockNumber,
        bool forceUntil,
        bytes data
    );

    /// Shares have been confiscated from a user who is not currently meeting
    /// the ERC20 tier contract minimum requirements.
    /// @param sender The confiscator who is confiscating the shares.
    /// @param confiscatee The user who had their shares confiscated.
    /// @param confiscated The amount of shares that were confiscated.
    /// @param justification The contextual data justifying the confiscation.
    event ConfiscateShares(
        address sender,
        address confiscatee,
        uint256 confiscated,
        bytes justification
    );

    /// A receipt has been confiscated from a user who is not currently meeting
    /// the ERC1155 tier contract minimum requirements.
    /// @param sender The confiscator who is confiscating the receipt.
    /// @param confiscatee The user who had their receipt confiscated.
    /// @param id The receipt ID that was confiscated.
    /// @param confiscated The amount of the receipt that was confiscated.
    /// @param justification The contextual data justifying the confiscation.
    event ConfiscateReceipt(
        address sender,
        address confiscatee,
        uint256 id,
        uint256 confiscated,
        bytes justification
    );

    /// A new ERC20 tier contract has been set.
    /// @param sender `msg.sender` who set the new tier contract.
    /// @param tier New tier contract used for all ERC20 transfers and
    /// confiscations.
    /// @param minimumTier Minimum tier that a user must hold to be eligible
    /// to send/receive/hold shares and be immune to share confiscations.
    /// @param context OPTIONAL additional context to pass to ITierV2 calls.
    /// @param data Associated data for the change in tier config.
    event SetERC20Tier(
        address sender,
        address tier,
        uint256 minimumTier,
        uint256[] context,
        bytes data
    );

    /// A new ERC1155 tier contract has been set.
    /// @param sender `msg.sender` who set the new tier contract.
    /// @param tier New tier contract used for all ERC1155 transfers and
    /// confiscations.
    /// @param minimumTier Minimum tier that a user must hold to be eligible
    /// to send/receive/hold receipts and be immune to receipt confiscations.
    /// @param context OPTIONAL additional context to pass to ITierV2 calls.
    /// @param data Associated data for the change in tier config.
    event SetERC1155Tier(
        address sender,
        address tier,
        uint256 minimumTier,
        uint256[] context,
        bytes data
    );

    /// Rolename for certifiers.
    /// Certifier role is required to extend the `certifiedUntil` time.
    bytes32 public constant CERTIFIER = keccak256("CERTIFIER");
    /// Rolename for certifier admins.
    bytes32 public constant CERTIFIER_ADMIN = keccak256("CERTIFIER_ADMIN");

    /// Rolename for confiscator.
    /// Confiscator role is required to confiscate shares and/or receipts.
    bytes32 public constant CONFISCATOR = keccak256("CONFISCATOR");
    /// Rolename for confiscator admins.
    bytes32 public constant CONFISCATOR_ADMIN = keccak256("CONFISCATOR_ADMIN");

    /// Rolename for depositors.
    /// Depositor role is required to mint new shares and receipts.
    bytes32 public constant DEPOSITOR = keccak256("DEPOSITOR");
    /// Rolename for depositor admins.
    bytes32 public constant DEPOSITOR_ADMIN = keccak256("DEPOSITOR_ADMIN");

    /// Rolename for ERC1155 tierer.
    /// ERC1155 tierer role is required to modify the tier contract for receipts.
    bytes32 public constant ERC1155TIERER = keccak256("ERC1155TIERER");
    /// Rolename for ERC1155 tierer admins.
    bytes32 public constant ERC1155TIERER_ADMIN =
        keccak256("ERC1155TIERER_ADMIN");

    /// Rolename for ERC20 snapshotter.
    /// ERC20 snapshotter role is required to snapshot shares.
    bytes32 public constant ERC20SNAPSHOTTER = keccak256("ERC20SNAPSHOTTER");
    /// Rolename for ERC20 snapshotter admins.
    bytes32 public constant ERC20SNAPSHOTTER_ADMIN =
        keccak256("ERC20SNAPSHOTTER_ADMIN");

    /// Rolename for ERC20 tierer.
    /// ERC20 tierer role is required to modify the tier contract for shares.
    bytes32 public constant ERC20TIERER = keccak256("ERC20TIERER");
    /// Rolename for ERC20 tierer admins.
    bytes32 public constant ERC20TIERER_ADMIN = keccak256("ERC20TIERER_ADMIN");

    /// Rolename for handlers.
    /// Handler role is required to accept tokens during system freeze.
    bytes32 public constant HANDLER = keccak256("HANDLER");
    /// Rolename for handler admins.
    bytes32 public constant HANDLER_ADMIN = keccak256("HANDLER_ADMIN");

    /// Rolename for withdrawers.
    /// Withdrawer role is required to burn shares and receipts.
    bytes32 public constant WITHDRAWER = keccak256("WITHDRAWER");
    /// Rolename for withdrawer admins.
    bytes32 public constant WITHDRAWER_ADMIN = keccak256("WITHDRAWER_ADMIN");

    /// The largest issued id. The next id issued will be larger than this.
    uint256 private highwaterId;

    /// The system is certified until this timestamp. If this is in the past then
    /// general transfers of shares and receipts will fail until the system can
    /// be certified to a future time.
    uint32 private certifiedUntil;

    /// The minimum tier required for an address to receive shares.
    uint8 private erc20MinimumTier;
    /// The minimum tier required for an address to receive receipts.
    uint8 private erc1155MinimumTier;

    /// The `ITierV2` contract that defines the current tier of each address for
    /// the purpose of receiving shares.
    ITierV2 private erc20Tier;
    /// The `ITierV2` contract that defines the current tier of each address for
    /// the purpose of receiving receipts.
    ITierV2 private erc1155Tier;

    /// Optional context to provide to the `ITierV2` contract when calculating
    /// any addresses' tier for the purpose of receiving shares. Global to all
    /// addresses.
    uint256[] private erc20TierContext;
    /// Optional context to provide to the `ITierV2` contract when calculating
    /// any addresses' tier for the purpose of receiving receipts. Global to all
    /// addresses.
    uint256[] private erc1155TierContext;

    /// Initializes the initial admin and the underlying `ReceiptVault`.
    /// The admin provided will be admin of all roles and can reassign and revoke
    /// this as appropriate according to standard Open Zeppelin access control
    /// logic.
    /// @param config_ All config required to initialize.
    function initialize(
        OffchainAssetReceiptVaultConfig memory config_
    ) external initializer {
        __ReceiptVault_init(config_.receiptVaultConfig);
        __AccessControl_init();

        // There is no asset, the asset is offchain.
        if (config_.receiptVaultConfig.vaultConfig.asset != address(0)) {
            revert NonZeroAsset();
        }
        // The config admin MUST be set.
        if (config_.admin == address(0)) {
            revert ZeroAdmin();
        }

        // Define all admin roles. Note that admins can admin each other which
        // is a double edged sword. ANY admin can forcibly take over the entire
        // role by removing all other admins.
        _setRoleAdmin(CERTIFIER, CERTIFIER_ADMIN);
        _setRoleAdmin(CERTIFIER_ADMIN, CERTIFIER_ADMIN);

        _setRoleAdmin(CONFISCATOR, CONFISCATOR_ADMIN);
        _setRoleAdmin(CONFISCATOR_ADMIN, CONFISCATOR_ADMIN);

        _setRoleAdmin(DEPOSITOR, DEPOSITOR_ADMIN);
        _setRoleAdmin(DEPOSITOR_ADMIN, DEPOSITOR_ADMIN);

        _setRoleAdmin(ERC1155TIERER, ERC1155TIERER_ADMIN);
        _setRoleAdmin(ERC1155TIERER_ADMIN, ERC1155TIERER_ADMIN);

        _setRoleAdmin(ERC20SNAPSHOTTER, ERC20SNAPSHOTTER_ADMIN);
        _setRoleAdmin(ERC20SNAPSHOTTER_ADMIN, ERC20SNAPSHOTTER_ADMIN);

        _setRoleAdmin(ERC20TIERER, ERC20TIERER_ADMIN);
        _setRoleAdmin(ERC20TIERER_ADMIN, ERC20TIERER_ADMIN);

        _setRoleAdmin(HANDLER, HANDLER_ADMIN);
        _setRoleAdmin(HANDLER_ADMIN, HANDLER_ADMIN);

        _setRoleAdmin(WITHDRAWER, WITHDRAWER_ADMIN);
        _setRoleAdmin(WITHDRAWER_ADMIN, WITHDRAWER_ADMIN);

        // Grant every admin role to the configured admin.
        _grantRole(CERTIFIER_ADMIN, config_.admin);
        _grantRole(CONFISCATOR_ADMIN, config_.admin);
        _grantRole(DEPOSITOR_ADMIN, config_.admin);
        _grantRole(ERC1155TIERER_ADMIN, config_.admin);
        _grantRole(ERC20SNAPSHOTTER_ADMIN, config_.admin);
        _grantRole(ERC20TIERER_ADMIN, config_.admin);
        _grantRole(HANDLER_ADMIN, config_.admin);
        _grantRole(WITHDRAWER_ADMIN, config_.admin);

        emit OffchainAssetReceiptVaultInitialized(msg.sender, config_);
    }

    /// Apply standard transfer restrictions to receipt transfers.
    /// @inheritdoc ReceiptVault
    function authorizeReceiptTransfer(
        address from_,
        address to_
    ) external view virtual override {
        enforceValidTransfer(
            erc1155Tier,
            erc1155MinimumTier,
            erc1155TierContext,
            from_,
            to_
        );
    }

    /// DO NOT call super `_beforeDeposit` as there are no assets to move.
    /// Highwater needs to witness the incoming id.
    /// @inheritdoc ReceiptVault
    function _beforeDeposit(
        uint256,
        address,
        uint256,
        uint256 id_
    ) internal virtual override {
        highwaterId = highwaterId.max(id_);
    }

    /// DO NOT call super `_afterWithdraw` as there are no assets to move.
    /// @inheritdoc ReceiptVault
    function _afterWithdraw(
        uint256,
        address,
        address owner_,
        uint256,
        uint256 id_ //solhint-disable-next-line no-empty-blocks
    ) internal view virtual override {}

    /// Shares total supply is 1:1 with offchain assets.
    /// Assets aren't real so only way to report this is to return the total
    /// supply of shares.
    /// @inheritdoc ReceiptVault
    function totalAssets() external view virtual override returns (uint256) {
        return totalSupply();
    }

    /// @inheritdoc ReceiptVault
    function _shareRatio(
        address owner_,
        address,
        uint256 id_,
        ShareAction shareAction_
    ) internal view virtual override returns (uint256) {
        if (shareAction_ == ShareAction.Mint) {
            return
                hasRole(DEPOSITOR, owner_)
                    ? _shareRatioUserAgnostic(id_, shareAction_)
                    : 0;
        } else {
            return
                hasRole(WITHDRAWER, owner_)
                    ? _shareRatioUserAgnostic(id_, shareAction_)
                    : 0;
        }
    }

    /// IDs for offchain assets are merely autoincremented. If the minter wants
    /// to track some external ID system as a foreign key they can emit this in
    /// the associated receipt information.
    /// @inheritdoc ReceiptVault
    function _nextId() internal view virtual override returns (uint256) {
        return highwaterId + 1;
    }

    /// Depositors can increase the deposited assets for the existing id of this
    /// receipt. It is STRONGLY RECOMMENDED the redepositor also provides data to
    /// be forwarded to asset information to justify the additional deposit. New
    /// offchain assets MUST NOT redeposit under existing IDs, they MUST be
    /// deposited under a new id instead. The ID preservation provided by
    /// `redeposit` is intended to ensure a consistent audit trail for the
    /// lifecycle of any asset. We do not need a corresponding "rewithdraw"
    /// function because withdrawals already target an ID.
    ///
    /// Note that the existence of `redeposit` and `withdraw` both allow the
    /// potential of two different depositor/withdrawer accounts to apply the
    /// same mint/burn concurrently to the mempool and have both included in a
    /// block inappropriately. Features like this, as well as more fundamental
    /// trust assumptions/limitations offchain, make it impossible to fully
    /// decouple depositors and withdrawers from each other _per token_. The
    /// model is that there are many decoupled tokens each with their own "team"
    /// that can be expected to coordinate to prevent double-mint/burn.
    ///
    /// @param assets_ As per IERC4626 `deposit`.
    /// @param receiver_ As per IERC4626 `deposit`.
    /// @param id_ The existing receipt to despoit additional assets under. Will
    /// mint new ERC20 shares and also increase the held receipt amount 1:1.
    /// @param receiptInformation_ Forwarded to receipt mint and
    /// `receiptInformation`.
    /// @return shares_ As per IERC4626 `deposit`.
    function redeposit(
        uint256 assets_,
        address receiver_,
        uint256 id_,
        bytes calldata receiptInformation_
    ) external returns (uint256) {
        // Only allow redepositing for IDs that exist.
        if (id_ > highwaterId) {
            revert InvalidId(id_);
        }

        uint256 shares_ = _calculateDeposit(
            assets_,
            _shareRatio(msg.sender, receiver_, id_, ShareAction.Mint),
            0
        );

        _deposit(assets_, receiver_, shares_, id_, receiptInformation_);
        return shares_;
    }

    /// Exposes `ERC20Snapshot` from Open Zeppelin behind a role restricted call.
    /// @param data_ Associated data relevant to the snapshot.
    /// @return The snapshot ID as per Open Zeppelin.
    function snapshot(
        bytes memory data_
    ) external onlyRole(ERC20SNAPSHOTTER) returns (uint256) {
        uint256 id_ = _snapshot();
        emit SnapshotWithData(msg.sender, id_, data_);
        return id_;
    }

    /// `ERC20TIERER` Role restricted setter for all internal state that drives
    /// the erc20 tier restriction logic on transfers.
    /// @param tier_ `ITier` contract to check when receiving shares. MAY be
    /// `address(0)` to disable report checking.
    /// @param minimumTier_ The minimum tier to be held according to `tier_`.
    /// @param context_ Global context to be forwarded with tier checks.
    /// @param data_ Associated data relevant to the change in tier contract.
    function setERC20Tier(
        address tier_,
        uint8 minimumTier_,
        uint256[] calldata context_,
        bytes memory data_
    ) external onlyRole(ERC20TIERER) {
        erc20Tier = ITierV2(tier_);
        erc20MinimumTier = minimumTier_;
        erc20TierContext = context_;
        emit SetERC20Tier(msg.sender, tier_, minimumTier_, context_, data_);
    }

    /// `ERC1155TIERER` Role restricted setter for all internal state that drives
    /// the erc1155 tier restriction logic on transfers.
    /// @param tier_ `ITier` contract to check when receiving receipts. MAY be
    /// `0` to disable report checking.
    /// @param minimumTier_ The minimum tier to be held according to `tier_`.
    /// @param context_ Global context to be forwarded with tier checks.
    /// @param data_ Associated data relevant to the change in tier contract.
    function setERC1155Tier(
        address tier_,
        uint8 minimumTier_,
        uint256[] calldata context_,
        bytes memory data_
    ) external onlyRole(ERC1155TIERER) {
        erc1155Tier = ITierV2(tier_);
        erc1155MinimumTier = minimumTier_;
        erc1155TierContext = context_;
        emit SetERC1155Tier(msg.sender, tier_, minimumTier_, context_, data_);
    }

    /// Certifiers MAY EXTEND OR REDUCE the `certifiedUntil` time. If there are
    /// many certifiers, any certifier can modify the certifiation at any time.
    /// It is STRONGLY RECOMMENDED that certifiers DO NOT set the `forceUntil_`
    /// flag to `true` unless they want to:
    ///
    /// - Potentially override another certifier's concurrent certification
    /// - Reduce the certification time
    ///
    /// The certifier is STRONGLY RECOMMENDED to submit a summary report of the
    /// process and findings used to justify the modified `certifiedUntil` time.
    ///
    /// The certifier MUST provide the block number containing the information
    /// they used to perform the certification. It is entirely possible that
    /// new mints/burns and receipt information becomes available after the
    /// certification process begins, so the certifier MUST specify THEIR highest
    /// seen block at the moment they made their decision. This block cannot be
    /// in the future relative to the moment of certification.
    ///
    /// The certifier is STRONGLY RECOMMENDED to ONLY use publicly available
    /// documents directly referenced by `ReceiptInformation` events to make
    /// their decision. The certifier MUST specify if, when and why private data
    /// was used to inform their certification decision. This is critical for
    /// share holders who inform themselves on the quality of their tokens not
    /// only by the overall audit outcome, but by the integrity of the sum of its
    /// parts in the form of receipt and associated visible information.
    ///
    /// The certifier SHOULD NOT provide a certification time that predates the
    /// timestamp of the reference block, although this is NOT enforced onchain.
    /// This would imply that the system was certified until a time before the
    /// data that informed the certification even existed. DO NOT certify until
    /// a `0` time, any time in the past relative to the current time will have
    /// the same effect on the system (freezing it immediately).
    /// The reason this is NOT enforced onchain is that the certification time is
    /// a timestamp and the reference block number is a block number, these two
    /// time keeping systems are NOT directly interchangeable.
    ///
    /// Note that redundant certifications MAY be submitted. Regardless of the
    /// `forceUntil_` flag the transaction WILL NOT REVERT and the `Certify`
    /// event will be emitted for any valid `certifyUntil_` time. If certifier A
    /// certifies until time X and certifier B certifies until time X - Y then
    /// both certifications will emit an event and time X is the certifiation
    /// date of the system. This encouranges multiple certifications to be sought
    /// in parallel if it helps maintain trust in the overall system.
    ///
    /// @param certifyUntil_ The new `certifiedUntil` time.
    /// @param referenceBlockNumber_ The highest block number that the certifier
    /// has seen at the moment they decided to certify the system.
    /// @param forceUntil_ Whether to force the new certification time even if it
    /// is in the past relative to the existing certification time.
    /// @param data_ Arbitrary data justifying the certification. MAY reference
    /// data available offchain e.g. on IPFS.
    function certify(
        uint256 certifyUntil_,
        uint256 referenceBlockNumber_,
        bool forceUntil_,
        bytes calldata data_
    ) external onlyRole(CERTIFIER) {
        if (certifyUntil_ == 0) {
            revert ZeroCertifyUntil(msg.sender);
        }
        if (referenceBlockNumber_ > block.number) {
            revert FutureReferenceBlock(msg.sender, referenceBlockNumber_);
        }
        // A certifier can set `forceUntil_` to true to force a _decrease_ in
        // the `certifiedUntil` time, which is unusual but MAY need to be done
        // in the case of rectifying a prior mistake.
        if (forceUntil_ || certifyUntil_ > certifiedUntil) {
            certifiedUntil = uint32(certifyUntil_);
        }
        emit Certify(
            msg.sender,
            certifyUntil_,
            referenceBlockNumber_,
            forceUntil_,
            data_
        );
    }

    /// Reverts if some transfer is disallowed. Handles both share and receipt
    /// transfers. Standard logic reverts any transfer that is EITHER to or from
    /// an address that does not have the required tier OR the system is no
    /// longer certified therefore ALL unpriviledged transfers MUST revert.
    ///
    /// Certain exemptions to transfer restrictions apply:
    /// - If a tier contract is not set OR the minimum tier is 0 then tier
    ///   restrictions are ignored.
    /// - Any handler role MAY SEND AND RECEIVE TOKENS AT ALL TIMES BETWEEN
    ///   THEMSELVES AND ANYONE ELSE. Tier and certification restrictions are
    ///   ignored for both sender and receiver when either is a handler. Handlers
    ///   exist to _repair_ certification issues, so MUST be able to transfer
    ///   unhindered.
    /// - `address(0)` is treated as a handler for the purposes of any minting
    ///   and burning that may be required to repair certification blockers.
    /// - Transfers TO a confiscator are treated as handler-like at all times,
    ///   but transfers FROM confiscators are treated as unpriviledged. This is
    ///   to allow potential legal requirements on confiscation during system
    ///   freeze, without assigning unnecessary priviledges to confiscators.
    ///
    /// @param tier_ The tier contract to check reports against.
    /// MAY be `address(0)`.
    /// @param minimumTier_ The minimum tier to check `from_` and `to_` against.
    /// @param tierContext_ Additional context to pass to `tier_` for the report.
    /// @param from_ The token is being transferred from this account.
    /// @param to_ The token is being transferred to this account.
    function enforceValidTransfer(
        ITierV2 tier_,
        uint256 minimumTier_,
        uint256[] memory tierContext_,
        address from_,
        address to_
    ) internal view {
        // Handlers can ALWAYS send and receive funds.
        // Handlers bypass BOTH the timestamp on certification AND tier based
        // restriction.
        if (hasRole(HANDLER, from_) || hasRole(HANDLER, to_)) {
            return;
        }

        // Minting and burning is always allowed for the respective roles if they
        // interact directly with the shares/receipt. Minting and burning is ALSO
        // valid after the certification expires as it is likely the only way to
        // repair the system and bring it back to a certifiable state.
        if (
            (from_ == address(0) && hasRole(DEPOSITOR, to_)) ||
            (to_ == address(0) && hasRole(WITHDRAWER, from_))
        ) {
            return;
        }

        // Confiscation is always allowed as it likely represents some kind of
        // regulatory/legal requirement. It may also be required to satisfy
        // certification requirements.
        if (hasRole(CONFISCATOR, to_)) {
            return;
        }

        // Everyone else can only transfer while the certification is valid.
        //solhint-disable-next-line not-rely-on-time
        if (block.timestamp > certifiedUntil) {
            revert CertificationExpired(
                from_,
                to_,
                certifiedUntil,
                block.timestamp
            );
        }

        // If there is a tier contract we enforce it.
        if (address(tier_) != address(0) && minimumTier_ > 0) {
            if (from_ != address(0)) {
                // The sender must have a valid tier.
                uint256 fromReportTime_ = tier_.reportTimeForTier(
                    from_,
                    minimumTier_,
                    tierContext_
                );
                if (block.timestamp < fromReportTime_) {
                    revert UnauthorizedSenderTier(from_, fromReportTime_);
                }
            }

            if (to_ != address(0)) {
                // The recipient must have a valid tier.
                uint256 toReportTime_ = tier_.reportTimeForTier(
                    to_,
                    minimumTier_,
                    tierContext_
                );
                if (block.timestamp < toReportTime_) {
                    revert UnauthorizedRecipientTier(to_, toReportTime_);
                }
            }
        }
    }

    /// Apply standard transfer restrictions to share transfers.
    /// @inheritdoc ReceiptVault
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual override {
        enforceValidTransfer(
            erc20Tier,
            erc20MinimumTier,
            erc20TierContext,
            from_,
            to_
        );
        super._beforeTokenTransfer(from_, to_, amount_);
    }

    /// Confiscators can confiscate ERC20 vault shares from `confiscatee_`.
    /// Confiscation BYPASSES TRANSFER RESTRICTIONS due to system freeze and
    /// IGNORES ALLOWANCES set by the confiscatee.
    ///
    /// The LIMITATION ON CONFISCATION is that the confiscatee MUST NOT have the
    /// minimum tier for transfers. I.e. confiscation is a two step process.
    /// First the tokens must be frozen according to due process by the token
    /// issuer (which may be an individual, organisation or many entities), THEN
    /// the confiscation can clear. This prevents rogue/compromised confiscators
    /// from being able to arbitrarily take tokens from users to themselves. At
    /// the least, assuming separate private keys managing the tiers and
    /// confiscation, the two steps require at least two critical security
    /// breaches per attack rather than one.
    ///
    /// Confiscation is a binary event. All shares or zero shares are
    /// confiscated from the confiscatee.
    ///
    /// Typically people DO NOT LIKE having their assets confiscated. It SHOULD
    /// be treated as a rare and extreme action, only taken when all other
    /// avenues/workarounds are explored and exhausted. The confiscator SHOULD
    /// provide their justification of each confiscation, and the general public,
    /// especially token holders SHOULD review and be highly suspect of unjust
    /// confiscation events. If you review and DO NOT agree with a confiscation
    /// you SHOULD NOT continue to hold the token, exiting systems that play fast
    /// and loose with user assets is the ONLY way to discourage such behaviour.
    ///
    /// @param confiscatee_ The address that shares are being confiscated from.
    /// @param data_ The associated justification of the confiscation, and/or
    /// other relevant data.
    /// @return The amount of shares confiscated.
    function confiscateShares(
        address confiscatee_,
        bytes memory data_
    ) external nonReentrant onlyRole(CONFISCATOR) returns (uint256) {
        uint256 confiscatedShares_ = 0;
        if (
            address(erc20Tier) == address(0) ||
            block.timestamp <
            erc20Tier.reportTimeForTier(
                confiscatee_,
                erc20MinimumTier,
                erc20TierContext
            )
        ) {
            confiscatedShares_ = balanceOf(confiscatee_);
            if (confiscatedShares_ > 0) {
                emit ConfiscateShares(
                    msg.sender,
                    confiscatee_,
                    confiscatedShares_,
                    data_
                );
                _transfer(confiscatee_, msg.sender, confiscatedShares_);
            }
        }
        return confiscatedShares_;
    }

    /// Confiscators can confiscate ERC1155 vault receipts from `confiscatee_`.
    /// The process, limitations and logic is identical to share confiscation
    /// except that receipt confiscation is performed per-ID.
    ///
    /// Typically people DO NOT LIKE having their assets confiscated. It SHOULD
    /// be treated as a rare and extreme action, only taken when all other
    /// avenues/workarounds are explored and exhausted. The confiscator SHOULD
    /// provide their justification of each confiscation, and the general public,
    /// especially token holders SHOULD review and be highly suspect of unjust
    /// confiscation events. If you review and DO NOT agree with a confiscation
    /// you SHOULD NOT continue to hold the token, exiting systems that play fast
    /// and loose with user assets is the ONLY way to discourage such behaviour.
    ///
    /// @param confiscatee_ The address that receipts are being confiscated from.
    /// @param id_ The ID of the receipt to confiscate.
    /// @param data_ The associated justification of the confiscation, and/or
    /// other relevant data.
    /// @return The amount of receipt confiscated.
    function confiscateReceipt(
        address confiscatee_,
        uint256 id_,
        bytes memory data_
    ) external nonReentrant onlyRole(CONFISCATOR) returns (uint256) {
        uint256 confiscatedReceiptAmount_ = 0;
        if (
            address(erc1155Tier) == address(0) ||
            block.timestamp <
            erc1155Tier.reportTimeForTier(
                confiscatee_,
                erc1155MinimumTier,
                erc1155TierContext
            )
        ) {
            IReceiptV1 receipt_ = _receipt;
            confiscatedReceiptAmount_ = receipt_.balanceOf(confiscatee_, id_);
            if (confiscatedReceiptAmount_ > 0) {
                emit ConfiscateReceipt(
                    msg.sender,
                    confiscatee_,
                    id_,
                    confiscatedReceiptAmount_,
                    data_
                );
                receipt_.ownerTransferFrom(
                    confiscatee_,
                    msg.sender,
                    id_,
                    confiscatedReceiptAmount_,
                    ""
                );
            }
        }
        return confiscatedReceiptAmount_;
    }
}