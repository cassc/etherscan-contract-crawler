// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC2981Royalties.sol";

/// @title IIkonicERC1155Token
/// @dev Interface for IIkonicERC1155Token
interface IIkonicERC1155Token is IERC1155, IERC2981Royalties{
    /**
     * @dev Returns signer address.
    */
    function getSignerAddress() external view returns(address);
}