// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4AFeePoolFactory {
    function createD4AFeePool(string memory _name) external returns (address pool);
}