// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";

import "test/contract-mocks/factory/MockBaseContract.sol";

/// @custom:salt MockInitializable
contract MockInitializable is
    ProxyInternalUpgradeLock,
    ProxyInternalUpgradeUnlock,
    IMockBaseContract
{
    error ContractAlreadyInitialized();
    error ContractNotInitializing();
    error Failed();
    address internal _factory;
    uint256 internal _var;
    uint256 internal _imut;
    address public immutable factoryAddress = 0x0BBf39118fF9dAfDC8407c507068D47572623069;
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        if (_initializing ? !_isConstructor() : _initialized) {
            revert ContractAlreadyInitialized();
        }

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (!_initializing) {
            revert ContractNotInitializing();
        }
        _;
    }

    function getFactory() external view returns (address) {
        return _factory;
    }

    function initialize(uint256 i_) public virtual initializer {
        __mockInit(i_);
    }

    function setFactory(address factory_) public {
        _factory = factory_;
    }

    function setV(uint256 _v) public {
        _var = _v;
    }

    function lock() public {
        __lockImplementation();
    }

    function unlock() public {
        __unlockImplementation();
    }

    function getVar() public view returns (uint256) {
        return _var;
    }

    function getImut() public view returns (uint256) {
        return _imut;
    }

    function fail() public pure {
        if (false != true) {
            revert Failed();
        }
    }

    function __mockInit(uint256 i_) internal onlyInitializing {
        __mockInitUnchained(i_);
    }

    function __mockInitUnchained(uint256 i_) internal onlyInitializing {
        _imut = i_;
        _factory = msg.sender;
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function _isConstructor() private view returns (bool) {
        return !_isContract(address(this));
    }
}