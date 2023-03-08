// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface IDodoV2Pool {
    function sellBase(address to) external payable returns (uint256);

    function sellQuote(address to) external payable returns (uint256);
}