//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract KeepBoredPass is ERC721A, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    string private _baseTokenURI;

    uint256 public _OGPrice = 0.075 ether;
    uint256 public _WLPrice = 0.080 ether;

    uint256 public TOTAL_SUPPLY = 561;
    uint256 public OGSupply = 307;
    uint256 public OGSminted = 0;
    //reserverd supply
    uint256 private ROGSupply = 11;
    uint256 private RSupply = 5;
    
    uint256 public constant MINT_PER_WALLET = 1;
    uint256 public ogclaistatus = 0;
    uint256 public wlminstatus = 0;
    uint claimrsp = 1;

    address private _OgsignerAddress;
    address private _WLsignerAddress;

    mapping(uint256 => uint256) public tokenType;
    mapping(address => uint256) public wogminted;
    mapping(address => uint256) public wwlminted;

    address COMPANY_WALLET = 0x027A3071090d429BD0C95107689328e6bC0D090d;

    //modifiers
    modifier onlyOrigin() {
        require(msg.sender == tx.origin, "Come on!!!");
        _;
    }
    
    constructor() ERC721A("Keep Bored Pass", "KBP") {}

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "no token");
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenType[tokenId].toString(),'.json'));
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function ogClain(bytes calldata signature) external payable onlyOrigin  {
        require(ogclaistatus == 1, "OG not started");
        require(totalSupply() + 1 < TOTAL_SUPPLY - (RSupply + ROGSupply) + 1, "Max exceeded!");
        require(OGSminted + 1 < OGSupply +1, "Sold out");
        require(wogminted[msg.sender] + 1 < MINT_PER_WALLET +1);
        
        require(_OgsignerAddress == verifySignature(signature),"Signer mismatch.");
        require(msg.value == _OGPrice, "Value incorrect");

        OGSminted += 1;
        wogminted[msg.sender] += 1;
        uint256 tokenId = _totalMinted();
        tokenType[tokenId] = 1;
        _safeMint(msg.sender, 1);
    }

    function wlMint(bytes calldata signature) external payable onlyOrigin {
        require(wlminstatus == 1, "mint not started");
        require(totalSupply() + 1 < TOTAL_SUPPLY - (RSupply + ROGSupply) + 1, "Max exceeded!");
        require(wwlminted[msg.sender] + 1 < MINT_PER_WALLET +1);

        require(_WLsignerAddress == verifySignature(signature),"Signer mismatch.");
        require(msg.value == _WLPrice, "Value incorrect");

        wwlminted[msg.sender] += 1;
        uint256 tokenId = _totalMinted();
        tokenType[tokenId] = 2;
        _safeMint(msg.sender, 1);
    }

    function dropnotMinted() external onlyOwner {
         uint256 totalminted = _totalMinted();
         require(totalminted < TOTAL_SUPPLY - (RSupply + ROGSupply),"Max SP!");
         uint256 ogtoMint = OGSupply - OGSminted;
         uint256 toMint = TOTAL_SUPPLY - (ogtoMint + totalminted);

         if(ogtoMint > 0){
         _safeMint(COMPANY_WALLET, ogtoMint);
         }
         if(toMint > 0){
         _safeMint(COMPANY_WALLET, toMint);
         }

         OGSminted += ogtoMint;

         for (uint256 i = 0; i < ogtoMint; ++i) {
            tokenType[totalminted+i] = 1;
        }

         for (uint256 i = 0; i < toMint; ++i) {
            tokenType[totalminted+ogtoMint+i] = 2;
        }
    }

    function claimReserved(address _dev, address _carteiro) external onlyOwner {
        require(claimrsp == 1, "Claimed");
        _safeMint(_dev, 3);
        _safeMint(_carteiro, 13);
        for (uint256 i = 0; i < ROGSupply; ++i) {
            tokenType[i] = 1;
        }
        for (uint256 i = 0; i < RSupply; ++i) {
            tokenType[i + ROGSupply] = 2;
        }
        claimrsp = 2;
    }

    function setSaleStatus(uint256 _ogClainActive, uint256 _wlsaleActive) external onlyOwner {
        ogclaistatus = _ogClainActive;
        wlminstatus = _wlsaleActive;
    }

     function setWlPrice(uint256 _price) external onlyOwner {
        _WLPrice = _price;
    }

    function updatesignerAddress(address signerAddress_, address ogsignerAddress_) external onlyOwner {
        _WLsignerAddress = signerAddress_;
        _OgsignerAddress = ogsignerAddress_;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(COMPANY_WALLET, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "fail.");
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function verifySignature(bytes calldata signature) private view returns (address) {
      bytes32 hash = keccak256(bytes(abi.encodePacked(msg.sender))); 
      bytes32 messageHash = hash.toEthSignedMessageHash();
      address signer = messageHash.recover(signature);
      return signer;
    }

}