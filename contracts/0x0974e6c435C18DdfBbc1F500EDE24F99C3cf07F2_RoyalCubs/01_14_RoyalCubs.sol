// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract RoyalCubs is ERC721Enumerable, Ownable {
  //  Accounts
  address
    private constant creator0Address = 0xd11351387b941F464e3A2bB11f3A0a63922f0DeE;
  address
    private constant creator1Address = 0x0C36922266e6cE0f92a357E20399F295c2b9ff10;
  address
    private constant creator2Address = 0x1eA3A4f1b89F3aDA30e7110e87b74a58fC1D33c3;
  address
    private constant creator3Address = 0xA286fee51f2FAAdDC79f921AaF8a559BBa77ce66;

  // Minting Variables
  uint256 public maxSupply = 8888;
  uint256 public mintPrice = 0.22 ether;
  uint256 public maxPurchase = 3;
  uint256 public maxRafflePurchase = 2;

  // Sale Status
  bool public locked;
  bool public presaleActive;
  bool public publicSaleActive;

  // Merkle Roots
  bytes32 private whitelistRoot;
  bytes32 private raffleRoot;

  mapping(address => uint256) private mintCounts;

  // Metadata
  string _baseTokenURI;

  // Events
  event PublicSaleActivation(bool isActive);
  event PresaleActivation(bool isActive);

  // Contract
  constructor() ERC721("The Royal Cubs", "TRC") {}

  // Merkle Proofs
  function setWhitelistRoot(bytes32 _root) external onlyOwner {
    whitelistRoot = _root;
  }

  function setRaffleRoot(bytes32 _root) external onlyOwner {
    raffleRoot = _root;
  }

  function _leaf(address _account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_account));
  }

  function isInTree(
    address _account,
    bytes32[] calldata _proof,
    bytes32 _root
  ) internal pure returns (bool) {
    return MerkleProof.verify(_proof, _root, _leaf(_account));
  }

  // Minting
  function ownerMint(address _to, uint256 _count) external onlyOwner {
    require(totalSupply() + _count <= maxSupply, "exceeds max supply");

    for (uint256 i = 0; i < _count; i++) {
      uint256 mintIndex = totalSupply();
      _safeMint(_to, mintIndex);
    }
  }

  function raffleMint(uint256 _count, bytes32[] calldata _proof)
    external
    payable
  {
    require(presaleActive, "Presale must be active");
    require(isInTree(msg.sender, _proof, raffleRoot), "Not on raffle whitelist");
    require(
      balanceOf(msg.sender) + _count <= maxRafflePurchase,
      "exceeds the account's presale quota"
    );
    require(totalSupply() + _count <= maxSupply, "exceeds max supply");
    require(mintPrice * _count <= msg.value, "Ether value sent is not correct");

    mintCounts[msg.sender] = mintCounts[msg.sender] + _count;
    require(mintCounts[msg.sender] <= maxRafflePurchase, "exceeds the account's quota");

    for (uint256 i = 0; i < _count; i++) {
      uint256 mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
    }
  }

  function presaleMint(uint256 _count, bytes32[] calldata _proof)
    external
    payable
  {
    require(presaleActive, "Presale must be active");
    require(
      isInTree(msg.sender, _proof, whitelistRoot),
      "not whitelisted for presale"
    );
    require(
      balanceOf(msg.sender) + _count <= maxPurchase,
      "exceeds the account's quota"
    );
    require(totalSupply() + _count <= maxSupply, "exceeds max supply");
    require(mintPrice * _count <= msg.value, "Ether value sent is not correct");

    mintCounts[msg.sender] = mintCounts[msg.sender] + _count;
    require(mintCounts[msg.sender] <= maxPurchase, "exceeds the account's quota");

    for (uint256 i = 0; i < _count; i++) {
      uint256 mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
    }
  }

  function mint(uint256 _count) external payable {
    require(publicSaleActive, "Sale must be active");
    require(_count <= maxPurchase, "exceeds maximum purchase amount");
    require(
      balanceOf(msg.sender) + _count <= maxPurchase,
      "exceeds the account's quota"
    );

    require(totalSupply() + _count <= maxSupply, "exceeds max supply");
    require(mintPrice * _count <= msg.value, "Ether value sent is not correct");

    mintCounts[msg.sender] = mintCounts[msg.sender] + _count;
    require(mintCounts[msg.sender] <= maxPurchase, "exceeds the account's quota");

    for (uint256 i = 0; i < _count; i++) {
      uint256 mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
    }
  }

  // Configurations
  function lockMetadata() external onlyOwner {
    locked = true;
  }

  function togglePresaleStatus() external onlyOwner {
    presaleActive = !presaleActive;
    emit PresaleActivation(presaleActive);
  }

  function toggleSaleStatus() external onlyOwner {
    publicSaleActive = !publicSaleActive;
    emit PublicSaleActivation(publicSaleActive);
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
    maxPurchase = _maxPurchase;
  }

  function withdrawAll() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "Balance can't be zero");
    
    uint256 creator1Dividend = (balance / 100) * 2;
    uint256 creator2Dividend = (balance / 100) * 3;
    uint256 creator3Dividend = (balance / 100) * 2;

    payable(creator1Address).transfer(creator1Dividend);
    payable(creator2Address).transfer(creator2Dividend);
    payable(creator3Address).transfer(creator3Dividend);
    payable(creator0Address).transfer(address(this).balance);
  }

  function getTotalSupply() external view returns (uint256) {
    return totalSupply();
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    require(!locked, "Contract metadata methods are locked");
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
}