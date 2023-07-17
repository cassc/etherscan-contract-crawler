//SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HammeredDragonWinery is ERC721, Ownable {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  // Public Sell Mint
  event SellMint(uint indexed nums, address indexed minter);

  uint256 public tokenPrice = 80000000000000000;  //0.08 ETH

  uint256 public constant MAX_DRAGONS = 10000;
  uint256 public constant MAX_GROUP_MINTS = 100;//AirDrop Community
  uint256 public constant MAX_SALE_MINTS = MAX_DRAGONS - MAX_GROUP_MINTS;

  uint256 public groupMintedNum = 0;
  uint256 public saleMintedNum = 0;

  uint public maxBuy = 10;
  uint public totalBuy = 20;

  bool public publicSale = false;
  bool public preSale = false;

  mapping(address => uint) public _soldMap;
  mapping(address => uint) public presaleWhitelist;
  EnumerableSet.AddressSet private _whitelistKeys;

  //Dragon Born
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
  }

  //withdraw this.blance to Owner
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    msg.sender.transfer(balance);
  }

  function flipSaleState() public onlyOwner {
    publicSale = !publicSale;
  }

  function flipPreSaleState() public onlyOwner {
    preSale = !preSale;
  }

  function setMaxBuy(uint nums) public onlyOwner {
    require(nums > 0, "nums should large then 0.");
    maxBuy = nums;
  }

  function setTotalBuy(uint nums) public onlyOwner {
    require(nums > 0, "nums should large then 0.");
    require(nums > maxBuy, "nums should large then maxBuy.");
    totalBuy = nums;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function changePrice(uint256 newPrice) public onlyOwner {
    tokenPrice = newPrice;
  }

  //Normal mint
  function mint(uint nums) external payable {
    require(publicSale, "Sale not started.");
    require(nums > 0, "nums should large then 0.");
    require(nums <= maxBuy, "reach max sell limit.");
    require(saleMintedNum.add(nums) <= MAX_SALE_MINTS, "Sale mint limit reached.");
    require(totalSupply() < MAX_DRAGONS, "DRAGONS sold out.");
    require((_soldMap[msg.sender]).add(nums) <= totalBuy, "Total buy exceeded.");

    uint salePrice = getPrice().mul(nums);
    require(msg.value >= salePrice, "not enough funds to purchase.");

    for (uint i = 0; i < nums; i++) {
      uint id = nextIndex();
      if (id < MAX_DRAGONS) {
        _safeMint(msg.sender, id);
      }
    }

    saleMintedNum = saleMintedNum.add(nums);
    _soldMap[msg.sender] = _soldMap[msg.sender].add(nums);

    emit SellMint(nums, msg.sender);
  }

  //ownerMint
  function ownerMint(uint nums, address recipient) public onlyOwner {
    require(totalSupply().add(nums) <= MAX_DRAGONS, "not enough hero left.");

    for (uint i = 0; i < nums; i++) {
      uint id = nextIndex();
      if (id < MAX_DRAGONS) {
        _safeMint(recipient, id);
      }
    }
  }

  //Community/Group/AirDrop Mint
  function mintToGroup(uint nums, address groupAddr) public onlyOwner {
    require(groupMintedNum.add(nums) <= MAX_GROUP_MINTS, "Community mint limit reached.");
    require(totalSupply() < MAX_DRAGONS, "DRAGONS sold out.");

    for (uint i = 0; i < nums; i++) {
      uint id = nextIndex();
      if (id < MAX_DRAGONS) {
        _safeMint(groupAddr, id);
        groupMintedNum = groupMintedNum.add(1);
      }
    }
  }

  function nextIndex() internal view returns (uint) {
    return totalSupply();
  }

  function getPrice() public view returns (uint) {
    return tokenPrice;
  }


  function setupWhitelist(address[] calldata candidates_, uint[] calldata values_) onlyOwner public returns (bool) {
    require(candidates_.length == values_.length, "Value lengths do not match.");
    require(candidates_.length > 0, "The length is 0");

    for (uint i = 0; i < candidates_.length; i++) {
      require(candidates_[i] != address(0));
      presaleWhitelist[candidates_[i]] = values_[i];
      _whitelistKeys.add(candidates_[i]);
    }

    return true;
  }

  function addWhitelist(address addr_, uint values_) onlyOwner public returns (bool) {
    require(addr_ != address(0), "Not Contract Address.");
    presaleWhitelist[addr_] = values_;
    _whitelistKeys.add(addr_);
    return true;
  }

  function removeWhitelist(address addr_) onlyOwner public returns (bool) {
    require(addr_ != address(0), "Not Contract Address.");
    delete presaleWhitelist[addr_];
    _whitelistKeys.remove(addr_);
    return true;
  }

  function cleanWhitelist() onlyOwner public returns (bool) {

    uint length = _whitelistKeys.length();
    for (uint i = 0; i < length; i++) {
      // modify fix 0 position while iterating all keys
      address key = _whitelistKeys.at(0);
      delete presaleWhitelist[key];
      _whitelistKeys.remove(key);
    }
    require(_whitelistKeys.length() == 0);

    return true;
  }

  function whitelistLength() public view returns (uint) {
    return _whitelistKeys.length();
  }


  function presale(uint nums) external payable {
    require(preSale, "Sale not started.");
    require(msg.sender != address(0));
    require(nums > 0, "Nums should large then 0.");
    require(nums <= maxBuy, "Reach max sell limit.");
    require(saleMintedNum.add(nums) <= MAX_SALE_MINTS, "Sale mint limit reached.");
    require(totalSupply() < MAX_DRAGONS, "DRAGONS sold out.");

    uint256 hdwNums = balanceOf(msg.sender);
    require(hdwNums.add(nums) <= totalBuy, "Reach max totalBuy limit.");

    uint amount = presaleWhitelist[msg.sender];
    require(amount > 0, "You're not in the presale whitelist");
    require(amount >= nums, "amount must be larger than nums.");

    uint salePrice = getPrice().mul(nums);
    require(msg.value >= salePrice, "not enough funds to purchase.");

    for (uint i = 0; i < nums; i++) {
      uint id = nextIndex();
      if (id < MAX_DRAGONS) {
        _safeMint(msg.sender, id);
      }
    }

    saleMintedNum = saleMintedNum.add(nums);
    presaleWhitelist[msg.sender] = amount.sub(nums);
  }
}