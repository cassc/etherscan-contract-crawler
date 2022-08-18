// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract BurningSins is AdminControl, ICreatorExtensionTokenURI {
    string _tokenURI;
    address _burnableContractAddress;
    uint[] _burnableTokenIds;
    uint[] _burnAmounts;
    address _newTokenAddress;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function configure(address burnableContractAddress, uint[] memory burnableTokenIds, address newTokenAddress) public adminRequired {
      _burnableContractAddress = burnableContractAddress;
      _burnableTokenIds = burnableTokenIds;
      _newTokenAddress = newTokenAddress;

      for (uint i; i < burnableTokenIds.length; i++) {
        _burnAmounts.push(1);
      }
    }

    function mint() public {
      for (uint i; i < _burnableTokenIds.length; i++) {
        require(IERC1155(_burnableContractAddress).balanceOf(msg.sender, _burnableTokenIds[i]) > 0, "Not enough to burn.");
        require(IERC1155(_burnableContractAddress).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");
      }

      try IERC1155CreatorCore(_burnableContractAddress).burn(msg.sender, _burnableTokenIds, _burnAmounts) {
      } catch (bytes memory) {
          revert("BurnRedeem: Burn failure");
      }

      IERC721CreatorCore(_newTokenAddress).mintExtension(msg.sender);
    }

    function updateURI(string memory newTokenURI) public adminRequired {
      _tokenURI = newTokenURI;
    }

    function tokenURI(address creator, uint256) external view override returns (string memory) {
        require(creator == _newTokenAddress, "Invalid token");
        return _tokenURI;
    }
}