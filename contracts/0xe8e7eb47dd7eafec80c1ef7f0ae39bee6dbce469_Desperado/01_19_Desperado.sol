//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

contract Desperado is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;
  using ECDSA for bytes32;

  Counters.Counter private _tokenIds;

  IERC721 public genesisKey;

  uint256 public maxSupply = 500;
  uint256 public mintPrice = 0.1 ether;
  uint256 public maxMintPerWallet = 5;

  string public tokenBaseUri = '';
  string public tokenRevealedBaseUri = '';
  uint256 public publicMintTime;

  address public payee;
  address public signatureAddress;

  bytes32 public merkleRoot;

  mapping(address => bool) private _accessList;
  mapping(uint256 => bool) private _genesisKeyUsage;
  mapping(address => uint256) private _walletsUsed;

  constructor(
    IERC721 genesisKeyCollection,
    address payeeAddress,
    address sigAddress,
    string memory preRevealBaseUri,
    uint256 mintTime,
    bytes32 root
  ) ERC721('R\xC5\x8CHKI', 'Desperado') Ownable() {
    genesisKey = IERC721(genesisKeyCollection);
    payee = payeeAddress;
    signatureAddress = sigAddress;
    tokenBaseUri = preRevealBaseUri;
    publicMintTime = mintTime;
    merkleRoot = root;
  }

  function _mint(bytes memory signature) internal {
    require(
      _verifySignature(
        keccak256(abi.encodePacked('MintApproval(address minter)', msg.sender)),
        signature
      ),
      'The address hash does not match the signed hash'
    );

    require(_tokenIds.current() < maxSupply, 'Supply unavailable to mint');
    require(
      _walletsUsed[msg.sender] < maxMintPerWallet,
      'This wallet has already minted 5 episodes'
    );
    require(mintPrice <= msg.value, 'You have not supplied enough eth');
    _walletsUsed[msg.sender] += 1;
    _tokenIds.increment();
    _safeMint(msg.sender, _tokenIds.current());
  }

  function publicMint(bytes memory signature) external payable nonReentrant {
    require(isPublicMintActive(), 'Public mint is not active right now');

    _mint(signature);
  }

  function genesisKeyMint(uint256 mintPass, bytes memory signature) external payable nonReentrant {
    require(isPresaleMintActive(), 'Presale is not active');
    require(
      msg.sender == genesisKey.ownerOf(mintPass),
      'You are not the owner of this Genesis Key'
    );
    require(
      isGenesisKeyUsable(mintPass),
      'This Genesis Key has already been used for this episode'
    );

    _genesisKeyUsage[mintPass] = true;

    _mint(signature);
  }

  function accessListMint(bytes32[] calldata merkleProof, bytes memory signature)
    external
    payable
    nonReentrant
  {
    require(isPresaleMintActive(), 'Presale is not active');

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

    require(!_accessList[msg.sender], 'Access list mint already used');

    _accessList[msg.sender] = true;

    _mint(signature);
  }

  function isPublicMintActive() public view returns (bool) {
    return publicMintTime <= block.timestamp;
  }

  function isGenesisKeyUsable(uint256 mintPass) public view returns (bool) {
    return !_genesisKeyUsage[mintPass];
  }

  function isPresaleMintActive() public view returns (bool) {
    return (publicMintTime - 1 days) <= block.timestamp;
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    tokenBaseUri = newBaseUri;
  }

  function setRevealedBaseUri(string memory newRevealedBaseUri) external onlyOwner {
    tokenRevealedBaseUri = newRevealedBaseUri;
  }

  function setPublicMintTime(uint256 newPublicMintTime) external onlyOwner {
    publicMintTime = newPublicMintTime;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    merkleRoot = root;
  }

  function updatePayee(address payeeAddress) external onlyOwner {
    payee = payeeAddress;
  }

  function updateMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
  }

  function updateSignatureAddress(address newSignatureAddress) external onlyOwner {
    signatureAddress = newSignatureAddress;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    return
      bytes(tokenRevealedBaseUri).length > 0
        ? string(abi.encodePacked(tokenRevealedBaseUri, tokenId.toString(), '.json'))
        : string(abi.encodePacked(tokenBaseUri, tokenId.toString(), '.json'));
  }

  function _verifySignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == signatureAddress;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(payable(payee).send(balance), 'Transfer failed');
  }
}