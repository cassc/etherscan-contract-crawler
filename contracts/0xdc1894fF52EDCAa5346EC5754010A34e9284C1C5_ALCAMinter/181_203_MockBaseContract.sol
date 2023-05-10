// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/proxy/ProxyInternalUpgradeLock.sol";
import "contracts/libraries/proxy/ProxyInternalUpgradeUnlock.sol";

interface IMockBaseContract {
    function setV(uint256 _v) external;

    function lock() external;

    function unlock() external;

    function fail() external;

    function getVar() external view returns (uint256);

    function getImut() external view returns (uint256);
}

/// @custom:salt Mock
contract MockBaseContract is
    ProxyInternalUpgradeLock,
    ProxyInternalUpgradeUnlock,
    IMockBaseContract
{
    error Failed();
    address internal _factory;
    uint256 internal _var;
    uint256 internal immutable _imut;
    string internal _pString;

    constructor(uint256 imut_, string memory pString_) {
        _pString = pString_;
        _imut = imut_;
        _factory = msg.sender;
    }

    function payMe() public payable {}

    function setV(uint256 _v) public {
        _var = _v;
    }

    function lock() public {
        __lockImplementation();
    }

    function unlock() public {
        __unlockImplementation();
    }

    function setFactory(address factory_) public {
        _factory = factory_;
    }

    function getFactory() public view returns (address) {
        return _factory;
    }

    function getpString() public view returns (string memory) {
        return _pString;
    }

    function getImut() public view returns (uint256) {
        return _imut;
    }

    function getVar() public view returns (uint256) {
        return _var;
    }

    function fail() public pure {
        if (false != true) {
            revert Failed();
        }
    }
}