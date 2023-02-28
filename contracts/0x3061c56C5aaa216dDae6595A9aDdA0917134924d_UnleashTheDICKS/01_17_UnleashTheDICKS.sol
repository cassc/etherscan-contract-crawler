// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Arrays.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './../DefaultOperatorFilterer.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import 'erc721a/contracts/ERC721A.sol';

pragma solidity >=0.8.13 <0.9.0;

contract UnleashTheDICKS is ERC721A, Ownable, DefaultOperatorFilterer, ReentrancyGuard {

  using Strings for uint256;

// Variables Start

  string public uri;
  string public uriSuffix = ".json";
  uint public constant NUMBER_RESERVED_TOKENS = 440;
  uint public reservedTokensMinted = 0;
  uint public preSaleSupply = 0;
  uint256 public cost = 0 ether;
  uint256 public supply = 0;
  uint256 public supplyLimit = 690;
  uint256 public maxMintAmountPerTx = 50;
  uint256 public maxLimitPerWallet = 5;
  bool public sale = true;
  bool public onlyWhitelisted = true;
  mapping(address => uint256) public addressMintedBalance;
  mapping (address => bool) userAddr;
  address[] public whitelistedAddresses;
  bool public revealed = false;
  string public notRevealedUri;
// Constructor Start 

  constructor(
  ) ERC721A("D-REX", "DREX")  {}

  mapping(address => bool) public whitelistClaimed;
// ================== Mint Functions Start =======================

    function mint(uint256 _mintAmount) public payable {
    require(sale == true, "Hold your Dick for a bit and wait");
    require(_mintAmount > 0, "You need 1 Dick minimum");
    require(_mintAmount <= maxMintAmountPerTx, "Stop trying to hoard these dicks");
    require(supply + _mintAmount <= supplyLimit, "Max NFT limit exceeded GG");
    require(msg.value >= cost * _mintAmount, "Broke boy transaction");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(_mintAmount + supply >= NUMBER_RESERVED_TOKENS, "mint more than allowed reserved tokens.");
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= maxLimitPerWallet, "max NFT per address exceeded");
        }
        //require(msg.value >= cost * _mintAmount, "insufficient funds");
    }
    
        for (uint256 i = _mintAmount; i <= _mintAmount; i++) {
            //if (onlyWhitelisted == true){reservedTokensMinted++;} i = _mintamount i <= _mintAmount; i++
         addressMintedBalance[msg.sender]++;
         _safeMint(msg.sender, supply + i);
        }
    }
// Set Functions Start
// uri
    function seturi(string memory _uri) public onlyOwner {
        uri = _uri;
    }
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
// sales toggle
    function setSaleStatus(bool _sale) public onlyOwner {
        sale = _sale;
    }
//  Flip Sale State
    function FlipSaleStatus(bool _onlyWhitelisted) public onlyOwner{
        onlyWhitelisted = _onlyWhitelisted;
    }
//  WL users in array
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
// WL check
    function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }
// max per tx
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }
// pax per wallet
    function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
        maxLimitPerWallet = _maxLimitPerWallet;
    }

// supply limit
    function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
        supplyLimit = _supplyLimit;
    }

//  Reveal
    function reveal(bool _revealed) public onlyOwner {
    revealed = _revealed;
    }

//  Withdraw Function Start
    function withdraw() public onlyOwner nonReentrant {
    //owner withdraw
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
//  Operators?

//  Read Functions Start 

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _nextTokenId();
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;    
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    if(revealed == false) {
        return notRevealedUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return uri;
    }
}
//2nd contract done by Alphabet.
//Contract was done in about 48 hours. theres a lot of extra stuff in the contract I know, thanks capt obvious.
//dicks out for harambe may the GOAT R.I.P
//DRAFTLEAGUE4LYFE JAMCTWNCMLEMPS x namespace