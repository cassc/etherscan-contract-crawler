// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./NFT.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
  event NFTContractCreated(
    address indexed nftContract,
    address indexed owner,
    string name,
    string symbol,
    string uri,
    uint256 royalties,
    uint256 maxSupply
  );

  address public immutable tokenImplementation;

  constructor() {
    tokenImplementation = address(new NFT());
  }

  function createToken(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    uint256 _royalties,
    uint256 _maxSupply
  ) external onlyOwner returns (address) {
    address clone = Clones.clone(tokenImplementation);
    NFT(clone).initialize(_name, _symbol, _uri, _royalties, _maxSupply, _msgSender());

    emit NFTContractCreated(clone, _msgSender(), _name, _symbol, _uri, _royalties, _maxSupply);

    return clone;
  }
}