//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IDexUsdOracle {
    function pair() external view returns (address);

    function period() external view returns (uint256);

    function blockTimestampLast1Period() external view returns (uint32);

    function update() external;
}