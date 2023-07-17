//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./PrometheusPassPausable.sol";
import "./PrometheusPassDistribution.sol";
import "./PrometheusPassOpenSeaApproval.sol";



string constant TOKEN_NAME = "Prometheus Pass (Gold)";
string constant TOKEN_SYMBOL = "PPG";



contract PrometheusPass is
  Ownable,
  ERC721,
  ERC721Enumerable,
  ERC721Pausable,
  PrometheusPassPausable,
  PrometheusPassDistribution,
  PrometheusPassOpenSeaApproval
{

  constructor(
    address owner,
    address payable treasury,
    address voucherSigner,
    address proxyRegistryAddress
  ) ERC721(TOKEN_NAME, TOKEN_SYMBOL)
    PrometheusPassTreasury(treasury)
    PrometheusPassVoucherSigner(voucherSigner)
    PrometheusPassOpenSeaApproval(proxyRegistryAddress)
  {
    transferOwnership(owner);
  }

  function tokenURI(uint256 tokenId) public view virtual
    override(ERC721)
    returns (string memory)
  {
    tokenId; // To suppress unused variable warning
    return "ipfs://QmWiZ5kJqKftqF2i1k6qpESPg8VLfGJ5mCEFxCeU7fkf8s";
    // View it at: https://gateway.pinata.cloud/ipfs/QmWiZ5kJqKftqF2i1k6qpESPg8VLfGJ5mCEFxCeU7fkf8s
  }



  // Explicit default disambiguation of multiple inheritance 

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    override(ERC721, ERC721Pausable, ERC721Enumerable, PrometheusPassDistribution)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view
    override(ERC721, ERC721Enumerable, PrometheusPassDistribution)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public
    override(ERC721)
  {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public
    override(ERC721)
  {
    super.safeTransferFrom(from, to, tokenId, _data);
  }

  function isApprovedForAll(address owner, address operator) public view
    override(ERC721, PrometheusPassOpenSeaApproval) virtual
    returns (bool)
  {
      return super.isApprovedForAll(owner, operator);
  }

}