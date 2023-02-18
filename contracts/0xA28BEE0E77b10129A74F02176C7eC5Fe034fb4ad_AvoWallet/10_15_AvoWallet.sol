// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import { IAvoWallet } from "../interfaces/IAvoWallet.sol";
import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { InstaFlashReceiverInterface } from "../external/InstaFlashReceiverInterface.sol";
import { SelfUpgradeable } from "./SelfUpgradeable.sol";
import { VariablesV1, AvoWallet__InvalidParams } from "./VariablesV1.sol";

/// @title  AvoWallet
/// @notice Smart wallet supporting meta transactions with EIP712 signature. Supports receiving NFTs.
///         The `cast` method allows the owner of the wallet to execute multiple arbitrary actions
///         Relayers are expected to call the forwarder contract `execute`, which deploys an AvoWallet if necessary first.
///         Upgradeable by calling `upgradeTo` (or `upgradeToAndCall`) through a `cast` call, see SelfUpgradeable.sol
/// @dev    This contract implements parts of EIP-2770 in a minimized form. E.g. domainSeparator is immutable etc.
///         This contract does not implement ERC2771, because trusting an upgradeable "forwarder"
///         bears a security risk for this non-custodial wallet
///         This contract validates all signatures for defaultChainId of 634 instead of current block.chainid from opcode (EIP-1344)
///         For replay protection, the current block.chainid instead is used in the EIP-712 salt
///         IMPORANT to keep VariablesV1 at first inheritance to ensure proxy impl address is at 0x0
/// @dev    Note For any new implementation, the upgrade method MUST be in the implementation itself,
///         otherwise it can not be upgraded anymore! also see SelfUpgradeable
contract AvoWallet is
    VariablesV1,
    SelfUpgradeable,
    EIP712Upgradeable,
    ERC721HolderUpgradeable,
    InstaFlashReceiverInterface
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    /***********************************|
    |               ERRORS              |
    |__________________________________*/

    error AvoWallet__InvalidSignature();
    error AvoWallet__Expired();
    error AvoWallet__Unauthorized();
    error AvoWallet__InsufficientGasSent();
    error AvoWallet__OutOfGas();

    /***********************************|
    |             CONSTANTS             |
    |__________________________________*/

    // constants for EIP712 values
    string public constant DOMAIN_SEPARATOR_NAME = "Avocado-Safe";
    string public constant DOMAIN_SEPARATOR_VERSION = "1.1.0";

    /// @dev overwrite chain id for EIP712 is always set to 634
    uint256 public constant DEFAULT_CHAIN_ID = 634;

    /// @dev _TYPE_HASH is copied from EIP712Upgradeable but with added salt as last param (we use it for block.chainid)
    bytes32 public constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)");

    /// @dev EIP712 typehash for cast calls including struct for Action
    bytes32 public constant CAST_TYPE_HASH =
        keccak256(
            "Cast(Action[] actions,uint256 validUntil,uint256 gas,address source,uint256 id,bytes metadata,uint256 avoSafeNonce)Action(address target,bytes data,uint256 value)"
        );

    /// @dev EIP712 typehash for Action struct
    bytes32 public constant ACTION_TYPE_HASH = keccak256("Action(address target,bytes data,uint256 value)");

    /// @dev amount of gas to keep in cast caller method as reserve for emitting CastFailed event
    uint256 private constant CAST_RESERVE_GAS = 9000;

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice emitted when all actions for cast() are executed successfully
    event CastExecuted(address indexed source, address indexed caller, bytes metadata);

    /// @notice emitted if one of the actions in cast() fails. reason will be prefixed with the index of the action.
    /// e.g. if action 1 fails, then the reason will be 1_reason
    /// if an action in the flashloan callback fails, it will be prefixed with with two numbers:
    /// e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails, the reason will be 1_2_reason
    event CastFailed(address indexed source, address indexed caller, string reason, bytes metadata);

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice                        constructor sets avoVersionsRegistry and avoForwarder (immutable).
    ///                                also see SelfUpgradeable constructor for details about setting avoVersionsRegistry
    /// @param avoVersionsRegistry_    address of the avoVersionsRegistry contract
    /// @param avoForwarder_           address of the avoForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in AvoVersionsRegistry.
    constructor(IAvoVersionsRegistry avoVersionsRegistry_, address avoForwarder_)
        VariablesV1(avoVersionsRegistry_, avoForwarder_)
    {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @inheritdoc IAvoWallet
    function initialize(address owner_) public initializer {
        // owner must be EOA
        if (owner_.isContract() || owner_ == address(0)) {
            revert AvoWallet__InvalidParams();
        }

        __EIP712_init(DOMAIN_SEPARATOR_NAME, DOMAIN_SEPARATOR_VERSION);

        owner = owner_;
    }

    /// @inheritdoc IAvoWallet
    function initializeWithVersion(address owner_, address avoWalletVersion_) public initializer {
        // owner must be EOA
        if (owner_.isContract() || owner_ == address(0)) {
            revert AvoWallet__InvalidParams();
        }

        __EIP712_init(DOMAIN_SEPARATOR_NAME, DOMAIN_SEPARATOR_VERSION);

        owner = owner_;

        _avoWalletImpl = avoWalletVersion_;
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    receive() external payable {}

    /// @inheritdoc IAvoWallet
    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4Override();
    }

    /// @inheritdoc IAvoWallet
    function verify(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        uint256 id_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external view returns (bool) {
        // do not use modifier to avoid stack too deep
        _validateParams(actions_, validUntil_);

        bytes32 digest_ = _getSigDigest(actions_, validUntil_, gas_, source_, id_, metadata_);

        if (!_verifySig(digest_, signature_)) {
            revert AvoWallet__InvalidSignature();
        }
        return true;
    }

    /// @inheritdoc IAvoWallet
    function cast(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        uint256 id_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable returns (bool success_, string memory revertReason_) {
        {
            if (msg.sender == avoForwarder) {
                // if sender is forwarder, first thing we must do is compare actual sent gas to user instructed gas
                // adding 500 to gasleft for approx. already used gas
                if ((gasleft() + 500) < gas_) {
                    // relayer has not sent enough gas to cover gas limit as user instructed
                    revert AvoWallet__InsufficientGasSent();
                }

                _validateParams(actions_, validUntil_);

                // if cast is called through forwarder signature must be valid
                bytes32 digest_ = _getSigDigest(actions_, validUntil_, gas_, source_, id_, metadata_);

                if (!_verifySig(digest_, signature_)) {
                    revert AvoWallet__InvalidSignature();
                }
            } else if (msg.sender == owner) {
                _validateParams(actions_, validUntil_);
            } else {
                // sender must be either owner or allowed forwarder
                revert AvoWallet__Unauthorized();
            }
        }

        // set status verified to 1 for call to _callTargets to avoid having to check signature etc. again
        _status = 1;

        // nonce increases *always* if signature is valid
        avoSafeNonce++;

        // execute _callTargets via a low-level call to create a separate execution frame
        // this is used to revert all the actions if one action fails without reverting the whole transaction
        bytes memory calldata_ = abi.encodeCall(AvoWallet._callTargets, (actions_, id_));
        bytes memory result_;
        // using inline assembly for delegatecall to define custom gas amount that should stay here in caller
        assembly {
            success_ := delegatecall(
                // reserve at least ~9k gas to make sure we can emit CastFailed event even for out of gas cases
                sub(gas(), CAST_RESERVE_GAS),
                sload(_avoWalletImpl.slot),
                add(calldata_, 0x20),
                mload(calldata_),
                0,
                0
            )
            let size := returndatasize()

            result_ := mload(0x40)
            mstore(0x40, add(result_, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(result_, size)
            returndatacopy(add(result_, 0x20), 0, size)
        }

        if (!success_) {
            if (result_.length == 0) {
                // @dev this case might be caused by edge-case out of gas errors that we were unable to catch
                // but could potentially also have other reasons
                revertReason_ = "AVO__REASON_NOT_DEFINED";
            } else if (bytes4(result_) == bytes4(0x8707015b)) {
                // 0x8707015b = selector for custom error AvoWallet__OutOfGas
                revertReason_ = "AVO__OUT_OF_GAS";
            } else {
                assembly {
                    result_ := add(result_, 0x04)
                }
                revertReason_ = abi.decode(result_, (string));
            }

            emit CastFailed(source_, msg.sender, revertReason_, metadata_);
        } else {
            emit CastExecuted(source_, msg.sender, metadata_);
        }
    }

    /***********************************|
    |         FLASHLOAN CALLBACK        |
    |__________________________________*/

    /// @dev                 callback used by Instadapp Flashloan Aggregator, executes operations while owning
    ///                      the flashloaned amounts. data_ must contain actions, one of them must pay back flashloan
    // /// @param assets_       assets_ received a flashloan for
    // /// @param amounts_      flashloaned amounts for each asset
    // /// @param premiums_     fees to pay for the flashloan
    /// @param initiator_    flashloan initiator -> must be this contract
    /// @param data_         data bytes containing the abi.encoded actions that are executed similarly to .callTargets
    function executeOperation(
        address[] calldata, /*  assets_ */
        uint256[] calldata, /*  amounts_ */
        uint256[] calldata, /*  premiums_ */
        address initiator_,
        bytes calldata data_
    ) external returns (bool) {
        // @dev using the valid case inverted via one ! instead of invalid case with 3 ! to optimize gas usage
        if (!((_status == 20 || _status == 21) && initiator_ == address(this))) {
            revert AvoWallet__Unauthorized();
        }

        // _status is set to original id_ pre-flashloan trigger in _callTargets
        uint256 id_ = _status;

        // reset status immediately
        _status = 0;

        // decode actions to be executed after getting the flashloan
        Action[] memory actions_ = abi.decode(data_, (Action[]));

        StorageSnapshot memory storageSnapshot_;
        if (id_ == 21) {
            // store values before execution to make sure storage vars are not modified by a delegatecall
            storageSnapshot_.owner = owner;
            storageSnapshot_.avoWalletImpl = _avoWalletImpl;
            storageSnapshot_.avoSafeNonce = avoSafeNonce;
        }

        uint256 actionsLength_ = actions_.length;
        for (uint256 i; i < actionsLength_; ) {
            Action memory action_ = actions_[i];

            // execute action
            bool success_;
            bytes memory result_;
            if (action_.operation == 0) {
                // no enforcing of id_ needed here because code would revert earlier if id is not 20 or 21
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else if (action_.operation == 1 && id_ == 21) {
                // delegatecall (operation =1 & id = mixed)
                (success_, result_) = action_.target.delegatecall(action_.data);
            } else {
                // either operation does not exist or the id was not set according to what the action wants to execute
                if (action_.operation > 2) {
                    revert(string.concat(i.toString(), "_AVO__OPERATION_NOT_EXIST"));
                } else if (action_.operation == 2) {
                    revert(string.concat(i.toString(), "_AVO__NO_FLASHLOAN_IN_FLASHLOAN"));
                } else {
                    // enforce that id must be set according to operation
                    revert(string.concat(i.toString(), "_AVO__ID_ACTION_MISMATCH"));
                }
            }

            if (!success_) {
                revert(string.concat(i.toString(), _getRevertReasonFromReturnedData(result_)));
            }

            unchecked {
                ++i;
            }
        }

        // if actions include delegatecall, make sure storage was not modified
        if (
            (storageSnapshot_.avoSafeNonce > 0) &&
            !(storageSnapshot_.avoWalletImpl == _avoWalletImpl &&
                storageSnapshot_.owner == owner &&
                storageSnapshot_.avoSafeNonce == avoSafeNonce &&
                _status == 0)
        ) {
            revert("AVO__MODIFIED_STORAGE");
        }

        return true;
    }

    /***********************************|
    |         INDIRECT INTERNAL         |
    |__________________________________*/

    /// @dev                  executes a low-level .call or .delegateCall on all actions, can only be called by this contract
    ///                       this is called like an external call to create a separate execution frame.
    ///                       this way we can revert all the actions if one fails without reverting the whole transaction
    /// @param actions_       the actions to execute (target, data, value)
    /// @param id_            id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable {
        // status must be verified or 0x000000000000000000000000000000000000dEaD used for backend gas estimations
        if (!(_status == 1 || tx.origin == 0x000000000000000000000000000000000000dEaD)) {
            revert AvoWallet__Unauthorized();
        }

        bool isCallId_ = id_ < 2 || id_ == 20 || id_ == 21;
        bool isDelegateCallId_ = id_ == 1 || id_ == 21;

        // reset status immediately
        _status = 0;

        StorageSnapshot memory storageSnapshot_;
        if (isDelegateCallId_) {
            // store values before execution to make sure storage vars are not modified by a delegatecall
            storageSnapshot_.owner = owner;
            storageSnapshot_.avoWalletImpl = _avoWalletImpl;
            storageSnapshot_.avoSafeNonce = avoSafeNonce;
        }

        uint256 actionsLength_ = actions_.length;
        for (uint256 i; i < actionsLength_; ) {
            Action memory action_ = actions_[i];

            // execute action
            bool success_;
            bytes memory result_;
            uint256 actionMinGasLeft_;
            if (action_.operation == 0 && isCallId_) {
                // call (operation =0 & id = call or mixed)
                // @dev try catch does not work for .call
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    actionMinGasLeft_ = gasleft() / 64;
                }
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else if (action_.operation == 1 && isDelegateCallId_) {
                // delegatecall (operation =1 & id = delegateCall(1) or mixed(2))
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    actionMinGasLeft_ = gasleft() / 64;
                }
                (success_, result_) = action_.target.delegatecall(action_.data);
            } else if (action_.operation == 2 && (id_ == 20 || id_ == 21)) {
                // flashloan is always execute via .call, flashloan aggregator uses msg.sender, so .delegatecall
                // wouldn't send funds to this contract but rather to the original sender
                _status = uint8(id_);
                unchecked {
                    // store amount of gas that stays with caller, according to EIP150 to detect out of gas errors
                    actionMinGasLeft_ = gasleft() / 64;
                }
                (success_, result_) = action_.target.call{ value: action_.value }(action_.data);
            } else {
                // either operation does not exist or the id was not set according to what the action wants to execute
                if (action_.operation > 2) {
                    revert(string.concat(i.toString(), "_AVO__OPERATION_NOT_EXIST"));
                } else {
                    // enforce that id must be set according to operation
                    revert(string.concat(i.toString(), "_AVO__ID_ACTION_MISMATCH"));
                }
            }

            if (!success_) {
                if (gasleft() < actionMinGasLeft_) {
                    // action ran out of gas, trigger revert with specific custom error
                    revert AvoWallet__OutOfGas();
                }

                revert(string.concat(i.toString(), _getRevertReasonFromReturnedData(result_)));
            }

            unchecked {
                ++i;
            }
        }

        // if actions include delegatecall, make sure storage was not modified
        if (
            (storageSnapshot_.avoSafeNonce > 0) &&
            !(storageSnapshot_.avoWalletImpl == _avoWalletImpl &&
                storageSnapshot_.owner == owner &&
                storageSnapshot_.avoSafeNonce == avoSafeNonce &&
                _status == 0)
        ) {
            revert("AVO__MODIFIED_STORAGE");
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
            revert AvoWallet__InvalidParams();
        }

        // make sure request is still valid
        if (validUntil_ > 0 && validUntil_ < block.timestamp) {
            revert AvoWallet__Expired();
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

    /// @dev                  gets the digest to verify an EIP712 signature
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in,
    ///                       or 0 if request validity is not time-limited
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    /// @param source_        Source like e.g. referral for this tx
    /// @param id_            id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @param metadata_      Optional metadata for future flexibility
    /// @return               bytes32 digest to verify signature
    function _getSigDigest(
        Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        uint256 id_,
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
                        id_,
                        keccak256(metadata_),
                        avoSafeNonce
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
    /// to build for chain id 634 and block.chainid in salt
    function _hashTypedDataV4(bytes32 structHash_) internal view override returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4Override(), structHash_);
    }

    /// @notice Returns the domain separator for the chain with id 634.
    /// @dev can not override EIP712 _domainSeparatorV4Override directly because it is not marked as virtual
    /// same as EIP712 _domainSeparatorV4Override but calls _buildDomainSeparatorOverride instead
    /// to build for chain id 634 and block.chainid in salt
    function _domainSeparatorV4Override() internal view returns (bytes32) {
        return _buildDomainSeparatorOverride(TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    /// @notice builds domain separator for EIP712 but with fixed chain id set to 634 instead of current chain
    /// @dev can not override EIP712 _buildDomainSeparatorOverride directly because it is not marked as virtual
    /// sets defaultChainId (634) instead of block.chainid for the hash, uses block.chainid in salt
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

    /// @dev Get the revert reason from the returnedData (supports Panic, Error & Custom Errors)
    /// Based on https://github.com/superfluid-finance/protocol-monorepo/blob/dev/packages/ethereum-contracts/contracts/libs/CallUtils.sol
    /// This is needed in order to provide some human-readable revert message from a call
    /// @param returnedData_ revert data of the call
    /// @return reason_      revert reason
    function _getRevertReasonFromReturnedData(bytes memory returnedData_)
        internal
        pure
        returns (string memory reason_)
    {
        if (returnedData_.length < 4) {
            // case 1: catch all
            return "_REASON_NOT_DEFINED";
        } else {
            bytes4 errorSelector;
            assembly {
                errorSelector := mload(add(returnedData_, 0x20))
            }
            if (
                errorSelector == bytes4(0x4e487b71) /* `seth sig "Panic(uint256)"` */
            ) {
                // case 2: Panic(uint256) (Defined since 0.8.0)
                // solhint-disable-next-line max-line-length
                // ref: https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require)
                reason_ = "_TARGET_PANICKED: 0x__";
                uint256 errorCode;
                assembly {
                    errorCode := mload(add(returnedData_, 0x24))
                    let reasonWord := mload(add(reason_, 0x20))
                    // [0..9] is converted to ['0'..'9']
                    // [0xa..0xf] is not correctly converted to ['a'..'f']
                    // but since panic code doesn't have those cases, we will ignore them for now!
                    let e1 := add(and(errorCode, 0xf), 0x30)
                    let e2 := shl(8, add(shr(4, and(errorCode, 0xf0)), 0x30))
                    reasonWord := or(
                        and(reasonWord, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000),
                        or(e2, e1)
                    )
                    mstore(add(reason_, 0x20), reasonWord)
                }
            } else {
                if (returnedData_.length > 68) {
                    // case 3: Error(string) (Defined at least since 0.7.0)
                    assembly {
                        returnedData_ := add(returnedData_, 0x04)
                    }
                    reason_ = string.concat("_", abi.decode(returnedData_, (string)));
                } else {
                    // case 4: Custom errors (Defined since 0.8.0)
                    reason_ = string.concat("_CUSTOM_ERROR:", fromCode(errorSelector));
                }
            }
        }
    }

    /// @dev used to convert bytes4 selector to string
    /// based on https://ethereum.stackexchange.com/a/111876
    function fromCode(bytes4 code) public pure returns (string memory) {
        bytes memory result = new bytes(10);
        result[0] = bytes1("0");
        result[1] = bytes1("x");
        for (uint256 i = 0; i < 4; ++i) {
            result[2 * i + 2] = toHexDigit(uint8(code[i]) / 16);
            result[2 * i + 3] = toHexDigit(uint8(code[i]) % 16);
        }
        return string(result);
    }

    /// @dev used to convert bytes4 selector to string
    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1("0")) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1("a")) + d - 10);
        }
        revert();
    }
}