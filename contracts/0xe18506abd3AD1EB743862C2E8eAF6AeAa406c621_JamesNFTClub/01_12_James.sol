// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract JamesNFTClub is ERC1155Supply, Ownable
{
  uint8 public saleState;
  uint256 public totalMinted;
  uint256 public MAX_SUPPLY = 569;
  uint256 public AIRDROP_AMOUNT = 69;
  bytes32 public root = 0x1ce2e6009842f6535f7fd932f8a2a596843af312357d0c45ad607acff4c86434;
  uint256 public PRESALE_PRICE = 0.1 ether;
  uint256 public PUBSALE_PRICE = 0.169 ether;
  bool public airdropped;
  string public name = "James NFT Club";
  string public contractURIstr = "";
  mapping(address => uint256) public minted;

  constructor() ERC1155("https://ipfs.io/ipfs/QmZ5im37Mkz8k1F6ayM3WN25rcReCakXn8Wwur15rnTeN9/{id}.json") {}

  function contractURI() public view returns (string memory)
  {
      return contractURIstr;
  }

  function setContractURI(string memory newuri) external onlyOwner
  {
      contractURIstr = newuri;
  }

  function setName(string memory _name) public onlyOwner 
  {
      name = _name;
  }

  function getName() public view returns (string memory) 
  {
      return name;
  }

  function setURI(string memory newuri) external onlyOwner
  {
    _setURI(newuri);
  }

  function setRoot(bytes32 _newRoot) external onlyOwner {
    root = _newRoot;
  }

  function startPresale() external onlyOwner {
    require(saleState == 0, "Sale is already active");
    saleState = 1;
  }

  function endPresale() external onlyOwner {
    require(saleState == 1, "Presale is not active");
    saleState = 0;
  }

  function startPublicSale() external onlyOwner {
    require(saleState == 0, "Sale is already active");
    saleState = 2;
  }

  function endPublicSale() external onlyOwner {
    require(saleState == 2, "Presale is not active");
    saleState = 0;
  }

  function giveAway() external onlyOwner {
    require(airdropped == false, "Already airdropped");
    require(totalMinted + AIRDROP_AMOUNT <= MAX_SUPPLY, "Exceeds max amount");
    _mint(owner(), 1, AIRDROP_AMOUNT, "");
    airdropped = true;
    totalMinted += AIRDROP_AMOUNT;
  }

  function mint(bytes32[] memory _proof, uint256 amount) external payable
  {
    require(saleState > 0, "Sale is not active");
    require(amount <= 2, "Exceeds max per transaction");
    require(totalMinted + amount <= MAX_SUPPLY, "Exceeds max amount");
    if (saleState == 1) {
      require(MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender))) == true, "Not on whitelist");
      require(minted[msg.sender] + amount <= 2, "Exceeds max amount in presale");
      require(msg.value >= PRESALE_PRICE * amount, "Insufficient Fund");
    } else {
      require(msg.value >= PUBSALE_PRICE * amount, "Insufficient Fund");
    }
    totalMinted += amount;
    minted[msg.sender] += amount;
    _mint(msg.sender, 1, amount, "");
  }

  function withdraw() external onlyOwner
  {
    require(msg.sender == owner(), "Invalid sender");
    payable(msg.sender).transfer(address(this).balance);
  }
}