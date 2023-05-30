// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SkullTroopers is ERC721, ERC721Burnable, EIP712, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address _signerAddress;
    string _baseUri;
    
    mapping (address => uint) public accountToMintedTokens;
    mapping (address => uint) public accountToMintedFreeTokens;

    uint public constant MAX_SUPPLY = 10000;
    
    uint public preSalePrice;
    uint public dutchInitialPrice;
    uint public dutchEndPrice;
    uint public dutchStartTimestamp;
    uint public dutchEndTimestamp;
    uint public saleStartTimestamp;
    
    modifier validSignature(uint maxFreeMints, uint maxMints, bytes calldata signature) {
        require(recoverAddress(msg.sender, maxFreeMints, maxMints, signature) == _signerAddress, "user cannot mint");
        _;
    }

    constructor() ERC721("Skull Troopers", "STroop") EIP712("SKULL", "1.0.0") {
        dutchInitialPrice = 0.666 ether;
        dutchEndPrice = 0.1 ether;
        preSalePrice = 0.2 ether;
        dutchStartTimestamp = 1638212400;
        dutchEndTimestamp = 1638212400;
        saleStartTimestamp = 1638126000;
        _signerAddress = 0x3115fEF0931aF890bd4E600fd5f19591430663c1;
        _baseUri = "ipfs://Qma645qjBBgz5Zz7ySHM13k6FCDfvDeQyK2C9yQDiRaefu/";
    }
    
    function safeMint(address to) internal {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    function currentPrice() public view returns (uint) {
        if (block.timestamp < dutchStartTimestamp) return dutchInitialPrice;
        else if(block.timestamp > dutchEndTimestamp) return dutchEndPrice;
        
        uint totalDutchPeriod = dutchEndTimestamp - dutchStartTimestamp;
        uint priceDecrementByTime = (dutchInitialPrice - dutchEndPrice) / totalDutchPeriod;
        
        return dutchInitialPrice - (block.timestamp - dutchStartTimestamp) * priceDecrementByTime;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function mint(uint quantity, address receiver) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "quantity exceeds max supply");

        for (uint i = 0; i < quantity; i++) {
            safeMint(receiver);
        }
    }
    
    function mint(uint quantity) external payable {
        require(block.timestamp >= dutchStartTimestamp && block.timestamp <= dutchEndTimestamp + 5 minutes, "mint is not active");
        require(msg.value >= quantity * currentPrice(), "not enough ethers");
        require(totalSupply() + quantity <= MAX_SUPPLY, "quantity exceeds max supply");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }
    
    function freeMint(uint maxFreeMints, uint maxMints, uint quantity, bytes calldata signature) 
        external validSignature(maxFreeMints, maxMints, signature) {
        require(isSalesActive(), "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "quantity exceeds max supply");
        require(quantity + accountToMintedFreeTokens[msg.sender] <= maxFreeMints, "quantity exceeds allowance");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
        
        accountToMintedFreeTokens[msg.sender] += quantity;
    }
    
    function preSaleMint(uint maxFreeMints, uint maxMints, uint quantity, bytes calldata signature) 
        external payable validSignature(maxFreeMints, maxMints, signature) {
        require(isSalesActive(), "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "quantity exceeds max supply");
        require(quantity + accountToMintedTokens[msg.sender] <= maxMints, "quantity exceeds allowance");
        require(msg.value >= quantity * preSalePrice, "not enough ethers");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
        
        accountToMintedTokens[msg.sender] += quantity;
    }
    
    function _hash(address account, uint maxFreeMints, uint maxMints) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(uint256 maxMints,uint256 maxFreeMints,address account)"),
                        maxMints,
                        maxFreeMints,
                        account
                    )
                )
            );
    }

    function isSalesActive() public view returns (bool) {
        return block.timestamp >= saleStartTimestamp;
    }

    function recoverAddress(address account, uint maxFreeMints, uint maxMints, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, maxFreeMints, maxMints), signature);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }
    
    function setPrices(uint preSalePrice_, uint dutchInitialPrice_, uint dutchEndPrice_) external onlyOwner {
        preSalePrice = preSalePrice_;
        dutchInitialPrice = dutchInitialPrice_;
        dutchEndPrice = dutchEndPrice_;
    }
    
    function setDates(uint saleStartTimestamp_, uint dutchStartTimestamp_, uint dutchEndTimestamp_) external onlyOwner {
        saleStartTimestamp = saleStartTimestamp_;
        dutchStartTimestamp = dutchStartTimestamp_;
        dutchEndTimestamp = dutchEndTimestamp_;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}