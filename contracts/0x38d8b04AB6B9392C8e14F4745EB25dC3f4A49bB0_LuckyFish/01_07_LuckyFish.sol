// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'erc721a/contracts/ERC721A.sol';

contract LuckyFish is Ownable, ERC721A {
  uint256 public maxSupply = 5000;

  string public baseURI = 'ipfs://bafybeibjhzmsamk7uxpb7duzawcrlnvxo4r2vtyd3ejil2jehsu6it6n2e/';

  address public signerAddress;

  constructor() ERC721A('LuckyFish', 'LF') {
    _mintERC2309(msg.sender, 250);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function verifySignature(
    uint64 maxPerWallet,
    uint128 unitPrice,
    bytes memory signature
  ) internal view returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sender, maxPerWallet, unitPrice));
    bytes32 message = ECDSA.toEthSignedMessageHash(hash);
    return signerAddress == ECDSA.recover(message, signature);
  }

  function mint(
    uint64 quantity,
    uint64 maxPerWallet,
    uint128 unitPrice,
    bytes calldata signature
  ) external payable {
    require((_nextTokenId() - _startTokenId() + quantity) <= maxSupply, 'sa');
    require((_numberMinted(msg.sender) + quantity) <= maxPerWallet, 'sb');
    require((quantity * unitPrice) <= msg.value, 'sc');
    require(verifySignature(maxPerWallet, unitPrice, signature), 'sd');
    _mint(msg.sender, quantity);
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setSignerAddress(address newSignerAddress) external onlyOwner {
    signerAddress = newSignerAddress;
  }

  function cutSupply(uint256 newSupply) external onlyOwner {
    require(newSupply < maxSupply);
    maxSupply = newSupply;
  }
}