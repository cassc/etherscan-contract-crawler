// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract RareShoe is ERC721, EIP712, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    address _signerAddress;
    
    uint public constant MAX_SUPPLY = 4444;
    uint public price = 0.08 ether;
    bool public isSalesActive = false;
    bool public isPreSalesActive = false;
    mapping(address => uint) public _addressToMintedFreeTokens;
    
    modifier validSignature(uint freeMints, bytes calldata signature) {
        require(_signerAddress == recoverAddress(msg.sender, freeMints, signature), "user cannot mint");
        _;
    }

    constructor() ERC721("Rare Shoe", "RSHOE") EIP712("RSHOE", "1.0.0") {
        _signerAddress = 0x3115fEF0931aF890bd4E600fd5f19591430663c1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "not enought supply remaining");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }
    
    function freeMint(uint quantity, uint freeMints, bytes calldata signature) external validSignature(freeMints, signature) {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "not enought supply remaining");
        require(_addressToMintedFreeTokens[msg.sender] + quantity <= freeMints, "account allowance exceeded");
        
        _addressToMintedFreeTokens[msg.sender] += quantity;
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }
    
    function mintPreSale(uint quantity, uint freeMints, bytes calldata signature) external payable validSignature(freeMints, signature) {
        require(isPreSalesActive, "pre sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "not enought supply remaining");
        require(msg.value >= price * quantity, "ether sent is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function _hash(address account, uint freeMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 freeMints,address account)"),
                        freeMints,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint freeMints, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, freeMints), signature);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function togglePreSales() external onlyOwner {
        isPreSalesActive = !isPreSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}