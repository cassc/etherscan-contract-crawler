// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IRoleAuthority} from "../interfaces/internal/IRoleAuthority.sol";
import {IMetadataResolver} from "../interfaces/internal/IMetadataResolver.sol";
import {NotOperator} from "../auth/Errors.sol";

/**
 * @notice A centralised contract to return the token URI for a DecaCollection token.
 *         Allows all DecaCollections to have their token URI updated with a single transaction.
 * @author 0x-jj, j6i
 */
contract MetadataResolver is IMetadataResolver {
  using StringsUpgradeable for uint256;
  using StringsUpgradeable for address;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the RoleAuthority used to determine whether an address has some admin role.
   */
  IRoleAuthority public immutable roleAuthority;

  /**
   * @notice The base URI for all tokens
   */
  string public baseUri;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  /**
   * @param _baseUri The base URI for the NFT metadata
   */
  constructor(string memory _baseUri, address _roleAuthority) {
    baseUri = _baseUri;
    roleAuthority = IRoleAuthority(_roleAuthority);
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Updates the base URI for all tokens
   * @param _baseUri The new base URI
   */
  function updateBaseUri(string calldata _baseUri) external {
    if (!roleAuthority.isOperator(msg.sender)) revert NotOperator();
    baseUri = _baseUri;
  }

  /*//////////////////////////////////////////////////////////////
                                 PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the token URI for a token
   * @param contractAddress The contract address for the token
   * @param tokenId The token ID
   */
  function tokenUri(address contractAddress, uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(baseUri, contractAddress.toHexString(), "/", tokenId.toString()));
  }
}