// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "witnet-solidity-bridge/contracts/patterns/Upgradeable.sol";
import "witnet-solidity-bridge/contracts/impls/WitnetProxy.sol";

/// @title Witnet Request Board base contract, with an Upgradeable (and Destructible) touch.
/// @author The Witnet Foundation.
abstract contract WittyPixelsUpgradeableBase
    is
        Ownable2StepUpgradeable,
        ReentrancyGuardUpgradeable,
        Upgradeable
{
    bytes32 internal immutable _UPGRADABLE_VERSION_TAG;

    error AlreadyInitialized(address implementation);
    error NotCompliant(bytes4 interfaceId);
    error NotUpgradable(address self);
    error OnlyOwner(address owner);

    constructor(
            bool _upgradable,
            bytes32 _versionTag,
            string memory _proxiableUUID
        )
        Upgradeable(_upgradable)
    {
        _UPGRADABLE_VERSION_TAG = _versionTag;
        proxiableUUID = keccak256(bytes(_proxiableUUID));        
        // Logic-only instance will have no owner.
    }
    
    /// @dev Reverts if proxy delegatecalls to unexistent method.
    fallback() external { // solhint-disable
        revert("WittyPixelsUpgradeableBase: not implemented");
    }


    // ================================================================================================================
    // --- Overrides 'Proxiable' --------------------------------------------------------------------------------------

    /// @dev Gets immutable "heritage blood line" (ie. genotype) as a Proxiable, and eventually Upgradeable, contract.
    ///      If implemented as an Upgradeable touch, upgrading this contract to another one with a different 
    ///      `proxiableUUID()` value should fail.
    bytes32 public immutable override proxiableUUID;


    // ================================================================================================================
    // --- Overrides 'Upgradeable' --------------------------------------------------------------------------------------

    /// Tells whether provided address could eventually upgrade the contract.
    function isUpgradableFrom(address _from) external view override returns (bool) {
        return (
            // false if the WRB is intrinsically not upgradable, or `_from` is no owner
            isUpgradable()
                && _from == owner()
        );
    }

    
    /// Retrieves human-readable version tag of current implementation.
    function version() public view override returns (string memory) {
        return _toString(_UPGRADABLE_VERSION_TAG);
    }


    // ================================================================================================================
    // --- Internal methods -------------------------------------------------------------------------------------------

    /// Converts bytes32 into string.
    function _toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(_toStringLength(_bytes32));
        for (uint _i = 0; _i < _bytes.length;) {
            _bytes[_i] = _bytes32[_i];
            unchecked {
                _i ++;
            }
        }
        return string(_bytes);
    }

    // Calculate length of string-equivalent to given bytes32.
    function _toStringLength(bytes32 _bytes32)
        internal pure
        returns (uint _length)
    {
        for (; _length < 32; ) {
            if (_bytes32[_length] == 0) {
                break;
            }
            unchecked {
                _length ++;
            }
        }
    }

}