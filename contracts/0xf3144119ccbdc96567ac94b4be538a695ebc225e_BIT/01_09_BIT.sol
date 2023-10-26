// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a/contracts/ERC721A.sol";

contract BIT is ERC721A, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 public constant MAX_SUPPLY = 1500;
  uint256 public constant MAX_PRESALE_SUPPLY = 1250;
  uint256 public constant MAX_SUPPLY_PER_WALLET = 5;
  uint256 public constant MAX_SUPPLY_PRESALE_PER_WALLET = 2;
  uint256 public constant TEAM_SUPPLY = 51;

  bytes32 public merkleRoot;
  bool public isActive = false;
  bool public preSaleActive = false;
  bool public publicSaleActive = false;

  mapping(address => uint256) public quantityPerWallet;

  uint256 public salePriceETH;      // the amount of ETH per token

  uint256 public salePriceAPE;      // the amount of APE per token

  uint256 public presaleMintedQty;

  string private baseTokenURI;

  address public verifier;

  // ApeCoin(APE) address
  address public apeAddress;

  // event list
  event publicSaleMinted(address _to, uint256 _qty);

  event publicSaleMintedAPE(address _to, uint256 _qty);

  event preSaleMinted(address _to, uint256 _qty);

  event preSaleMintedAPE(address _to, uint256 _qty);

  constructor(
    address _apeAddress,
    uint256 _salePriceETH,
    uint256 _salePriceAPE
  ) ERC721A("BackInTime", "BIT") {
    apeAddress = _apeAddress;
    salePriceETH = _salePriceETH;
    salePriceAPE = _salePriceAPE;
  }

  modifier onlyEOA() {
    require(tx.origin == msg.sender, "YO Contract your not allowed !");
    _;
  }

  //  Set Sale Price
  function setSalePriceETH(uint256 price) external onlyOwner {
    salePriceETH = price;
  }

  function setSalePriceAPE(uint256 price) external onlyOwner {
    salePriceAPE = price;
  }

  // Set Base URI
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  //  Set verifier for public sale
  function setVerifier(address _verifier) external onlyOwner {
    verifier = _verifier;
  }

  // Toggle activate/desactivate the smart contract
  function toggleActive() external onlyOwner {
    isActive = !isActive;
  }

  //  Set presale active / deactive
  function setPreSaleActive(bool active) external onlyOwner {
    require(preSaleActive != active, "PreSale: Active Same State");
    preSaleActive = active;
  }

  //  Set public sale active / deactive
  function setPublicSaleActive(bool active) external onlyOwner {
    require(publicSaleActive != active, "PublicSale: Active Same State");
    publicSaleActive = active;
  }

  function isPublicSaleValid(bytes calldata sig) internal view returns (bool) {
    return
      ECDSA.recover(
        keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash(),
        sig
      ) == verifier;
  }

  // Mint on Public Sale using ETH
  function publicSaleMint(uint256 qty, bytes calldata sig)
    external
    payable
    nonReentrant
    onlyEOA
  {
    require(isActive, "Contract: Not Active");
    require(publicSaleActive, "PublicSale: Not Active");
    require(isPublicSaleValid(sig), "PublicSale: Invalid Signature");
    require(qty != 0, "PublicSale: 0 Quantity");
    require(totalSupply() + qty <= MAX_SUPPLY, "PublicSale: Over Max Supply");
    require(
      quantityPerWallet[msg.sender] + qty <= MAX_SUPPLY_PER_WALLET,
      "PublicSale: Over Max Supply Per Wallet"
    );
    require(msg.value == salePriceETH * qty, "PublicSale: Insufficient ETH");

    _mint(msg.sender, qty);
    quantityPerWallet[msg.sender] += qty;

    emit publicSaleMinted(msg.sender, qty);
  }

  // Mint on Public Sale using APE
  function publicSaleMintAPE(uint256 qty, bytes calldata sig)
    external
    nonReentrant
    onlyEOA
  {
    require(isActive, "Contract: Not Active");
    require(publicSaleActive, "PublicSale: Not Active");
    require(isPublicSaleValid(sig), "PublicSale: Invalid Sale");
    require(qty != 0, "PublicSale: No Quantity");
    require(totalSupply() + qty <= MAX_SUPPLY, "PublicSale: Over Max Supply");
    require(
      quantityPerWallet[msg.sender] + qty <= MAX_SUPPLY_PER_WALLET,
      "PublicSale: Over Max Supply Per Wallet"
    );

    uint256 apePrice = salePriceAPE * qty;
    require(IERC20(apeAddress).balanceOf(msg.sender) >= apePrice, "PublicSale: Insufficient APE");
    require(_transferAPE(msg.sender, address(this), apePrice), "APE Token: Transfer Error.");

    _mint(msg.sender, qty);
    quantityPerWallet[msg.sender] += qty;

    emit publicSaleMintedAPE(msg.sender, qty);
  }

  // Verify the Merkle Tree Proof
  function verify(
    bytes32 root,
    bytes32[] memory proof,
    bytes32 leaf
  ) public pure returns (bool) {
    bytes32 hash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (hash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        hash = keccak256(abi.encodePacked(hash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        hash = keccak256(abi.encodePacked(proofElement, hash));
      }
    }

    return hash == root;
  }

  //  Set merkle root hash
  function setMintList(bytes32 merkleRootHash) external onlyOwner {
    require(merkleRoot != merkleRootHash, "MintList MerkleRoot is Already Set the Same!");
    merkleRoot = merkleRootHash;
  }

  // Mint on presale / raffle using ETH
  function preSaleMint(uint256 qty, bytes32[] calldata _proof)
    external
    payable
    nonReentrant
    onlyEOA
  {
    require(isActive, "Contract: Not Active");
    require(preSaleActive, "PreSale: Not Active");
    require(qty != 0, "PreSale: 0 Quantity");
    require(totalSupply() + qty <= MAX_SUPPLY, "PreSale: Over Max Supply");
    require(
      quantityPerWallet[msg.sender] + qty <= MAX_SUPPLY_PRESALE_PER_WALLET,
      "PreSale: Over Max Supply Per Wallet"
    );
    require(
      presaleMintedQty + qty <= MAX_PRESALE_SUPPLY,
      "PreSale: Over Max Presale Supply"
    );
    require(msg.value == salePriceETH * qty, "PreSale: Insufficient ETH");

    // Check Allowlist
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(verify(merkleRoot, _proof, leaf), "PreSale: Not mintlisted");

    // We don't prevent several mints, we rely on quantity only
    presaleMintedQty += qty;
    quantityPerWallet[msg.sender] += qty;
    _mint(msg.sender, qty);

    emit preSaleMinted(msg.sender, qty);
  }

  // Mint on presale / raffle using APE
  function preSaleMintAPE(uint256 qty, bytes32[] memory _proof)
    external
    nonReentrant
    onlyEOA
  {
    require(isActive, "Contract: Not Active");
    require(preSaleActive, "PreSale: Not Active");
    require(qty != 0, "PreSale: No Quantity");
    require(totalSupply() + qty <= MAX_SUPPLY, "PreSale: Over Max Supply");
    require(
      quantityPerWallet[msg.sender] + qty <= MAX_SUPPLY_PRESALE_PER_WALLET,
      "PreSale: Over Max Supply Per Wallet"
    );
    require(
      presaleMintedQty + qty <= MAX_PRESALE_SUPPLY,
      "PreSale: Over Max Presale Supply"
    );

    uint256 apePrice = salePriceAPE * qty;
    require(IERC20(apeAddress).balanceOf(msg.sender) >= apePrice, "PreSale: Insufficient APE");
    require(_transferAPE(msg.sender, address(this), apePrice), "APE Token: Transfer Error.");

    // Check Allowlist
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(verify(merkleRoot, _proof, leaf), "PreSale: Not mintlisted");

    // We don't prevent several mints, we rely on quantity only

    presaleMintedQty += qty;
    quantityPerWallet[msg.sender] += qty;
    _mint(msg.sender, qty);

    emit preSaleMintedAPE(msg.sender, qty);
  }

  //  Team mint
  function teamMint() external onlyOwner {
    require(
      totalSupply() + TEAM_SUPPLY <= MAX_SUPPLY,
      "TeamMint: Over Max Supply"
    );

    uint256 maxBatchSize = 10;
    for (uint256 i; i < 5; i++) { 
        _mint(msg.sender, maxBatchSize);
    }

    uint256 remaining = TEAM_SUPPLY % maxBatchSize;
    if (remaining > 0) {
        _mint(msg.sender, remaining);
    }
  }

  //  Withdraw ETH
  function withdrawETH() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "Withdraw: Insufficient ETH");

    bool success;
    if(balance > 0){
      (success, ) = payable(msg.sender).call{ value: balance }("");
    }
    require(success, "Withdraw: Failed");
  }

  //  Withdraw APE
  function withdrawAPE() external onlyOwner {
    uint256 balanceAPE = IERC20(apeAddress).balanceOf(address(this));
    require(balanceAPE > 0, "Withdraw: Insufficient APE");
    
    bool success;
    if(balanceAPE > 0){
      success = IERC20(apeAddress).transfer(msg.sender, balanceAPE);
    }
    require(success, "Withdraw: Failed");
  }

  /**
    * @notice Transfer APE and return the success status.
    */
  function _transferAPE(address from, address to, uint256 amount) internal returns (bool) {
      bool success = IERC20(apeAddress).transferFrom(from, to, amount);
      return success;
  }
}