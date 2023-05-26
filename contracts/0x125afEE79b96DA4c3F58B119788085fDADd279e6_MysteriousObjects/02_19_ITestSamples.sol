// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

interface ITestSamples {
    function burn(address from, uint256 id, uint256 amount) external;
    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) external;
}