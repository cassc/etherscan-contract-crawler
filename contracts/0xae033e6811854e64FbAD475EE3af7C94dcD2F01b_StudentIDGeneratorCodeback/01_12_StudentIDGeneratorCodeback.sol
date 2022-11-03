//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StudentIDGeneratorCodeback {
  address public trustee;
  uint256 public balance;

  using Strings for uint256;
  using SafeMath for uint256;

  event CodebackDeployed(address _creator, address _trustee, string _message);
  // This only works for ETH and ERC721.SafeTransferFrom, not ERC20 or ERC721.TransferFrom. To get all tip events, will have to monitor for token transfer events to all known Codeback addresses
  event CodebackTipReceived(address _from, address _token, uint _amount);
  event CodebackTipClaimed(address _to, address _token, uint _amount);
  event CodebackUsed(address _from);
  event CodebackTrusteeChanged(address _from, address _to);

  constructor(address trusteeWallet) {
    trustee = trusteeWallet;
    emit CodebackDeployed(msg.sender, trustee, "Codeback Deployed");
  }

  receive() payable external {
    balance += msg.value;
    emit CodebackTipReceived(msg.sender, address(0x0000000000000000000000000000000000000000), msg.value);
  }

  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public virtual returns (bytes4) {
      emit CodebackTipReceived(_from, msg.sender, 1);
      return this.onERC721Received.selector;
  }

  function withdraw(uint amount, address payable destAddr) public {
    require(msg.sender == trustee, "Only the trustee can withdraw funds");
    require(amount <= balance, "Insufficient funds");

    destAddr.transfer(amount);
    balance -= amount;
    emit CodebackTipClaimed(msg.sender, address(0x0000000000000000000000000000000000000000), amount);
  }

  function withdrawERC20(IERC20 token, uint amount, address payable destAddr) public {
    require(msg.sender == trustee, "Only the trustee can withdraw tokens");
    uint256 erc20balance = token.balanceOf(address(this));
    require(amount <= erc20balance, "Insufficient funds");

    token.transfer(destAddr, amount);
    emit CodebackTipClaimed(msg.sender, address(token), amount);
  }

  function withdrawERC721(IERC721 token, uint tokenId, address payable destAddr) public {
    require(msg.sender == trustee, "Only the trustee can withdraw tokens");
    require(token.ownerOf(tokenId) == address(this));

    token.safeTransferFrom(address(this), destAddr, tokenId);
    emit CodebackTipClaimed(msg.sender, address(token), 1);
  }

  function changeTrustee(address newTrustee) public {
    require(msg.sender == trustee, "Only the trustee can change the trustee");
    require(newTrustee != trustee, "New trustee must be different from current trustee");
    trustee = newTrustee;
    emit CodebackTrusteeChanged(msg.sender, newTrustee);

  }

  function generateRandomStudentId(string memory _identifier) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(_identifier))) % 10**24; //10 is modulus and 24 is student id digits based on number of layers
  }

  function setStudentId(uint256 tokenId, address wallet) public returns (uint256) {
    emit CodebackUsed(msg.sender);
    return uint256(generateRandomStudentId(string(abi.encodePacked(tokenId.toString(), wallet))));
  } 

}