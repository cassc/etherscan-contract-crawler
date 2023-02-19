// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOnChainMetadata {
    /**
     * Mint new tokens.
     */
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}