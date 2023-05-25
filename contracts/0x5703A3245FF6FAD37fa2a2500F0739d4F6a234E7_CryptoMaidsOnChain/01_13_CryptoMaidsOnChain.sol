// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./roles/AccessOperatable.sol";

// On Chain Maids Contract Interface(Full on chain metadata)
interface iOCM {
  function tokenURI(uint256 tokenId_) external view returns (string memory);
}

contract CryptoMaidsOnChain is ERC721, AccessOperatable {
  iOCM public OCM;
  bool public useOnChainMetadata = false;
  uint256 public constant MAX_ELEMENTS = 2023;
  string public defaultURI;
  uint256 private _supply;

  constructor() ERC721("CryptoMaidsOnChain", "CMOC") {
    defaultURI = "https://api.cryptomaids.tokyo/metadata/crypto_maid/";
  }

  function setOCM(address address_) external onlyOperator() {
    OCM = iOCM(address_);
  }

  function setUseOnChainMetadata(bool useOnChainMetadata_) external onlyOperator() {
    useOnChainMetadata = useOnChainMetadata_;
  }

  function mint(address to, uint256 tokenId) public onlyOperator()  {
    require(totalSupply() < MAX_ELEMENTS, "Exceed Max Elements");
    _supply++;
    _safeMint(to, tokenId);
  }

  function bulkMint(address[] memory _tos, uint256[] memory _tokenIds) public onlyOperator() {
    require(_tos.length == _tokenIds.length);
    uint8 i;
    for (i = 0; i < _tos.length; i++) {
      mint(_tos[i], _tokenIds[i]);
    }
  }

  function totalSupply() public view returns (uint256) {
    return _supply;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (useOnChainMetadata && OCM != iOCM(address(0x0))) {
      return OCM.tokenURI(tokenId);
    } else {
      return super.tokenURI(tokenId);
    }
  }

  function setDefaultURI(string memory defaultURI_) public onlyOperator() {
    defaultURI = defaultURI_;
  }

  function _baseURI() internal view override returns (string memory) {
    return defaultURI;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}