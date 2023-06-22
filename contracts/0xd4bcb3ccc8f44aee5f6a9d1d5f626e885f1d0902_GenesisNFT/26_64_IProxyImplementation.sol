// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IProxyImplementation {

    enum HowToCall { Call, DelegateCall }

    function proxy(address dest, HowToCall howToCall, bytes memory data) external returns (bool result);

}