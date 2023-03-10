// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/proxy/Clones.sol";
import "openzeppelin-contracts/proxy/utils/Initializable.sol";

/**
 * @title Clonable.sol
 * @author spacebunny @ Bunny Labs
 * @notice Contract for adding low-gas cloning support to smart contracts using [EIP-1167 minimal proxy contracts](https://eips.ethereum.org/EIPS/eip-1167).
 */

abstract contract Clonable is Initializable {
    //*******//
    // Types //
    //*******//

    /// Thrown when `feeBps` is set to >100%.
    error FeeBpsTooHigh();
    /// Thrown when functions that are meant to be called by the contract author are called by third parties.
    error AuthorOnly();
    /// Thrown when excess cloning fee cannot be refunded to the caller.
    error RefundFailed();
    /// Thrown when cloning fees cannot be transferred to the recipient.
    error FeeTransferFailed();
    /// Thrown when transaction value is set too low to cover cloning fees.
    error MsgValueTooLow();
    /// Thrown when functions that are meant to be called on the original contract are called on clones.
    error NotCallableOnClones();
    /// Thrown when functions that are meant to be called by the original contract are called by third parties.
    error OriginalContractOnly();

    /// Emitted when a new clone is deployed.
    event Cloned(address to, uint256 fee, address feeRecipient);

    /// Struct for cloning-related configuration.
    struct CloningConfig {
        /// Contract author, allowed to update cloning configuration.
        address author;
        /// The share of cost savings from cloning to charge as fees, in basis points.
        uint256 feeBps;
        /// The address that should receive cloning fees.
        address feeRecipient;
    }

    //***********//
    // Variables //
    //***********//

    /// Size of the minimal proxy bytecode deployed for clones, in bytes.
    uint256 constant CLONE_CODE_SIZE = 45;

    /// Basis for calculating cloning fees.
    /// A `CLONING_FEE_BASIS` of 10 000 (=100%) means that `feeBps` of 100 bps = 1% fees.
    uint256 public constant CLONING_FEE_BASIS = 10_000;

    /// Gas cost for storing 1 byte of contract bytecode on-chain, as specified in the [Ethereum yellow paper](https://ethereum.github.io/yellowpaper/paper.pdf).
    uint256 constant CODE_DEPOSIT_GAS_COST = 200;

    /// Version of the `Clonable` base contract ABI in the `<MAJOR>_<MINOR>` format.
    /// @dev Increment `MAJOR` for backwards-incompatible changes and `MINOR` for the rest.
    uint256 public constant CLONABLE_ABI_VERSION = 1_01;

    /// Cloning configuration.
    CloningConfig private _config;

    /// Reference to the original contract.
    /// @dev Set once during deployment of the original, accessible from all clones.
    Clonable private immutable _original;

    //****************//
    // Initialization //
    //****************//

    /**
     * Constructor for the original (non-clone) contract instance.
     * @param config The initial cloning configuration to use.
     */
    constructor(CloningConfig memory config) initializer {
        _original = this;
        _updateCloningConfig(config);
    }

    /**
     * Public initializer for cloned contracts.
     * @dev This is a wrapper to set up a common interface for initializing clones. Contract-specific initialization should be implemented in the _initialize(bytes) function.
     * @param initdata Contract initialization data, encoded as bytes.
     */
    function initializeClone(bytes memory initdata) external initializer {
        if (msg.sender != address(_original)) {
            revert OriginalContractOnly();
        }

        _initialize(initdata);
    }

    /**
     * Internal function for performing the actual initialization work.
     * @dev Must be implemented in contracts inheriting from `Clonable`.
     * @param initdata Contract initialization data, encoded as bytes.
     */
    function _initialize(bytes memory initdata) internal virtual;

    //****************//
    // View functions //
    //****************//

    /**
     * Get the cloning configuration for this contract.
     * @dev Can be called on the original contract or any clone.
     */
    function cloningConfig() public view returns (CloningConfig memory) {
        if (_isClone()) return _original.cloningConfig();
        return _config;
    }

    /**
     * Get the cloning fee based on the current block basefee.
     * @dev When cloning, add a buffer on top of this to avoid reverts from block fee fluctuations. Any excess ether will be refunded.
     */
    function cloningFee() public view returns (uint256) {
        uint256 codesizeDelta = (address(_original).code.length - CLONE_CODE_SIZE);
        uint256 gasSavings = codesizeDelta * CODE_DEPOSIT_GAS_COST;

        // block.basefee is used to improve cloning fee predictability.
        uint256 costSavings = gasSavings * block.basefee;

        return (((costSavings * cloningConfig().feeBps) / 1 gwei) * 1 gwei) / CLONING_FEE_BASIS;
    }

    //*********//
    // Cloning //
    //*********//

    /**
     * Deploy a clone of this contract.
     * @param initdata Contract initialization data, encoded as bytes.
     */
    function clone(bytes memory initdata) public payable returns (address) {
        uint256 collectedFee = cloningFee();
        _preCloningHook(collectedFee);

        if (_isClone()) return _original.clone{value: collectedFee}(initdata);
        address cloneAddress = Clones.clone(address(_original));

        return _postCloningHook(cloneAddress, initdata, collectedFee);
    }

    /**
     * Deploy a clone of this contract with a deterministic address.
     * @param initdata Contract initialization data, encoded as bytes.
     */
    function cloneDeterministic(bytes memory initdata, bytes32 salt) public payable returns (address) {
        uint256 collectedFee = cloningFee();
        _preCloningHook(collectedFee);

        if (_isClone()) return _original.cloneDeterministic{value: collectedFee}(initdata, salt);
        address cloneAddress = Clones.cloneDeterministic(address(_original), salt);

        return _postCloningHook(cloneAddress, initdata, collectedFee);
    }

    /**
     * Update cloning configuration
     * @dev Callable on the original contract and by the contract author only.
     */
    function updateCloningConfig(CloningConfig memory config) public {
        if (_isClone()) revert NotCallableOnClones();
        if (msg.sender != _config.author) revert AuthorOnly();
        _updateCloningConfig(config);
    }

    //***********//
    // Internals //
    //***********//

    /**
     * @dev This hook executes before cloning both in cloned and original contract contexts.
     * @param collectedFee The fee that will get charged for deploying the clone.
     */
    function _preCloningHook(uint256 collectedFee) internal {
        // Check msg.value and issue a refund (if needed) as the first thing.
        // This way we can just refund msg.sender and don't have to pass caller
        // to the original contract.
        if (msg.value < collectedFee) revert MsgValueTooLow();
        if (msg.value > collectedFee) _refundExcess(collectedFee);
    }

    /**
     * @dev This hook executes after clonign and only in original contract contexts.
     * @param cloneAddress The address of the clone that was created.
     * @param initdata The initialization data that should be forwarded to the newly created clone.
     * @param collectedFee The fee that was charged for deploying the clone.
     */
    function _postCloningHook(address cloneAddress, bytes memory initdata, uint256 collectedFee)
        internal
        returns (address)
    {
        Clonable(cloneAddress).initializeClone(initdata);

        (bool success,) = _config.feeRecipient.call{value: collectedFee}("");
        if (!success) revert FeeTransferFailed();

        emit Cloned(cloneAddress, collectedFee, _config.feeRecipient);
        return cloneAddress;
    }

    /**
     * Check if the current contract is a clone.
     */
    function _isClone() internal view returns (bool) {
        return this != _original;
    }

    /**
     * Refund msg.value in excess of a specified amount.
     * @param collectedFee The amount of ether to keep.
     */
    function _refundExcess(uint256 collectedFee) private {
        uint256 refund = msg.value - collectedFee;
        (bool success,) = msg.sender.call{value: refund}("");
        if (!success) revert RefundFailed();
    }

    /**
     * Internal method for validating and updating cloning configuration.
     */
    function _updateCloningConfig(CloningConfig memory config) private {
        if (config.feeBps > CLONING_FEE_BASIS) revert FeeBpsTooHigh();
        _config = config;
    }
}