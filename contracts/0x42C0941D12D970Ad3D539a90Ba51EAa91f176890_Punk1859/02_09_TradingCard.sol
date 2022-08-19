// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

struct MintPhase {
  bytes32 merkleRoot;
  uint32 startTime;
  uint32 walletLimit;
  uint32 id;
}

contract TradingCard is ERC721A, Ownable, ReentrancyGuard, Pausable {

  string private _name;
  string private _symbol;
  string private _metadataRoot;
  string private _contractMetadata;
  mapping(uint => MintPhase) private _mintPhases;
  mapping(bytes32 => bool) private _usedLeaves;
  uint private _maxMintPhase = 0;
  bool private _mintStatus = false;
  uint public supplyLimit = 2_500;

  constructor(
    string memory name_,
    string memory symbol_,
    string memory metadataRoot_,
    string memory contractMetadata_

  ) ERC721A(name_, symbol_) {
    _name = name_;
    _symbol = symbol_;
    _metadataRoot = metadataRoot_;
    _contractMetadata = contractMetadata_;
  }

  function updateTokenInfo(
    string memory name_,
    string memory symbol_,
    string memory metadataRoot_,
    string memory contractMetadata_
  ) onlyOwner public {
    _name = name_;
    _symbol = symbol_;
    _metadataRoot = metadataRoot_;
    _contractMetadata = contractMetadata_;
  }

  function name() public view override returns(string memory) {
    return _name;
  }

  function symbol() public view override returns(string memory) {
    return _symbol;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataRoot;
  }

  function setBaseURI(string memory uri) onlyOwner public {
    _metadataRoot = uri;
  }

  function contractURI() public view returns(string memory) {
    return _contractMetadata;
  }

  function setContractURI(string memory uri) onlyOwner public {
    _contractMetadata = uri;
  }

  function mintStatus() public view returns(bool) {
    return _mintStatus;
  }

  function setMintStatus(bool status) onlyOwner public {
    _mintStatus = status;
  }

  function walletLimit() public view returns(uint) {
    return uint256(currentMintPhase().walletLimit);
  }

  function pause(bool pause_) onlyOwner public {
    if (pause_) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setMintPhases(uint[] memory listID, bytes32[] memory root, uint32[] memory startTimes, uint32[] memory walletLimits) onlyOwner public {
    require(listID.length == root.length && listID.length == startTimes.length, 'Array mismatch');

    for (uint i = 0; i < listID.length; i++) {
      _mintPhases[ listID[i] ] = MintPhase(
        root[ i ],
        startTimes[ i ],
        walletLimits[ i ],
        uint32(listID[ i ])
      );

      if (listID[ i ] > _maxMintPhase) {
        _maxMintPhase = listID[ i ];
      }
    }
  }

  function mintPhase(uint listID) public view returns(MintPhase memory) {
    return _mintPhases[ listID ];
  }

  function currentMintPhase() public view returns(MintPhase memory) {
    MintPhase memory phase;
    for (uint i = _maxMintPhase + 1; i > 0; i--) {
      phase = _mintPhases[ i - 1 ];
      if (phase.startTime > 0
        && block.timestamp >= phase.startTime) {
          return phase;
      }
    }

    return MintPhase(0x0, 0, 0, 0);
  }

  function totalMinted() public view returns(uint) {
    return _totalMinted();
  }

  function numberMinted(address wallet) public view returns(uint) {
    return _numberMinted(wallet);
  }

  function mint(uint64 quantity) public {
    bytes32[] memory proof;
    mint(quantity, proof);
  }

  function mint(uint64 quantity, bytes32[] memory proof) nonReentrant public {
    require(_mintStatus, "Minting not open");
    MintPhase memory phase = currentMintPhase();
    require(phase.startTime > 0 && phase.startTime <= block.timestamp, "Open phase not found");
    require((_totalMinted() + quantity) <= supplyLimit, "Supply cap reached");
    require(proof.length != 0 || phase.merkleRoot == bytes32(0x0),
       "Public minting not open"
    );

    require(phase.walletLimit == 0 || (_numberMinted(_msgSender()) + quantity) <= uint256(phase.walletLimit),
      "Mint limit reached"
    );

    require(
      phase.merkleRoot == bytes32(0x0)
      || MerkleProof.verify(proof, phase.merkleRoot,  makeMerkleLeaf(_msgSender())),
      "Not on allow list"
    );

    _safeMint(_msgSender(), quantity);
  }

  function adminMint(address[] calldata owners, uint64[] calldata quantities) nonReentrant onlyOwner public {
    require(owners.length == quantities.length, "Array mismatch");
    for (uint i = 0; i < owners.length; i++) {
      require(_totalMinted() + quantities[ i ] <= supplyLimit, "Supply cap reached");
      _safeMint(owners[ i ], quantities[ i ]);
    }
  }

  function makeMerkleLeaf(address wallet) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(wallet));
  }
}