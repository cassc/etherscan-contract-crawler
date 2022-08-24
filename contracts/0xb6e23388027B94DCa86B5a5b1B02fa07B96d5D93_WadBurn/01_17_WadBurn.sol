// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: laurentcastellani.com

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract WadBurn is AdminControl, ICreatorExtensionTokenURI {

  address private _creator;
  uint private burnableTokenId;
  uint256[] private mintedTokenIds; 
  bool private initialized;
  string[] private assetURIs = new string[](4);

  address private wadContract;
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
   * Pushes the deactivation time to 7 days past the call's blocktime
   */
  function setActive() public adminRequired {
    deactivationTimestamp = block.timestamp + 7*86400;
  }

  /*
   * Can only be called once.
   * Creates the token that users will later mint via burn-redeem.
   */
  function initialize() public adminRequired {
    require(!initialized, 'Initialized');
    initialized = true;

    address[] memory addressToSend = new address[](1);
    addressToSend[0] = msg.sender;
    
    uint256[] memory amount = new uint256[](4);
    amount[0] = 1;
    amount[1] = 1;
    amount[2] = 1;
    amount[3] = 1;
  
    string[] memory uris = new string[](4);
    uris[0] = "";
    uris[1] = "";
    uris[2] = "";
    uris[3] = "";


    // forge 4 completely separate 1155 token that this extension can mint
    mintedTokenIds = IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amount, uris);
  }

  /*
   * See {ICreatorExtensionTokenURI-tokenURI}
   */
  function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
    require(creator == _creator, "Invalid creator");
    require(tokenId >= mintedTokenIds[0] && tokenId <= mintedTokenIds[3], "Invalid token");
    return assetURIs[tokenId - mintedTokenIds[0]];
  }

/*
   * Sets the URIs for the 4 tokens minted and controlled by this extension.
   */
  function setAssetURIs(string memory uri, string memory bonus1uri, string memory bonus2uri, string memory bonus3uri) public adminRequired {
    assetURIs[0] = uri;
    assetURIs[1] = bonus1uri;
    assetURIs[2] = bonus2uri;
    assetURIs[3] = bonus3uri;
  }

  /*
   * Public minting function with burn-redeem mechanism.
   * User must burn 10 WAD to receive the new token.
   * If the user burns a multiple of 10, they will get that multiple of each of the new tokens.
   * If the user burns 30 WADs or more, they will get 3 tokens (or more) + 1 bonus1
   * If the user burns 60 WADs or more, they will get 6 tokens (or more) + 1 bonus1 & 1 bonus2
   * If the user burns 100 WADs or more, they will get 10 tokens (or more) + 1 bonus1 & 1 bonus2 & 1 bonus3
   */
  function burnRedeem(uint256 amount) public {
    require(IERC1155(wadContract).balanceOf(msg.sender, burnableTokenId) >= 10 * amount, "Must own 10x WAD");
    require(IERC1155(wadContract).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");
    require(block.timestamp < deactivationTimestamp, "Inactive");
    require(amount > 0, "None");

    uint[] memory tokenIds = new uint[](1);
    tokenIds[0] = burnableTokenId;

    uint[] memory burnAmounts = new uint[](1);
    burnAmounts[0] = 10 * amount;

    try IERC1155CreatorCore(wadContract).burn(msg.sender, tokenIds, burnAmounts) {
    } catch (bytes memory) {
        revert("BurnRedeem: Burn failure");
    }

    address[] memory addressToSend = new address[](1);
    addressToSend[0] = msg.sender;

    uint[] memory numToSend = new uint[](4);
    numToSend[0] = amount;
    numToSend[1] = amount>=3 ? 1:0;
    numToSend[2] = amount>=6 ? 1:0;
    numToSend[3] = amount>=10 ? 1:0;

    IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, mintedTokenIds, numToSend);
  }
    
}