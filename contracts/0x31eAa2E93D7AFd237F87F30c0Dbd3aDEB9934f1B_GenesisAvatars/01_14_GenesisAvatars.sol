// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GenesisAvatars is ERC721Pausable, Ownable {
    IERC1155 private _isotileFurnitureInstance;
    
    string public avatarsHashSha1 = "3b2aaeee939ebd5b41866075662819dce7bdcd3f";

    bool private _claimingPaused = true;
    uint256 private _mintingId;
    uint256 private _claimingId;
    
    uint256 private _maxClaimingIdIncluded = 4496;
    uint256 private _maxMintingIdIncluded = 8999;
    
    string private _name = "isotile Genesis Avatars";
    string private _symbol = "ISO";

    string private _baseTokenURI;
    uint256 private _price = 0.09 ether;
    
    mapping (address => uint256) private _earlyClaimers;
    
    constructor(string memory baseURI) ERC721(_name, _symbol) {
        setBaseURI(baseURI);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }
    
    function isClaimingPaused() public view returns (bool){
        return _claimingPaused;
    }
    
    function getEarlyClaimerAmount(address user_address) public view returns (uint256){
        return _earlyClaimers[user_address];
    }
    
    function mint(uint256 num) public payable {
        uint256 supply = _maxClaimingIdIncluded + _mintingId + 1;
        require(num < 51, "You can mint max 50 avatars");
        require(num > 0, "You cant mint negative avatars");
        require(supply + num <= _maxMintingIdIncluded + 1, "Exceeds maximum avatars supply");
        require(msg.value == _price * num, "Ether sent is not correct");

        _mintingId += num;
        for(uint256 i; i < num; i++){
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function claim(uint256 megarares_count) public {
        require(!_claimingPaused, "Claiming is paused");
        
        require(megarares_count > 0, "Cant claim 0");
        require(megarares_count < 501, "Cant claim more than 500");
        
        address[] memory addresses = new address[](4);
        addresses[0] = msg.sender;
        addresses[1] = msg.sender;
        addresses[2] = msg.sender;
        addresses[3] = msg.sender;
        
        uint256[] memory ids = new uint256[](4);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        
        uint256[] memory totalBatch = _isotileFurnitureInstance.balanceOfBatch(addresses, ids);
        uint256 totalBalanceIsotileFurnitures = totalBatch[0] + totalBatch[1] + totalBatch[2] + totalBatch[3];
        
        _earlyClaimers[msg.sender] += megarares_count;
        require(totalBalanceIsotileFurnitures >= _earlyClaimers[msg.sender], "You are trying to claim more than you can");
        
        uint256 totalAvatars = megarares_count * 3;
        
        uint256 supply = _claimingId;
        require(supply + totalAvatars <= _maxClaimingIdIncluded + 1, "Exceeds maximum avatars supply");
        
        _claimingId += totalAvatars;
        for(uint256 i; i < totalAvatars; i++){
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function claimForAddress(address user_address, uint256 megarares_count) onlyOwner public {
        require(megarares_count > 0, "Cant claim 0");
        require(megarares_count < 501, "Cant claim more than 500");
        
        _earlyClaimers[user_address] += megarares_count;

        uint256 totalAvatars = megarares_count * 3;
        
        uint256 supply = _claimingId;
        require(supply + totalAvatars <= _maxClaimingIdIncluded + 1, "Exceeds maximum avatars supply");
        
        _claimingId += totalAvatars;
        for(uint256 i; i < totalAvatars; i++){
            _safeMint(user_address, supply + i);
        }
    }
    
    function setIsotileFurnitureInstance(address isotileFurnitureAddress) onlyOwner public {
        _isotileFurnitureInstance = IERC1155(isotileFurnitureAddress);
    }
  
    function setBaseURI(string memory baseURI) onlyOwner public {
        _baseTokenURI = baseURI;
    }
    
    function setPrice(uint256 price) onlyOwner public {
        _price = price;
    }
    
    function setName(string memory name_) onlyOwner public {
        _name = name_;
    }
    
    function setSymbol(string memory symbol_) onlyOwner public {
        _symbol = symbol_;
    }
    
    function pauseClaiming() onlyOwner public {
        _claimingPaused = true;
    }
    
    function unpauseClaiming() onlyOwner public {
        _claimingPaused = false;
    }

    function pause() onlyOwner public {
        _pause();
    }
  
    function unpause() onlyOwner public {
        _unpause();
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}