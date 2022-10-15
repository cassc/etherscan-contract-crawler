// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ITraded is IERC165 {
    /// @notice Update traded value to true
    event UpdatedTraded(uint256 indexed _tokenId);

    /// @notice For check if the token has been traded before or not
    /// @dev Can be a simple mapping to return false as it would create the same getter
    /// @param _tokenId Id of the token to check if it has been traded before or not
    /// @return bool value
    function isTraded(uint256 _tokenId) external view returns (bool);

    /// @notice To update the value of the token as true. This means token has been traded.
    /// @dev Generally called by the marketplace where the token was traded
    /// @param _tokenId Id of the token which was traded
    function traded(uint256 _tokenId) external;
}