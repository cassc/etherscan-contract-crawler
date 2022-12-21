// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IGSWFactory } from "./interfaces/IGSWFactory.sol";
import { IGaslessSmartWallet } from "./interfaces/IGaslessSmartWallet.sol";

error GSWForwarder__InvalidParams();

/// @title    GSWForwarder
/// @notice   Only compatible with forwarding `cast` calls to GaslessSmartWallet contracts. This is not a generic forwarder.
///           This is NOT a "TrustedForwarder" as proposed in EIP-2770. See notice in GaslessSmartWallet.
/// @dev      Does not validate the EIP712 signature (instead this is done in the Gasless Smart wallet)
///           contract is Upgradeable through GSWForwarderProxy
contract GSWForwarder is Initializable {
    using Address for address;

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice  GSWFactory that this contract uses to find or create GSWProxy deployments
    /// @dev     Note that if this changes for some reason then the deployment addresses for GSW change too
    ///          Relayers might want to pass in version as new param then to forward to the correct factory
    IGSWFactory public immutable gswFactory;

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice emitted when all actions for GSW.cast() are executed successfully
    event Executed(address indexed gswOwner, address indexed gswAddress, address indexed source, bytes metadata);

    /// @notice emitted if one of the actions in GSW.cast() fails
    event ExecuteFailed(
        address indexed gswOwner,
        address indexed gswAddress,
        address indexed source,
        bytes metadata,
        string reason
    );

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice constructor sets the immutable gswFactory address
    /// @param gswFactory_      address of GSWFactory
    constructor(IGSWFactory gswFactory_) {
        if (address(gswFactory_) == address(0)) {
            revert GSWForwarder__InvalidParams();
        }
        gswFactory = gswFactory_;

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

    /// @notice             Retrieves the current gswNonce of GSW for owner address, which is necessary to sign meta transactions
    /// @param owner_       GaslessSmartWallet owner to retrieve the nonce for. Address who signs a transaction (the signature creator)
    /// @return             returns the gswNonce for the owner necessary to sign a meta transaction
    function gswNonce(address owner_) external view returns (uint256) {
        address gswAddress_ = gswFactory.computeAddress(owner_);
        if (gswAddress_.isContract()) {
            return IGaslessSmartWallet(gswAddress_).gswNonce();
        }

        return 0;
    }

    /// @notice             Retrieves the current gsw implementation name for owner address, which is necessary to sign meta transactions
    /// @param owner_       GaslessSmartWallet owner to retrieve the name for. Address who signs a transaction (the signature creator)
    /// @return             returns the domain separator name for the owner necessary to sign a meta transaction
    function gswVersionName(address owner_) external view returns (string memory) {
        address gswAddress_ = gswFactory.computeAddress(owner_);
        if (gswAddress_.isContract()) {
            // if GSW is deployed, return value from deployed GSW
            return IGaslessSmartWallet(gswAddress_).DOMAIN_SEPARATOR_NAME();
        }

        // otherwise return default value for current implementation that will be deployed
        return IGaslessSmartWallet(gswFactory.gswImpl()).DOMAIN_SEPARATOR_NAME();
    }

    /// @notice             Retrieves the current gsw implementation version for owner address, which is necessary to sign meta transactions
    /// @param owner_       GaslessSmartWallet owner to retrieve the version for. Address who signs a transaction (the signature creator)
    /// @return             returns the domain separator version for the owner necessary to sign a meta transaction
    function gswVersion(address owner_) external view returns (string memory) {
        address gswAddress_ = gswFactory.computeAddress(owner_);
        if (gswAddress_.isContract()) {
            // if GSW is deployed, return value from deployed GSW
            return IGaslessSmartWallet(gswAddress_).DOMAIN_SEPARATOR_VERSION();
        }

        // otherwise return default value for current implementation that will be deployed
        return IGaslessSmartWallet(gswFactory.gswImpl()).DOMAIN_SEPARATOR_VERSION();
    }

    /// @notice         Computes the deterministic address for owner based on Create2
    /// @param owner_   GaslessSmartWallet owner
    /// @return         computed address for the contract
    function computeAddress(address owner_) external view returns (address) {
        return gswFactory.computeAddress(owner_);
    }

    /// @notice             Deploys GaslessSmartWallet for owner if necessary and calls `cast` on it.
    ///                     This method should be called by relayers.
    /// @param from_        GaslessSmartWallet owner who signed the transaction (the signature creator)
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_         As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_      Source like e.g. referral for this tx
    /// @param metadata_    Optional metadata for future flexibility
    /// @param signature_   the EIP712 signature, see verifySig method
    function execute(
        address from_,
        IGaslessSmartWallet.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external payable {
        // gswFactory.deploy automatically checks if GSW has to be deployed
        // or if it already exists and simply returns the address in that case
        IGaslessSmartWallet gsw_ = IGaslessSmartWallet(gswFactory.deploy(from_));

        (bool success_, string memory revertReason_) = gsw_.cast{ value: msg.value }(
            actions_,
            validUntil_,
            gas_,
            source_,
            metadata_,
            signature_
        );

        if (success_ == true) {
            emit Executed(from_, address(gsw_), source_, metadata_);
        } else {
            emit ExecuteFailed(from_, address(gsw_), source_, metadata_, revertReason_);
        }
    }

    /// @notice             Verify the transaction is valid and can be executed.
    ///                     IMPORTANT: Expected to be called via callStatic
    ///                     Does not revert and returns successfully if the input is valid.
    ///                     Reverts if any validation has failed. For instance, if params or either signature or gswNonce are incorrect.
    /// @param from_        GaslessSmartWallet owner who signed the transaction (the signature creator)
    /// @param actions_     the actions to execute (target, data, value)
    /// @param validUntil_  As EIP-2770: the highest block number the request can be forwarded in, or 0 if request validity is not time-limited
    ///                     Protects against relayers executing a certain transaction at a later moment not intended by the user, where it might
    ///                     have a completely different effect. (Given that the transaction is not executed right away for some reason)
    /// @param gas_         As EIP-2770: an amount of gas limit to set for the execution
    ///                     Protects gainst potential gas griefing attacks / the relayer getting a reward without properly executing the tx completely
    ///                     See https://ronan.eth.limo/blog/ethereum-gas-dangers/
    /// @param source_      Source like e.g. referral for this tx
    /// @param metadata_    Optional metadata for future flexibility
    /// @param signature_   the EIP712 signature, see verifySig method
    /// @return             returns true if everything is valid, otherwise reverts
    /// @dev                not marked as view because it does potentially state by deploying the GaslessSmartWallet for "from" if it does not exist yet.
    ///                     Expected to be called via callStatic
    function verify(
        address from_,
        IGaslessSmartWallet.Action[] calldata actions_,
        uint256 validUntil_,
        uint256 gas_,
        address source_,
        bytes calldata metadata_,
        bytes calldata signature_
    ) external returns (bool) {
        // gswFactory.deploy automatically checks if GSW has to be deployed
        // or if it already exists and simply returns the address
        IGaslessSmartWallet gsw_ = IGaslessSmartWallet(gswFactory.deploy(from_));

        return gsw_.verify(actions_, validUntil_, gas_, source_, metadata_, signature_);
    }
}