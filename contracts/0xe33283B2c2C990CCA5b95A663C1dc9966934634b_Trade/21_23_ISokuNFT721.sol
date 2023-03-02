// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISokuNFT721 is IERC721{
    function owner() external returns (address);

}