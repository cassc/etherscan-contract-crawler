// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SpaceBapesCertificateDrop is Ownable {
  using Strings for uint256;

  bool private isMintStarted = false;
  bytes32 private merkleRoot;
  uint256 public mintPerWallet = 1;
  uint256 public startTokenId = 2143;
  mapping(address => uint256) private mintedWallets;

  IERC721 private sbc;

  constructor() {
    sbc = IERC721(0xD332A125ba3e5471980b7320e21884479143AF92);
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

  function transferTo(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      sbc.safeTransferFrom(address(this), _receiver, startTokenId);

      startTokenId++;
    }
  }

  function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
    uint256 minted = mintedWallets[msg.sender];

    require(isMintStarted, "Minting is paused");
    require(minted < mintPerWallet, "This wallet has already minted");

    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _mintAmount.toString()));

    require(
      MerkleProof.verify(_merkleProof, merkleRoot, leaf),
      "Invalid proof, this wallet is not eligible for selected amount of NFTs"
    );

    mintedWallets[msg.sender] = mintPerWallet;

    transferTo(msg.sender, _mintAmount);
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyOwner {
    require(isMintStarted, "Minting is paused");

    transferTo(_receiver, _mintAmount);
  }

  function toggleMint(bool _state) external onlyOwner {
    isMintStarted = _state;
  }

  function updateMintPerWallet(uint256 _amount) external onlyOwner {
    mintPerWallet = _amount;
  }

  function updateStartTokenId(uint256 _tokenId) external onlyOwner {
    startTokenId = _tokenId;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}