// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OmnikitGenesisToken is ERC721Enumerable, Ownable {
  using ECDSA for bytes32;

  uint256 public constant MAX_GENESIS_TOKENS = 300;
  uint256 public constant MINT_PRICE = 0.175 ether;
  uint256 public constant SUCCESSLIST_MINT_PRICE = 0.15 ether;

  string private _metadataBaseURI;
  string private _contractURI;

  bool public successlistSaleActive = false;
  bool public whitelistSaleActive = false;
  bool public publicSaleActive = false;

  address public successlistSigner = 0x000000e004CfD89dD32c31eD3b1F98A9aC8b2eC6;
  address public whitelistSigner = 0x00000000116Ac2B09EBd44b5e34fAB4B8C8828eD;
  
  mapping(address => bool) public addressMinted;

  enum MintType {
    SUCCESSLIST,
    WHITELIST,
    PUBLIC
  }


  constructor(string memory initContractURI, string memory initBaseURI) ERC721("OmnikitGenesisToken", "OMNIKIT") {
    _contractURI = initContractURI;
    _metadataBaseURI = initBaseURI;
  }

  modifier senderIsOrigin() {
    require(msg.sender == tx.origin, "Calling from contract not allowed");
    _;
  }

  function _verifySignature(address addressToHash, bytes memory signature, address expectedSigner) private pure returns(bool) {
    
    bytes32 messageHash = keccak256(abi.encodePacked(addressToHash));
    address actualSigner = messageHash.toEthSignedMessageHash().recover(signature);
    return actualSigner == expectedSigner;
  }

  function _checkAndCompleteMint(MintType phase, bytes memory signature) private {
    require(!addressMinted[msg.sender], "Max 1 mint per wallet");

    uint256 tokenIdToMint = totalSupply() + 1;
    require(tokenIdToMint <= MAX_GENESIS_TOKENS, "Max supply reached");

    if (phase == MintType.SUCCESSLIST) require(_verifySignature(msg.sender, signature, successlistSigner), "Invalid signature");
    else if (phase == MintType.WHITELIST) require(_verifySignature(msg.sender, signature, whitelistSigner), "Invalid signature");

    addressMinted[msg.sender] = true;
    _safeMint(msg.sender, tokenIdToMint);
  }

  function successlistMint(bytes memory signature) public payable senderIsOrigin {
    require(successlistSaleActive, "Successlist sale is not active");
    require(msg.value >= SUCCESSLIST_MINT_PRICE, "Insufficient funds sent to mint");
    _checkAndCompleteMint(MintType.SUCCESSLIST, signature);
  }

  function whitelistMint(bytes memory signature) public payable senderIsOrigin {
    require(whitelistSaleActive, "Whitelist sale is not active");
    require(msg.value >= MINT_PRICE, "Insufficient funds sent to mint");
    _checkAndCompleteMint(MintType.WHITELIST, signature);
  }

  function publicMint() public payable senderIsOrigin {
    require(publicSaleActive, "Public sale is not active");
    require(msg.value >= MINT_PRICE, "Insufficient funds sent to mint");
    _checkAndCompleteMint(MintType.PUBLIC, "");
  }

  function ownerMint(address dest, uint256 qty) public onlyOwner {
    require(qty > 0, "Qty must not be none");
    require(dest != address(0), "Cannot mint to zero address");
    require(totalSupply() + qty <= MAX_GENESIS_TOKENS, "Mint would exceed max supply");
    uint256 firstTokenId = totalSupply() + 1;
    for (uint256 i=0; i < qty; i++) {
      _safeMint(dest, firstTokenId+i);
    }
  }

  function flipSuccesslistSaleActive() external onlyOwner {
    successlistSaleActive = !successlistSaleActive;
  }

  function flipWhitelistSaleActive() external onlyOwner {
    whitelistSaleActive = !whitelistSaleActive;
  }

  function flipPublicsaleActive() external onlyOwner {
    publicSaleActive = !publicSaleActive;
  }
  function setSuccesslistSigner(address signer) external onlyOwner {
    successlistSigner = signer;
  }
  
  function setWhitelistSigner(address signer) external onlyOwner {
    whitelistSigner = signer;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function _baseURI() internal view override returns (string memory) {
		return _metadataBaseURI;
	}

  function setContractURI(string calldata newContractURI) external onlyOwner {
    _contractURI = newContractURI;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    _metadataBaseURI = newBaseURI;
  }

  function withdrawBalance() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

}