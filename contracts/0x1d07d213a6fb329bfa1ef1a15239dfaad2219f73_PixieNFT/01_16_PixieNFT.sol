// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// @title:  PIXIE NFTs
// @desc:   4,400 MAGICAL CREATURES
// @founder: https://twitter.com/ManticoreProG
// @artist: https://twitter.com/wunder_bot
// @dev: https://twitter.com/marcelc63
// @url:    https://pixienft.io/

/*
 * ######  ### #     # ### #######
 * #     #  #   #   #   #  #
 * #     #  #    # #    #  #
 * ######   #     #     #  #####
 * #        #    # #    #  #
 * #        #   #   #   #  #
 * #       ### #     # ### #######
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PixieNFT is ERC721A, Ownable, IERC2981, ReentrancyGuard {
  using Address for address payable;

  // .・゜゜・ Supply ・゜゜・．

  uint256 public reserved = 30;
  uint256 public maxSupply = 4400;
  uint256 public maxAmountPerTx = 3;

  // .・゜゜・ Cost ・゜゜・．

  uint256 private price = 0.04 ether;

  // .・゜゜・ Mint Status ・゜゜・．

  enum MintStatus {
    CLOSED,
    PRESALE,
    PUBLIC
  }
  MintStatus public mintStatus = MintStatus.CLOSED;

  // .・゜゜・ General ・゜゜・．

  string public baseTokenURI;
  uint256 private royaltyDivisor = 20;

  // .・゜゜・ Mint Tracking ・゜゜・．

  bytes32 public merkleRoot;
  mapping(address => uint256) public addressToPresaleMintCount;

  // .・゜゜・ Withdraw Addresses ・゜゜・．

  address t1 = 0x5e226ae843aDf2F0d7E8596fc1effc58eB0e2af8;
  address t2 = 0xF1023b1E95694585f7b8C0d3718d56e42aD8d6Eb;

  // .・゜゜・ Contract ・゜゜・．

  constructor(
    string memory _baseTokenURI,
    bytes32 _merkleRoot,
    uint256 _maxSupply
  ) ERC721A("Pixie NFTs", "PIXIE") {
    merkleRoot = _merkleRoot;
    baseTokenURI = _baseTokenURI;
    maxSupply = _maxSupply;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  // .・゜゜・ Mint ・゜゜・．

  function mint(
    uint256 _amount,
    uint256 _maxAmount,
    bytes32[] calldata _proof
  ) public payable nonReentrant {
    require(mintStatus != MintStatus.CLOSED, "Sale inactive");
    require(
      _amount <= maxAmountPerTx,
      "Amount is more than max allowed per transaction"
    );
    require(totalSupply() + _amount <= maxSupply - reserved, "Sold out!");
    require(msg.value >= price * _amount, "Amount of ETH sent is incorrect");

    if (mintStatus == MintStatus.PUBLIC) {
      _mintPublic(_amount);
    } else if (mintStatus == MintStatus.PRESALE) {
      _mintPresale(_amount, _maxAmount, _proof);
    }
  }

  function mintReserved(address _to, uint256 _amount) external onlyOwner {
    require(_amount <= reserved, "Exceeds reserved NFT supply");

    reserved -= _amount;
    _mintPrivate(_to, _amount);
  }

  function _mintPublic(uint256 _amount) internal {
    _mintPrivate(msg.sender, _amount);
  }

  function _mintPresale(
    uint256 _amount,
    uint256 _maxAmount,
    bytes32[] calldata _proof
  ) internal {
    require(
      addressToPresaleMintCount[msg.sender] + _amount <= _maxAmount,
      "Amount must be less than or equal to whitelist allowance"
    );
    require(
      MerkleProof.verify(
        _proof,
        merkleRoot,
        keccak256(abi.encodePacked(msg.sender, _maxAmount))
      ),
      "Proof is not valid"
    );

    addressToPresaleMintCount[msg.sender] += _amount;
    _mintPrivate(msg.sender, _amount);
  }

  function _mintPrivate(address _to, uint256 _amount) internal {
    _safeMint(_to, _amount);
  }

  // .・゜゜・ Setters ・゜゜・．

  function setPrice(uint256 _newPrice) external onlyOwner {
    price = _newPrice;
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMaxAmountPerTx(uint256 _maxAmountPerTx) external onlyOwner {
    maxAmountPerTx = _maxAmountPerTx;
  }

  function setReserved(uint256 _reserved) external onlyOwner {
    reserved = _reserved;
  }

  function setRoyaltyDivisor(uint256 _divisor) external onlyOwner {
    royaltyDivisor = _divisor;
  }

  function setStatus(uint8 _status) external onlyOwner {
    mintStatus = MintStatus(_status);
  }

  // .・゜゜・ Withdraw ・゜゜・．

  function withdraw() public onlyOwner {
    require(address(this).balance != 0, "Balance is zero");

    payable(t1).sendValue(address(this).balance / 5);
    payable(t2).sendValue(address(this).balance);
  }

  // .・゜゜・ Misc ・゜゜・．

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");

    return (address(this), salePrice / royaltyDivisor);
  }
}