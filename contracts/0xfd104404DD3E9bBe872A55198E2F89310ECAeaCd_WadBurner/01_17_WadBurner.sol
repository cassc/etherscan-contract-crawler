// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: laurentcastellani.com

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract WadBurner is AdminControl, ICreatorExtensionTokenURI {

  address private _creator;
  uint private burnableTokenId;
  uint256[] private mintedTokenIds; 
  mapping (uint256=>string) private assetURIs;

  address private wadContract;
  uint256 public burnRatio;
  uint256 public deactivationTimestamp = 0;

  constructor(address creator) {
    _creator = creator;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
    return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
  }

  /*
   * Allows us to set the contract and token ID eligible for burning
   */
  function setBurnableContractAndToken(address theContract, uint tokenId) public adminRequired {
    wadContract = theContract;
    burnableTokenId = tokenId;
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
  function initialize(uint256 _burnRatio, address[] calldata premints) public adminRequired {
    burnRatio = _burnRatio;

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

  /*
   * Public minting function with burn-redeem mechanism.
   * User must burn "burnRatio" WADs to receive the new token.
   */
  function burnRedeem(uint256 amount) public {
    require(IERC1155(wadContract).balanceOf(msg.sender, burnableTokenId) >= burnRatio * amount, "Not enough WADs");
    require(IERC1155(wadContract).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");
    require(block.timestamp < deactivationTimestamp, "Inactive");
    require(amount > 0, "None");

    uint[] memory tokenIds = new uint[](1);
    tokenIds[0] = burnableTokenId;

    uint[] memory burnAmounts = new uint[](1);
    burnAmounts[0] = burnRatio * amount;

    try IERC1155CreatorCore(wadContract).burn(msg.sender, tokenIds, burnAmounts) {
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