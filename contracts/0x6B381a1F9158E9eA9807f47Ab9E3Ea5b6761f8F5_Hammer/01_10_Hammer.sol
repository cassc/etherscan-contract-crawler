// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./safeMath.sol";

contract Hammer is ERC1155 {
  using safeMath for uint256;

  uint256 public maxSupply = 2400;
  uint256 public mintFee = 0.1 ether;
  uint256 public maxMint = 30;
  uint256 private totalSupply;
  uint256 private tokenIds;

  address private owner;
  address payable private renumeration;

  string name;

  modifier ownerOnly() {
      require(msg.sender == owner, "Sender is not owner");
      _;
  }

  constructor() ERC1155("https://ipfs.io/ipfs/QmecgCGZnjQpnyj8obXVzxywL5pmAskLRhJ9yUq9715HEF/{id}.json") {
    renumeration = payable(msg.sender);
    owner = msg.sender;
    setName("The Martelus Project");
  }



  function mint(uint amount) public payable {
    require(amount <= maxMint, "Max mint is 30");
    require(totalSupply <= maxSupply, "Reached max supply");
    require(msg.value >= mintFee * amount, "Insufficient funds");
    totalSupply += amount;

    for(uint256 a = 1; a <= amount; a = a.add(1)) {
      tokenIds = tokenIds.add(1);
      _mint(msg.sender, tokenIds, 1, "");
    }


    if(address(this).balance >= 300000000000000000) {
      autoWithdraw();
    }
  }

  function burn(address account, uint256 id, uint256 amount) public {
    require(msg.sender == account, "Sender is not the Token Owner");
    _burn(account, id, amount);
  }

  function autoWithdraw() internal {
    renumeration.transfer(address(this).balance);
  }

  function withdraw() public payable ownerOnly {
    (bool os, ) = payable(renumeration).call{value: address(this).balance}("");
    require(os);
  }

  function updateSupply(uint256 updatedSupply) public ownerOnly {
    maxSupply = updatedSupply;
  }

  function updateMint(uint256 updatedMint) public ownerOnly {
    maxMint = updatedMint;
  }

  function setURI(string memory newURI) public ownerOnly {
    _setURI(newURI);
  }

  function updateFee(uint256 updatedFee) public ownerOnly {
    mintFee = updatedFee;
  }

  function setName(string memory _name) public ownerOnly {
    name = _name;
  }

  function transferControl(address newOwner) public ownerOnly {
    owner = newOwner;
  }
}