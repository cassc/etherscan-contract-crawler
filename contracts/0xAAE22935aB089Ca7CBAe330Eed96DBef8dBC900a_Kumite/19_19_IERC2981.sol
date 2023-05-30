// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// taken from here:
//   https://eips.ethereum.org/EIPS/eip-2981

/**
 * @dev Implementation of royalties for 721s
 *
 */
interface IERC2981 is IERC165 {
    /*
     * ERC165 bytes to add to interface array - set in parent contract implementing this standard
     *
     * bytes4(keccak256('royaltyInfo()')) == 0x46e80720
     * bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x46e80720;
     * _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
     */
    /**
    /**
     *      @notice Called to return both the creator's address and the royalty percentage - this would be the main function called by marketplaces unless they specifically        *       need just the royaltyAmount
     *       @notice Percentage is calculated as a fixed point with a scaling factor of 10,000, such that 100% would be the value (1000000) where, 1000000/10000 = 100. 1%          *        would be the value 10000/10000 = 1
     */
    function royaltyInfo(uint256 _tokenId) external returns (address receiver, uint256 amount);
}