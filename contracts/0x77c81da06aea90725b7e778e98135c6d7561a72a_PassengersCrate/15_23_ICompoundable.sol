// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
interface ICompoundable is IERC721Upgradeable{

    function getTokenAttachTo(uint256 tokenId) external view returns (address baseToken, uint256 baseTokenId);
    function hasAttachment (uint256 tokenId) external view returns (bool);
    function releaseToken(address to, address nftAddress, uint256 tokenId) external;
    function isCompoundable() external view returns (bool);
    function isContract(address addr) external returns (bool);
    function topOwnerOf(uint256 attachmentToken) external view returns(address topOwner);
    function getHeadOf(address childAddress, uint256 childTokenId) external view returns(uint256);
}