// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.10;

interface IURIReturner {
    function uri(uint256 id) external view returns (string memory);
}