// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ISBT is IERC165 {
    /// @dev This emits when an SBT is newly minted.
    ///  This event emits when SBTs are created
    event Mint(address indexed _owner, uint256 indexed _tokenId);

    /// @dev This emits when an SBT is burned
    ///  This event emits when SBTs are destroyed
    event Burn(address indexed _owner, uint256 indexed _tokenId);

    /// @notice Count all SBTs assigned to an owner
    /// @dev SBTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of SBTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an SBT
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an SBT
    /// @return The address of the owner of the SBT
    function ownerOf(uint256 _tokenId) external view returns (address);
}