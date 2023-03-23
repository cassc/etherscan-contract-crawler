// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/utils/Counters.sol';
import 'openzeppelin-contracts/contracts/access/Ownable.sol';
import 'openzeppelin-contracts/contracts/utils/math/SafeMath.sol';
import 'openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

interface _1984Redux {
  function balanceOf(address owner) external returns (uint256);
}

contract _1984Serum is ERC721Enumerable, Ownable {
  event BurnSerum(uint256[] serumIds, uint256 indexed reduxTargetId, address indexed sender);
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;

  uint256 public constant MAX_SUPPLY = 1600;
  uint256 public constant MAX_PER_MINT = 5;
  uint256 public price = 0.009 ether;
  address private nftAddress;
  bool public public_mint_active = false;
  bool public mint_active = false;
  bool public burn_active = false;
  mapping(address => uint256) public addressToMinted;

  address public treasury;
  string public baseTokenURI;

  constructor() ERC721('1984Serum', '1984S') {}

  function setPublicMintActive(bool newValue) public onlyOwner {
    public_mint_active = newValue;
  }

  function setMintActive(bool newValue) public onlyOwner {
    mint_active = newValue;
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function setNftAddress(address newAddy) public onlyOwner {
    nftAddress = newAddy;
  }

  function reserveNFTs() public onlyOwner {
    uint256 totalMinted = _tokenIds.current();
    uint256 newTokenCount = 20;

    require(totalMinted.add(newTokenCount) <= MAX_SUPPLY, 'Not enough NFTs left to reserve');

    for (uint256 i = 0; i < newTokenCount; i++) {
      uint256 newTokenID = _tokenIds.current();
      _safeMint(msg.sender, newTokenID);
      _tokenIds.increment();
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  /// @notice Mint any number of nfts
  /// @param _count Number of NFTs to mint
  function mintNFTs(uint256 _count) public payable {
    require(mint_active, 'Mint is not active yet, please try again later.');
    require(_count > 0, 'Cannot mint negative number of NFTs.');
    if (public_mint_active) {
      require(msg.value >= price.mul(_count), 'Not enough ether to purchase NFTs.');
    }

    uint256 totalMinted = _tokenIds.current();
    require(totalMinted.add(_count) < MAX_SUPPLY, 'Not enough NFTs left!');

    uint256 tokensToMint = _count + addressToMinted[msg.sender];

    if (!public_mint_active) {
      _1984Redux nft = _1984Redux(nftAddress);
      uint256 mintedBySender = nft.balanceOf(msg.sender);

      if (tokensToMint >= 5) {
        require(mintedBySender >= 10, 'Minting more than 4 vials requires 10 or more tokens');
      } else if (tokensToMint >= 3) {
        require(mintedBySender >= 5, 'Minting more than 2 vials requires 5 or more tokens');
      } else {
        require(mintedBySender >= 2, 'Minting more than 1 vials requires 2 or more tokens');
      }
    }

    require(tokensToMint <= MAX_PER_MINT, 'Minting too many NFTs.');

    addressToMinted[msg.sender] = tokensToMint;

    for (uint256 i = 0; i < _count; i++) {
      uint256 newTokenID = _tokenIds.current();
      _safeMint(msg.sender, newTokenID);
      _tokenIds.increment();
    }
  }

  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);

    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function withdraw() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, 'No ether left to withdraw');

    (bool success,) = (msg.sender).call{ value: balance }('');
    require(success, 'Transfer failed.');
  }

  function setTreasury(address newAddy) external onlyOwner {
    treasury = newAddy;
  }

  function setIsBurnActive(bool newVal) public onlyOwner {
    burn_active = newVal;
  }

  function burn(uint256[] calldata ids, uint256 reduxTargetId) external {
    require(burn_active, "Burn phase has yet to commence");
    for (uint256 i = 0; i < ids.length; i++) {
      safeTransferFrom(msg.sender, treasury, ids[i]);
    }

    emit BurnSerum(ids, reduxTargetId, msg.sender);
  }

  function safeBatchTransfer(uint256[] calldata ids, address to) external {
    for (uint256 i = 0; i < ids.length; i++) {
      safeTransferFrom(msg.sender, to, ids[i]);
    }
  }
}