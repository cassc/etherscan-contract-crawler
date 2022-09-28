// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GMTool is ERC721A, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant MAX_GM_TOOL = 3333;
  uint256 public MAX_GM_TOOL_PER_PURCHASE = 7;
  uint256 public MAX_GM_TOOL_WHITELIST_CAP = 2;
  uint256 public constant GM_TOOL_PRICE = 0.07 ether;
  uint256 public constant GM_TOOL_PRESALE_PRICE = 0.05 ether;
  uint256 public constant RESERVED_GM_TOOL = 100;
  
  bytes32 internal merkleroot;
  bytes32 internal freeMintmerkleroot;
  string public tokenBaseURI;
  bool public presaleActive = false;
  bool public mintActive = false;
  bool public reservesMinted = false;
  bool public reveal = false;
  bool public freeSale = false;

  mapping(address => uint256) private whitelistAddressMintCount;
  mapping(address => uint256) public freemintAddressMintCount;

  IERC721 gmkeyInterface;

  /**
   * @dev Contract Methods
   */
  constructor(
    uint256 _maxGMToolPerPurchase,
    address tokenContractAddress
  ) ERC721A("GM Tools", "GMT", _maxGMToolPerPurchase, MAX_GM_TOOL) {
      gmkeyInterface = IERC721(tokenContractAddress);
  }
  /********
   * Mint *
   ********/ 
  function presaleMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable nonReentrant {
    require(verifyMerkleProof(keccak256(abi.encodePacked(msg.sender)), _merkleProof), "Invalid whitelist signature");
    require(presaleActive, "Presale is not active");
    require(_quantity <= MAX_GM_TOOL_WHITELIST_CAP, "This is above the max allowed mints for presale");
    require(msg.value >= GM_TOOL_PRESALE_PRICE.mul(_quantity), "The ether value sent is not correct");
    require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_GM_TOOL_WHITELIST_CAP, "This purchase would exceed the maximum you are allowed to mint in the presale");
    require(totalSupply().add(_quantity) <= MAX_GM_TOOL - RESERVED_GM_TOOL - 777, "This purchase would exceed max supply for presale");

    whitelistAddressMintCount[msg.sender] += _quantity;
    _safeMintGMTool(_quantity);
  }

  function publicMint(uint256 _quantity) external payable {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_GM_TOOL_PER_PURCHASE, "Quantity is more than allowed per transaction.");
    require(msg.value >= GM_TOOL_PRICE.mul(_quantity), "The ether value sent is not correct");
    require(totalSupply().add(_quantity) <= MAX_GM_TOOL - 777, "This would exceed max supply");
    _safeMintGMTool(_quantity);
  }

  function freesaleMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable nonReentrant {
    require(verifyFreeMintMerkleProof(keccak256(abi.encodePacked(msg.sender)), _merkleProof), "Invalid freemint signature");
    require(freeSale, "Free Sale is not active");
    uint256 keybalance = gmkeyInterface.balanceOf(msg.sender);
    if(keybalance > 0) {
      require(freemintAddressMintCount[msg.sender].add(_quantity) <= keybalance, "This purchase would exceed the maximum you are allowed to mint in the freesale");
    }
    if(keybalance == 0) {
      require(freemintAddressMintCount[msg.sender].add(_quantity) <= 1, "This purchase would exceed the maximum you are allowed to mint in the freesale");
    }
    require(totalSupply().add(_quantity) <= MAX_GM_TOOL, "This purchase would exceed max supply for freesale");

    freemintAddressMintCount[msg.sender] += _quantity;
    _safeMintGMTool(_quantity);
  }

  function _safeMintGMTool(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 gm tool nft");
    require(totalSupply().add(_quantity) <= MAX_GM_TOOL, "This purchase would exceed max supply");
    _safeMint(msg.sender, _quantity);
  }

  /*
   * Note: Mint reserved gm tool.
   */

  function mintReservedGMTool() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(totalSupply().add(RESERVED_GM_TOOL) <= MAX_GM_TOOL, "This mint would exceed max supply");
    _safeMint(msg.sender, RESERVED_GM_TOOL);

    reservesMinted = true;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }
  
  function setFreeSale(bool _freeSale) external onlyOwner {
    freeSale = _freeSale;
  }

  function setMerkleRoot(bytes32 MR) external onlyOwner {
    merkleroot = MR;
  }
  
  function setFreeMintmerkleroot(bytes32 _freeMintmerkleroot) external onlyOwner {
    freeMintmerkleroot = _freeMintmerkleroot;
  }

  function setReveal(bool _reveal) external onlyOwner {
    reveal = _reveal;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    if (!reveal) {
      return string(abi.encodePacked(tokenBaseURI));
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }
  /**************
   * Withdrawal *
   **************/

  function teamWithdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    uint payeeOneValue = balance.div(4);
    address payeeWallet = 0x599b79655cE201b83F5E13db063472fFf842b1e0;
    payable(payeeWallet).transfer(payeeOneValue);
    uint256 remainingBalance = balance - payeeOneValue;
    payable(msg.sender).transfer(remainingBalance);
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /************
   * Security *
   ************/

  function verifyMerkleProof(bytes32 leaf, bytes32[] memory _merkleProof) private view returns(bool) {
    return MerkleProof.verify(_merkleProof, merkleroot, leaf);
  }

  function verifyFreeMintMerkleProof(bytes32 leaf, bytes32[] memory _merkleProof) private view returns(bool) {
    return MerkleProof.verify(_merkleProof, freeMintmerkleroot, leaf);
  }
}