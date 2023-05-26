// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function burn(uint256 amount) external;

    function mint(address recipient, uint256 amount) external;

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}