// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// eth - 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
// eth-goerli -

interface IPriceOracle {
    function getPrice() external view returns (uint256);

    function getWeiValueOfDollar() external view returns (uint256);
}