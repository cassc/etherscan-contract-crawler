//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../interfaces/IGovernorModule.sol";
import "@fractal-framework/core-contracts/contracts/ModuleFactoryBase.sol";
import "../interfaces/ITimelockUpgradeable.sol";

/// @dev Governor Factory used to deploy Gov Modules
/// @dev Deploys Timelock dependecies
contract GovernorFactory is ERC165, ModuleFactoryBase {
    event GovernorCreated(address timelock, address governorModule);

    function initialize() external initializer {
        __initFactoryBase();
    }

    /// @dev Creates a Governor module
    /// @param data The array of bytes used to create the module
    /// @return address[] The array of addresses of the created module
    function create(bytes[] calldata data)
        external
        override
        returns (address[] memory)
    {
        address[] memory createdContracts = new address[](2);

        createdContracts[1] = createTimelock(data);

        createdContracts[0] = createGovernor(createdContracts[1], data);

        emit GovernorCreated(createdContracts[0], createdContracts[1]);

        return createdContracts;
    }

    function createTimelock(bytes[] memory data)
        private
        returns (address timelock)
    {
        timelock = address(
            new ERC1967Proxy(
                address(abi.decode(data[4], (address))),
                abi.encodeWithSelector(
                    ITimelockUpgradeable(payable(address(0)))
                        .initialize
                        .selector,
                    abi.decode(data[1], (address)),
                    abi.decode(data[0], (address)),
                    abi.decode(data[10], (uint256))
                )
            )
        );
    }

    function createGovernor(address timelock, bytes[] memory data)
        private
        returns (address governorModule)
    {
        governorModule = address(
            new ERC1967Proxy(
                address(abi.decode(data[3], (address))),
                abi.encodeWithSelector(
                    IGovernorModule(payable(address(0))).initialize.selector,
                    abi.decode(data[2], (address)),
                    timelock,
                    abi.decode(data[5], (uint64)),
                    abi.decode(data[6], (uint256)),
                    abi.decode(data[7], (uint256)),
                    abi.decode(data[8], (uint256)),
                    abi.decode(data[9], (uint256)),
                    abi.decode(data[1], (address))
                )
            )
        );
    }

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, ModuleFactoryBase)
        returns (bool)
    {
        return
            interfaceId == type(IModuleFactory).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}