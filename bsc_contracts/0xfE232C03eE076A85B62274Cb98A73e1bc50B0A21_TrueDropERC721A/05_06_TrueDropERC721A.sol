// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/ITrueDropERC721A.sol";
import "./interfaces/IDropManagementForERC721A.sol";
import "./ERC721A.sol";
import "./libraries/Verify.sol";

contract TrueDropERC721A is ERC721A, ITrueDropERC721A {
  address _owner;
  address _signer;
  address _mintter;
  uint256 _maxSupply;
  string _contractURI;
  string _imageBaseURI;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory mContractURI,
    string memory mImageBaseURI,
    address signer,
    uint256 totalSupply,
    uint256 fee,
    string memory uniqueId
  ) payable ERC721A(name_, symbol_) {
    _maxSupply = totalSupply;
    _contractURI = mContractURI;
    _imageBaseURI = mImageBaseURI;
    _signer = signer;
    if (fee > 0) {
      (bool success, ) = payable(address(0x8028928e75EcC005C035a49A6a76c0De1753b067)).call{ value: fee }("");
      require(success, "Fee fail");
    }
    _owner = msg.sender;
    emit TrueDropCollectionCreated(address(this), msg.sender, signer, fee, uniqueId);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function baseURI() external view returns (string memory) {
    return _baseURI;
  }

  function imageBaseURI() external view override returns (string memory) {
    return _imageBaseURI;
  }

  function contractURI() external view override returns (string memory) {
    return _contractURI;
  }

  function maxSupply() external view override returns (uint256) {
    return _maxSupply;
  }

  function mintter() external view returns (address) {
    return _mintter;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  // drop management
  function setMintter(address mMintter, bytes memory signature) external override {
    Verify.verifySignature(keccak256(abi.encodePacked(_owner, address(this))), signature, _signer);
    if (_mintter != address(0)) {
      IDropManagementForERC721A dropManagement = IDropManagementForERC721A(_mintter);
      require(dropManagement.currentStatus() == IDropManagementForERC721A.Status.CANCELED, "Only canceled");
    }
    _mintter = mMintter;
  }

  function setBaseUri(string memory uri, bytes memory signature) external override {
    require(tx.origin == _owner || msg.sender == _owner, "Not permission");
    Verify.verifySignature(keccak256(abi.encodePacked(uri)), signature, _signer);
    _baseURI = uri;
  }

  function mintNFT(address to, uint256 quantity) external override {
    require(msg.sender == _mintter, "Unauthorize");
    require(totalSupply() + quantity <= _maxSupply, "Out of stock");
    _safeMint(to, quantity);
  }
}