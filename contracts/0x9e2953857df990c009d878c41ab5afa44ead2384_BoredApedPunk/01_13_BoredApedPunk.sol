// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoredApedPunk is ERC721Enumerable, Ownable {
    uint256 private basePrice = 10000000000000000;
    uint256 private freeCount = 20;
    uint256 private reserveAtATime = 25;
    uint256 private reservedCount = 0;
    uint256 private maxReserveCount = 75;
    
    string _baseTokenURI;
    
    uint256 public constant MAX_BAPS = 1000;
    bool public active = false;
    uint256 public maximumAllowedTokensPerPurchase = 25;
    
    uint256[] baps;

    // Truth.
    constructor(string memory baseURI) ERC721("Bored Aped Punk", "BAP") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(totalSupply() <= MAX_BAPS, "Sale has ended.");
        _;
    }

    function updateMaximumAllowedTokens(uint256 _count) public onlyOwner {
        maximumAllowedTokensPerPurchase = _count;
    }

    function setActive(bool val) public onlyOwner {
        active = val;
    }
    
    function setReserveCount(uint256 val) public onlyOwner {
        reserveAtATime = val;
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        basePrice = _price;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function reserveBap() public onlyOwner {
        require(reservedCount <= maxReserveCount, "BAPs: Max Reserves taken already!");
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < reserveAtATime; i++) {
            _safeMint(msg.sender, supply + i);
            reservedCount++;
        }   
    }
    
    function getMaximumAllowedTokens() public view onlyOwner returns (uint256) {
        return maximumAllowedTokensPerPurchase;
    }

    function price(uint256 _count) public view returns (uint256) {
        uint256 _id = totalSupply();
        if (_id <= freeCount) {
            return 0;
        }

        return basePrice * _count; // 0.01 ETH
    }


    function mintMyBap(address _to, uint256 _count) public payable saleIsOpen {
        if (msg.sender != owner()) {
            require(active, "Sale is not active currently.");
        }
        
        require(totalSupply() + _count <= MAX_BAPS, "Total supply exceeded.");
        require(totalSupply() <= MAX_BAPS, "Total supply spent.");
        require(
            _count <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(msg.value >= price(_count), "Insuffient amount sent.");

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(_to, totalSupply());
        }
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
}