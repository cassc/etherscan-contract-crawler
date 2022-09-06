//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IModuleBase.sol";

/// @notice An abstract contract to be inherited by module contracts
abstract contract ModuleBase is IModuleBase, UUPSUpgradeable, ERC165 {
    IAccessControlDAO public accessControl;
    address public moduleFactory;
    string internal _name;

    /// @notice Requires that a function caller has the associated role
    modifier authorized() {
        if (
            !accessControl.actionIsAuthorized(
                msg.sender,
                address(this),
                msg.sig
            )
        ) {
            revert NotAuthorized();
        }
        _;
    }

    /// @notice Function for initializing the contract that can only be called once
    /// @param _accessControl The address of the access control contract
    /// @param _moduleFactory The address of the factory deploying the module
    /// @param __name Human readable string of the module name
    function __initBase(address _accessControl, address _moduleFactory, string memory __name)
        internal
        onlyInitializing
    {
        accessControl = IAccessControlDAO(_accessControl);
        moduleFactory = _moduleFactory;
        _name = __name;
        __UUPSUpgradeable_init();
    }

    /// @dev Applies authorized modifier so that an upgrade require the caller to have the correct role
    /// @param newImplementation The address of the new implementation contract being upgraded to
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        authorized
    {}

    /// @notice Returns the module name
    /// @return The module name
    function name() public view virtual returns (string memory) {
      return _name;
    }

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IModuleBase)
        returns (bool)
    {
        return
            interfaceId == type(IModuleBase).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}