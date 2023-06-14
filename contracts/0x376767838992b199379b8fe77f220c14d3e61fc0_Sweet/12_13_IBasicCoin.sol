// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBasicCoin {
    // 1.[Types: Basic]
    struct recdBasicUnit {
        uint256 nonce;
        uint256[] amount;
        uint256[] tag;
    }

    // 2.[Functions: Configuration]
    function setOpSigner(address addr) external;

    function setTreasury(address addr) external;

    // 3.[Events]
    event evSpend(
        address indexed addr,
        uint256 nonce,
        uint256 amount,
        uint256 tag
    );
    event evClaim(
        address indexed addr,
        uint256 nonce,
        uint256 amount,
        uint256 tag
    );

    event evSetup(address indexed addrOld, address addrNew, uint256 tag);
}