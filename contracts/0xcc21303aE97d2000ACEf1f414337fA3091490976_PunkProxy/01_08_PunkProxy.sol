// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// this contract is simply a hack for being able to support CryptoPunks. it doesn't mint or transfer any tokens. it's meant for a simple ownerOf implementation so Punk owners can be verified.

interface PunkCheck {
  function punkIndexToAddress(uint256) external view returns (address);
}

contract PunkProxy is Context, ERC165, IERC721, IERC721Metadata, Ownable {
  using Address for address;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  PunkCheck private punk_contract;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function setContract(address _contract) external {
    punk_contract = PunkCheck(_contract);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function balanceOf(address owner)
    external
    view
    override
    returns (uint256 balance)
  {
    //implement
  }

  function ownerOf(uint256 tokenId)
    external
    view
    override
    returns (address owner)
  {
    return punk_contract.punkIndexToAddress(tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external override {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external override {}

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external override {}

  function approve(address to, uint256 tokenId) external override {}

  function setApprovalForAll(address operator, bool _approved)
    external
    override
  {}

  function getApproved(uint256 tokenId)
    external
    view
    override
    returns (address operator)
  {}

  function isApprovedForAll(address owner, address operator)
    external
    view
    override
    returns (bool)
  {}

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {}
}