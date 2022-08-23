// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC2981Royalties.sol";

/// @title IIkonicERC721Token
/// @dev Interface for IIkonicERC721Token
interface IIkonicERC721Token is IERC721, IERC2981Royalties{
    /**
     * @dev Returns signer address.
    */
    function getSignerAddress() external view returns(address);
}