// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IComptroller {
    function cTokensByUnderlying(address) external view returns (address cToken);
}