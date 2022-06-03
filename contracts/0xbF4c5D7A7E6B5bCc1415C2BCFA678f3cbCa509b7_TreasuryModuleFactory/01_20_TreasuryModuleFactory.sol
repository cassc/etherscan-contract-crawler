//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "@fractal-framework/core-contracts/contracts/ModuleFactoryBase.sol";
import "./interfaces/ITreasuryModuleFactory.sol";
import "./interfaces/ITreasuryModule.sol";

/// @notice A factory contract for deploying Treasury Modules
contract TreasuryModuleFactory is ERC165, ModuleFactoryBase, ITreasuryModuleFactory {
    event TreasuryCreated(address indexed treasuryAddress, address indexed accessControl);

    function initialize() external initializer {
        __initFactoryBase();
    }

    /// @dev Creates a Treasury module
    /// @param data The array of bytes used to create the module
    /// @return address[] The array of addresses of the created module
    function create(bytes[] calldata data)
        external
        override
        returns (address[] memory)
    {
        address[] memory createdContracts = new address[](1);
      
        address accessControl = abi.decode(data[0], (address));
        address treasuryImplementation = abi.decode(data[1], (address));

        createdContracts[0] = address(
            new ERC1967Proxy(
                treasuryImplementation,
                abi.encodeWithSelector(
                    ITreasuryModule(payable(address(0))).initialize.selector,
                    accessControl
                )
            )
        );

        emit TreasuryCreated(createdContracts[0], accessControl);

        return createdContracts;
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