// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MogulERC1155.sol";
import "./FactoryInterfaces.sol";

// ERC1155 Factory
contract ERC1155Factory is Ownable, IERC1155Factory {
  address tokenImplementation;
  event ERC1155Created(address contractAddress, address owner);

  constructor() {
    tokenImplementation = address(new MogulERC1155());
  }

  function setTokenImplementation(address _tokenImplementation)
    public
    onlyOwner
  {
    tokenImplementation = _tokenImplementation;
  }

  function createERC1155(address owner) external override {
    address clone = Clones.clone(tokenImplementation);
    IInitializableERC1155(clone).init(owner);
    emit ERC1155Created(clone, owner);
  }
}