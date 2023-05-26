// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LongNeckieLadies is ERC721Enumerable, Ownable {
    uint256 private basePrice = 33000000000000000;
    uint256 private reserveAtATime = 25;
    uint256 private reservedCount = 0;
    uint256 private maxReserveCount = 200;
    address private MPAddress = 0xAa0D34B3Ac6420B769DDe4783bB1a95F157ddDF5;
    address private ARAddress = 0xfdA4Be6dc1Be74010B768556CD28C330a6Ad23F9;


    string _baseTokenURI;
    
    uint256 public constant MAX_LONGNECK = 3333;
    bool public active = false;
    uint256 public maximumAllowedTokensPerPurchase = 25;
    
    event AssetMinted(uint256 tokenId, address sender);
    event SaleActivation(bool active);

    // Truth.
    constructor(string memory baseURI) ERC721("Long Neckie Ladies", "LNL") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        require(totalSupply() <= MAX_LONGNECK, "Sale has ended.");
        _;
    }

    function setMaximumAllowedTokens(uint256 _count) public onlyOwner {
        maximumAllowedTokensPerPurchase = _count;
    }

    function setActive(bool val) public onlyOwner {
        active = val;
        emit SaleActivation(val);
    }
    
    function setReserveAtATime(uint256 val) public onlyOwner {
        reserveAtATime = val;
    }

    function setMaxReserve(uint256 val) public onlyOwner {
        maxReserveCount = val;
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        basePrice = _price;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getMaximumAllowedTokens() public view onlyOwner returns (uint256) {
        return maximumAllowedTokensPerPurchase;
    }

    function getPrice() external view returns (uint256) {
        return basePrice; // 0.0420 ETH
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function reserveLongNecks() public onlyOwner {
        require(reservedCount <= maxReserveCount, "LNL: Max Reserves taken already!");
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < reserveAtATime; i++) {
            emit AssetMinted(supply + i, msg.sender);
            _safeMint(msg.sender, supply + i);
            reservedCount++;
        }  
    }

    function mintMyLongNeck(address _to, uint256 _count) public payable saleIsOpen {
        if (msg.sender != owner()) {
            require(active, "Sale is not active currently.");
        }
        
        require(totalSupply() + _count <= MAX_LONGNECK, "Total supply exceeded.");
        require(totalSupply() <= MAX_LONGNECK, "Total supply spent.");
        require(
            _count <= maximumAllowedTokensPerPurchase,
            "Exceeds maximum allowed tokens"
        );
        require(msg.value >= basePrice * _count, "Insuffient amount sent.");

        for (uint256 i = 0; i < _count; i++) {
            emit AssetMinted(totalSupply(), _to);
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

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(MPAddress).transfer(balance/4);
        payable(ARAddress).transfer(balance/4);
        payable(msg.sender).transfer(address(this).balance);
    }
}