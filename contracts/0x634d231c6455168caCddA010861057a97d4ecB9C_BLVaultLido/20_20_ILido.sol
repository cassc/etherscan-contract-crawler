// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0;

interface IWsteth {
    function stEthPerToken() external view returns (uint256);
}