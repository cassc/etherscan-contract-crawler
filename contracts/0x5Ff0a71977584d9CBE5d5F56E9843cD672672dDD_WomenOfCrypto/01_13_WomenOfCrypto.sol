//SPDX-License-Identifier: Unlicense
/*
$$\      $$\ $$$$$$\ $$\      $$\$$$$$$$$\$$\   $$\        $$$$$$\ $$$$$$$$\        $$$$$$\ $$$$$$$\$$\     $$\$$$$$$$\$$$$$$$$\ $$$$$$\
$$ | $\  $$ $$  __$$\$$$\    $$$ $$  _____$$$\  $$ |      $$  __$$\$$  _____|      $$  __$$\$$  __$$\$$\   $$  $$  __$$\__$$  __$$  __$$\
$$ |$$$\ $$ $$ /  $$ $$$$\  $$$$ $$ |     $$$$\ $$ |      $$ /  $$ $$ |            $$ /  \__$$ |  $$ \$$\ $$  /$$ |  $$ | $$ |  $$ /  $$ |
$$ $$ $$\$$ $$ |  $$ $$\$$\$$ $$ $$$$$\   $$ $$\$$ |      $$ |  $$ $$$$$\          $$ |     $$$$$$$  |\$$$$  / $$$$$$$  | $$ |  $$ |  $$ |
$$$$  _$$$$ $$ |  $$ $$ \$$$  $$ $$  __|  $$ \$$$$ |      $$ |  $$ $$  __|         $$ |     $$  __$$<  \$$  /  $$  ____/  $$ |  $$ |  $$ |
$$$  / \$$$ $$ |  $$ $$ |\$  /$$ $$ |     $$ |\$$$ |      $$ |  $$ $$ |            $$ |  $$\$$ |  $$ |  $$ |   $$ |       $$ |  $$ |  $$ |
$$  /   \$$ |$$$$$$  $$ | \_/ $$ $$$$$$$$\$$ | \$$ |       $$$$$$  $$ |            \$$$$$$  $$ |  $$ |  $$ |   $$ |       $$ |   $$$$$$  |
\__/     \__|\______/\__|     \__\________\__|  \__|       \______/\__|             \______/\__|  \__|  \__|   \__|       \__|   \______/
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract WomenOfCrypto is ERC721A, Ownable {
  uint256 public constant MAX_SUPPLY = 8888;
  uint256 public constant MAX_MINTS = 2;
  uint256 public constant PUBLIC_PRICE = 0.25 ether;
  uint256 public constant PRESALE_PRICE = 0.2 ether;

  bool public isPresaleActive = false;
  bool public isPublicSaleActive = false;

  bytes32 public merkleRoot;
  mapping(address => uint256) public purchaseTxs;
  mapping(address => uint256) private _allowed;

  string private _baseURIextended;

  address[] private mintPayees = [
    0x1F5688d6CFb24DC0aF7927f4cB59c3e1AC712c78,
    0x6d11A1B72b5ae0baEAA335F047c353e01c3DA2cA,
    0xCe736092A43b1864380bdadb0c39D78296a84017,
    0x5c1E3841e3CBE62a185c83D054f3f6eD21616CdC
  ];

  constructor() ERC721A("Women of Crypto", "WOC") {}

  function preSaleMint(bytes32[] calldata _proof, uint256 nMints)
    external
    payable
  {
    require(msg.sender == tx.origin, "Can't mint through another contract");
    require(isPresaleActive, "Presale not active");

    bytes32 node = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, merkleRoot, node), "Not on allow list");
    require(nMints <= MAX_MINTS, "Exceeds max token purchase");
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(PRESALE_PRICE * nMints <= msg.value, "Sent incorrect ETH value");
    require(_allowed[msg.sender] + nMints <= MAX_MINTS, "Exceeds mint limit");

    // Keep track of mints for each address
    if (_allowed[msg.sender] > 0) {
      _allowed[msg.sender] = _allowed[msg.sender] + nMints;
    } else {
      _allowed[msg.sender] = nMints;
    }

    _safeMint(msg.sender, nMints);
  }

  function mint(uint256 nMints) external payable {
    require(msg.sender == tx.origin, "Can't mint through another contract");
    require(isPublicSaleActive, "Public sale not active");
    require(nMints <= MAX_MINTS, "Exceeds max token purchase");
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(PUBLIC_PRICE * nMints <= msg.value, "Sent incorrect ETH value");

    _safeMint(msg.sender, nMints);
  }

  function withdrawAll() external onlyOwner {
    require(address(this).balance > 0, "No funds to withdraw");
    uint256 contractBalance = address(this).balance;

    _withdraw(mintPayees[0], (contractBalance * 15) / 100);
    _withdraw(mintPayees[1], (contractBalance * 23) / 100);
    _withdraw(mintPayees[2], (contractBalance * 10) / 100);
    _withdraw(mintPayees[3], address(this).balance);
  }

  function reserveMint(uint256 nMints, uint256 batchSize) external onlyOwner {
    require(totalSupply() + nMints <= MAX_SUPPLY, "Mint exceeds total supply");
    require(nMints % batchSize == 0, "Can only mint a multiple of batchSize");

    for (uint256 i = 0; i < nMints / batchSize; i++) {
      _safeMint(msg.sender, batchSize);
    }
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    _baseURIextended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function togglePresale() external onlyOwner {
    isPresaleActive = !isPresaleActive;
  }

  function togglePublicSale() external onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  receive() external payable {}
}