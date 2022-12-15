// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721B.sol";

/**
 * Modified interface to add temporaryApproval for guardian contract
 */
interface ILockERC721 is IERC721 {
    function lockId(uint256 _id) external;

    function unlockId(uint256 _id) external;

    function freeId(uint256 _id, address _contract) external;

    function temporaryApproval(uint256 _id) external;
}