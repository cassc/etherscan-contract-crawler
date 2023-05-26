// SPDX-License-Identifier: MIT

import "./shared/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

contract RastaBeachClub is Ownable, ERC721A, ReentrancyGuard {
  using Strings for uint256;
  using ECDSA for bytes32;

  string public baseURI = "ipfs://bafybeiazdutuuq3lvz4s6dhdz33qjxv3jppkbzgj2fyer6qeh3oorostnq/";
  uint256 public price = 0 ether;
  uint16 public maxSupply = 10000;

  bool public isPublicSale = true;
  bool public isPreSale = false;
  bool public isReveal = false;
  address private signer;

  uint256 public mintPerWallet = 1;

  constructor(
    address _owner,
    uint256 _ownerMintAmount,
    address _signer
  ) ERC721A("Rasta Beach Club", "RSTBC", maxSupply, maxSupply) {
    transferOwnership(_owner);
    signer = _signer;

    _safeMint(_owner, _ownerMintAmount);
  }

  function mint(uint256 _mintAmount) external payable {
    require(isPublicSale, "Minting currently on hold");
    _mint(_mintAmount);
  }

  function presaleMint(uint256 _mintAmount, bytes memory signature) external payable {
    require(isPreSale, "Private Sale is not active");
    address recover = recoverSignerAddress(msg.sender, signature);
    require(recover == signer, "Address not whitelisted for sale");

    _mint(_mintAmount);
  }

  function _mint(uint256 _mintAmount) private {
    require(_mintAmount > 0, "Amount to mint can not be 0");
    require(
      (_numberMinted(msg.sender) < mintPerWallet && _mintAmount + _numberMinted(msg.sender) <= mintPerWallet) ||
        msg.sender == owner(),
      "You have reached your quota to mint"
    );

    require(totalSupply() + _mintAmount <= maxSupply, "Purchase would exceed max supply of NFT");
    if (msg.sender != owner()) {
      require(msg.value >= price * _mintAmount, "Amount sent less than the cost of minting NFT(s)");
    }

    _safeMint(msg.sender, _mintAmount);
  }

  // HELPER FUNCTIONS
  function hashTransaction(address minter) private pure returns (bytes32) {
    bytes32 argsHash = keccak256(abi.encodePacked(minter));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", argsHash));
  }

  function recoverSignerAddress(address minter, bytes memory signature) private pure returns (address) {
    bytes32 hash = hashTransaction(minter);
    return hash.recover(signature);
  }

  // GETERS
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function getSigner() public view returns (address) {
    return signer;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: tokenURI queried for nonexistent token");
    if (!isReveal) return string(abi.encodePacked(baseURI, "conceal.json"));
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  // SETTERS
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function togglePublicSale() external onlyOwner {
    isPublicSale = !isPublicSale;
  }

  function togglePreSale() external onlyOwner {
    isPreSale = !isPreSale;
  }

  function setIsReveal(string memory _newBaseURI, bool _isReveal) external onlyOwner {
    baseURI = _newBaseURI;
    isReveal = _isReveal;
  }

  function setMintPerWallet(uint256 _mintPerWallet) external onlyOwner {
    mintPerWallet = _mintPerWallet;
  }

  function configure(
    bool _isPublicSale,
    bool _isPreSale,
    address _signer,
    uint256 _price,
    bool _isReveal
  ) external onlyOwner {
    isPublicSale = _isPublicSale;
    isPreSale = _isPreSale;
    signer = _signer;

    price = _price;
    isReveal = _isReveal;
  }

  function withdraw(address _receiver) external onlyOwner {
    (bool success, ) = address(_receiver).call{value: address(this).balance}("");
    require(success, "Unable to withdraw balance");
  }
}