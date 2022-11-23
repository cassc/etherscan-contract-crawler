// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: laurentcastellani.com

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract EditionsBurner is AdminControl, ICreatorExtensionTokenURI {

  address private _creator;
  uint256[] private burnableTokenIds;
  uint256[] private mintedTokenIds; 
  mapping (uint256=>string) private assetURIs;

  uint[] public burnRatios;
  uint256 public deactivationTimestamp = 0;

  constructor(address creator) {
    _creator = creator;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
    return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
  }

  /*
   * Pushes the deactivation time to x days past the call's blocktime
   */
  function setActive(uint8 _days) public adminRequired {
    deactivationTimestamp = block.timestamp + _days*86400;
  }

  /*
   * Can only be called once.
   * Creates the token that users will later mint via burn-redeem.
   */
  function initialize(uint[] calldata _burnRatios, uint256[] calldata _tokenIds, address[] calldata premints) public adminRequired {

    require(_burnRatios.length == _tokenIds.length);

    burnRatios = _burnRatios;
    burnableTokenIds = _tokenIds;

    uint256[] memory amount = new uint256[](1);
    amount[0] = 1;
    
    string[] memory uris = new string[](1);
    uris[0] = "";

    // forge 1155 token that this extension can mint
    mintedTokenIds = IERC1155CreatorCore(_creator).mintExtensionNew(premints, amount, uris);
  }

  /*
   * See {ICreatorExtensionTokenURI-tokenURI}
   */
  function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
    require(creator == _creator, "Invalid creator");
    return assetURIs[tokenId];
  }

/*
   * Sets the URIs for the 4 tokens minted and controlled by this extension.
   */
  function setAssetURIs(uint256 tokenId, string memory uri) public adminRequired {
    assetURIs[tokenId] = uri;
  }

  function indexOfToken(uint256 searchFor) private view returns (bool,uint256) {
    for (uint256 i = 0; i < burnableTokenIds.length; i++) {
      if (burnableTokenIds[i] == searchFor) {
        return (true,i);
      }
    }
    return (false,0); // not found
  }

  /*
   * Public minting function with burn-redeem mechanism.
   * User must burn one of the allowed tokens to receive the "amount" new token.
   */
  function burnRedeem(uint256 tokenId, uint256 amount) public {
    (bool tokenFound,uint256 tokenIndex) = indexOfToken(tokenId);
    require(tokenFound);
    require(IERC1155(_creator).balanceOf(msg.sender, tokenId) >= burnRatios[tokenIndex] * amount, "Not enough tokens");
    require(IERC1155(_creator).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");
    require(block.timestamp < deactivationTimestamp, "Inactive");
    require(amount > 0, "None");

    uint[] memory tokenIds = new uint[](1);
    tokenIds[0] = tokenId;

    uint[] memory burnAmounts = new uint[](1);
    burnAmounts[0] = burnRatios[tokenIndex] * amount;

    try IERC1155CreatorCore(_creator).burn(msg.sender, tokenIds, burnAmounts) {
    } catch (bytes memory) {
        revert("BurnRedeem: Burn failure");
    }

    address[] memory addressToSend = new address[](1);
    addressToSend[0] = msg.sender;

    uint[] memory numToSend = new uint[](1);
    numToSend[0] = amount;

    IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, mintedTokenIds, numToSend);
  }
    
}