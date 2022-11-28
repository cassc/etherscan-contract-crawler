pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
import "./IBattleRoyaleNFT.sol";
//import "../lib/forge-std/src/console.sol";

interface IBattleRoyaleNFTRenderer {
    function tokenURI(uint tokenId, uint property) external view returns (string memory);
}