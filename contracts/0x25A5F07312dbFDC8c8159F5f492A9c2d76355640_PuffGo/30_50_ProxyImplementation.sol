// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IProxyFactory.sol';
import "hardhat/console.sol";

contract ProxyImplementation is Initializable {
    using Address for address;

    address public user;

    IProxyFactory public factory;

    bool public revoked;

    enum HowToCall { Call, DelegateCall }

    event Revoked(bool revoked);

    function initialize (address _user, IProxyFactory _factory) external initializer {
        require(user == address(0) && address(_factory) == address(0), "already verified");
        user = _user;
        factory = _factory;
    }

    function setRevoke(bool revoke) external {
        require(msg.sender == user, "only user can do this");
        revoked = revoke;
        emit Revoked(revoke);
    }

    function proxy(address dest, HowToCall howToCall, bytes memory data) public returns (bool result) {
        require(msg.sender == user || (!revoked && factory.contracts(msg.sender)));
        if (howToCall == HowToCall.Call) {
            dest.functionCall(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            dest.functionDelegateCall(data);
        } else {
            return false;
        }
        return true;
    }

}