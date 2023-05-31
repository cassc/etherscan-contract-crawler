// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract PendulumNft is ERC721URIStorage, Ownable {
  uint256 public tokenId;
  address private _minter;

  event MinterChanged(address indexed previousMinter, address indexed newMinter);

  constructor() ERC721('Pendulum NFT', 'PFT') {
    setMinter(owner());
  }

  modifier onlyMinter() {
    require(minter() == msg.sender, "PendulumNft: caller is not the minter");
    _;
  }

  function mint(address account, string memory tokenURI) public onlyMinter returns (uint256) {
    tokenId = tokenId + 1;
    _mint(account, tokenId);
    _setTokenURI(tokenId, tokenURI);
    return tokenId;
  }

  function minter() public view returns (address) {
    return _minter;
  }

  function setMinter(address newMinter) public onlyOwner {
    require(newMinter != address(0), "PendulumNft: new minter is the zero address");
    address oldMinter = _minter;
    _minter = newMinter;
    emit MinterChanged(oldMinter, newMinter);
  }

}