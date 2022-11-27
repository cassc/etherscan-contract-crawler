// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
  uint256 public minAmount;
  address payable public VAULT;

  //ERC-165 identifier
  bytes4 _ERC721 = 0x80ac58cd;
  bytes4 _ERC1155 = 0xd9b67a26;

  //events
  event NftSold(address seller, address tokenContract, uint256 tokenId);
  event NftBoughtback(address seller, address tokenContract, uint256 tokenId);
  event ERC20Sold(address sender, address tokenContract, uint256 amount);
  event ERC20Boughtback(address sender, address tokenContract, uint256 amount);

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
    require(msg.value >= buybackFee, "You need to send at least 0.03 eth (buyback fee)");
    require(msg.sender.balance > msg.value, "You do not have enough ether");
    ERCBase token = ERCBase(tokenContract);
    if (token.supportsInterface(_ERC721)) {
      ERC721Partial(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId);
    } else if (token.supportsInterface(_ERC1155)) {
      ERC1155Partial(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
    }
    emit NftBoughtback(msg.sender, tokenContract, tokenId);
  }

  function sellERC20Tokens(address tokenContract, uint256 amount) public payable whenNotPaused {
    require(amount >= minAmount, "Amount less than minimum amount which is 0.0001");
    require(IERC20(tokenContract).allowance(msg.sender, address(this)) >= amount, "You need to approve contract to spend on your behalf");
    IERC20(tokenContract).transferFrom(msg.sender, address(this), amount);
    require(address(this).balance > amountToSend, "Not enough ether in contract.");
    (bool sent, ) = payable(msg.sender).call{ value: amountToSend }("");
    require(sent, "Failed to send ether.");
    emit ERC20Sold(msg.sender, tokenContract, amount);
  }

  function buybackERC20Tokens(address tokenContract, uint256 amount) public payable whenNotPaused {
    if (msg.value == 0) {
      revert NoEtherSent();
    }
    require(msg.value >= buybackFee, "You need to send at least 0.03 eth (buyback fee)");
    require(msg.sender.balance > msg.value, "You do not have enough ether");
    uint256 tokenBalance = IERC20(tokenContract).balanceOf(address(this));
    require(tokenBalance >= amount, "Contract does not have enough tokens");
    IERC20(tokenContract).transfer(msg.sender, amount);
    emit ERC20Boughtback(msg.sender, tokenContract, amount);
  }

  function withdrawNFT(address tokenContract, uint256 tokenId) public onlyOwner {
    ERCBase token = ERCBase(tokenContract);
    if (token.supportsInterface(_ERC721)) {
      ERC721Partial(tokenContract).safeTransferFrom(address(this), VAULT, tokenId);
    } else if (token.supportsInterface(_ERC1155)) {
      ERC1155Partial(tokenContract).safeTransferFrom(address(this), VAULT, tokenId, 1, "");
    }
  }

  function withdrawERC20Token(address tokenContract) public onlyOwner {
    IERC20(tokenContract).transferFrom(address(this), VAULT, IERC20(tokenContract).balanceOf(address(this)));
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

  function minimumTokenAmount(uint256 minimum) public onlyOwner {
    minAmount = minimum;
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