// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IAccessContract {
    function addTrustedAddress(address _address) external;

    function removeTrustedAddress(address _address) external;

    function isTrustedAddress(address _address)
        external
        view
        returns (bool);
}

abstract contract AccessContract is IAccessContract, Ownable {
    mapping(address => bool) private _trustedAddresses; // trusted contracts

    function isTrustedCaller() public view returns (bool) {
        return _trustedAddresses[_msgSender()] || _msgSender() == address(this);
    }

    modifier onlyTrustedCaller() {
        require(isTrustedCaller(), "AC:ADDRESS_IS_NOT_TRUSTED");
        _;
    }

    function addTrustedAddress(address _address) public override onlyOwner {
        _trustedAddresses[_address] = true;
    }

    function removeTrustedAddress(address _address)
        public
        override
        onlyOwner
    {
        _trustedAddresses[_address] = false;
    }

    function isTrustedAddress(address _address)
        public
        view
        override
        returns (bool)
    {
        return _trustedAddresses[_address] || _msgSender() == address(this);
    }
}