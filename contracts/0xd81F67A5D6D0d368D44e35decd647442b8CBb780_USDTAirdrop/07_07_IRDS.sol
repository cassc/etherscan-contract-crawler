// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRDS {
    function totalSupplyAt(uint256 _blockNumber)
        external
        view
        returns (uint256);

    function balanceOfAt(address _owner, uint256 _blockNumber)
        external
        view
        returns (uint256);
}