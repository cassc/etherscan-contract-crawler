//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface ICurve3CRVMinter {
    function mint(address gauge_addr) external;
}