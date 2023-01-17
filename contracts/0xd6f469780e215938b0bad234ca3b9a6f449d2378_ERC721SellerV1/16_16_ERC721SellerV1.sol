//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin-upgradable/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin-upgradable/contracts/proxy/utils/UUPSUpgradeable.sol';
import './AdminableUpgradable.sol';

/*
 * @title ERC721 Seller
 * @description transfer ERC721 token to user when paid with fiat money
 * @author WayneHong @ Havbeat
 */

abstract contract OwnableERC721 is IERC721, Ownable {

}

contract ERC721SellerV1 is Initializable, UUPSUpgradeable, AdminableUpgradable {
  error InvokeContractWithAbiFail(bytes data);

  event InvokeContractWithAbi(address indexed tokenAddress, bool success, bytes data);
  event SendNFT(address indexed tokenAddress, address indexed to, uint256 indexed tokenId);
  event WithdrawCoin(uint256 amount);
  event WithdrawToken(address indexed tokenAddress, uint256 amount);
  event ReceiveFund(address indexed from, uint256 amount);

  address private payoutAddress;

  function initialize(address _payoutAddress) public initializer {
    payoutAddress = _payoutAddress;
    __Adminable_init();
  }

  function callContractWithSelector(address tokenAddress, bytes memory tokenCallAbi) external payable onlyAdmin {
    (bool success, bytes memory data) = tokenAddress.call{value: msg.value}(tokenCallAbi);
    emit InvokeContractWithAbi(tokenAddress, success, data);

    if (!success) revert InvokeContractWithAbiFail(data);
  }

  function sendOwnedNFT(
    address tokenAddress,
    address to,
    uint256 tokenId
  ) external onlyAdmin {
    OwnableERC721 token = OwnableERC721(tokenAddress);
    token.transferFrom(address(this), to, tokenId);

    emit SendNFT(tokenAddress, to, tokenId);
  }

  function withdrawCoin(uint256 amount) external onlyOwner {
    uint256 accountBalance = address(this).balance;
    uint256 withdrawAmount = amount == 0 ? accountBalance : amount;

    payable(payoutAddress).transfer(withdrawAmount);
    emit WithdrawCoin(withdrawAmount);
  }

  function withdrawToken(address tokenAddress, uint256 amount) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    uint256 accountBalance = token.balanceOf(address(this));
    uint256 withdrawAmount = amount == 0 ? accountBalance : amount;

    token.transfer(payoutAddress, withdrawAmount);
    emit WithdrawToken(tokenAddress, withdrawAmount);
  }

  function transferTokenOwnership(address tokenAddress, address newOwner) external onlyOwner {
    OwnableERC721 token = OwnableERC721(tokenAddress);
    token.transferOwnership(newOwner);
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  receive() external payable {
    emit ReceiveFund(msg.sender, msg.value);
  }
}