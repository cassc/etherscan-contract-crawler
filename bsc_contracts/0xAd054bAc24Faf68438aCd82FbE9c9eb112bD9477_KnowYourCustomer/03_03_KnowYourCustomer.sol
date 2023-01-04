// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KnowYourCustomer is Ownable {

    address public kycRemoteAddress;
    bool private kycInitailized;
    bool private kycRestrictionActive;

    mapping(address => bool) private _isWhitelisted;

    event KnowYourCustomerActivated(bool active);
    event KnowYourCustomerWhitelistChanged();

    function initKnowYourCustomer(address remoteAddress) public onlyOwner {
        require(!kycInitailized, "KnowYourCustomer: Already initialized");
        kycInitailized = true;
        if (remoteAddress == address(0) || remoteAddress == address(this)) {
            address[] memory addrList = new address[](1);
            addrList[0] = owner();
            whitelistAccount(addrList, true);
            setKnowYourCustomerActive(true);
        } else {
            kycRemoteAddress = remoteAddress;
        }
    }

    function setKnowYourCustomerActive(bool _active) public onlyOwner {
        require(kycRemoteAddress == address(0), 'KnowYourCustomer: disabled in remote mode!');
        kycRestrictionActive = _active;
        emit KnowYourCustomerActivated(kycRestrictionActive);
    }

    function isKnowYourCustomerActive() public view returns (bool) {
        if (kycRemoteAddress != address(0)) {
            return KnowYourCustomer(kycRemoteAddress).isKnowYourCustomerActive();
        }
        return kycRestrictionActive;
    }

    function whitelistAccount(address[] memory _account, bool _whitelisted) public onlyOwner {
        require(kycRemoteAddress == address(0), 'KnowYourCustomer: disabled in remote mode!');
        for (uint i=0; i<_account.length; i++) _isWhitelisted[_account[i]] = _whitelisted;
        emit KnowYourCustomerWhitelistChanged();
    }

    function isWhitelisted(address addr) public view returns (bool) {
        if (kycRemoteAddress != address(0)) {
            return KnowYourCustomer(kycRemoteAddress).isWhitelisted(addr);
        }
        return _isWhitelisted[addr];
    }

    modifier onlyKnownCustomer() {
        require(!isKnowYourCustomerActive() || isWhitelisted(msg.sender), 'KnowYourCustomer: not whitelisted address');
        _;
    }
}