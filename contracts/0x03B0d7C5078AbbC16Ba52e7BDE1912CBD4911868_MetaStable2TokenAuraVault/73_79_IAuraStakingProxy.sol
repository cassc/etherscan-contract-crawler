// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IAuraStakingProxy {
    function crv() external view returns(address);
    function cvx() external view returns(address);
}