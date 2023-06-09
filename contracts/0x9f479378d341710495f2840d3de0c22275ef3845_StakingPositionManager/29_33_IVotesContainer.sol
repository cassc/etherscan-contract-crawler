// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IVotesContainer {

    function initialize() external;

    function getVotes(address token) external view returns (uint256);
    function getPastVotes(address token, uint256 blockNumber) external view returns (uint256);
    function delegates(address token) external view returns (address);

    function delegate(address token, address target) external;
    function transfer(address token, bytes32 id, address to, uint256 amount, bytes memory data) external;
    function transfer(address token, address to, uint256 amount) external;
}