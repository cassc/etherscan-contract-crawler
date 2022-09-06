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


contract RektCollective is ERC721A, EIP712, Ownable{
    using ECDSA for bytes32;
    using Strings for uint256;

    address WHITELIST_SIGNER = 0xE86cc8E0fd53B912Dac2Ad68986Cee3e3A7B8d02;
    address FREE_MINT_SIGNER = 0xCB585beeDb64a84dd22B60A4Fb5b33d6fa9B1274;

    string public baseUri;
    
    uint256 public mintFee = 0.02 ether;
    uint256 public whitelistMintFee = 0.00 ether;
    uint public DegenLimit = 1;

    bool public REKTMode = false;
    uint256 public MAX_SUPPLY = 1111;

    //claimed bitmask
    mapping(uint256 => uint256) private freeMintClaimBitMask;
    mapping(uint256 => uint256) private whitelistClaimBitMask;
    mapping(address => uint) public addressToFreeMinted;
   
    constructor() 
    ERC721A("REKT Collective", "REKT")
    EIP712("REKT", "1.0.0")
    {}

    function mint(bytes calldata _signature, uint256 _nftIndex, uint256 _quantity) external payable {
      require(totalSupply() < MAX_SUPPLY, "Sold out, mfers");
      require(tx.origin == msg.sender, "Caller cannot be a contract.");

        if(!REKTMode){
          claimWhitelist(_signature, _nftIndex, 1);
        } 
        else {
              safeMint(_quantity);
        }
    }


    function safeMint(uint256 _quantity) internal{
      require(msg.value >= mintFee * _quantity, "No liquidity, REKT");
        _mint(msg.sender, _quantity);
    }

    function TeamMint(bytes calldata _signature, uint256 _nftIndex, uint256 _quantity) external payable {
      require(!isClaimed(_nftIndex, false), "NFT: Token already claimed!");
      require(_verify(_hash(msg.sender, _nftIndex, _quantity), _signature, false), "NFT: Invalid Claiming!");
      _setClaimed(_nftIndex, false);
        _mint(msg.sender, _quantity);
    }

    function claimWhitelist(bytes calldata _signature, uint256 _nftIndex, uint256 _quantity) internal{
    require(!isClaimed(_nftIndex, true), "NFT: Token already claimed!");
    require(addressToFreeMinted[msg.sender] < DegenLimit, "You need to get a job.");
    require(_verify(_whitelistHash(msg.sender, _nftIndex), _signature, true), "NFTWL: Invalid Claiming!");
      for (uint i =0 ;i <_quantity ; i++){
        addressToFreeMinted[msg.sender]++;
      }
      _mint(msg.sender, _quantity);
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

    function GodMode(string memory newBaseURI) external onlyOwner {
        baseUri = newBaseURI;
    }

    function RektMode() external onlyOwner {
        REKTMode = !REKTMode;
    }

    function Rug() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}