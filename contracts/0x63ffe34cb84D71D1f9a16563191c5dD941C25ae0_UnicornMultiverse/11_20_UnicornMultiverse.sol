// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IUnicornMultiverse.sol";

contract UnicornMultiverse is
  IUnicornMultiverse,
  ERC721AQueryable,
  PaymentSplitter,
  Ownable,
  ReentrancyGuard,
  DefaultOperatorFilterer
{
  MintRules public mintRules;

  string public baseTokenURI;

  bytes32 private _root;

  constructor(
    address[] memory _payees,
    uint256[] memory _shares
  ) ERC721A("Unicorn Multiverse", "UCMV") PaymentSplitter(_payees, _shares) {}

  /*//////////////////////////////////////////////////////////////
                         Public getters
  //////////////////////////////////////////////////////////////*/

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function numberMinted(address _owner) external view returns (uint256) {
    return _numberMinted(_owner);
  }

  function nonFreeAmount(address _owner, uint256 _amount, uint256 _freeAmount) external view returns (uint256) {
    return _calculateNonFreeAmount(_owner, _amount, _freeAmount);
  }

  /*//////////////////////////////////////////////////////////////
                         Minting functions
  //////////////////////////////////////////////////////////////*/

  function whitelistMint(uint256 _amount, bytes32[] memory _proof) external payable {
    _verify(_proof);

    uint256 _nonFreeAmount = _calculateNonFreeAmount(msg.sender, _amount, mintRules.whitelistFreePerWallet);

    if (_nonFreeAmount != 0 && msg.value < mintRules.whitelistPrice * _nonFreeAmount) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _amount > mintRules.whitelistMaxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _amount);
  }

  function mint(uint256 _amount) external payable {
    uint256 _nonFreeAmount = _calculateNonFreeAmount(msg.sender, _amount, mintRules.freePerWallet);

    if (_nonFreeAmount != 0 && msg.value < mintRules.price * _nonFreeAmount) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _amount > mintRules.maxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _amount);
  }

  /*//////////////////////////////////////////////////////////////
                          Owner functions
  //////////////////////////////////////////////////////////////*/

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMintRules(MintRules memory _mintRules) external onlyOwner {
    mintRules = _mintRules;
  }

  function airdrop(address _to, uint256 _amount) external onlyOwner {
    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(_to, _amount);
  }

  function setRoot(bytes32 _newRoot) external onlyOwner {
    _root = _newRoot;
  }

  /*//////////////////////////////////////////////////////////////
                         Internal functions
  //////////////////////////////////////////////////////////////*/

  function _calculateNonFreeAmount(
    address _owner,
    uint256 _amount,
    uint256 _freeAmount
  ) internal view returns (uint256) {
    uint256 _freeAmountLeft = _numberMinted(_owner) >= _freeAmount ? 0 : _freeAmount - _numberMinted(_owner);

    return _freeAmountLeft >= _amount ? 0 : _amount - _freeAmountLeft;
  }

  function _verify(bytes32[] memory _proof) private view {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));

    if (!MerkleProof.verify(_proof, _root, leaf)) {
      revert InvalidProof();
    }
  }

  /*//////////////////////////////////////////////////////////////
                          Overriden ERC721A
  //////////////////////////////////////////////////////////////*/

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  /*//////////////////////////////////////////////////////////////
                        DefaultOperatorFilterer
  //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}