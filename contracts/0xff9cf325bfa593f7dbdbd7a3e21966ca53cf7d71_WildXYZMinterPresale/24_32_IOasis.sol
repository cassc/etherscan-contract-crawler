// SPDX-License-Identifier: GPL-3.0-or-later

// IOasis.sol - Simplified interface for the Oasis NFT contract

pragma solidity ^0.8.17;

interface IOasis {
    function balanceOf(address _address) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}