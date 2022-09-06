// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'erc721a/contracts/ERC721A.sol';

contract SummerPenguin is Ownable, ERC721A {
  string public baseURI = 'ipfs://bafybeid27h7j6c6mpufa75n6s2eaymxfgz6k3jqagwydepuiw3bxpv3ynq/';
  address public signerAddress;
  uint256 public maxSupply = 4000;

  struct SaleConfig {
    uint32 maxPerWallet;
    uint32 supplyLimit;
    uint32 timeDeadline;
    uint128 unitPrice;
  }

  constructor() ERC721A('SummerPenguin', 'SUPE') {
    _mintERC2309(msg.sender, maxSupply / 10);
  }

  function verifySignature(SaleConfig calldata saleConfig, bytes calldata signature)
    internal
    view
    returns (bool)
  {
    bytes32 hash = keccak256(
      abi.encodePacked(
        msg.sender,
        saleConfig.maxPerWallet,
        saleConfig.supplyLimit,
        saleConfig.timeDeadline,
        saleConfig.unitPrice
      )
    );
    bytes32 message = ECDSA.toEthSignedMessageHash(hash);
    return signerAddress == ECDSA.recover(message, signature);
  }

  function mint(
    uint32 quantity,
    SaleConfig calldata saleConfig,
    bytes calldata signature
  ) external payable {
    uint256 nextSupply = _nextTokenId() - _startTokenId() + quantity;
    require(nextSupply <= maxSupply, '1');
    require(nextSupply <= saleConfig.supplyLimit, '2');
    require(block.timestamp <= saleConfig.timeDeadline, '3');
    require((_numberMinted(msg.sender) + quantity) <= saleConfig.maxPerWallet, '4');
    require((quantity * saleConfig.unitPrice) <= msg.value, '5');
    require(verifySignature(saleConfig, signature), '6');

    _mint(msg.sender, quantity);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 0;
  }

  function setBaseURI(string calldata __baseURI) external onlyOwner {
    baseURI = __baseURI;
  }

  function reduceMaxSupplyTo(uint256 _maxSupply) external onlyOwner {
    require(_maxSupply < maxSupply);
    maxSupply = _maxSupply;
  }

  function setSignerAddress(address _signerAddress) external onlyOwner {
    signerAddress = _signerAddress;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}