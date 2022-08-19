// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/IERC721A.sol";

interface IERC721ALockable is IERC721A {
    function setTokenLockStatus(uint256[] calldata tokenIds, bool isLock) external;

    function getTokenLockStatus(uint256[] calldata tokenIds) external returns(bool[] memory);
}