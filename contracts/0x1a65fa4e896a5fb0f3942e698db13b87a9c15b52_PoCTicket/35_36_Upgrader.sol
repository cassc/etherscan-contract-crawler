// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";
import {ERC4906} from "ethier/erc721/ERC4906.sol";

/**
 * @notice PROOF-issued signatures of block numbers.
 */
struct SignedBlockNumber {
    uint256 blockNumber;
    bytes signature;
}

interface UpgraderEvents {
    event TicketUpgraded(address indexed by, uint256 indexed ticketId);
}

/**
 * @title Proof of Conference Tickets - VIP Upgrades module.
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
abstract contract Upgrader is
    UpgraderEvents,
    AccessControlEnumerable,
    ERC4906
{
    using Address for address payable;
    using ECDSA for bytes;
    using ECDSA for bytes32;

    // =========================================================================
    //                           Errors
    // =========================================================================

    error ExceedingAvailableUpgrades();
    error InvalidPaymentForUpgrade(uint256 want);
    error TicketNotEligibleForUpgrade(uint256);
    error TicketAlreadyUpgraded(uint256);
    error TicketDoesNotExist(uint256);
    error IncorrectSigner();
    error CurrentlyDisabled();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The role allowed to perform manual upgrades.
     */
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /**
     * @notice Unity in fixed-point arithmetic with a 64bit decimal point.
     */
    uint256 private constant _ONE = 1 << 64;

    /**
     * @notice The probability for a free upgrade to VIP.
     * @dev Given as a 256x64bit fixed-point number.
     */
    uint256 private immutable _freeUpgradeProbability;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Flag to enable the upgrades purchase.
     */
    bool private _upgradesPurchaseOpen;

    /**
     * @notice Flag to enable the publishing of block salts to lock in random
     * upgrades.
     */
    bool private _blockSaltPublishingOpen;

    /**
     * @notice The number of upgrades sold.
     */
    uint16 private _numUpgradesSold;

    /**
     * @notice The price to purchase a VIP upgrade.
     */
    uint128 private _upgradePrice;

    /**
     * @notice The address of the PROOF-owned backend to provide salt for the
     * free upgrades randomisation.
     */
    address private _bnSigner;

    /**
     * @notice Stores purchased upgrades.
     */
    mapping(uint256 => bool) private _upgraded;

    /**
     * @notice Stores PROOF-issued salt for the free upgrades randomisation.
     */
    mapping(uint256 => bytes32) private _salts;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    /**
     * @param freeUpgradeProbabilityBasePoints_ the probability to randomly get
     * a free VIP upgrade in basis points (i.e. 1/10k).
     */
    constructor(uint256 freeUpgradeProbabilityBasePoints_, address bnSigner_) {
        _upgradesPurchaseOpen = true;
        _blockSaltPublishingOpen = true;

        _upgradePrice = 0.5 ether;

        _freeUpgradeProbability =
            (freeUpgradeProbabilityBasePoints_ * _ONE) / 10_000;
        _bnSigner = bnSigner_;
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice Returns if a ticket is upgraded to VIP.
     * @dev Includes both bought and randomly won upgrades.
     */
    function upgraded(uint256 ticketId) public view returns (bool) {
        return _upgraded[ticketId] || _hasFreeUpgrade(ticketId);
    }

    /**
     * @notice Returns if a ticket is upgradable to VIP.
     * @dev Excludes already upgraded, airdropped and inexistant tickets.
     */
    function _upgradable(uint256 ticketId) internal view returns (bool) {
        return !upgraded(ticketId) && !_airdropped(ticketId);
    }

    // =========================================================================
    //                           Purchase Upgrades
    // =========================================================================

    /**
     * @notice Purchases VIP upgrades for a list of tickets.
     * @dev Ticket ownership is not verified. Reverts if a ticket was already
     * upgraded.
     */
    function purchaseUpgrade(uint256[] calldata ticketIds)
        external
        payable
        onlyIf(_upgradesPurchaseOpen)
    {
        uint256 numUpgrades = ticketIds.length;
        // Checking this first to revert as early as possible in the case of a
        // race for tickets.
        if (_numUpgradesSold + numUpgrades > _maxUpgradesSellable()) {
            revert ExceedingAvailableUpgrades();
        }

        uint256 wantValue = numUpgrades * _upgradePrice;
        if (msg.value != wantValue) {
            revert InvalidPaymentForUpgrade(wantValue);
        }

        for (uint256 i; i < numUpgrades; ++i) {
            _doPurchaseUpgrade(ticketIds[i]);
        }
        _numUpgradesSold += uint16(numUpgrades);

        _upgradeSalesReceiver().sendValue(msg.value);
    }

    /**
     * @notice Performs the purchase of an upgrade for a given ticket.
     * @dev Reverts if the given ticket is not eligible for an upgrade according
     * to `_upgradable`.
     */
    function _doPurchaseUpgrade(uint256 ticketId) private {
        // We deliberately don't use `_upgradable` here to provide more context
        // by reverting with different errors depening on the violation.
        if (_airdropped(ticketId)) {
            revert TicketNotEligibleForUpgrade(ticketId);
        }
        _doUpgrade(ticketId);
    }

    /**
     * @notice Returns the price to purchase an upgrade.
     */
    function upgradePrice() external view returns (uint128) {
        return _upgradePrice;
    }

    /**
     * @notice Returns the number of sold VIP upgrades.
     */
    function numUpgradesSold() external view returns (uint256) {
        return _numUpgradesSold;
    }

    /**
     * @notice Returns the maximum number of upgrades that will be sold.
     */
    function maxUpgradesSellable() external view returns (uint256) {
        return _maxUpgradesSellable();
    }

    /**
     * @notice Returns flag to indicate if the upgrades purchase is enabled.
     */
    function upgradesPurchaseOpen() external view returns (bool) {
        return _upgradesPurchaseOpen;
    }

    // =========================================================================
    //                           Owner Upgrades
    // =========================================================================

    /**
     * @notice Manually upgrades a list of tickets to VIP.
     * @dev This bypasses the number of upgradable tickets.
     */
    function upgrade(uint256[] calldata ticketIds)
        external
        onlyRole(UPGRADER_ROLE)
    {
        for (uint256 i; i < ticketIds.length; ++i) {
            _doUpgrade(ticketIds[i]);
        }
    }

    /**
     * @notice Upgrades a ticket to VIP.
     * @dev Reverts if the ticket was already upgraded or does not exist.
     */
    function _doUpgrade(uint256 ticketId) private {
        if (upgraded(ticketId)) {
            revert TicketAlreadyUpgraded(ticketId);
        }
        if (!_exists(ticketId)) {
            revert TicketDoesNotExist(ticketId);
        }

        _upgraded[ticketId] = true;
        emit TicketUpgraded(msg.sender, ticketId);
        emit MetadataUpdate(ticketId);
    }

    // =========================================================================
    //                           Publishing block salts
    // =========================================================================

    /**
     * @notice Stores PROOF-issued block number signatures and locks in randomly
     * assigned free upgrades in the process.
     */
    function publishBlockSalts(SignedBlockNumber[] calldata bns)
        external
        onlyIf(_blockSaltPublishingOpen)
    {
        for (uint256 i; i < bns.length; ++i) {
            _publishBlockSalt(bns[i].blockNumber, bns[i].signature);
        }

        // Publishing block salts locks in randomised upgrades for certain
        // tickets. Since we do not keep book over the tokens that will be
        // affected we would need to trigger a collection-wide metadata refresh
        // to inform marketplaces. This can be abused because one can call this
        // method by only paying gas, which might result in rate limiting. So we
        // refrain from emitting a corresponding ERC4906 event here and emit
        // it manually on a daily basis.
    }

    /**
     * @notice Stores a PROOF-issued block number signature and locks in
     * randomly assigned free upgrades in the process.
     * @dev Reverts if the message or signer is incorrect.
     */
    function _publishBlockSalt(uint256 blockNumber, bytes calldata signature)
        private
    {
        // Already published. Reverting early in the case of multiple user
        // submissions.
        if (_salts[blockNumber] != 0) {
            return;
        }

        if (
            abi.encode(blockNumber, block.chainid).toEthSignedMessageHash()
                .recover(signature) != _bnSigner
        ) {
            revert IncorrectSigner();
        }

        _salts[blockNumber] = keccak256(signature);
    }

    /**
     * @notice Returns the salt for a given block number.
     * @dev Returns zero if nothing has been stored yet.
     */
    function _salt(uint256 blockNumber)
        internal
        view
        virtual
        returns (bytes32)
    {
        return _salts[blockNumber];
    }

    /**
     * @notice Returns flag to indicate if the interface to publish block salts
     * is enabled.
     */
    function blockSaltPublishingOpen() external view returns (bool) {
        return _blockSaltPublishingOpen;
    }

    // =========================================================================
    //                           Random Free Upgrades
    // =========================================================================

    /**
     * @notice Checks if a ticket is upgradable free of charge using a given
     * signature.
     * @dev This method is external because we will exclusively use it to inform
     * the frontend that a given signature unlocks the free upgrade for a token.
     * The eligibility does not need to be verified on the contract because the
     * upgrades are derived on-the-fly from the stored salts, effectively
     * reproducing what is checked here.
     * Once the salt for a revealBlockNumber of a given ticket was stored, this
     * function will return false since the ticket was already upgraded.
     * @param signature The signature of the revealing block number associated
     * to the ticket issued by PROOF.
     */
    function upgradableFreeOfCharge(uint256 ticketId, bytes calldata signature)
        external
        view
        returns (bool)
    {
        if (
            abi.encode(_revealBlockNumber(ticketId), block.chainid)
                .toEthSignedMessageHash().recover(signature) != _bnSigner
        ) {
            revert IncorrectSigner();
        }

        return !_upgraded[ticketId]
            && _isRandomlyUpgradedBy(ticketId, keccak256(signature))
            && _salts[_revealBlockNumber(ticketId)] == 0;
    }

    /**
     * @notice Checks if a given ticket was upgraded via the random lottery.
     */
    function _upgradedFreeOfCharge(uint256 ticketId)
        internal
        view
        returns (bool)
    {
        return !_upgraded[ticketId] && !_airdropped(ticketId)
            && _hasFreeUpgrade(ticketId);
    }

    /**
     * @notice Checks if a ticket is randomly upgraded using a provided salt.
     */
    function _isRandomlyUpgradedBy(uint256 ticketId, bytes32 salt)
        private
        view
        returns (bool)
    {
        bytes32 rand = keccak256(
            abi.encodePacked(salt, _mixHashOfTicket(ticketId), ticketId)
        );
        return uint256(rand) % _ONE < _freeUpgradeProbability;
    }

    /**
     * @notice Checks if a ticket is randomly upgraded using the stored salt.
     */
    function _hasFreeUpgrade(uint256 ticketId) internal view returns (bool) {
        if (_airdropped(ticketId)) {
            return false;
        }

        bytes32 salt = _salts[_revealBlockNumber(ticketId)];
        if (salt == 0) {
            return false;
        }

        return _isRandomlyUpgradedBy(ticketId, salt);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the PROOF-owned blocknumber signer.
     */
    function setBNSigner(address signer)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _bnSigner = signer;
    }

    /**
     * @notice Sets the price to purchase a VIP upgrade.
     */
    function setUpgradePrice(uint128 price)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _upgradePrice = price;
    }

    /**
     * @notice Enables or disables the upgrades purchase and salt publishing
     * functions.
     */
    function setUpgradesOpen(
        bool upgradesPurchaseOpen_,
        bool blockSaltPublishingOpen_
    ) external onlyRole(DEFAULT_STEERING_ROLE) {
        _upgradesPurchaseOpen = upgradesPurchaseOpen_;
        _blockSaltPublishingOpen = blockSaltPublishingOpen_;
    }

    // =========================================================================
    //                           Internal
    // =========================================================================

    /**
     * @notice Makes a function only executable if a given flag is true.
     */
    modifier onlyIf(bool activationFlag) {
        if (!activationFlag) {
            revert CurrentlyDisabled();
        }
        _;
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC4906)
        returns (bool)
    {
        return AccessControlEnumerable.supportsInterface(interfaceId)
            || ERC4906.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                           Interfacing
    // =========================================================================

    /**
     * @notice Returns the mixHash for a given block number.
     * @dev Will be provided by `Minter`.
     */
    function _mixHashOfTicket(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Returns if the given ticket was airdropped.
     * @dev Will be provided by `Minter`.
     */
    function _airdropped(uint256 ticketId)
        internal
        view
        virtual
        returns (bool);

    /**
     * @notice Returns the block number that is used to derive the salt.
     * @dev Will be provided by `PoCTicket`.
     */
    function _revealBlockNumber(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Returns the reveicer of the upgrades proceeds.
     * @dev Will be provided by `PoCTicket`.
     */
    function _upgradeSalesReceiver()
        internal
        view
        virtual
        returns (address payable);

    /**
     * @notice Returns the maximum number of sellable upgrades.
     * @dev Depends on stage. Will be provided by `PoCTicket`.
     */
    function _maxUpgradesSellable() internal view virtual returns (uint256);

    /**
     * @notice Returns if the given ticket exists.
     */
    function _exists(uint256 ticketId) internal view virtual returns (bool);
}