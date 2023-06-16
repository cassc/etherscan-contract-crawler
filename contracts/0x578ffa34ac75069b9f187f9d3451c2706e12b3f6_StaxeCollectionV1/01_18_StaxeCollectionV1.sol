// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @custom:security-contact [email protected]
contract StaxeCollectionV1 is ERC721, ERC721Enumerable, ERC2981, Ownable {
  using Counters for Counters.Counter;

  uint16 public immutable maxTokens;

  bool public enabled;
  bytes32 public merkleRoot;
  mapping(address => bool) public claimed;
  bool public openForPublic;
  Counters.Counter private _tokenIdCounter;

  constructor(bytes32 _merkleRoot, uint16 _maxTokens) ERC721("Staxe Genesis", "STX0") {
    merkleRoot = _merkleRoot;
    maxTokens = _maxTokens;
    _setDefaultRoyalty(_msgSender(), 500); // 5%
  }

  function _baseURI() internal pure override returns (string memory) {
    return "ipfs://QmNWbGaVPzK5hE23fm9X3cuUW4AYdxMQv1PGT71SNYpp1k/";
  }

  function mintOwner(address to) public onlyOwner {
    mintWithMax(to);
  }

  function mintAllowList(bytes32[] calldata merkleProof) external {
    require(enabled, "Not open for mint");
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));
    bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
    require(valid, "Merkle proof invalid");
    require(!claimed[_msgSender()], "Drop already claimed");
    claimed[_msgSender()] = true;
    mintWithMax(_msgSender());
  }

  function mintPublic() external {
    require(enabled && openForPublic, "Not open for public minting");
    mintWithMax(_msgSender());
  }

  function mintWithMax(address to) private {
    uint256 tokenId = _tokenIdCounter.current();
    require(tokenId < maxTokens, "Max supply reached");
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  function hasMoreMints() external view returns (bool) {
    return _tokenIdCounter.current() < maxTokens;
  }

  function hasClaimed() external view returns (bool) {
    return claimed[_msgSender()];
  }

  // Management functions for owner

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setOpenForPublic(bool _openForPublic) external onlyOwner {
    openForPublic = _openForPublic;
  }

  function setEnabled(bool _enabled) external onlyOwner {
    enabled = _enabled;
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}