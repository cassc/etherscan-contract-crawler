//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {DominiumProxy} from "./DominiumProxy.sol";
import {Manageable} from "../access/Manageable.sol";
import {IProxyInitializer} from "../interfaces/IProxyInitializer.sol";
import {IGroup} from "../interfaces/IGroup.sol";
import {IDeploymentRefund} from "../interfaces/IDeploymentRefund.sol";
import {IAnticFeeCollectorProvider} from "../external/diamond/interfaces/IAnticFeeCollectorProvider.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/// @author Amit Molek
/// @dev Factory to replicate DominiumProxy contracts
contract DominiumProxyFactory is Manageable {
    /// @dev Emitted on instantiating a new `DominiumProxy` clone
    /// @param clone The `DominiumProxy` clone address
    /// @param implementation The implementation the proxy points to
    event Cloned(DominiumProxy clone, address implementation);

    /// @dev Emitted on `cloneAndJoin`
    /// @param clone The `DominiumProxy` clone address
    /// @param gasUsed The gas used to instantiate and initialize the clone
    event GasUsed(DominiumProxy clone, uint256 gasUsed);

    /// @dev Emitted on `changeImplementation`
    /// @param newImpl The address of the new implementation
    /// @param oldImpl The address of the old implementation
    event ImplementationChanged(address newImpl, address oldImpl);

    address public implementation;

    constructor(
        address admin,
        address[] memory managers,
        address implementation_
    ) Manageable(admin, managers) {
        _validImplementationGuard(implementation_);

        implementation = implementation_;
    }

    /// @dev The caller also joins the group
    /// @return instance an initialized `DominiumProxy` with the caller as the first member
    function cloneAndJoin(
        bytes32 salt,
        bytes memory initData,
        bytes memory joinData
    )
        external
        payable
        returns (DominiumProxy instance, uint256 deploymentGasUsed)
    {
        uint256 gasBefore = gasleft();
        instance = _replicate(salt, initData);
        deploymentGasUsed = gasBefore - gasleft();

        emit GasUsed(instance, deploymentGasUsed);

        // Initialize the deployment cost
        IDeploymentRefund(address(instance)).initDeploymentCost(
            deploymentGasUsed,
            msg.sender
        );

        // Member joins the group
        IGroup(address(instance)).join{value: msg.value}(joinData);
    }

    /// @dev Can revert:
    ///     - "Missing initialization data": If `data` is empty
    ///     - "Empty salt": if `salt_` is the empty hash
    /// @dev Emits `Cloned`
    function _replicate(bytes32 salt_, bytes memory data)
        internal
        returns (DominiumProxy instance)
    {
        require(data.length > 0, "Missing initialization data");
        require(salt_ != bytes32(0), "Empty salt");

        // The salt is unique to the deployer/caller
        bytes32 deployerSalt = _deploySalt(msg.sender, salt_);

        // Deploy `DominiumProxy` using create2, so we can get
        // the precalculated address
        instance = new DominiumProxy{salt: deployerSalt}(implementation);

        emit Cloned(instance, implementation);

        // Fetch fee info provider
        IAnticFeeCollectorProvider feeCollectorProvider = IAnticFeeCollectorProvider(
                implementation
            );

        // Fetch Antic's fee collector address
        address anticFeeCollector = feeCollectorProvider.anticFeeCollector();

        // Fetch Antic's join & sell fees
        (uint16 joinFee, uint16 sellFee) = feeCollectorProvider.anticFees();

        // Initialize clone
        IProxyInitializer(address(instance)).proxyInit(
            anticFeeCollector,
            joinFee,
            sellFee,
            data
        );
    }

    /// @return the address of the contract if it will be deployed using `clone` & `cloneAndJoin`
    /// with `salt`
    function computeAddress(address deployer, bytes32 salt)
        external
        view
        returns (address)
    {
        bytes memory proxyBytecode = _proxyCreationBytecode(implementation);
        bytes32 deployerSalt = _deploySalt(deployer, salt);

        bytes32 _data = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                deployerSalt,
                keccak256(proxyBytecode)
            )
        );
        return address(uint160(uint256(_data)));
    }

    /// @return the `DominiumProxy`'s creation code
    function _proxyCreationBytecode(address implementation_)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                type(DominiumProxy).creationCode,
                abi.encode(implementation_)
            );
    }

    /// @return the salt that will be used for cloning if `deployer`
    /// is the caller and `salt` is passed
    function _deploySalt(address deployer, bytes32 salt)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(deployer, salt));
    }

    function changeImplementation(address implementation_)
        external
        onlyAuthorized
    {
        _validImplementationGuard(implementation_);

        emit ImplementationChanged(implementation_, implementation);

        implementation = implementation_;
    }

    /// @dev Reverts if `implementation_` is not a valid implementation
    function _validImplementationGuard(address implementation_) internal view {
        require(
            ERC165Checker.supportsInterface(
                implementation_,
                type(IAnticFeeCollectorProvider).interfaceId
            ),
            "Implementation must support IAnticFeeCollectorProvider"
        );
    }
}