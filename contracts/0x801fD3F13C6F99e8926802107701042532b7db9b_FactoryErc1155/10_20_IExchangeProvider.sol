// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface IExchangeProvider {
    function exchange() external view returns(address);
}