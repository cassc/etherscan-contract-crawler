// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { IAvoVersionsRegistry } from "../interfaces/IAvoVersionsRegistry.sol";
import { IAvoWalletV2 } from "../interfaces/IAvoWalletV2.sol";

error AvoWallet__InvalidParams();

/// @title      VariablesV1
/// @notice     Contains storage variables for AvoWallet.
abstract contract VariablesV1 is IAvoWalletV2 {
    /// @notice  registry holding the valid versions (addresses) for AvoWallet implementation contracts
    ///          The registry is used to verify a valid version before upgrading
    ///          immutable but could be updated in the logic contract when a new version of AvoWallet is deployed
    IAvoVersionsRegistry public immutable avoVersionsRegistry;

    /// @notice address of the AvoForwarder (proxy) that is allowed to forward tx with valid
    ///         signatures to this contract
    ///         immutable but could be updated in the logic contract when a new version of AvoWallet is deployed
    address public immutable avoForwarder;

    // the next 3 vars (avoWalletImpl, nonce, status) are tightly packed into 1 storage slot

    /// @notice address of the Avo wallet logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    IMPORTANT: DO NOT MOVE THIS VARIABLE
    ///         _avoWalletImpl MUST ALWAYS be the first declared variable here in the logic contract and in the proxy!
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    ///         immutable and constants do not take up storage slots so they can come before.
    address internal _avoWalletImpl;

    /// @notice nonce that is incremented for every `cast` transaction with valid signature
    uint88 public avoSafeNonce;

    /// @dev flag set temporarily to signal various cases:
    /// 0 -> default state
    /// 1 -> signature is valid or called by owner, _callTargets can be executed
    /// 20 / 21 -> flashloan receive can be executed (set to original id param from cast())
    uint8 internal _status;

    /// @notice owner of the smart wallet
    /// @dev theoretically immutable, can only be set in initialize (at proxy clone factory deployment)
    address public owner;

    /// @dev
    /// after owner variable there still is uint8 and bool from Initializable library. Rest of slot (10 bytes) should be empty
    /// uint8 private _initialized;
    /// bool private _initializing;

    /// @dev contracts deployed before V2 contain two more variables from EIP712Upgradeable: hashed domain separator
    /// name and version which were set at initialization (Now we do this in logic contract at deployment as constant)
    /// https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/cryptography/EIP712Upgradeable.sol#L32
    /// bytes32 private _HASHED_NAME;
    /// bytes32 private _HASHED_VERSION;

    /// @notice constructor sets the immutable avoVersionsRegistry address
    /// @dev    setting this on the logic contract at deployment is ok because the
    ///         AvoVersionsRegistry is upgradeable so this address is the proxy address which really shouldn't change.
    ///         Even if it would change then worst case a new AvoWallet logic contract
    ///         has to be deployed pointing to a new registry
    /// @param avoVersionsRegistry_    address of the avoVersionsRegistry contract
    /// @param avoForwarder_           address of the avoForwarder (proxy) contract
    ///                                to forward tx with valid signatures. must be valid version in AvoVersionsRegistry.
    constructor(IAvoVersionsRegistry avoVersionsRegistry_, address avoForwarder_) {
        if (address(avoVersionsRegistry_) == address(0)) {
            revert AvoWallet__InvalidParams();
        }
        avoVersionsRegistry = avoVersionsRegistry_;

        avoVersionsRegistry.requireValidAvoForwarderVersion(avoForwarder_);
        avoForwarder = avoForwarder_;
    }
}