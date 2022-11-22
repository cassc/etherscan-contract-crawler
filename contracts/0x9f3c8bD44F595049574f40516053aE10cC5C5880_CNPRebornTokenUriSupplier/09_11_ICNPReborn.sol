// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "contract-allow-list/contracts/ERC721AntiScam/lockable/IERC721Lockable.sol";

interface ICNPReborn is IERC721Lockable {

    function isAdult(uint256 tokenId) external view returns (bool);

    function isChild(uint256 tokenId) external view returns (bool);

    function playGimmick(uint256 tokenId) external;

    function inCoolDownTime(uint256 tokenId) external view returns (bool);

    function nextTokenId() external view returns (uint256);
}