//SPDX-License-Identifier: MIT
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

contract Vroom is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;
  using ECDSA for bytes32;

  Counters.Counter private _tokenIds;

  IERC721 public genesisKey;
  IERC721 public desperado;

  uint256 public maxSupply = 250;
  uint256 public discountMintPrice = 0.05 ether;
  uint256 public mintPrice = 0.1 ether;
  uint256 public maxMintPerWallet = 10;

  string public tokenBaseUri = '';
  uint256 public publicMintTime;

  address public payee;
  address public treasury;
  address public signatureAddress;

  bytes32 public merkleRoot;

  mapping(address => bool) private _accessList;
  mapping(uint256 => bool) private _genesisKeyUsage;
  mapping(uint256 => bool) private _desperadoUsage;
  mapping(address => uint256) private _walletsUsed;

  constructor(
    IERC721 genesisKeyCollection,
    IERC721 desperadoCollection,
    address payeeAddress,
    address treasuryAddress,
    address sigAddress,
    string memory preRevealBaseUri,
    uint256 mintTime,
    bytes32 root
  ) ERC721('R\xC5\x8CHKI', 'Vroom') Ownable() {
    genesisKey = IERC721(genesisKeyCollection);
    desperado = IERC721(desperadoCollection);
    payee = payeeAddress;
    treasury = treasuryAddress;
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
      'This wallet has already minted 10 episodes'
    );
    _walletsUsed[msg.sender] += 1;
    _tokenIds.increment();
    _safeMint(msg.sender, _tokenIds.current());
  }

  function genesisKeyMint(uint256 mintPass, bytes memory signature) external payable nonReentrant {
    require(isFreeMintActive(), 'Free mint is not active');
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
    require(isFreeMintActive(), 'Free mint is not active');

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

    require(!_accessList[msg.sender], 'Access list mint already used');

    _accessList[msg.sender] = true;

    _mint(signature);
  }

  function desperadoMint(uint256 desperadoId, bytes memory signature)
    external
    payable
    nonReentrant
  {
    require(isDiscountMintActive(), 'Desperado mint is not active');
    require(
      msg.sender == desperado.ownerOf(desperadoId),
      'You are not the owner of this Desperado'
    );
    require(
      isDesperadoUsable(desperadoId),
      'This Desperado has already been used for this episode'
    );

    require(discountMintPrice <= msg.value, 'You have not supplied enough eth');
    _desperadoUsage[desperadoId] = true;

    _mint(signature);
  }

  function publicMint(bytes memory signature) external payable nonReentrant {
    require(isPublicMintActive(), 'Public mint is not active right now');

    require(mintPrice <= msg.value, 'You have not supplied enough eth');

    _mint(signature);
  }

  function mintRemainingToTreasury() external onlyOwner {
    uint256 remainingQty = maxSupply - _tokenIds.current();

    for (uint256 i = 0; i < remainingQty; i++) {
      _tokenIds.increment();
      _safeMint(treasury, _tokenIds.current());
    }
  }

  function isFreeMintActive() public view returns (bool) {
    return (publicMintTime - 2 days) <= block.timestamp;
  }

  function isDiscountMintActive() public view returns (bool) {
    return (publicMintTime - 1 days) <= block.timestamp;
  }

  function isPublicMintActive() public view returns (bool) {
    return publicMintTime <= block.timestamp;
  }

  function isGenesisKeyUsable(uint256 mintPass) public view returns (bool) {
    return !_genesisKeyUsage[mintPass];
  }

  function isDesperadoUsable(uint256 mintPass) public view returns (bool) {
    return !_desperadoUsage[mintPass];
  }

  function setBaseUri(string memory newBaseUri) external onlyOwner {
    tokenBaseUri = newBaseUri;
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

  function updateTreasury(address treasuryAddress) external onlyOwner {
    treasury = treasuryAddress;
  }

  function updateMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
  }

  function updateDiscountMintPrice(uint256 newDiscountMintPrice) external onlyOwner {
    discountMintPrice = newDiscountMintPrice;
  }

  function updateSignatureAddress(address newSignatureAddress) external onlyOwner {
    signatureAddress = newSignatureAddress;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    return string(abi.encodePacked(tokenBaseUri, tokenId.toString(), '.json'));
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