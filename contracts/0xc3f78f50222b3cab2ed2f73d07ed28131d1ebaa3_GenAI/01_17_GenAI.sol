// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/cryptography/ECDSA.sol";
import "@openzeppelin/[email protected]/drafts/EIP712.sol";

contract GenAI is ERC721, EIP712, Ownable {
    using SafeMath for uint256;
    
    address _signerAddress;
    uint _tokenIdCounter = 10;
    
    uint constant MAX_SUPPLY = 5545;
    uint constant MAX_TO_MINT = 10;
    uint constant PRE_SALE_MAX_TO_MINT = 10;
    
    uint public price = 0.1 ether;
    bool public hasSaleStarted = false;
    bool public hasPreSaleStarted = false;
    
    mapping(address => uint) public _addressToMintedTokens;
    mapping(address => bool) public _addressToMintedFree;
    
    modifier validSignature(bool freeMint, bytes calldata signature) {
        require(_signerAddress == recoverAddress(msg.sender, freeMint, signature), "user cannot mint");
        _;
    }
    
    constructor() ERC721("GEN AI", "GENAI") EIP712("GENAI", "1.0.0") { }
    
    function mint(address receiver) external onlyOwner {
        safeMint(receiver);
    }

    function mint(uint256 quantity) public payable {
        require(hasSaleStarted, "sale has not started yet");
        require(quantity <= MAX_TO_MINT, "invalid quantity");
        require(msg.value >= price.mul(quantity), "ether value must be greater than price");
        require(_tokenIdCounter.add(quantity) <= MAX_SUPPLY, "total supply cannot exceed MAX_SUPPLY");

        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function batchGoldenMint(address[] memory recipients) public onlyOwner {
        require(recipients.length == 10, "recipent list must have 10 addresses");

        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], i);
        }
    }
    
    function batchMint(address[] memory receivers, uint[] memory quantities) external onlyOwner {
        require(receivers.length == quantities.length, "receivers and quantities must be the same length");
        for (uint i = 0; i < receivers.length; i++) {
            for (uint j = 0; j < quantities[i]; j++) {
                safeMint(receivers[i]);
            }
        }
    }
    
    function freePreSaleMint(bytes calldata signature) external validSignature(true, signature) {
        require(hasPreSaleStarted, "pre sale did not started yet");
        require(_addressToMintedTokens[msg.sender] < PRE_SALE_MAX_TO_MINT, "quantity exceeds allowance");
        require(!_addressToMintedFree[msg.sender], "user already minted for free");
        
        _addressToMintedTokens[msg.sender] += 1;
        _addressToMintedFree[msg.sender] = true;
        
        safeMint(msg.sender);
    }
    
    function preSaleMint(uint quantity, bool freeMint, bytes calldata signature) payable external validSignature(freeMint, signature) {
        require(hasPreSaleStarted, "pre sale did not started yet");
        require(msg.value >= price.mul(quantity), "ether value must be greater than price");
        require(quantity.add(quantity) <= MAX_SUPPLY, "total supply cannot exceed MAX_SUPPLY");
        require(_addressToMintedTokens[msg.sender].add(quantity) <= PRE_SALE_MAX_TO_MINT, "quantity exceeds allowance");
        
        _addressToMintedTokens[msg.sender] += quantity;
        
        for (uint256 i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }
    
    function _hash(address account, bool freeMint) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFT(bool freeMint,address account)"),
                        freeMint,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, bool freeMint, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, freeMint), signature);
    }
    
    function burn(uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller must be owner or approved");
        _burn(tokenId);
    }

    function safeMint(address receiver) internal {
        _safeMint(receiver, _tokenIdCounter++);
    }

    function toggleSale() public onlyOwner {
        hasSaleStarted = !hasSaleStarted;
    }

    function togglePreSale() public onlyOwner {
        hasPreSaleStarted = !hasPreSaleStarted;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function withdrawAll() external onlyOwner {
       require(payable(msg.sender).send(address(this).balance));
    }
}