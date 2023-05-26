// Culture Cubs NFT collection

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

interface IERC721Pledge {
    function pledgeMint(address to, uint8 quantity)
    external
    payable;
}

contract CultureCubs is IERC721Pledge, Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant PRESALE_PRICE = 0.13 ether;
  uint256 public constant MINT_PRICE = 0.15 ether;
  uint16 public constant MAX_COLLECTION_SIZE = 6666;
  uint8 public constant MAX_PER_WALLET = 10;

  uint8 public constant OG_MAX_MINT = 5;
  uint8 public constant CUBLIST_MAX_MINT = 3;
  uint8 public constant MASTER_MAX_MINT = 2;

  address public pledgeContractAddress;

  uint256 public maxPerWallet;
  uint256 public maxCollectionSize;

  uint256 public ogStartTime = 1655125200;      // Monday, June 13, 2022 1:00:00 PM GMT
  uint256 public cublistStartTime = 1655211600; // Tuesday, June 14, 2022 1:00:00 PM GMT
  uint256 public masterStartTime = 1655298000;  // Wednesday, June 15, 2022 1:00:00 PM GMT
  uint256 public publicStartTime = 1655312400;  // Wednesday, June 15, 2022 5:00:00 PM GMT

  mapping(address => uint256) public cublist;
  mapping(address => uint256) public oglist;
  mapping(address => uint256) public masterlist;
  
  constructor(
    address pledgeContractAddress_
  ) ERC721A("Culture Cubs", "CCUBS") {
    maxCollectionSize = MAX_COLLECTION_SIZE;
    maxPerWallet = MAX_PER_WALLET;
    pledgeContractAddress = pledgeContractAddress_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier onlyPledgeContract() {
    require(pledgeContractAddress == msg.sender, "The caller is not PledgeMint");
    _; 
  }

  function ogMint(uint256 quantity) external payable callerIsUser {
    require(block.timestamp > ogStartTime, "Presale has not yet started");
    _presaleMint(quantity, oglist);
  }

  function cublistMint(uint256 quantity) external payable callerIsUser {
    require(block.timestamp > cublistStartTime, "Presale has not yet started");
    _presaleMint(quantity, cublist);
  }

  function masterMint(uint256 quantity) external payable callerIsUser {
    require(block.timestamp > masterStartTime, "Presale has not yet started");
    _presaleMint(quantity, masterlist);
  }

  function _presaleMint(uint256 quantity, mapping(address => uint256) storage allowanceArr) internal {
    require(allowanceArr[msg.sender] >= quantity, "cannot mint this quantity");
    require(totalSupply() + quantity <= maxCollectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxPerWallet, "cannot mint this quantity");
    allowanceArr[msg.sender] -= quantity;
    _mint(msg.sender, quantity);
    refundIfOver(PRESALE_PRICE * quantity);
  }

  function publicMint(uint256 quantity) external payable callerIsUser {
    require(block.timestamp > publicStartTime, "General sale has not yet started");
    require(totalSupply() + quantity <= maxCollectionSize, "reached max supply");
    require(numberMinted(msg.sender) + quantity <= maxPerWallet, "cannot mint this quantity");
    _mint(msg.sender, quantity);
    refundIfOver(MINT_PRICE * quantity);
  }

  function devMint(address to, uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= maxCollectionSize, "reached max supply");
    _mint(to, quantity);
  }

  function pledgeMint(address to, uint8 quantity) override
    external
    payable
    onlyPledgeContract {
    require(totalSupply() + quantity <= maxCollectionSize, "reached max supply");
    require(msg.value >= PRESALE_PRICE * quantity, "Need to send more ETH.");
    _mint(to, quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function seedCublist(address[] memory addresses)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      cublist[addresses[i]] = CUBLIST_MAX_MINT;
    }
  }

  function seedOglist(address[] memory addresses)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      oglist[addresses[i]] = OG_MAX_MINT;
    }
  }

  function seedMasterlist(address[] memory addresses)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      masterlist[addresses[i]] = MASTER_MAX_MINT;
    }
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setMaxCollectionSize(uint16 maxCollectionSize_) external onlyOwner {
    // Can only be decreased
    require(maxCollectionSize_ < maxCollectionSize);
    maxCollectionSize = maxCollectionSize_;
  }

  function setMaxPerWallet(uint16 maxPerWallet_) external onlyOwner {
    require(maxPerWallet_ <= MAX_PER_WALLET);
    maxPerWallet = maxPerWallet_;
  }  

  function setOgStartTime(uint256 setOgStartTime_) external onlyOwner {
    ogStartTime = setOgStartTime_;
  }

  function setCublistStartTime(uint256 setCublistStartTime_) external onlyOwner {
    cublistStartTime = setCublistStartTime_;
  }

  function setMasterStartTime(uint256 setMasterStartTime_) external onlyOwner {
    masterStartTime = setMasterStartTime_;
  }

  function setPublicStartTime(uint256 setPublicStartTime_) external onlyOwner {
    publicStartTime = setPublicStartTime_;
  }

  function setPledgeContractAddress(address pledgeContractAddress_) external onlyOwner {
    pledgeContractAddress = pledgeContractAddress_;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
}