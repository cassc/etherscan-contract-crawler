// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Guido Di Salle

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol"; 

contract ExtraHotSicilianKiss is AdminControl, ICreatorExtensionTokenURI {

  bool private _initialized;
  string private _assetURI; 

  address private _sicilianKissContract;
  uint private _burnableTokenId;
  address private _newTokenContract;
  uint private _newTokenId;

  uint256 public deactivationTimestamp;

  function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
    return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
  }

  /*
   * Allows us to set the contract and token ID eligible for burning
   */
  function configure(address sicialianKissContract, uint tokenId, address newTokenContract) public adminRequired {
    _sicilianKissContract = sicialianKissContract;
    _burnableTokenId = tokenId;
    _newTokenContract = newTokenContract;
  }

  /*
   * Pushes the deactivation time to 24hrs past the call's blocktime
   */
  function setActive() public adminRequired {
    deactivationTimestamp = block.timestamp + 86400;
  }

  /*
   * Can only be called once.
   * Creates the base token that users will later mint via burn-redeem.
   */
  function initialize() public adminRequired {
    require(!_initialized, "Already initialized.");
    _initialized = true;

    address[] memory addressToSend = new address[](1);
    addressToSend[0] = msg.sender;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 1;
    string[] memory uris = new string[](1);
    uris[0] = "";

    uint256[] memory mintedTokenIds = IERC1155CreatorCore(_newTokenContract).mintExtensionNew(addressToSend, amounts, uris);
    _newTokenId = mintedTokenIds[0];
  }

  /*
   * Public minting function with burn-redeem mechanism.
   * User must burn 15 Sicilian Kiss to receive 1 new token.   
   */
  function mint() public {
    require(IERC1155(_sicilianKissContract).balanceOf(msg.sender, _burnableTokenId) >= 15, "Must own 15+ Kisses");
    require(IERC1155(_sicilianKissContract).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");
    require(block.timestamp < deactivationTimestamp, "Inactive");

    uint[] memory tokenIds = new uint[](1);
    tokenIds[0] = _burnableTokenId;

    uint[] memory burnAmount = new uint[](1);
    burnAmount[0] = 15;

    try IERC1155CreatorCore(_sicilianKissContract).burn(msg.sender, tokenIds, burnAmount) {
    } catch (bytes memory) {
        revert("BurnRedeem: Burn failure");
    }

    address[] memory addressToSend = new address[](1);
    addressToSend[0] = msg.sender;

    uint[] memory numToSend = new uint[](1);
    numToSend[0] = 1;

    uint[] memory tokenToSend = new uint[](1);
    tokenToSend[0] = _newTokenId;
    IERC1155CreatorCore(_newTokenContract).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
  }

  /*
   * Sets the URIs for the token minted and controlled by this extension.
   */
  function setAssetURI(string memory assetURI) public adminRequired {
    _assetURI = assetURI;
  }

  /*
   * See {ICreatorExtensionTokenURI-tokenURI}
   */
  function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
    require(creator == _newTokenContract && tokenId == _newTokenId, "Invalid token");
    return _assetURI;
  }
}