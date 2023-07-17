// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC721xHelper {
    function tokenNameByIndexMultiple(uint256[] calldata tokenIds) external view returns (string[] memory);

    function ownerOfMultiple(uint256[] calldata tokenIds) external view returns (address[] memory);

    function isUnlockedMultiple(uint256[] calldata tokenIds) external view returns (bool[] memory);
}