// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface ILazyMint {
    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee
    ) external returns(uint256 _tokenId);
    
    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee,
        uint256 supply,
        uint256 qty
    ) external returns(uint256 _tokenId);
}