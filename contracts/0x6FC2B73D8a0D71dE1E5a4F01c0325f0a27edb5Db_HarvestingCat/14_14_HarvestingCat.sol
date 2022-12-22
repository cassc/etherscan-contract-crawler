// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error NoEtherSent();

interface ERCBase {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function isApprovedForAll(address account, address operator) external view returns (bool);
}

interface ERC721Partial is ERCBase {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC1155Partial is ERCBase {
  function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata) external;
}

contract HarvestingCat is ReentrancyGuard, Ownable, IERC721Receiver, IERC1155Receiver, Pausable {
  using SafeERC20 for IERC20;

  //contract variables
  address payable public VAULT;

  //ERC-165 identifier
  bytes4 _ERC721 = 0x80ac58cd;
  bytes4 _ERC1155 = 0xd9b67a26;

  //events
  event NftTransferred(address from, address to, address tokenContract, uint256 tokenId);

  function supportsInterface(bytes4 interfaceID) public virtual override view returns (bool) {
    return interfaceID == type(IERC1155Receiver).interfaceId;
  }

  function onERC721Received(
    address,
    address,
    uint256 tokenId,
    bytes memory
  ) whenNotPaused public virtual override returns (bytes4) {
    require(ERCBase(msg.sender).supportsInterface(_ERC721) == true, 'Msg sender is not erc721');
    IERC721(msg.sender).safeTransferFrom(address(this), VAULT, tokenId);
    emit NftTransferred(address(this), VAULT, msg.sender, tokenId);
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address,
    address,
    uint256 tokenId,
    uint256 value,
    bytes calldata data
  ) whenNotPaused public virtual override returns (bytes4) {
    require(ERCBase(msg.sender).supportsInterface(_ERC1155) == true, 'Msg sender is not erc1155');
    IERC1155(msg.sender).safeTransferFrom(address(this), VAULT, tokenId, value, data);
    emit NftTransferred(address(this), VAULT, msg.sender, tokenId);
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) whenNotPaused public virtual override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function transferERC20Tokens(address tokenContract, uint256 amount) external onlyOwner {
    IERC20(tokenContract).safeTransferFrom(address(this), VAULT, amount);
  }

  function transferEther(uint256 amount) public onlyOwner {
    payable(VAULT).transfer(amount);
  }

  function setVaultAddress(address vault) public onlyOwner {
    VAULT = payable(vault);
  }

  function pause() onlyOwner public {
    _pause();
  }

  function unpause() onlyOwner public {
    _unpause();
  }

  function withdrawBalance() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  receive() external payable {}
}