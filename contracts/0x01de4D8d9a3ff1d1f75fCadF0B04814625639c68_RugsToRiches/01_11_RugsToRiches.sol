//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC721A.sol";


contract RugsToRiches is ERC721A, EIP712, Ownable{
    
    using ECDSA for bytes32;
    using Strings for uint256;

    bool public active=false;
    bool public publicSale = false;
    bool public revealed = false;

    address WHITELIST_SIGNER = 0xA5DE609e1F1Fea73ecd4a4042A9ed732f388f4D4;
    address OG_MINT_SIGNER = 0xde82149de1110347b7c2B491a7F360E37c7ec991;

    string public baseUri ="ipfs://bafybeib4i2yw6axrb5wmpv77zp4oijfpz34yxghpc2pgvp5kvqlioprz5y/";
    
    uint256 public OGMintFee = 0.055 ether;
    uint256 public whitelistMintFee = 0.0 ether;
    uint256 public publicmintfee = 0.003 ether;


    uint256 public MAX_SUPPLY = 777;

    //claimed bitmask
    mapping(uint256 => uint256) private freeMintClaimBitMask;
    mapping( address => uint256 ) private mintedAmount;

    constructor() 
    ERC721A("RugsToRiches", "R2R")
    EIP712("R2R", "1.0.0"){
        
    }
    


    function whitelistmint(bytes calldata _signature, uint256 _nftIndex, uint256 _quantity) external payable mintCompliance(){
      	uint256 _mintedAmount = mintedAmount[msg.sender];
        require(msg.value >= whitelistMintFee * _quantity, "Invalid ETH");

    	require( !isClaimed(_nftIndex), "Whitelist Spot has been Claimed." );
        require(_verify(_whitelistHash(msg.sender, _nftIndex), _signature, true), "NFT: Invalid Claiming!");
		require(_mintedAmount + _quantity <= 1, "You already minted 1");
          _setClaimed( _nftIndex);		
        _mint( msg.sender, _quantity);
        mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
      
    }



 function publicmint(uint256 _quantity) external payable mintCompliance(){
             require(msg.value >= publicmintfee * _quantity, "Invalid ETH");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= 3,"ONLY 3 PER ADDRESS MAX");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }
    
 function teammint(uint256 _quantity) external onlyOwner mintCompliance (){
                _safeMint(msg.sender, _quantity);
    }

	modifier mintCompliance() {
		require( tx.origin == msg.sender, "CALLER CANNOT BE A CONTRACT" );
		require(active, "SALE IS NOT ACTIVE");
        require( totalSupply() <= MAX_SUPPLY, "SOLD OUT" );
		_;
	}

    function claimWhitelist(bytes calldata _signature, uint256 _nftIndex, uint256 _quantity) internal{
        require(msg.value >= whitelistMintFee * _quantity, "NFT: Not enough Mint Fee!");
        require(_verify(_whitelistHash(msg.sender, _nftIndex), _signature, true), "NFT: Invalid Claiming!");
     
        _safeMint(msg.sender, _quantity);
        
    }

    function isClaimed(uint256 _nftIndex) public view returns (bool) {
        uint256 wordIndex = _nftIndex / 256;
        uint256 bitIndex = _nftIndex % 256;
        uint256 mask = 1 << bitIndex;
        return freeMintClaimBitMask[wordIndex] & mask == mask;
    }

    function _setClaimed(uint256 _nftIndex) internal{
        uint256 wordIndex = _nftIndex / 256;
        uint256 bitIndex = _nftIndex % 256;
        uint256 mask = 1 << bitIndex;
        freeMintClaimBitMask[wordIndex] |= mask;
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
          return SignatureChecker.isValidSignatureNow(OG_MINT_SIGNER, digest, signature);

    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NFT: URI query for nonexistent token");
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : "";
    }

    function Activate() external onlyOwner {
        active = !active;
    }


    function burnSupply() external onlyOwner {
        MAX_SUPPLY = totalSupply();
    }

  function setUri(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function withdraw() external payable onlyOwner {
                (bool os, ) = payable(owner()).call{value: address(this).balance}("");
                require(os);
    }
}