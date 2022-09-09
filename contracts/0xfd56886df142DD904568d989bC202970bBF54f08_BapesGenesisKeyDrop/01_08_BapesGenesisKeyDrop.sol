// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BapesGenesisKeyDrop is Ownable {
  using Strings for uint256;

  bool private isPaused = false;
  bytes32 private merkleRoot;
  uint256 public mintPerWallet = 1;
  uint256 public currentTokenId = 2143;
  mapping(address => uint256) private mintedWallets;

  IERC721 private bgk1;

  constructor() {
    bgk1 = IERC721(0x3A472c4D0dfbbb91ed050d3bb6B3623037c6263c);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function addressToString() internal view returns (string memory) {
    return Strings.toHexString(uint160(msg.sender), 20);
  }

  function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
    uint256 minted = mintedWallets[msg.sender];

    require(!isPaused, "Minting is paused");
    require(minted < mintPerWallet, "This wallet has already minted");

    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _mintAmount.toString()));

    require(
      MerkleProof.verify(_merkleProof, merkleRoot, leaf),
      "Invalid proof, this wallet is not eligible for selected amount of NFTs"
    );

    mintedWallets[msg.sender] = mintPerWallet;

    for (uint256 i = 0; i < _mintAmount; i++) {
      bgk1.safeTransferFrom(address(this), msg.sender, currentTokenId);

      currentTokenId++;
    }
  }

  function togglePause(bool _state) external onlyOwner {
    isPaused = _state;
  }

  function updateMintPerWallet(uint256 _amount) external onlyOwner {
    mintPerWallet = _amount;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}