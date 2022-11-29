// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice Extended ERC721 interface with methods required by the Rentals contract.
interface IERC721Rentable is IERC721 {
    /// @dev Updates the operator of the asset.
    /// The idea of this role is mostly of a content operator, a role capable of modifying the content of the asset.
    /// It is not the same as the one defined in the ERC721 standard, which can manipulate the asset in itself.
    function setUpdateOperator(uint256, address) external;

    /// @dev Updates the update operator of many DCL LANDs simultaneously inside an Estate.
    function setManyLandUpdateOperator(
        uint256 _tokenId,
        uint256[] memory _landTokenIds,
        address _operator
    ) external;

    /// @dev Checks that the provided fingerprint matches the fingerprint of the composable asset.
    function verifyFingerprint(uint256, bytes memory) external view returns (bool);
}