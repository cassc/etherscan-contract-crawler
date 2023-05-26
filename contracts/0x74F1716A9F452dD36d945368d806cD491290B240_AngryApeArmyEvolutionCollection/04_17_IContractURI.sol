// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the proposed contractURI standard
///
interface IContractURI is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("contractURI()")) == 0xe8a3d485

    /// @notice Called to return the URI pertaining to the contract metadata
    /// @return contractURI - the URI that pertaining to the contract metadata
    function contractURI() external view returns (string memory);
}