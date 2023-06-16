// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract GrapeGrannys is ERC721, Ownable, ReentrancyGuard, PaymentSplitter {
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 public maxSupply = 10000;

  string public baseURI;
  string public baseExtension = '.json';

  bool public paused = false;

  uint256 _price = 25000000000000000; // 0.025 ETH

  Counters.Counter private _tokenIds;

  uint256[] private _teamShares = [80, 20]; // 2 PEOPLE IN THE TEAM
  address[] private _team = [
    0x01d9A5A2B3B026CdE4e76c0f959237A660dCAFe5, // Owner Account gets 80% of the total revenue
    0xAB97A52d9eCC615C673624AD36e00f179d7f7984 // Second Account gets 20% of the total revenue
  ];

  constructor(
    string memory uri
  )
    ERC721('GrapeGrannys', 'GGS')
    PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
    ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
  {
    setBaseURI(uri);
  }

  function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
    baseURI = _tokenBaseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  modifier onlyAccounts() {
    require(msg.sender == tx.origin, 'Not allowed origin');
    _;
  }

  function togglePause() public onlyOwner {
    paused = !paused;
  }

  function publicSaleMint(uint256 _amount) external payable onlyAccounts {
    require(!paused, 'GrapeGrannys: Contract is paused');
    require(_amount > 0, 'GrapeGrannys: zero amount');

    uint current = _tokenIds.current();

    require(
      current + _amount <= maxSupply,
      'GrapeGrannys: Max supply exceeded'
    );
    require(
      _price * _amount <= msg.value,
      'GrapeGrannys: Not enough ethers sent'
    );

    for (uint i = 0; i < _amount; i++) {
      mintInternal();
    }
  }

  function mintInternal() internal nonReentrant {
    _tokenIds.increment();

    uint256 tokenId = _tokenIds.current();
    _safeMint(msg.sender, tokenId);
  }

  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    string memory currentBaseURI = _baseURI();

    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : '';
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function totalSupply() public view returns (uint) {
    return _tokenIds.current();
  }

  // This function allows an account to withdraw its share
  function withdrawFunds() public {
    require(
      _msgSender() == _team[0] || _msgSender() == _team[1],
      "You're not allowed to withdraw funds."
    );

    // Call the release function from the PaymentSplitter contract
    release(payable(_msgSender()));
  }
}