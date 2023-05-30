// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721Enumerable.sol";

interface IBoostToken is IERC721Enumerable {
    function updateStakeTime(uint tokenId, bool isStake) external;

    function getTokenOwner(uint tokenId) external view returns(address);
}