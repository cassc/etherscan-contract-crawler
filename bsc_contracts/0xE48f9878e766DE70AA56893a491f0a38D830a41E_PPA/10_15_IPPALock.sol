// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPPALock {
    function lockTreasury(address adr, uint256 amount) external;

    function treasuryAvailableClaim(address adr, uint256 percent)
        external
        view
        returns (uint256 avl, uint256 claimed);

    function releaseTreasury(address adr, uint256 percent)
        external
        returns (uint256);

    function lockNFT(
        address adr,
        uint256 init,
        uint256 amount
    ) external;

    function addLiq(
        address adr,
        uint256 amount,
        uint256 addedLp
    ) external;

    function releaseNFT(address adr, uint256 percent)
        external
        returns (uint256 released, uint256 blackhole);

    function nftAvailableClaim(address adr, uint256 percent)
        external
        view
        returns (uint256 avl, uint256 claimed);
}