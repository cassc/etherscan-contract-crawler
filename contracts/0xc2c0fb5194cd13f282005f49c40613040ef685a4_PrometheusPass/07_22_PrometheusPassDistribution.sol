//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./PrometheusPassTreasury.sol";
import "./PrometheusPassVoucherSigner.sol";
import "./PrometheusPassVoucher.sol";



abstract contract PrometheusPassDistribution is
  Ownable,
  PrometheusPassTreasury,
  PrometheusPassVoucherSigner,
  ERC721,
  ERC721Enumerable
{
  using Counters for Counters.Counter;



  uint public constant MAX_SUPPLY = 1888;
  uint public constant RESERVED_SUPPLY = 88;  // Reserved for Prometheus
  uint public constant FOR_SALE_SUPPLY = MAX_SUPPLY - RESERVED_SUPPLY;
  uint256 public constant SALE_PRICE = 0.1888 ether; // In ETH
  uint256 public constant PRIVATE_SALE_OPEN_TIME = 1634299200; // Fri Oct 15 2021 20:00:00 GMT+0800 (Singapore Standard Time)
  uint256 public constant PUBLIC_SALE_OPEN_TIME = 1634385600; // Sat Oct 16 2021 20:00:00 GMT+0800 (Singapore Standard Time)



  Counters.Counter internal _latestTokenId;

  mapping(uint => bool) claimedVouchers;

  constructor() {
    _mintReserved();
  }

  function isPrivateSaleOpen() public view returns (bool) {
    return block.timestamp >= PRIVATE_SALE_OPEN_TIME;
  }

  function isPublicSaleOpen() public view returns (bool) {
    return block.timestamp >= PUBLIC_SALE_OPEN_TIME;
  }

  function _mint(address to) internal
  {
    require(
      totalSupply() < FOR_SALE_SUPPLY,
      "PrometheusPass: Sold out, unable to mint"
    );

    require(
      SALE_PRICE == msg.value,
      "PrometheusPass: ETH value not the same as sale price"
    );

    _latestTokenId.increment();
    _sendToTreasury(SALE_PRICE);
    _mint(to, _latestTokenId.current());
  }

  function validateVoucher(PrometheusPassVoucher.Voucher calldata v) external view returns (bool) {
    return PrometheusPassVoucher.validateVoucher(v, getVoucherSigner());
  }

  function publicSaleMint(address to) external payable
  {
    require(
      block.timestamp >= PUBLIC_SALE_OPEN_TIME,
      "PrometheusPass: Public sale not open"
    );

    _mint(to);
  }

  function privateSaleMint(PrometheusPassVoucher.Voucher calldata v)
    external payable
  {
    require(
      block.timestamp >= PRIVATE_SALE_OPEN_TIME,
      "PrometheusPass: Private sale not open"
    );

    require(
      claimedVouchers[v.voucherId] == false,
      "PrometheusPass: Voucher already claimed"
    );

    require(
      PrometheusPassVoucher.validateVoucher(v, getVoucherSigner()),
      "PrometheusPass: Invalid voucher"
    );

    claimedVouchers[v.voucherId] = true;
    _mint(v.to);
  }

  function _mintRangeReserved(address to, uint tokenIdStart, uint tokenIdEnd) private {
    for (uint tokenId = tokenIdStart; tokenId < tokenIdEnd; tokenId++) {
      _mint(to, tokenId);
    }
  }

  function _mintReserved()
    internal
  {
    _mint(0x00A4eBa3E508f5eD9a69c1fb276A2659EC420AEE, 1801);
    _mint(0xC45c8E56a92310990Cd950fb5Ff59bD28E5cCda7, 1802);
    _mint(0xB32B4350C25141e779D392C1DBe857b62b60B4c9, 1803);
    _mint(0x0a2542a170aA02B96B588aA3AF8B09AB22a9D7ac, 1804);
    _mint(0x45c109b4dFE64f14810e3207371557Bb9b1540d2, 1805);
    _mint(0xcac77543C1Be5A5580aB9C772061a598219F71C7, 1806);
    _mint(0x973f18c0eAA0292A9c7F40cd8c228e949097fA15, 1807);
    _mint(0xA2c504Ac82B8364927EA646F62403A7C58C6FbCb, 1808);
    _mint(0xd15246f8821131A86c037ab36e8713bE704deeC2, 1809);
    _mint(0x9C30842c78Bec02F212Bd9c832746e0987a2dd79, 1810);
    _mint(0x3A32B201632EAa604fB2AaBeE4af4C3e71eee8e7, 1811);
    _mint(0x4caB1d07ba5D44A25E21E4CCDB85AE19f8a8b85E, 1812);
    _mint(0x96d6c4526e726AdA54a0094a2ff9745D358e6B07, 1813);
    _mint(0xC9FAe6a7efA781F856cD929bC05F1FFD420d39c9, 1814);
    _mint(0xed87d0aC2e19D5591B9a4b1EAE6Cd8D8429035A5, 1815);
    _mint(0xe1185396eC5B406526F7b3965094F44C8B1FC079, 1816);
    _mint(0x914Dc8e36f6CD89Ec538875740a5D04dA761ae4b, 1817);
    _mint(0xd8Bb7fab88C754f78F64d71DA1C82433CD926039, 1818);
    _mint(0x52755642f947D3A7F36e66741B5EbF9039707393, 1819);
    _mintRangeReserved(0xC45c8E56a92310990Cd950fb5Ff59bD28E5cCda7, 1820, 1888);
    _mint(0xb8D19c18B0EE7CF985432323663caed44F5cc41A, 1888);
  }

  // Section: Explicit default disambiguation of multiple inheritance 

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    virtual
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

}