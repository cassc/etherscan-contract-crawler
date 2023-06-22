// SPDX-License-Identifier: MIT

/*                                      
   _|      _|  _|_|_|  _|      _|  _|_|_|_|_|  _|_|_|      _|_|_|  
   _|_|  _|_|    _|    _|_|    _|      _|      _|    _|  _|        
   _|  _|  _|    _|    _|  _|  _|      _|      _|_|_|      _|_|    
   _|      _|    _|    _|    _|_|      _|      _|              _|  
   _|      _|  _|_|_|  _|      _|      _|      _|        _|_|_|    
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MINTPS is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    address private constant PS_ADDRESS = 0xf5F8938199e2A041E5f28ff9C361E746EABf3cd3;
    uint256 public constant MAX_SUPPLY = 600;
    uint256 public constant PRESALE_ALLOC = 500;
    uint256 public constant GIFT_ALLOC = 100;
    uint256 public constant PRICE = 0.24 ether;
    uint256 public constant PER_MINT = 3;
    uint256 public constant PER_PRESALE = 3;
    
    mapping(address => uint256) public presalerPurchases;
    mapping(string => bool) private _usedNonces;
    
    string private _tokenBaseURI = "https://mintps.com/api/metadata/";
    address private _signerAddress = 0x688d50CB5f6AbB31622404ec9e581CcB6309dD7b;

    uint256 public publicCounter;
    uint256 public privateCounter;
    uint256 public giftCounter;
    bool public saleLive;
    bool public presaleLive;
    
    constructor() ERC721("MINTPS", "MINTPS") { }
    
    function verifyTransaction(address sender, uint256 amount, string calldata nonce, bytes calldata signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, amount, nonce));
        return _signerAddress == hash.recover(signature);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + receivers.length <= MAX_SUPPLY, "MAX_MINT");
        require(giftCounter + receivers.length <= GIFT_ALLOC, "GIFTS_EMPTY");
        
        giftCounter += receivers.length;
        
        for (uint256 i = 1; i <= receivers.length; i++) {
            _safeMint(receivers[i - 1], supply + i);
        }
    }
    
    function purchase(uint256 amount, string calldata nonce, bytes calldata signature) external payable {
        require(saleLive && !presaleLive, "SALE_CLOSED");
        require(verifyTransaction(msg.sender, amount, nonce, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(totalSupply() + amount - giftCounter <= MAX_SUPPLY - GIFT_ALLOC, "OUT_OF_STOCK");
        require(amount <= PER_MINT, "EXCEED_PER_MINT");
        require(PRICE * amount <= msg.value, "INSUFFICIENT_ETH");
        
        _usedNonces[nonce] = true;
        uint256 supply = totalSupply();
        publicCounter += amount;
        
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function purchasePresale(uint256 amount, string calldata nonce, bytes calldata signature) external payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require(verifyTransaction(msg.sender, amount, nonce, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(privateCounter + amount <= PRESALE_ALLOC, "EXCEED_PRIVATE");
        require(totalSupply() + amount - giftCounter <= MAX_SUPPLY - GIFT_ALLOC, "OUT_OF_STOCK");
        require(presalerPurchases[msg.sender] + amount <= PER_PRESALE, "EXCEED_ALLOC");
        require(amount <= PER_MINT, "EXCEED_PER_MINT");
        require(PRICE * amount <= msg.value, "INSUFFICIENT_ETH");
        
        _usedNonces[nonce] = true;
        uint256 supply = totalSupply();
        privateCounter += amount;
        presalerPurchases[msg.sender] += amount;
        
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function totalSupply() public view returns (uint256) {
        return publicCounter + privateCounter + giftCounter;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    function withdraw() external onlyOwner {
        payable(PS_ADDRESS).transfer(address(this).balance);
    }
    
    function toggleSale() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function togglePresale() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}