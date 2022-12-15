// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
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
  //contract variables
  uint256 public buybackFee;
  uint256 public amountToSend;
  address payable public VAULT;

  //ERC-165 identifier
  bytes4 _ERC721 = 0x80ac58cd;
  bytes4 _ERC1155 = 0xd9b67a26;

  // mappings
  mapping(address => mapping(uint256 => mapping(address => uint256))) public nftBalanceForBuyback;

  //events
  event NftSold(address seller, address tokenContract, uint256 tokenId);
  event NftBoughtback(address seller, address tokenContract, uint256 tokenId);

  function supportsInterface(bytes4 interfaceID) public virtual override view returns (bool) {
    return interfaceID == type(IERC1155Receiver).interfaceId;
  }

  function onERC721Received(
    address,
    address from,
    uint256 tokenId,
    bytes memory
  ) whenNotPaused public virtual override returns (bytes4) {
    require(ERCBase(msg.sender).supportsInterface(_ERC721) == true, 'Msg sender is not erc721');
    require(address(this).balance > amountToSend, "Not enough ether in contract.");
    (bool sent, ) = payable(from).call{ value: amountToSend }("");
    require(sent, "Failed to send ether.");
    nftBalanceForBuyback[msg.sender][tokenId][from] += 1;
    emit NftSold(from, msg.sender, tokenId);
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address,
    address from,
    uint256 tokenId,
    uint256,
    bytes memory
  ) whenNotPaused public virtual override returns (bytes4) {
    require(ERCBase(msg.sender).supportsInterface(_ERC1155) == true, 'Msg sender is not erc1155');
    require(address(this).balance > amountToSend, "Not enough ether in contract.");
    (bool sent, ) = payable(from).call{ value: amountToSend }("");
    require(sent, "Failed to send ether.");
    nftBalanceForBuyback[msg.sender][tokenId][from] += 1;
    emit NftSold(from, msg.sender, tokenId);
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

  function buyback(address tokenContract, uint256 tokenId) public payable whenNotPaused {
    if (msg.value == 0) {
      revert NoEtherSent();
    }
    require(msg.value >= buybackFee, "You need to send more than 0 ether at least");
    require(msg.sender.balance > msg.value, "You do not have enough ether");
    require(nftBalanceForBuyback[tokenContract][tokenId][msg.sender] > 0, "You canont buy back this nft because it belongs to someone else");
    ERCBase token = ERCBase(tokenContract);
    if (token.supportsInterface(_ERC721)) {
      ERC721Partial(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId);
    } else if (token.supportsInterface(_ERC1155)) {
      ERC1155Partial(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
    }
    nftBalanceForBuyback[tokenContract][tokenId][msg.sender] -= 1;
    emit NftBoughtback(msg.sender, tokenContract, tokenId);
  }

  function withdrawNFT(address tokenContract, address originalOwner, uint256 tokenId) public onlyOwner {
    ERCBase token = ERCBase(tokenContract);
    if (token.supportsInterface(_ERC721)) {
      ERC721Partial(tokenContract).safeTransferFrom(address(this), VAULT, tokenId);
    } else if (token.supportsInterface(_ERC1155)) {
      ERC1155Partial(tokenContract).safeTransferFrom(address(this), VAULT, tokenId, 1, "");
    }
    nftBalanceForBuyback[tokenContract][tokenId][originalOwner] -= 1;
  }

  function setVaultAddress(address vault) public onlyOwner {
    VAULT = payable(vault);
  }

  function setAmountToSend(uint256 amount) public onlyOwner {
    amountToSend = amount;
  }

  function setBuybackFee(uint256 amount) public onlyOwner {
    buybackFee = amount;
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