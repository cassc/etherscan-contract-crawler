// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721EnumerableB.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AveragePunks is ERC721EnumerableB, Ownable, PaymentSplitter, ReentrancyGuard {
  using Strings for uint;

  enum preSaleClaimStatus { Invalid, Unclaimed, Claimed }

  string private _baseTokenURI = '';
  string private _tokenURISuffix = '';
  string public PROVENANCE;

  uint public constant MAX_SUPPLY = 6667;
  uint public constant PRICE = 0.085 ether;
  uint public preSalePrice = 0.069 ether;
  uint public maxOrder = 3;

  bool public isPreSaleActive = false;
  bool public isActive = false;
  bool public locked = false;

  mapping (address => preSaleClaimStatus) private _preSaleClaims;
  mapping (address => uint) private _preSaleTokens;

  constructor(string memory provenance, address[] memory _payees, uint256[] memory _shares)
    ERC721B("Average Punks", "AVGP")
    PaymentSplitter(_payees, _shares) {
    PROVENANCE = provenance;
    _owners.push(address(0));
  }

  function mint(uint numberOfTokens) external payable nonReentrant() {
    require(isActive, "Sale must be active" );
    require(numberOfTokens <= maxOrder, "Check the max tokens per transaction" );
    require(msg.value >= PRICE * numberOfTokens, "Incorrect eth amount" );

    uint256 supply = totalSupply();
    require(supply + numberOfTokens <= MAX_SUPPLY, "Max supply reached" );

    for(uint i = 0; i < numberOfTokens; ++i) {
      _safeMint(msg.sender, supply++);
    }
  }

  function mintPreSale(uint numberOfTokens) external payable nonReentrant() {
    require(isPreSaleActive, "Pre sale must be active");
    require(_preSaleClaims[msg.sender] != preSaleClaimStatus.Claimed, "Already Claimed");
    require(_preSaleClaims[msg.sender] == preSaleClaimStatus.Unclaimed, "Not on the list");
    require(numberOfTokens <= maxOrder, "Check the max tokens per transaction");
    require(msg.value >= preSalePrice * numberOfTokens, "Incorrect eth amount");
    require(_preSaleTokens[msg.sender] + numberOfTokens <= maxOrder, "Check max presale amount");

     uint256 supply = totalSupply();
     require(supply + numberOfTokens <= MAX_SUPPLY, "Max supply reached" );

    _preSaleTokens[msg.sender] += numberOfTokens;
    if(_preSaleTokens[msg.sender] == maxOrder) {
      _preSaleClaims[msg.sender] = preSaleClaimStatus.Claimed;
    }

    for(uint i = 0; i < numberOfTokens; ++i) {
      _safeMint(msg.sender, supply++);
    }
  }

  function airdrop(uint[] calldata quantity, address[] calldata recipient) external onlyOwner {
    require(quantity.length == recipient.length, "Quantity length is not equal to recipients");

    uint totalQuantity = 0;
    for(uint i = 0; i < quantity.length; ++i) {
      totalQuantity += quantity[i];
    }

    uint256 supply = totalSupply();
    require(supply + totalQuantity <= MAX_SUPPLY, "Max supply reached");

    delete totalQuantity;

    for(uint i = 0; i < recipient.length; ++i) {
      for(uint j = 0; j < quantity[i]; ++j) {
        _safeMint(recipient[i], supply++);
      }
    }
  }

  function togglePublicSale() external onlyOwner {
    isPreSaleActive = false;
    isActive = !isActive;
  }

  function togglePreSale() external onlyOwner {
    isPreSaleActive = !isPreSaleActive;
  }

  function setMaxOrder(uint _maxOrder) external onlyOwner {
    maxOrder = _maxOrder;
  }

  function setPreSalePrice(uint _price) external onlyOwner {
    preSalePrice = _price;
  }

  function setProvenance(string calldata provenance) public onlyOwner {
    require(!locked, "Locked");
    PROVENANCE = provenance;
  }

  function lock() public onlyOwner {
    locked = true;
  }

  function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyOwner {
    _baseTokenURI = _newBaseURI;
    _tokenURISuffix = _newSuffix;
  }

  function addToList(address[] memory members) external onlyOwner {
    for (uint256 i = 0; i < members.length; ++i) {
      _preSaleClaims[members[i]] = preSaleClaimStatus.Unclaimed;
    }
  }

  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(_baseTokenURI).length > 0 ?
      string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix)) :
      'ipfs://QmS82n1AXodv4BEAHhDBC9RKgnW8Gkmnj9ZGykFixtAJsU';
  }
}