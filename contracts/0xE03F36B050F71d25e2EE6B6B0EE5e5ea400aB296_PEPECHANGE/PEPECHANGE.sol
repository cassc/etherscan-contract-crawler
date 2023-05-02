/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

// SPDX-License-Identifier: UNLICENSED

/********************************
**:::::::::::::::::::::::::::::**
**:::::██████████████::::::::::**
**:::██::::::::::::::██::::::::**
**:::██████████████████████::::**
**:::::::::::::::::::::::::::::**
**:::████::████:███:█::████::::**
**:::██:██:███:::██:█::████::::**
**:::████::████::::██::████::::**
**:::::::::::::::::::::::::::::**
********************************/

/// Author   : 0xSumo of @TheCapLabs
/// Twitter  : https://twitter.com/TheCapLabs

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}
interface ICSG { function adminChangeTrait(uint16 tokenId_, uint8 traitNumber_, uint16 traitValue_) external; }
interface IPEPE { function transferFrom(address from_, address to_, uint256 amount_) external; }
interface IMSUMO { function ownerOf(uint256 tokenId_) external view returns (address); }
contract PEPECHANGE is Ownable {
    ICSG private CSG = ICSG(0xBFd68FB24C6C6E37F00152800D1982A8e8d74Efb);
    IPEPE private PEPE = IPEPE(0x6982508145454Ce325dDbE47a25d4ec3d2311933);
    IMSUMO private MSUMO = IMSUMO(0xEE0e0b6c76d528B07113bB5709b30822DE46732B);
    uint256 public constant cost = 69 ether;
    function pepeChangeTrait(uint16 tokenId_) external {
        require(MSUMO.ownerOf(tokenId_) == msg.sender, "Not Owner");
        PEPE.transferFrom(msg.sender, owner, cost);
        CSG.adminChangeTrait(tokenId_, 3, 69);
    }
}