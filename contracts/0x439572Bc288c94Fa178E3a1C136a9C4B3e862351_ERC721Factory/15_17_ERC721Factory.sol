// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MogulERC721.sol";
import "./FactoryInterfaces.sol";

// ERC721 Factory
contract ERC721Factory is Ownable, IERC721Factory {
  address tokenImplementation;
  event ERC721Created(address contractAddress, address owner);

  constructor() {
    tokenImplementation = address(new MogulERC721());
  }

  function setTokenImplementation(address _tokenImplementation)
    public
    onlyOwner
  {
    tokenImplementation = _tokenImplementation;
  }

  function createERC721(address owner) external override {
    address clone = Clones.clone(tokenImplementation);
    IInitializableERC721(clone).init(owner);
    emit ERC721Created(clone, owner);
  }
}