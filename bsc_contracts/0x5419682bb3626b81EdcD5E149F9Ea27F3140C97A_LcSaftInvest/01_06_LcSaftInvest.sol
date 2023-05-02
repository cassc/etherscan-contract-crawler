// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract LcSaftInvest is EIP712 {
  string private SIGNING_DOMAIN;
  string private SIGNATURE_VERSION;

  struct InvestInfo {
    uint256[] tiers;
    uint256[] amounts;
    uint256 timestamp;
  }

  address public investToken;
  address public tokenX;
  address public wNFT;

  uint256[] public tierids;
  // map tierId to nft price i.e 1 -> $500
  mapping (uint256 => uint256) public tierPrice;
  // map tierId to numbers of max NFT i.e 1 -> 1000x
  mapping (uint256 => uint256) public tierLimit;
  mapping (uint256 => uint256) public tierSupplied;
  // map tierId to numbers of TokenX to transfer when invest i.e 1 -> 50,000 TokenX
  mapping (uint256 => uint256) public tierTokenX;
  // map tierId to numbers of Extra TokenX to transfer when invest i.e 1 -> 200000 (20%)
  mapping (uint256 => uint256) public tierExtraTokenX;

  constructor (
    address _investToken,
    address _tokenX,
    address _wNFT,
    string memory domain,
    string memory version
  ) EIP712(domain, version) {
    investToken = _investToken;
    tokenX = _tokenX;
    wNFT = _wNFT;

    SIGNING_DOMAIN = domain;
    SIGNATURE_VERSION = version;
  }


  function invest(
    bytes memory code,
    bytes memory signature
  ) public view returns (address, InvestInfo memory, bytes32) {
    InvestInfo memory info = abi.decode(code, (InvestInfo));
    bytes32 digest = _hash(info);
    address signer = _verify(info, signature);
    return (signer, info, digest);
  }

  function _hash(InvestInfo memory info) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("InvestInfo(uint256[] tiers,uint256[] amounts,uint256 timestamp)"),
      info.tiers,
      info.amounts,
      info.timestamp
    )));
  }

  function _verify(InvestInfo memory info, bytes memory signature) internal view returns (address) {
    bytes32 digest = _hash(info);
    return ECDSA.recover(digest, signature);
  }
}