// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IKubzWardrobe {
    function getKWRLockStatusSimple(
        address contractAddress, // 1 = kzg, 2 = kubz
        uint256 collectionTokenId
    ) external view returns (uint256);

    function resetKWRLockStatus(
        address contractAddress, // 1 = kzg, 2 = kubz
        uint256 collectionTokenId
    ) external;
}