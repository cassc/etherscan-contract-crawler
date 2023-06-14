// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TheCyberDogeNFT is Ownable, ERC721Enumerable {
  uint256 public constant COLLECTION_SIZE = 300;
  bool public isActive = false;

  mapping(address => uint256) private _walletTokenId;
  mapping(address => uint256) private _walletQuantity;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function walletClaimable(address _address) public view returns (bool) {
    return _walletQuantity[_address] == 1;
  }

  function setActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  function _mint() external callerIsUser {
    require(isActive == true, "mint is not live yet");
    require(
      _walletQuantity[msg.sender] == 1,
      "not eligible for mint or you've already minted"
    );
    require(
      totalSupply() + 1 <= COLLECTION_SIZE,
      "reached max supply SALE IS OVER"
    );
    _walletQuantity[msg.sender] = _walletQuantity[msg.sender] - 1;
    _safeMint(msg.sender, _walletTokenId[msg.sender]);
  }

  function seedMintWalletAndTokenId(
    address[] memory addresses,
    uint256[] memory _tokenId
  ) external onlyOwner {
    require(
      addresses.length == _tokenId.length,
      "addresses does not match tokenId length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      _walletTokenId[addresses[i]] = _tokenId[i];
    }
  }

  function seedMintQuantity(
    address[] memory addresses,
    uint256[] memory _quantity
  ) external onlyOwner {
    require(
      addresses.length == _quantity.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      _walletQuantity[addresses[i]] = _quantity[i];
    }
  }

  string private baseURI;

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}