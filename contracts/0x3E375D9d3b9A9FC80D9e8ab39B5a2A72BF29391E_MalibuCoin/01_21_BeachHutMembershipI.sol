//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BeachHutMembershipI is IERC1155, Ownable {
    function balanceOf(address account, uint256 id) external view virtual override returns (uint256);

    function totalSupply(uint256 id) external view virtual returns (uint256);

    function getMintedPerAddress(address account) public view virtual returns(uint256);

    function exists(uint256 id) public view virtual returns (bool);

    function getLastRewarded(address account) external view virtual returns (uint256);

    function setLastRewarded(address account) external virtual;

    function getMembershipTokenCount(address account) public view virtual returns (uint256);

    function getRetroActiveRewards(address account) external view virtual returns (uint256);

    function resetRetroActiveRewards(address account) external virtual;
}