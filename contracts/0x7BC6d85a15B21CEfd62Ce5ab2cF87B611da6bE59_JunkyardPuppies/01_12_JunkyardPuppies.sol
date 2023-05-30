pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/token/erc721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract JunkyardPuppies is ERC721, Ownable {
  string internal uri = "https://api.junkyarddogs.io/puppies?tokenId=";
  mapping (bytes32 => bool) signatureUsed;
  uint256 public totalSupply = 0;
  uint256 public cost = 0.06 ether;
  uint256 public remainingForSale = 0;

  event RedeemedPumpkinPass(address redeemer, uint256 passId);

  constructor() ERC721("JunkyardPuppies", "JYP") {}

  function buyWithPumpkinPass(uint256 passId, uint256 amount, bytes memory signature) public {
    require(amount > 0, "You must mint at least 1");
    bytes32 messageHash = keccak256(abi.encodePacked("mint puppy", msg.sender, passId, amount));
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);
    require(!signatureUsed[digest], "This signature has already been used");

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner(), "Invalid signature");
    signatureUsed[digest] = true;

    for (uint256 i = 1; i <= amount; i++) {
      _mint(msg.sender, totalSupply + i);
    }
    totalSupply += amount;
    emit RedeemedPumpkinPass(msg.sender, passId);
  }

  function buyWithEth(uint256 amount) public payable {
    require(amount > 0, "You must mint at least 1");
    require(remainingForSale >= amount, "Not enough for sale");
    uint256 totalCost = cost * amount;
    require(totalCost <= msg.value, "You must send enough eth");

    remainingForSale -= amount;
    for (uint256 i = 1; i <= amount; i++) {
      _mint(msg.sender, totalSupply + i);
    }
    totalSupply += amount;
  }

  function setCost(uint256 c) public onlyOwner {
    cost = c;
  }

  function setUri(string memory u) public onlyOwner {
    uri = u;
  }

  function setRemaining(uint256 r) public onlyOwner {
    remainingForSale = r;
  }

  function withdraw(address to) public onlyOwner {
    require(to != address(0), "You must send to a valid address");
    uint balance = address(this).balance;
    payable(to).transfer(balance);
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return uri;
  }
}