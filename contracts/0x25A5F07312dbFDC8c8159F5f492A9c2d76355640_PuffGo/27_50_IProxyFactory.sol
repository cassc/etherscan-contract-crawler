// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './IProxyImplementation.sol';

interface IProxyFactory {

    function contracts(address _caller) external returns (bool);

    function registerProxy() external returns (address);

    function proxies(address user) external returns (IProxyImplementation);

    function proxyImplementation() external returns (IProxyImplementation);

}