// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoWalletV1 } from "./interfaces/IAvoWalletV1.sol";
import { IAvoWalletV2 } from "./interfaces/IAvoWalletV2.sol";
import { IAvoSafe } from "./AvoSafe.sol";

/// @title    AvoForwarder
/// @notice   Only compatible with forwarding `cast` calls to AvoWallet contracts. This is not a generic forwarder.
///           This is NOT a "TrustedForwarder" as proposed in EIP-2770. See notice in AvoWallet.
/// @dev      Does not validate the EIP712 signature (instead this is done in the AvoWallet)
///           contract is Upgradeable through AvoForwarderProxy
contract AvoForwarder is Initializable {
    using Address for address;

    /***********************************|
    |                ERRORS             |
    |__________________________________*/

    error AvoForwarder__VersionMismatch();
    error AvoForwarder__InvalidParams();
    error AvoForwarder__Unauthorized();
    error AvoForwarder__LegacyVersionNotDeployed();

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice  AvoFactory that this contract uses to find or create AvoSafe deployments
    /// @dev     Note that if this changes then the deployment addresses for AvoWallet change too
    ///          Relayers might want to pass in version as new param then to forward to the correct factory
    IAvoFactory public immutable avoFactory;

    /// @dev cached AvoSafe Bytecode to optimize gas usage.
    /// If this changes because of a AvoFactory (and AvoSafe change) upgrade,
    /// then this variable must be updated through an upgrade deploying a new AvoForwarder!
    bytes32 public immutable avoSafeBytecode;

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice emitted when all actions for AvoWallet.cast() are executed successfully
    event Executed(
        address indexed avoSafeOwner,
        address indexed avoSafeAddress,
        address indexed source,
        bytes metadata
    );

    /// @notice emitted if one of the actions in AvoWallet.cast() fails
    event ExecuteFailed(
        address indexed avoSafeOwner,
        address indexed avoSafeAddress,
        address indexed source,
        bytes metadata,
        string reason
    );

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice constructor sets the immutable avoFactory address
    /// @param avoFactory_      address of AvoFactory
    constructor(IAvoFactory avoFactory_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoForwarder__InvalidParams();
        }
        avoFactory = avoFactory_;

        // get avo safe bytecode from factory.
        // @dev Note if a new AvoFactory is deployed (upgraded), a new AvoForwarder must be deployed
        // to update the avoSafeBytecode. See Readme for more info.
        avoSafeBytecode = avoFactory.avoSafeBytecode();

        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @notice initializes the contract
    function initialize() public initializer {}

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @notice         Retrieves the current avoSafeNonce of AvoWallet for owner address, needed for signatures
    /// @param owner_   AvoSafe Owner to retrieve the nonce for. Address signing a tx
    /// @return         returns the avoSafeNonce for the owner necessary to sign a meta transaction
    function avoSafeNonce(address owner_) external view returns (uint88) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (avoAddress_.isContract()) {
            return IAvoWalletV2(avoAddress_).avoSafeNonce();
        }

        return 0;
    }

    /// @notice         Retrieves the current AvoWallet implementation name for owner address, needed for signatures
    /// @param owner_   AvoSafe Owner to retrieve the name for. Address signing a tx
    /// @return         returns the domain separator name for the owner necessary to sign a meta transaction
    function avoWalletVersionName(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (avoAddress_.isContract()) {
            // if AvoWallet is deployed, return value from deployed Avo
            return IAvoWalletV2(avoAddress_).DOMAIN_SEPARATOR_NAME();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoWalletV2(avoFactory.avoWalletImpl()).DOMAIN_SEPARATOR_NAME();
    }

    /// @notice         Retrieves the current AvoWallet implementation version for owner address, needed for signatures
    /// @param owner_   AvoSafe Owner to retrieve the version for. Address signing a tx
    /// @return         returns the domain separator version for the owner necessary to sign a meta transaction
    function avoWalletVersion(address owner_) external view returns (string memory) {
        address avoAddress_ = _computeAvoSafeAddress(owner_);
        if (avoAddress_.isContract()) {
            // if AvoWallet is deployed, return value from deployed Avo
            return IAvoWalletV2(avoAddress_).DOMAIN_SEPARATOR_VERSION();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvoWalletV2(avoFactory.avoWalletImpl()).DOMAIN_SEPARATOR_VERSION();
    }

    /// @notice         Computes the deterministic address for owner based on Create2
    /// @param owner_   AvoSafe Owner
    /// @return         computed address for the contract
    function computeAddress(address owner_) external view returns (address) {
        if (Address.isContract(owner_)) {
            // owner of a AvoSafe must be an EOA, if it's a contract return zero address
            return address(0);
        }
        return _computeAvoSafeAddress(owner_);
    }

    /***********************************|
    |         Version V2: 2.0.0         |
    |__________________________________*/

    /// @notice               Deploys AvoSafe for owner if necessary and calls `cast` on it. For AvoWallet version ~2
    ///                       This method should be called by relayers.
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    function executeV2(
        address from_,
        IAvoWalletV2.Action[] calldata actions_,
        IAvoWalletV2.CastParams calldata params_,
        bytes calldata signature_
    ) external payable {
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvoWalletV2 avoWallet_ = IAvoWalletV2(_getDeployedAvoWallet(from_));

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            actions_,
            params_,
            signature_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(from_, address(avoWallet_), params_.source, params_.metadata, revertReason_);
        }
    }

    /// @notice               Verify the transaction is valid and can be executed. For AvoWallet version ~2
    ///                       IMPORTANT: Expected to be called via callStatic
    ///                       Does not revert and returns successfully if the input is valid.
    ///                       Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param params_        Cast params: validUntil, gas, source, id and metadata
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    /// @dev                  not marked as view because it does potentially state by deploying the AvoWallet for "from" if it does not exist yet.
    ///                       Expected to be called via callStatic
    function verifyV2(
        address from_,
        IAvoWalletV2.Action[] calldata actions_,
        IAvoWalletV2.CastParams calldata params_,
        bytes calldata signature_
    ) external returns (bool) {
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        IAvoWalletV2 avoWallet_ = IAvoWalletV2(_getDeployedAvoWallet(from_));

        return avoWallet_.verify(actions_, params_, signature_);
    }

    /***********************************|
    |         Version V1: 1.0.0         |
    |__________________________________*/

    /// @notice               Calls `cast` on an already deployed AvoWallet. For AvoWallet version 1.0.0
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    ///                       Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_        Source like e.g. referral for this tx
    /// @param metadata_      Optional metadata for future flexibility
    /// @param signature_     the EIP712 signature, see verifySig method
    function executeV1(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) public payable {
        // For legacy versions, AvoWallet must already be deployed
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (!Address.isContract(computedAvoSafeAddress_)) {
            revert AvoForwarder__LegacyVersionNotDeployed();
        }
        IAvoWalletV1 avoWallet_ = IAvoWalletV1(computedAvoSafeAddress_);

        (bool success_, string memory revertReason_) = avoWallet_.cast{ value: msg.value }(
            actions_,
            validUntil_,
            gas_,
            source_,
            metadata_,
            signature_
        );

        if (success_ == true) {
            emit Executed(from_, address(avoWallet_), source_, metadata_);
        } else {
            emit ExecuteFailed(from_, address(avoWallet_), source_, metadata_, revertReason_);
        }
    }

    /// @notice               Verify the transaction is valid and can be executed. For AvoWallet version 1.0.0
    ///                       IMPORTANT: Expected to be called via callStatic
    ///                       Does not revert and returns successfully if the input is valid.
    ///                       Reverts if any validation has failed. For instance, if params or either signature or avoSafeNonce are incorrect.
    /// @param from_          AvoSafe Owner who signed the transaction (the signature creator)
    /// @param actions_       the actions to execute (target, data, value)
    /// @param validUntil_    As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                       Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                       have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_           As EIP-2770: an amount of gas limit to set for the execution
    ///                       Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_        Source like e.g. referral for this tx
    /// @param metadata_      Optional metadata for future flexibility
    /// @param signature_     the EIP712 signature, see verifySig method
    /// @return               returns true if everything is valid, otherwise reverts
    /// @dev                  not marked as view to make as similar as possible to legacy version. Expected to be called via callStatic
    function verifyV1(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) public returns (bool) {
        // For legacy versions, AvoWallet must already be deployed
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (!Address.isContract(computedAvoSafeAddress_)) {
            revert AvoForwarder__LegacyVersionNotDeployed();
        }
        IAvoWalletV1 avoWallet_ = IAvoWalletV1(computedAvoSafeAddress_);

        return avoWallet_.verify(actions_, validUntil_, gas_, source_, metadata_, signature_);
    }

    /***********************************|
    |      LEGACY DEPRECATED FOR V1     |
    |__________________________________*/

    /// @custom:deprecated    DEPRECATED: Use executeV1() instead. Will be removed in the next version
    /// @notice               see executeV1() for details
    function execute(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable {
        return executeV1(from_, actions_, validUntil_, gas_, source_, metadata_, signature_);
    }

    /// @custom:deprecated    DEPRECATED: Use executeV1() instead. Will be removed in the next version
    /// @notice               see verifyV1() for details
    function verify(
        address from_,
        IAvoWalletV1.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external returns (bool) {
        return verifyV1(from_, actions_, validUntil_, gas_, source_, metadata_, signature_);
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev             gets or if necessary deploys an AvoSafe
    /// @param from_     AvoSafe Owner
    /// @return          the AvoSafe for the owner
    function _getDeployedAvoWallet(address from_) internal returns (address) {
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return computedAvoSafeAddress_;
        } else {
            return avoFactory.deploy(from_);
        }
    }

    /// @dev            computes the deterministic contract address for a AvoSafe deployment for owner_
    /// @param  owner_  AvoSafe owner
    /// @return         the computed contract address
    function _computeAvoSafeAddress(address owner_) internal view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSalt(owner_), avoSafeBytecode)
        );

        // cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /// @dev            gets the salt used for deterministic deployment for owner_
    /// @param owner_   AvoSafe owner
    /// @return         the bytes32 (keccak256) salt
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of AvoFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }
}