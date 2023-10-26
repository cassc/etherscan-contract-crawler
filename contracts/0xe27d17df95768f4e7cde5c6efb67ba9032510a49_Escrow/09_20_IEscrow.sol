// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IEscrowEvents {
    event ReleaseFund(address from, uint256 price);
    event ReleaseNFT(address to, address drop, uint256 tokenId);
    event LockNFT(address from, address drop, uint256 tokenId);
}

interface IEscrow is IEscrowEvents {
    function lock(
        address drop,
        uint256 tokenId,
        address from
    ) external;

    function releaseFund(address to, uint256 price) external;

    function releaseNFT(
        address to,
        address drop,
        uint256 tokenId
    ) external;
}