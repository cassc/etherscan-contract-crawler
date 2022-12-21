// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

import { IGaslessSmartWallet } from "../interfaces/IGaslessSmartWallet.sol";
import { IGSWVersionsRegistry } from "../interfaces/IGSWVersionsRegistry.sol";
import { SelfUpgradeable } from "./SelfUpgradeable.sol";
import { VariablesV1, GaslessSmartWallet__InvalidParams } from "./VariablesV1.sol";

error GaslessSmartWallet__InvalidSignature();
error GaslessSmartWallet__Expired();
error GaslessSmartWallet__Unauthorized();

/// @title  GaslessSmartWallet
/// @notice Implements meta transactions, partially aligned with EIP2770 and according to EIP712 signature
///         The `cast` method allows the owner of the wallet to execute multiple arbitrary actions
///         Relayers are expected to call the forwarder contract `execute`, which deploys a Gasless Smart Wallet if necessary first
///         Upgradeable by calling `upgradeTo` (or `upgradeToAndCall`) through a `cast` call, see SelfUpgradeable.sol
/// @dev    This contract implements parts of EIP-2770 in a minimized form. E.g. domainSeparator is immutable etc.
///         This contract does not implement ERC2771, because trusting an upgradeable "forwarder"
///         bears a security risk for this non-custodial wallet
///         This contract validates all signatures for defaultChainId of 75 instead of current block.chainid from opcode (EIP-1344)
///         For replay protection, the current block.chainid instead is used in the EIP-712 salt
///         IMPORANT to keep VariablesV1 at first inheritance to ensure proxy impl address is at 0x0
contract GaslessSmartWallet is VariablesV1, SelfUpgradeable, EIP712Upgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    /***********************************|
    |             CONSTANTS             |
    |__________________________________*/

    // constants for EIP712 values
    string public constant DOMAIN_SEPARATOR_NAME = "Instadapp-Safe";
    string public constant DOMAIN_SEPARATOR_VERSION = "1.0.0";

    /// @dev overwrite chain id for EIP712 is always set to 75
    uint256 public constant DEFAULT_CHAIN_ID = 75;

    /// @dev _TYPE_HASH is copied from EIP712Upgradeable but with added salt as last param (we use it for block.chainid)
    bytes32 public constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    /// @dev EIP712 typehash for cast calls including struct for Action
    bytes32 public constant CAST_TYPE_HASH =
        keccak256(
            "Cast(Action[] actions,uint256 validUntil,uint256 gas,address source,bytes metadata,uint256 gswNonce)Action(address target,bytes data,uint256 value)"
        );

    /// @dev EIP712 typehash for Action struct
    bytes32 public constant ACTION_TYPE_HASH = keccak256("Action(address target,bytes data,uint256 value)");

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice emitted when all actions for cast() are executed successfully
    event CastExecuted(address indexed source, address indexed caller, bytes metadata);

    /// @notice emitted if one of the actions in cast() fails
    event CastFailed(address indexed source, address indexed caller, string reason, bytes metadata);

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice                        constructor sets gswVersionsRegistry and gswForwarder (immutable).
    ///                                also see SelfUpgradeable constructor for details about setting gswVersionsRegistry
    /// @param gswVersionsRegistry_    address of the gswVersionsRegistry contract
    /// @param gswForwarder_           address of the gswForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in GSWVersionsRegistry.
    constructor(IGSWVersionsRegistry gswVersionsRegistry_, address gswForwarder_)
        VariablesV1(gswVersionsRegistry_, gswForwarder_)
    {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @inheritdoc IGaslessSmartWallet
    function initialize(address owner_) public initializer {
        // owner must be EOA
        if (owner_.isContract() || owner_ == address(0)) {
            revert GaslessSmartWallet__InvalidParams();
        }

        __EIP712_init(DOMAIN_SEPARATOR_NAME, DOMAIN_SEPARATOR_VERSION);

        owner = owner_;
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    receive() external payable {}

    /// @inheritdoc IGaslessSmartWallet
    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4Override();
    }

    /// @inheritdoc IGaslessSmartWallet
    function verify(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external view returns (bool) {
        // do not use modifier to avoid stack too deep
        _validateParams(actions_, validUntil_);

        bytes32 digest_ = _getSigDigest(actions_, validUntil_, gas_, source_, metadata_);

        if (!_verifySig(digest_, signature_)) {
            revert GaslessSmartWallet__InvalidSignature();
        }
        return true;
    }

    /// @inheritdoc IGaslessSmartWallet
    function cast(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable returns (bool success_, string memory revertReason_) {
        bool isSenderForwarder_ = msg.sender == gswForwarder;

        {
            // sender must be either owner or allowed forwarder
            if (msg.sender != owner && isSenderForwarder_ != true) {
                revert GaslessSmartWallet__Unauthorized();
            }

            // do not use modifier to avoid stack too deep
            _validateParams(actions_, validUntil_);
        }

        {
            // if cast is called through forwarder signature must be valid
            if (isSenderForwarder_) {
                bytes32 digest_ = _getSigDigest(actions_, validUntil_, gas_, source_, metadata_);

                if (!_verifySig(digest_, signature_)) {
                    revert GaslessSmartWallet__InvalidSignature();
                }
            }
        }

        // nonce increases *always* if signature is valid
        gswNonce++;

        // execute _callTargets via a low-level call to create a separate execution frame
        // this is used to revert all the actions if one action fails without reverting the whole transaction
        bytes memory result_;
        (success_, result_) = address(this).call{ value: msg.value }(
            abi.encodeCall(GaslessSmartWallet._callTargets, actions_)
        );

        if (!success_) {
            // get revert reason if available, based on https://ethereum.stackexchange.com/a/83577
            // as used by uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
            if (result_.length > 68) {
                assembly {
                    result_ := add(result_, 0x04)
                }
                revertReason_ = abi.decode(result_, (string));
                emit CastFailed(source_, msg.sender, revertReason_, metadata_);
            } else {
                emit CastFailed(source_, msg.sender, "", metadata_);
            }
        } else {
            emit CastExecuted(source_, msg.sender, metadata_);
        }

        // Logic below based on MinimalForwarderUpgradeable from openzeppelin:
        // (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/MinimalForwarder.sol)
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        if (gasleft() <= gas_ / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }
    }

    /***********************************|
    |         INDIRECT INTERNAL         |
    |__________________________________*/

    /// @dev                executes a low-level .call on all actions, can only be called by this contract
    ///                     this is called like an external call to create a separate execution frame.
    ///                     this way we can revert all the actions if one fails without reverting the whole transaction
    /// @param actions_     the actions to execute (target, data, value)
    function _callTargets(Action[] calldata actions_) external payable {
        if (msg.sender != address(this)) {
            revert GaslessSmartWallet__Unauthorized();
        }

        uint256 actionsLength_ = actions_.length;

        for (uint256 i; i < actionsLength_; ) {
            Action memory action_ = actions_[i];
            if (action_.value != 0) {
                if (address(this).balance < action_.value) {
                    revert(string.concat(i.toString(), "_GSW__INSUFFICIENT_VALUE"));
                }
            }

            // try catch does not work for .call
            (bool success_, bytes memory result_) = action_.target.call{ value: action_.value }(action_.data);

            if (!success_) {
                // get revert reason if available, based on https://ethereum.stackexchange.com/a/83577
                // as used by uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
                if (result_.length > 68) {
                    assembly {
                        result_ := add(result_, 0x04)
                    }
                    string memory revertReason_ = abi.decode(result_, (string));
                    revert(string.concat(i.toString(), string.concat("_", revertReason_)));
                } else {
                    revert(string.concat(i.toString(), "_REASON_NOT_DEFINED"));
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev                Validates input params to cast and verify calls. Reverts on invalid values.
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in,
    ///                     or 0 if request validity is not time-limited
    function _validateParams(Action[] calldata actions_, uint256 validUntil_) internal view {
        if (actions_.length == 0) {
            revert GaslessSmartWallet__InvalidParams();
        }

        // make sure request is still valid
        if (validUntil_ != 0 && validUntil_ < block.timestamp) {
            revert GaslessSmartWallet__Expired();
        }
    }

    /// @dev                Verifies a EIP712 signature
    /// @param digest_      the EIP712 digest for the signature
    /// @param signature_   the EIP712 signature, see verifySig method
    /// @return             true if the signature is valid, false otherwise
    function _verifySig(bytes32 digest_, bytes calldata signature_) internal view returns (bool) {
        address recoveredSigner_ = ECDSAUpgradeable.recover(digest_, signature_);

        return recoveredSigner_ == owner;
    }

    /// @dev                gets the digest to verify an EIP712 signature
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in,
    ///                     or 0 if request validity is not time-limited
    /// @param gas_         As EIP-2770: an amount of gas limit to set for the execution
    /// @param source_      Source like e.g. referral for this tx
    /// @param metadata_    Optional metadata for future flexibility
    /// @return             bytes32 digest to verify signature
    function _getSigDigest(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CAST_TYPE_HASH,
                        getActionsHash_(actions_),
                        validUntil_,
                        gas_,
                        source_,
                        keccak256(metadata_),
                        gswNonce
                    )
                )
            );
    }

    /// @dev                gets the keccak256 hash for actions array struct for EIP712 signature digest
    /// @param actions_     the actions to execute (target, data, value)
    /// @return             bytes32 hash for actions array struct to verify signature
    function getActionsHash_(Action[] calldata actions_) internal pure returns (bytes32) {
        // get keccak256s for actions
        uint256 actionsLength_ = actions_.length;
        bytes32[] memory keccakActions_ = new bytes32[](actionsLength_);
        for (uint256 i; i < actionsLength_; ) {
            keccakActions_[i] = keccak256(
                abi.encode(ACTION_TYPE_HASH, actions_[i].target, keccak256(actions_[i].data), actions_[i].value)
            );

            unchecked {
                ++i;
            }
        }

        return keccak256(abi.encodePacked(keccakActions_));
    }

    /// @inheritdoc EIP712Upgradeable
    /// @dev same as _hashTypedDataV4 but calls _domainSeparatorV4Override instead
    /// to build for chain id 75 and block.chainid in salt
    function _hashTypedDataV4(bytes32 structHash_) internal view override returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4Override(), structHash_);
    }

    /// @notice Returns the domain separator for the chain with id 75.
    /// @dev can not override EIP712 _domainSeparatorV4Override directly because it is not marked as virtual
    /// same as EIP712 _domainSeparatorV4Override but calls _buildDomainSeparatorOverride instead
    /// to build for chain id 75 and block.chainid in salt
    function _domainSeparatorV4Override() internal view returns (bytes32) {
        return _buildDomainSeparatorOverride(TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    /// @notice builds domain separator for EIP712 but with fixed chain id set to 75 instead of current chain
    /// @dev can not override EIP712 _buildDomainSeparatorOverride directly because it is not marked as virtual
    /// sets defaultChainId (75) instead of block.chainid for the hash, uses block.chainid in salt
    function _buildDomainSeparatorOverride(
        bytes32 typeHash_,
        bytes32 nameHash_,
        bytes32 versionHash_
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash_,
                    nameHash_,
                    versionHash_,
                    DEFAULT_CHAIN_ID,
                    address(this),
                    keccak256(abi.encodePacked(block.chainid))
                )
            );
    }
}