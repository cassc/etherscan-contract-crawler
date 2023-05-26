//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC721A.sol";


contract CloneXAI is ERC721A, EIP712, Ownable{
    using ECDSA for bytes32;
    using Strings for uint256;

    address WHITELIST_SIGNER = 0x910bBdE1Ed26ccA5858Bcb2358eE4B0411EC61B8;
    address FREE_MINT_SIGNER = 0x48bC580268e23Be79A18DeCFb0716EF803a75946;

    address artist = 0x8803Ee2D34Af29fB8A2ef98106677757177406c9;

    string public baseUri;
    
    uint256 public mintFee = 0.0099 ether;
    uint256 public whitelistMintFee = 0.0099 ether;

    bool public saleIsActive = false;


    uint256 public MAX_SUPPLY = 8000;
    uint256 public FREE_SUPPLY = 900;

    uint256 public MaxPerWallet = 3;



    //claimed bitmask
    mapping(uint256 => uint256) private freeMintClaimBitMask;
    mapping(uint256 => uint256) private whitelistClaimBitMask;

    mapping(address => bool) public addressToFreeMinted;
    mapping(address => uint256) public mintedAmount;


   
    constructor() 
    ERC721A("CloneX AI", "CloneXAI")
    EIP712("CloneX", "1.0.0")
    {}

 modifier mintCompliance() {
      require(saleIsActive, "Sale is not active yet.");
      require(totalSupply() < MAX_SUPPLY, "Sold out");
      require(tx.origin == msg.sender, "Caller cannot be a contract.");
      _;
 }
 
  function TeamMint(bytes calldata _signature, uint256 _nftIndex, uint256 _quantity) external payable  {
      require(!isClaimed(_nftIndex, false), "NFT: Token already claimed!");
      require(_verify(_hash(msg.sender, _nftIndex, _quantity), _signature, false), "Team NFT: Invalid Claiming!");
      _setClaimed(_nftIndex, false);
        _mint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable mintCompliance(){
      require(msg.value >= mintFee * _quantity, "You do not have enough ETH to pay for this");
               
        uint256 _mintedAmount = mintedAmount[msg.sender];
        require(_mintedAmount + _quantity <= MaxPerWallet,"Exceeds max mints per address!"
        );
        _mint(msg.sender, _quantity);
         mintedAmount[msg.sender] = _mintedAmount + _quantity;
    }

    function WhitelistMint(bytes calldata _signature, uint256 _nftIndex, uint256 _quantity) external payable  mintCompliance(){
      require(!isClaimed(_nftIndex, true), "NFT: Token already claimed!");
      require(_verify(_whitelistHash(msg.sender, _nftIndex), _signature, true), "NFT WL: Invalid Claiming!");
      uint256 _mintedAmount = mintedAmount[msg.sender];
      require(_mintedAmount + _quantity <= (MaxPerWallet+1),"Exceeds max mints per address!");
     
      if(addressToFreeMinted[msg.sender]){
        require(msg.value >= mintFee * _quantity, "Already got your free mint");
      }
      else{
        addressToFreeMinted[msg.sender] = true;
        if ( totalSupply() + _quantity > FREE_SUPPLY) {
          require(msg.value >= mintFee * _quantity, "Over Supply");
        }
        else { 
          if ( _quantity > 1 ){
            require(msg.value >= mintFee * (_quantity - 1), "Insufficient Funds");
          }
        }
      }
      _mint(msg.sender, _quantity);
      
       mintedAmount[msg.sender] = _mintedAmount + _quantity;
    }

    function isClaimed(uint256 _nftIndex, bool isWhiteListSale) public view returns (bool) {
      uint256 wordIndex = _nftIndex / 256;
      uint256 bitIndex = _nftIndex % 256;
      uint256 mask = 1 << bitIndex;
      if(isWhiteListSale){
          return whitelistClaimBitMask[wordIndex] & mask == mask;
      }
      else{
        return freeMintClaimBitMask[wordIndex] & mask == mask;
      }
    }

    function _setClaimed(uint256 _nftIndex, bool isWhiteListSale) internal{
       uint256 wordIndex = _nftIndex / 256;
      uint256 bitIndex = _nftIndex % 256;
      uint256 mask = 1 << bitIndex;
      if(isWhiteListSale){
        whitelistClaimBitMask[wordIndex] |= mask;
      }else{
        freeMintClaimBitMask[wordIndex] |= mask;
      }
    }

    function _hash(address _account, uint256 _nftIndex, uint256 _quantity)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address _account,uint256 _nftIndex,uint256 _quantity)"),
            _account,
            _nftIndex,
            _quantity
        )));
    }

    function _whitelistHash(address _account, uint256 _nftIndex)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address _account,uint256 _nftIndex)"),
            _account,
            _nftIndex
        )));
    }

    function _verify(bytes32 digest, bytes memory signature, bool isWhitelist)
    internal view returns (bool)
    {   
        if(isWhitelist)
          return SignatureChecker.isValidSignatureNow(WHITELIST_SIGNER, digest, signature);
        else
          return SignatureChecker.isValidSignatureNow(FREE_MINT_SIGNER, digest, signature);

    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NFT: URI query for nonexistent token");
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : "";
    }

    function setbaseUri(string memory newBaseURI) external onlyOwner {
        baseUri = newBaseURI;
    }


  function withdraw() public payable onlyOwner {

    (bool hs, ) = payable(artist).call{value: address(this).balance * 22 / 100}("");
    require(hs);
    
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

    function ActivateSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
}