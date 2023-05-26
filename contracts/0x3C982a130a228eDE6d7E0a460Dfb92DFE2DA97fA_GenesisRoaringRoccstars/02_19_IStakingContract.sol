// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingContract {

    function hasDepositsOrOwns(address owner, uint256[] memory tokenIds) external view returns (bool);
}