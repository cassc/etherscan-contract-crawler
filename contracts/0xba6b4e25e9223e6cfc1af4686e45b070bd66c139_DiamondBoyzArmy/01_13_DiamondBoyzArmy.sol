// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2; // use dynamic arrays of strings

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

contract DiamondBoyzArmy is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    address payable public owner;
    uint256 public immutable maxSupply = 10000;
    uint256 public listingPrice = 0.08 ether; // 80000000000000000 wei;
    uint256 private soldCount = 0;
    bool private startSale = false;
    string baseUrl = "https://diamondboyzarmy.mypinata.cloud/ipfs/QmeDt7VqrLZV2YYNoGfCAht5nob7MR2Q7pyJ5mka8BYAe7/";

    // Mapping for reserved urls
    mapping (string => bool) private _urlReserved;
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;
    
    event Minted(uint256 indexed newItemId, address tokenMinter);
    event SaleMint(address indexed tokenMinter, uint256 numberOfTokens);
    event TokenURIChanged(uint256 tokenId, string newTokenURI);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(owner == _msgSender(), "DBA: caller is not the owner");
        _;
    }

    constructor(address payable _owner) ERC721("Diamond Boyz Army", "DBA") {
        owner = _owner;
    }

    function mintDBA(
        address recipient,
        string[] memory tokenURI,
        uint[] memory tokenIds
    ) public payable {
        uint256 maxDbaPurchase = 20;
        uint256 numberOfTokens = tokenIds.length;
        uint256 totalPrice = listingPrice * numberOfTokens; 
        uint256 originalUserBalance = balanceOf(recipient);

        require(startSale == true, "DBA: Sale is not started yet");
        require(recipient != address(0), "DBA: zero address");
        require(numberOfTokens > 0, "DBA: invalid number of tokens");
        require(tokenURI.length == numberOfTokens,"DBA: not appropriate number of tokens and tokenURIs");
        require(msg.value == totalPrice, "DBA: incorrect Ether value");

        require(
            _tokenIds.current() + numberOfTokens <= maxSupply,
            "DBA: max supply exceeded"
        );

        require(
            balanceOf(recipient) + numberOfTokens <= maxDbaPurchase,
            "DBA: max purchase per user exceeded"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(isURLReserved(tokenURI[i]) == false, "DBA: URL already reserved");
            _urlReserved[tokenURI[i]] = true;
            
            string memory tokenUri = string(abi.encodePacked(baseUrl, tokenURI[i], ".json"));

            _mint(recipient, tokenIds[i]);
            _setTokenURI(tokenIds[i], tokenUri);

            _addTokenToOwnerEnumeration(recipient, tokenIds[i]);
            
            emit Minted(tokenIds[i], msg.sender);
            
            soldCount++;
        }
        
        assert(balanceOf(recipient) == originalUserBalance + numberOfTokens);
        
        payable(owner).transfer(msg.value);

        emit SaleMint(msg.sender, numberOfTokens);
    }

    function reserveDBA(address recipient, string[] memory tokenURI, uint[] memory tokenIds)
        public
        onlyOwner
    {
        uint256 maxDbaReserve = 100; 
        uint256 numberOfTokens = tokenIds.length;
        uint256 originalUserBalance = balanceOf(recipient);

        require(startSale == true, "DBA: Sale is not started yet");
        require(recipient != address(0), "DBA: zero address");
        require(numberOfTokens > 0, "DBA: invalid number of tokens");
        require(tokenURI.length == numberOfTokens,"DBA: not appropriate number of tokens and tokenURIs");

        require(
            _tokenIds.current() + numberOfTokens <= maxSupply,
            "DBA: max supply exceeded"
        );

        require(
            balanceOf(recipient) + numberOfTokens <= maxDbaReserve,
            "DBA: max reserve count exceeded"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(isURLReserved(tokenURI[i]) == false, "DBA: URL already reserved");
            _urlReserved[tokenURI[i]] = true;

            string memory tokenUri = string(abi.encodePacked(baseUrl, tokenURI[i], ".json"));
            
            _mint(recipient, tokenIds[i]);
            _setTokenURI(tokenIds[i], tokenUri);
            
            _addTokenToOwnerEnumeration(recipient, tokenIds[i]);
            
            emit Minted(tokenIds[i], msg.sender);
            
            soldCount++;
        }
        
        assert(balanceOf(recipient) == originalUserBalance + numberOfTokens);

        emit SaleMint(msg.sender, numberOfTokens);
    }

    function isURLReserved(string memory urlString) public view returns (bool) {
        return _urlReserved[urlString];
    }

    function getStartSale() public view onlyOwner returns (bool) {
        return startSale;
    }

    function setStartSale(bool _startSale) public onlyOwner {
        require(startSale == false, "DBA: Start sale run only once");
        startSale = _startSale;
    }

    function _tokenOfOwnerByIndex(address user, uint256 index) private view returns (uint256) {
        require(index <= ERC721.balanceOf(user), "ERC721Enumerable: user index out of bounds");
        return _ownedTokens[user][index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function tokensOfOwner(address user) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(user);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 tokenByIndex = 0;
            uint resultIndex = 0;
            uint256 index;

            for (index = 1; index <= tokenCount; index++) {
                tokenByIndex = _tokenOfOwnerByIndex(user, index);
                result[resultIndex] = tokenByIndex;
                resultIndex++;
            }
            return result;
        }      
    }
    
    function getSoldCount() public view returns (uint256) {
        return soldCount;
    }
    
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }
    
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = payable(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}