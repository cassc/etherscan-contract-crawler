// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../utils/AccessLock.sol";

/// @title IMoonRatzWTF
/// @author 0xhohenheim <[email protected]>
/// @notice Interface for the MoonRatzWTF NFT contract
interface IMoonRatzWTF is IERC721 {
    /// @notice - Mint NFT
    /// @dev - callable only by admin
    /// @param recipient - mint to
    /// @param quantity - number of NFTs to mint
    function mint(address recipient, uint256 quantity) external;
}