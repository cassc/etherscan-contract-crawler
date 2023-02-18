// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IAvoFactory } from "../interfaces/IAvoFactory.sol";
import { IAvoWallet } from "../interfaces/IAvoWallet.sol";

interface IAvoWalletWithCallTargets is IAvoWallet {
    function _callTargets(Action[] calldata actions_, uint256 id_) external payable;
}

contract AvoGasEstimationsHelper {
    using Address for address;

    error AvoGasEstimationsHelper__InvalidParams();

    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice  AvoFactory that this contract uses to find or create AvoSafe deployments
    IAvoFactory public immutable avoFactory;

    /// @dev cached AvoSafe Bytecode to optimize gas usage.
    bytes32 public immutable avoSafeBytecode;

    /// @notice constructor sets the immutable avoFactory address
    /// @param avoFactory_      address of AvoFactory
    constructor(IAvoFactory avoFactory_) {
        if (address(avoFactory_) == address(0)) {
            revert AvoGasEstimationsHelper__InvalidParams();
        }
        avoFactory = avoFactory_;

        // get avo safe bytecode from factory.
        // @dev Note if a new AvoFactory is deployed (upgraded), a new AvoGasEstimationsHelper must be deployed
        // to update the avoSafeBytecode. See Readme for more info.
        avoSafeBytecode = avoFactory.avoSafeBytecode();
    }

    /// @notice estimate gas usage of actions_ via ._callTargets() on AvoWallet and deploying AvoSafe if necessary
    /// Note this gas estimation will not include the gas consumed in `.cast()`
    /// @param owner_         AvoSafe owner
    /// @param actions_       the actions to execute (target, data, value)
    /// @param id_            id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @return totalGasUsed_           total amount of gas used
    /// @return deploymentGasUsed_      amount of gas used for deployment (or for getting the AvoWallet if already deployed)
    /// @return isAvoSafeDeployed_      boolean flag indicating if avo safe is already deployed (true) or if it must be deployed (false)
    /// @return success_                boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGas(
        address owner_,
        IAvoWallet.Action[] calldata actions_,
        uint256 id_
    )
        external
        payable
        returns (
            uint256 totalGasUsed_,
            uint256 deploymentGasUsed_,
            bool isAvoSafeDeployed_,
            bool success_
        )
    {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoWalletWithCallTargets avoWallet_;
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoWallet_, isAvoSafeDeployed_) = _getDeployedAvoWallet(owner_, address(0));

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoWallet_).call{ value: msg.value }(
            abi.encodeCall(avoWallet_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /// @notice estimate gas usage of actions_ via ._callTargets() on AvoWallet and deploying AvoSafe if necessary
    /// Note this gas estimation will not include the gas consumed in `.cast()`
    /// @param owner_               AvoSafe owner
    /// @param actions_             the actions to execute (target, data, value)
    /// @param id_                  id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall), 20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
    /// @param avoWalletVersion_    Version of AvoWallet logic contract to deploy
    /// @return totalGasUsed_       total amount of gas used
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the AvoWallet if already deployed)
    /// @return isAvoSafeDeployed_  boolean flag indicating if avo safe is already deployed (true) or if it must be deployed (false)
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    function estimateCallTargetsGasWithVersion(
        address owner_,
        IAvoWallet.Action[] calldata actions_,
        uint256 id_,
        address avoWalletVersion_
    )
        external
        payable
        returns (
            uint256 totalGasUsed_,
            uint256 deploymentGasUsed_,
            bool isAvoSafeDeployed_,
            bool success_
        )
    {
        uint256 gasSnapshotBefore_ = gasleft();

        IAvoWalletWithCallTargets avoWallet_;
        // _getDeployedAvoWallet automatically checks if AvoSafe has to be deployed
        // or if it already exists and simply returns the address
        (avoWallet_, isAvoSafeDeployed_) = _getDeployedAvoWallet(owner_, avoWalletVersion_);

        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        (success_, ) = address(avoWallet_).call{ value: msg.value }(
            abi.encodeCall(avoWallet_._callTargets, (actions_, id_))
        );

        totalGasUsed_ = gasSnapshotBefore_ - gasleft();
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev                        gets or if necessary deploys an AvoSafe
    /// @param from_                AvoSafe Owner
    /// @param avoWalletVersion_    Optional param to define a specific Avo Wallet version to deploy
    /// @return                     the AvoSafe for the owner & boolean flag for if was already deployed or not
    function _getDeployedAvoWallet(address from_, address avoWalletVersion_)
        internal
        returns (IAvoWalletWithCallTargets, bool)
    {
        address computedAvoSafeAddress_ = _computeAvoSafeAddress(from_);
        if (Address.isContract(computedAvoSafeAddress_)) {
            return (IAvoWalletWithCallTargets(computedAvoSafeAddress_), true);
        } else {
            if (avoWalletVersion_ == address(0)) {
                return (IAvoWalletWithCallTargets(avoFactory.deploy(from_)), false);
            } else {
                return (IAvoWalletWithCallTargets(avoFactory.deployWithVersion(from_, avoWalletVersion_)), false);
            }
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