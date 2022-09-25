// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Merge is ERC721A, Ownable {
  string private _name;
  string private _symbol;
  string private _metadataRoot;
  address private _metadataGenerator;
  string private _contractMetadata;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory metadataRoot_,
    string memory contractMetadata_

  ) ERC721A(name_, symbol_) {
    _name = name_;
    _symbol = symbol_;
    _metadataRoot = metadataRoot_;
    _contractMetadata = contractMetadata_;
    mint(address(this), 10_000);
  }

  function updateTokenInfo(
    string memory name_,
    string memory symbol_,
    string memory metadataRoot_,
    string memory contractMetadata_
  ) onlyOwner public {
    _name = name_;
    _symbol = symbol_;
    _metadataRoot = metadataRoot_;
    _contractMetadata = contractMetadata_;
  }

  function mint(address recipient, uint64 quantity) internal {
    require(totalMinted() + quantity <= 10_000, "Can not mint over max supply.");
    _mint(recipient, quantity);
  }

  function name() public view override returns(string memory) {
    return _name;
  }

  function symbol() public view override returns(string memory) {
    return _symbol;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataRoot;
  }

  function setBaseURI(string memory uri) onlyOwner public {
    _metadataRoot = uri;
  }

  function contractURI() public view returns(string memory) {
    return _contractMetadata;
  }

  function setContractURI(string memory uri) onlyOwner public {
    _contractMetadata = uri;
  }

  function setMetadataGenerator(address _address) onlyOwner public {
    _metadataGenerator = _address;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (address(0) == _metadataGenerator) {
      return ITokenURIGenerator(_metadataGenerator).tokenURI(tokenId);
    }

    return ERC721A.tokenURI(tokenId);
  }

  function totalMinted() public view returns(uint) {
    return _totalMinted();
  }

  function delegateOperator(address operator, bool auth) onlyOwner public {
    _operatorApprovals[ address(this) ][ operator ] = auth;
    emit ApprovalForAll( address(this), operator, auth );
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
      if (operator == _msgSenderERC721A()) revert ApproveToCaller();

      _operatorApprovals[_msgSenderERC721A()][operator] = approved;
      emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
      return _operatorApprovals[owner][operator];
    }

    function batchSafeTransferFrom(address[] calldata from, address[] calldata to, uint64[] calldata tokens) public {
      require(from.length == to.length && to.length == tokens.length, "Array mis-match");
      for (uint i = 0; i < from.length; i++) {
        safeTransferFrom(from[i], to[i], tokens[i]);
      }
    }
}