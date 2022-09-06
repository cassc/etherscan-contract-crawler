// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IERC721AQueryable {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}