// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "witnet-solidity-bridge/contracts/patterns/Clonable.sol";

/// @title Witnet Request Board base contract, with an Upgradeable (and Destructible) touch.
/// @author The Witnet Foundation.
abstract contract WittyPixelsClonableBase
    is
        Clonable,
        ReentrancyGuardUpgradeable
{
    /// @dev Reverts w/ specific message if a delegatecalls falls back into unexistent method.
    fallback() external { // solhint-disable
        revert("WittyPixelsClonableBase: not implemented");
    }

    function version() virtual external view returns (string memory);


    // ================================================================================================================
    // --- 'Clonable' extension ---------------------------------------------------------------------------------------

    function initializeClone(bytes memory _initBytes)
        virtual external
        initializer
        onlyDelegateCalls
    {
        __initialize(_initBytes);
    }

    function __initialize(bytes memory) 
        virtual
        internal
    {
        // initialize openzeppelin's underlying patterns
        __ReentrancyGuard_init();
    }

}