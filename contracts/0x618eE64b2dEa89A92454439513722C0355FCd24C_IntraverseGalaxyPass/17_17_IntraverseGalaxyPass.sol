// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//   ___ _   _ _____ ____      ___     _______ ____  ____  _____
//  |_ _| \ | |_   _|  _ \    / \ \   / / ____|  _ \/ ___|| ____|
//   | ||  \| | | | | |_) |  / _ \ \ / /|  _| | |_) \___ \|  _|
//   | || |\  | | | |  _ <  / ___ \ V / | |___|  _ < ___) | |___
//  |___|_| \_| |_| |_| \_\/_/   \_\_/  |_____|_| \_\____/|_____|

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract IntraverseGalaxyPass is ERC721, ERC2981, Pausable, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  // Defining struct
  struct MintStatus {
    string name;
    uint256 price;
    uint256 maxPerAddress;
    mapping(address => uint256) mintedByAddress;
  }

  // Defining variables
  string public activeMintStatus;
  uint256 public maxSupply = 555;
  uint256 private _tokenIdCounter = 0;
  address private _signer;
  string private _baseTokenURI;

  mapping(string => MintStatus) public mintStatus;
  mapping(bytes32 => bool) public nonceUsed;

  // Defining Modifier
  modifier onlyEOA() {
    require(msg.sender == tx.origin, "Not allowed");
    _;
  }

  // Constructor // Change token info
  constructor() ERC721("IntraverseGalaxyPass", "IGP") {
    _pause();

    setMintStatus("VIP_ALLOWLIST", 0.055 ether, 2);
    setMintStatus("PREMIUM_ALLOWLIST", 0.066 ether, 2);
    setMintStatus("PUBLIC", 0.077 ether, maxSupply);

    setActiveMintStatus("VIP_ALLOWLIST");
  }

  // Mint: public
  function mint(
    uint256 _amount,
    bytes memory _signature,
    string memory _doc,
    bytes memory _docSignature,
    bytes32 _nonce
  ) external payable whenNotPaused onlyEOA nonReentrant {
    require(!nonceUsed[_nonce], "Invalid nonce");
    require(addressCanMintAmount(msg.sender, _amount), "Not available");
    require(
      isSignatureValid(
        _signer,
        keccak256(abi.encodePacked(msg.sender, activeMintStatus, _doc, _docSignature, _nonce)),
        _signature
      ),
      "Invalid signature"
    );
    require(msg.value >= price(), "Not enough eth");

    nonceUsed[_nonce] = true;
    _addMintedByAddress(activeMintStatus, msg.sender, _amount);
    _mintAmountTo(_amount, msg.sender);
  }

  // Mint: reserved for the owner
  function ownerMint(uint256 _amount) external onlyOwner {
    _mintAmountTo(_amount, msg.sender);
  }

  // Private: mint _amount in _to address
  function _mintAmountTo(uint256 _amount, address _to) private {
    require(_tokenIdCounter + _amount <= maxSupply, "Not available");
    uint256 tokenId = _tokenIdCounter;
    _tokenIdCounter += _amount;
    for (uint256 i = 1; i <= _amount; ++i) {
      _mint(_to, tokenId + i);
    }
  }

  // Private: Update mintedByAddress
  function _addMintedByAddress(string memory _mintStatusName, address _address, uint256 _amount) private {
    MintStatus storage status = mintStatus[_mintStatusName];
    status.mintedByAddress[_address] += _amount;
  }

  // Checker: if an address can mint a certain amount
  function addressCanMintAmount(address _address, uint256 _amount) public view returns (bool) {
    return amountMintableByAddress(_address) >= _amount;
  }

  // Checker: signature
  function isSignatureValid(address signer, bytes32 hash, bytes memory signature) public pure returns (bool) {
    return hash.toEthSignedMessageHash().recover(signature) == signer;
  }

  // Getter: price
  function price() public view returns (uint256) {
    MintStatus storage status = mintStatus[activeMintStatus];
    return status.price;
  }

  // Getter: amountMintableByAddress
  function amountMintableByAddress(address _address) public view returns (uint256) {
    MintStatus storage status = mintStatus[activeMintStatus];
    return status.maxPerAddress - status.mintedByAddress[_address];
  }

  // Getter: minted
  function minted() public view returns (uint256) {
    return _tokenIdCounter;
  }

  // Setter: signer
  function setSigner(address _newSigner) external onlyOwner whenPaused {
    require(_newSigner != address(0), "Undefined signer");
    _signer = _newSigner;
  }

  // Setter: mintStatus[_name]
  function setMintStatus(string memory _name, uint256 _price, uint256 _maxPerAddress) public onlyOwner {
    require(_maxPerAddress != 0, "Invalid _maxPerAddress");
    MintStatus storage status = mintStatus[_name];
    status.name = _name;
    status.price = _price;
    status.maxPerAddress = _maxPerAddress;
  }

  // Setter: activeMintStatus
  function setActiveMintStatus(string memory _name) public onlyOwner {
    MintStatus storage status = mintStatus[_name];
    require(status.maxPerAddress != 0, "Mint status does not exist");
    activeMintStatus = _name;
  }

  // Setter: pause -> true
  function pause() public onlyOwner {
    _pause();
  }

  // Setter: pause -> false
  function unpause() public onlyOwner {
    require(_signer != address(0), "Undefined signer");
    _unpause();
  }

  // Metadata: set base token URI
  function setBaseTokenURI(string memory _URI) external onlyOwner {
    _baseTokenURI = _URI;
  }

  // Metadata: override _baseURI
  function _baseURI() internal view virtual override(ERC721) returns (string memory) {
    return _baseTokenURI;
  }

  // ERC2981: Set Default royalty
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  // ERC2981: Set Token royalty
  function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  // ERC2981: override _burn
  function _burn(uint256 tokenId) internal virtual override(ERC721) {
    super._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }

  // ERC2981: override supportsInterface
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // Withdraw: all
  function withdrawAll(address payable _to) external onlyOwner {
    require(_to != address(0), "Invalid address");
    require(address(this).balance >= 0, "Not enough eth");
    (bool sent, ) = _to.call{ value: address(this).balance }("");
    require(sent, "Failed");
  }
}