// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./IERC4494.sol";

interface IDeNFT is IERC721Upgradeable, IERC4494 {
    /// @dev Mints a new token and transfers it to `to` address
    /// @param _to new token's owner
    /// @param _tokenId new token's id
    /// @param _tokenUri new token's URI
    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenUri
    ) external;

    /// @dev Mints multiple tokens sequentially in a single call, taking each token's ID and URI
    ///      from the given arrays correspondingly, and transfers each token to the `msg.sender`
    function mintMany(uint256[] memory _tokenIds, string[] memory _tokenUris) external;

    /// @dev Mints multiple tokens sequentially in a single call, taking each object's ID and URI
    ///      from the given arrays correspondingly, and transfers each token to the given `_to` recipient
    function mintMany(
        address _to,
        uint256[] memory _tokenIds,
        string[] memory _tokenUris
    ) external;

    /// @dev Mints multiple tokens sequentially in a single call, taking each object's owner, ID and URI
    ///      from the given arrays correspondingly, and transfers each token to the corresponding owner's address
    function mintMany(
        address[] memory _to,
        uint256[] memory _tokenIds,
        string[] memory _tokenUris
    ) external;

    function burn(uint256 _tokenId) external;

    /* ========== OWNER METHODS  ========== */

    function addMinter(address _minter) external;

    function revokeMinter(address _minter) external;

    /// @dev This method revokes owner and all registered minters, leaving only the DeNftBridge
    ///      as a minter, which is necessary to burn/mint objects which travel across chains
    function revokeOwnerAndMinters() external;

    /* ========== VIEWS  ========== */
    function hasMinterAccess(address sender) external view returns (bool hasAccess);
}