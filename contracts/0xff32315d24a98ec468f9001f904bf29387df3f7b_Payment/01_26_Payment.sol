// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { PullPaymentUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IPayment } from "./interfaces/IPayment.sol";
import { IFeeDistributor } from "./interfaces/IFeeDistributor.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { ParamEncoder } from "./libraries/ParamEncoder.sol";

error NFTItemRangeMissed(uint8[2] nftItemRange, uint256 currentNFTItemCount);
error MaxItemUsageReached(uint256 deduplicationId, uint256 currentUsage);

contract Payment is
    IPayment,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PullPaymentUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant VERSION = "1.0.0";

    IVerifier public verifier;
    IFeeDistributor public feeDistributor;
    // deduplicationId => itemUsage
    // slither-disable-next-line uninitialized-state
    mapping(uint256 => CountersUpgradeable.Counter) public itemUsages;

    event VerifierSet(IVerifier indexed verifier);
    event FeeDistributorSet(IFeeDistributor indexed feeDistributor);
    event Paid();
    event TransactionProcessed(uint256 indexed transactionId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        _asyncTransfer(msg.sender, msg.value);
    }

    function initialize(IVerifier verifier_, IFeeDistributor feeDistributor_) external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();
        PullPaymentUpgradeable.__PullPayment_init();

        verifier = verifier_;
        feeDistributor = feeDistributor_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setVerifier(IVerifier verifier_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        verifier = verifier_;
        emit VerifierSet(verifier_);
    }

    function setFeeDistributor(IFeeDistributor feeDistributor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeDistributor = feeDistributor_;
        emit FeeDistributorSet(feeDistributor_);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    function pay(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IFeeDistributor.Fee[] calldata fees,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        bytes32 hash = _payHash(transactionId, deduplicationId, maxUsage, fees, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _setItemUsage(deduplicationId, maxUsage);
        feeDistributor.distributeFees{ value: msg.value }(fees);

        emit Paid();
        emit TransactionProcessed(transactionId);
    }

    function payHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) external pure returns (bytes32) {
        return _payHash(transactionId, deduplicationId, maxUsage, fees, sender);
    }

    function _setItemUsage(uint256 deduplicationId, uint256 maxUsage) private {
        CountersUpgradeable.Counter storage currentUsage = itemUsages[deduplicationId];
        if (maxUsage != 0 && currentUsage.current() == maxUsage) {
            revert MaxItemUsageReached(deduplicationId, currentUsage.current());
        }
        currentUsage.increment();
    }

    function _payHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(transactionId, deduplicationId, maxUsage, ParamEncoder.encodeFees(fees), sender)
            );
    }
}