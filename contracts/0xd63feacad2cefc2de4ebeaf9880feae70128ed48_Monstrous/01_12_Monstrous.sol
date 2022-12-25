// SPDX-License-Identifier: MIT

/*
  __  __  ____  _   _  _____ _______ _____   ____  _    _  _____ 
 |  \/  |/ __ \| \ | |/ ____|__   __|  __ \ / __ \| |  | |/ ____|
 | \  / | |  | |  \| | (___    | |  | |__) | |  | | |  | | (___  
 | |\/| | |  | | . ` |\___ \   | |  |  _  /| |  | | |  | |\___ \ 
 | |  | | |__| | |\  |____) |  | |  | | \ \| |__| | |__| |____) |
 |_|  |_|\____/|_| \_|_____/   |_|  |_|  \_\\____/ \____/|_____/ 
                                                                 
*/


pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkelProof.sol";
import "./DefaultOperatorFilterer.sol";
import "./Strings.sol";

contract Monstrous is ERC721A, Ownable, DefaultOperatorFilterer {

  using Strings for uint256;
  string _baseTokenURI;
  bytes32 public merkleRoot;

  string public hiddenURI ="ipfs://QmXYb8Nbsdqzi6pDzYDBPjfAVJCh2pxRHRD4A6RQHrCYhp";

  bool public isActive = false;
  bool public isWhitelistSaleActive = false;
  bool public revealed = false;

  uint256 public mintPrice = 0.0098 ether; //Price after free mint quota
  uint256 public MAX_SUPPLY = 2222;
  uint256 public maximumAllowedTokensPerPurchase = 2;
  uint256 public whitelistWalletLimitation = 2;
  uint256 public publicWalletLimitation = 2;
  uint256 public freeMintTill = 222;
  uint256 public freeMintTracker = 0;

  address private wallet1 = 0xB7e07997Faf79B63Ed4bd9Fc2D8795e23Fb5122F; //dev
  address private wallet2 = 0x289Af5a9CfADe667d0ECa03b807d9b72694669cC; //artist
  address private wallet3 = 0x34598784Ed520c3499499119393d388dc16c9C58; //market penguine
  address private wallet4 = 0xDab7A33b45B90bB0030B2E37D2DE7130a931080A; //market dep
  address private wallet5 = 0x08d93E10290868E3E3bEdB942A06407Bd56680cB; //main wallet
  address private wallet6 = 0xC33424A82f65aa2746504eBf37cdffDC2daf9Ab9; //audit

  mapping(address => uint256) private _whitelistWalletMints;
  mapping(address => uint256) private _publicWalletMints;


  constructor(string memory baseURI) ERC721A("MONSTROUS", "MON") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  // Minting for devs to use in future giveaways and raffles and treasury

  function devMint(uint256 _count, address _address) external onlyOwner {
    uint256 mintIndex = totalSupply();
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");

    _safeMint(_address, _count);
  }

  //mint for whitelisted people

  function whitelistMint(bytes32[] calldata _merkleProof, uint256 _count) public payable isValidMerkleProof(_merkleProof) saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isWhitelistSaleActive, "Whitelist is not active");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require(_count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_whitelistWalletMints[msg.sender] + _count <= whitelistWalletLimitation, "You have already minted max");
    if (freeMintTracker >= freeMintTill || _whitelistWalletMints[msg.sender] >= 1) {
      require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent...");
    } else {
      if(_count > 1) {
        require(msg.value >= (mintPrice * (_count - 1)), "Insufficient ETH amount sent.");
        freeMintTracker = freeMintTracker + 1;
      } else {
        require(_whitelistWalletMints[msg.sender] + _count <= 1, "You have already minted free");
        freeMintTracker = freeMintTracker + 1;
      }
    }

    _whitelistWalletMints[msg.sender] += _count;
    _safeMint(msg.sender, _count);

  }

  //mint for public

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    require(isActive, "Sale is not active currently.");
    require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
    require( _count <= maximumAllowedTokensPerPurchase, "Exceeds maximum allowed tokens");
    require(_publicWalletMints[msg.sender] + _count <= publicWalletLimitation, "You have already minted or minting more than allowed.");
    require(msg.value >= (mintPrice * _count), "Insufficient ETH amount sent.");

    _publicWalletMints[msg.sender] += _count;
    _safeMint(msg.sender, _count);
    
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof) {
      require(
          MerkleProof.verify(
              merkleProof,
              merkleRoot,
              keccak256(abi.encodePacked(msg.sender))
          ),
          "Address does not exist in list"
      );
    _;
  }

  function setMerkleRootHash(bytes32 _rootHash) public onlyOwner {
    merkleRoot = _rootHash;
  }
  
  function setWhitelistSaleWalletLimitation(uint256 _maxMint) external  onlyOwner {
    whitelistWalletLimitation = _maxMint;
  }

  function setPublicSaleWalletLimitation(uint256 _count) external  onlyOwner {
    publicWalletLimitation = _count;
  }

  function setMaximumAllowedTokensPerPurchase(uint256 _count) public onlyOwner {
    maximumAllowedTokensPerPurchase = _count;
  }

  function setFreeMintTill(uint256 _count) public onlyOwner {
    freeMintTill = _count;
  }

  function setMintPrice(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }


  function setMaxMintSupply(uint256 _maxMintSupply) external  onlyOwner {
    MAX_SUPPLY = _maxMintSupply;
  }

  function toggleSaleStatus() public onlyOwner {
    isActive = !isActive;
  }

  function toggleWhiteslistSaleStatus() external onlyOwner {
    isWhitelistSaleActive = !isWhitelistSaleActive;
  }
  
  function reveal() external onlyOwner {
    revealed = !revealed;
  }

  function setHiddenURI(string memory _hiddenURI) public onlyOwner {
    hiddenURI = _hiddenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
		require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
    if (revealed == false) {
      return hiddenURI;
    }
    string memory currentBaseURI = _baseURI();
		return bytes( currentBaseURI ).length > 0 ? string( abi.encodePacked( currentBaseURI, _tokenId.toString(), ".json" ) ) : "";
	}

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      uint256 balance1 = (balance * 200) / 1000;
      uint256 balance2 = (balance * 100) / 1000;
      uint256 balance3 = (balance * 100) / 1000;
      uint256 balance4 = (balance * 100) / 1000;
      uint256 balance5 = (balance * 465) / 1000;
      uint256 balance6 = (balance * 35) / 1000;

      payable(wallet1).transfer(balance1);
      payable(wallet2).transfer(balance2);
      payable(wallet3).transfer(balance3);
      payable(wallet4).transfer(balance4);
      payable(wallet5).transfer(balance5); 
      payable(wallet6).transfer(balance6); 
    }

  // For compliance with opensea

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }
}