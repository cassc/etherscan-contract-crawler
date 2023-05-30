// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./PowerUpMembershipPass1155Merkle.sol";

     
contract PowerUpCharacter is ERC721Enumerable, Ownable {    
    bool public isSaleActive = false;     
    bool public isPresale = true;       
    bool public isPremint = true;
    bool public lockMeta = false;
    string private metadataUri;

    uint public goldPrice;
    uint public platinumPrice;
    uint public blackPrice;
    uint public memberPrice;
    uint public nonMemberPrice;
    uint public maxSupply;

    mapping(address => bool) private _allowList;
    bool private _useAllowList = false;

    // Only allow holders of membership passes to mint    
    PowerUpMembershipPass1155Merkle private membershipPass;

    constructor(
        uint goldPrice_,
        uint platinumPrice_,
        uint blackPrice_,
        uint memberPrice_,        
        uint nonMemberPrice_,        
        uint maxSupply_,
        address membershipPassAddress_,
        string memory metadataUri_        
    ) ERC721("PowerUp", "POW") {  
        membershipPass = PowerUpMembershipPass1155Merkle(membershipPassAddress_);
        goldPrice = goldPrice_;
        platinumPrice = platinumPrice_;
        blackPrice = blackPrice_;
        memberPrice = memberPrice_;
        nonMemberPrice = nonMemberPrice_;
        maxSupply = maxSupply_;
        metadataUri = metadataUri_;
    }

    function mintCost(uint numCharacters) public view returns (uint) {
        uint passType = membershipPass.passType(msg.sender);        
        if (isPresale) {    
            if (passType == 0) {
                return blackPrice*numCharacters;
            } else if (passType == 1) {
                return platinumPrice*numCharacters;
            } else if (passType == 2) {
                if (_useAllowList && !_allowList[msg.sender]) {
                    return numCharacters*goldPrice;     
                } else {
                    return (balanceOf(msg.sender) == 0) ? 
                        (numCharacters-1)*goldPrice : 
                        numCharacters*goldPrice;              
                }
            } else {
                return 1 ether;
            }
        }

        return ((passType > 2) ? nonMemberPrice : memberPrice)*numCharacters;        
    }

    function mintLimit() public view returns (uint) {
        return (isPresale) ?
            4 - balanceOf(msg.sender) :
            10;                
    }

    function mint(uint numCharacters) public payable {   
        require(isSaleActive, "Sale is not active.");                        
        require(msg.sender == tx.origin, "Not user.");
        require(!isPresale || membershipPass.hasPass(msg.sender), "Does not own membership pass");        
        require(msg.value >= mintCost(numCharacters), "Not enough ETH.");
        require(numCharacters <= mintLimit(), "Exceeded mint limit.");
            
        _mintCharacters(numCharacters);
    }

    function _mintCharacters(uint numCharacters) internal {
        require(totalSupply() + numCharacters <= maxSupply, "Not enough supply.");    
        
        for (uint i = 0; i < numCharacters; i++) {                                    
            uint tokenId = totalSupply() + 1;
            if (tokenId <= maxSupply) {
                _safeMint(msg.sender, tokenId);           
            }                        
        } 
    }

    function  _baseURI() internal view override returns (string memory) {
       return metadataUri;
    }
    
    function premint(uint numCharacters) public onlyOwner {
        require(isPremint, "Premint not allowed");
        _mintCharacters(numCharacters);
    } 

    function setMetaDataUri(string memory metadataUri_) public onlyOwner {
        require(!lockMeta, "Metadata is locked");
        metadataUri = metadataUri_;
    }

    function setSaleActive(bool isSaleActive_) public onlyOwner {
        isSaleActive = isSaleActive_;
        isPremint = false;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPresale(bool isPresale_) public onlyOwner {
        isPresale = isPresale_;
    }

    function setPrices(uint gold, uint platinum, uint black, uint member, uint nonmember) public onlyOwner {
        goldPrice = gold;
        platinumPrice = platinum;
        blackPrice = black;
        memberPrice = member;
        nonMemberPrice = nonmember;
    }

    function lockMetaData() public onlyOwner {
        lockMeta = true;
    }

    function setUseAllowList(bool useAllowList_) public onlyOwner {
        _useAllowList = useAllowList_;
    }

    function addToAllowList(address[] calldata addresses) public onlyOwner {
        _useAllowList = true;
        for (uint i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
        }        
    }
}