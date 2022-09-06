// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Lockable is IERC721 {
    function setTokenLockStatus(uint256[] calldata tokenIds, bool isLock) external;

    function getTokenLockStatus(uint256[] calldata tokenIds) external returns(bool[] memory);
}