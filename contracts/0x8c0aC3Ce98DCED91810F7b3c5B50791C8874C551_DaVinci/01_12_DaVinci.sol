// SPDX-License-Identifier: MIT

//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░╔═══╦═══╦╗░░╔╦══╦═╗░╔╦═══╦══╗░░░░░░
//░░░█░╚╗╔╗║╔═╗║╚╗╔╝╠╣╠╣║╚╗║║╔═╗╠╣╠╝░░░░░░
//░░░░░░║║║║║░║╠╗║║╔╝║║║╔╗╚╝║║░╚╝║║░░░░░░░
//░░░░░░║║║║╚═╝║║╚╝║░║║║║╚╗║║║░╔╗║║░░░░░░░
//░░░░░╔╝╚╝║╔═╗║╚╗╔╝╔╣╠╣║░║║║╚═╝╠╣╠╗░░░░░░
//░░░░░╚═══╩╝░╚╝░╚╝░╚══╩╝░╚═╩═══╩══╝░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DaVinci is ERC721, Ownable {
  // Max Total Supply
  uint256 public constant MAX_SUPPLY = 1333;
  // Purchase price
  uint256 public constant SALE_PRICE = 0.07 ether; // 0.07 ether
  //Token counter
  uint256 public tokenCounter;
  // Max mintable
  uint256 public maxMintable = 15;

  bool public preSaleActive;
  bool public saleActive;
  bool public locked;

  // Alien Genesys Tokens
  address public agAddress = 0xc7DcAeb8270b049CAa75afdD879d8eAC28406C36;
  address private _signer;
  string private _baseURIExtended;

  mapping(uint256 => bool) public usedAGTokens;
  mapping(uint256 => bool) public usedNonces;
  mapping(string => bool) private usedReq;

  
  mapping(uint256 => string) public tokenIdToReq;
  mapping(address => uint ) public walletMint;

  uint256 private remainingGiveAway = 50;

  // External functions
  constructor(
    string memory __uri,
    address __signer
  ) ERC721("DaVinci By AML", "DVNCI") {
    _baseURIExtended = __uri;
    _signer = __signer;
  }

function claim(
    string memory _reqId,
    uint256 _nonce,
    bytes calldata signature
  ) external returns (uint256 newId) {
    newId = tokenCounter+1;
    require(!usedNonces[_nonce], "Signature expired");
    require(newId <= MAX_SUPPLY, "Mint finished");
    verifySignature(_nonce, _reqId, signature);
    tokenIdToReq[newId] = _reqId;
    remainingGiveAway--;
    usedNonces[_nonce] = true;
    _safeMint(msg.sender, newId);
    tokenCounter = newId;
  }

function agMinter(
    uint256 _tokenId,
    string memory _reqId,
    bytes calldata signature
  ) external returns(uint256 newId) {
    newId = tokenCounter+1;
    IERC721 ag = IERC721(agAddress);
    require(ag.ownerOf(_tokenId) == msg.sender, "Invalid owner");
    require(!usedAGTokens[_tokenId], "Only 1 mint per AG token");
    require(preSaleActive || saleActive, "Sale must be active");
    require(newId <= MAX_SUPPLY, "Mint finished");
    verifySignature( _reqId,0, signature);
    usedAGTokens[_tokenId] = true;
    tokenIdToReq[newId] = _reqId;
    _safeMint(msg.sender, newId);
    tokenCounter = newId;
  }

function preSaleMint(
    string memory _reqId,
    uint256 _nonce,
    bytes calldata signature
  ) external payable returns (uint256 newId) {
    newId = tokenCounter + 1;
    require(preSaleActive, "Sale must be active");
    require(!usedNonces[_nonce], "Signature expired");
    require(newId <= MAX_SUPPLY, "Mint finished");
    require(msg.value >= SALE_PRICE, "Incorrect value send");
    verifySignature( _reqId, _nonce, signature);
    tokenIdToReq[newId] = _reqId;
    _safeMint(msg.sender, newId);
    tokenCounter = newId;
    usedNonces[_nonce]=true;
    walletMint[msg.sender]++;
  }

  function publicMint(
    string memory _reqId,
    bytes calldata signature
  ) external payable returns (uint256 newId) {
    newId = tokenCounter + 1;
    require(saleActive, "Sale must be active");
    require(newId <= MAX_SUPPLY, "Mint finished");
    require(msg.value >= SALE_PRICE, "Incorrect value send");
    require(walletMint[msg.sender] < maxMintable, "Wallet limit reached");
    verifySignature(_reqId, 0, signature);
    tokenIdToReq[newId] = _reqId;
    _safeMint(msg.sender, newId);
    tokenCounter = newId;
    walletMint[msg.sender]++;
  }

//Verification for signature
  function verifySignature(
    string memory _reqId,
    uint256 _nonce,
    bytes calldata sig
  ) internal {
    if(_nonce != 0){
        bytes32 _msg = keccak256(
            abi.encodePacked(msg.sender,_reqId, _nonce));
        require(ECDSA.recover(_msg, sig) == _signer, "Invalid Signature");
    }
    else{
        bytes32 _msg = keccak256(
            abi.encodePacked(msg.sender,_reqId));
        require(ECDSA.recover(_msg, sig) == _signer, "Invalid Signature");
    }
    require(!usedReq[_reqId], "Used Signature");
    usedReq[_reqId]=true;
  }

  function verifySignature(
    uint256 _nonce,
    string memory _reqId,
    bytes calldata sig
  ) internal {
        bytes32 hash = keccak256(
      abi.encodePacked(_nonce, _reqId, msg.sender)
    );
    require(ECDSA.recover(hash, sig) == _signer, "Invalid Signature");
    require(!usedReq[_reqId], "Used Signature");
    usedReq[_reqId] = true;
  }

  // Control Functions
  function closeNonce(uint256 _nonce) external onlyOwner {
    usedNonces[_nonce] = true;
  }

  function toggleSale() external onlyOwner {
    saleActive = !saleActive;
  }

  function togglePreSale() external onlyOwner {
    preSaleActive = !preSaleActive;
  }

  function setSigner(address __signer) external onlyOwner {
    _signer = __signer;
  }

  function setBaseURI(string memory __baseURI) external onlyOwner {
    require(!locked, "locked...");
    _baseURIExtended = __baseURI;
  }

  function withdrawAll(address payable receiver) external onlyOwner {
    uint256 balance = address(this).balance;
    receiver.transfer(balance);
  }

  // And for the eternity ...
  function lockMetadata() external onlyOwner {
    locked = true;
  }

  //View Functions
  function _baseURI() internal view override returns (string memory) {
    return _baseURIExtended;
  }

  receive() external payable {}
}