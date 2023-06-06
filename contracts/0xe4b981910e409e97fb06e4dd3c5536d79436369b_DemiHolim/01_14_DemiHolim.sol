// SPDX-License-Identifier: MIT
/*  

╭━━━╮╱╱╱╱╱╱╭╮╱╭╮╱╱╭╮╱╱╱╱╱╭━━━┳━━━┳━━━┳━━━╮
╰╮╭╮┃╱╱╱╱╱╱┃┃╱┃┃╱╱┃┃╱╱╱╱╱┃╭━╮┃╭━╮┃╭━╮┃╭━╮┃
╱┃┃┃┣━━┳╮╭┳┫╰━╯┣━━┫┃╭┳╮╭╮╰╯╭╯┃┃┃┃┣╯╭╯┣╯╭╯┃
╱┃┃┃┃┃━┫╰╯┣┫╭━╮┃╭╮┃┃┣┫╰╯┃╭━╯╭┫┃┃┃┣━╯╭╋━╯╭╯
╭╯╰╯┃┃━┫┃┃┃┃┃╱┃┃╰╯┃╰┫┃┃┃┃┃┃╰━┫╰━╯┃┃╰━┫┃╰━╮
╰━━━┻━━┻┻┻┻┻╯╱╰┻━━┻━┻┻┻┻╯╰━━━┻━━━┻━━━┻━━━╯

  Demiverse Studio - DemiHumanNFTs 
*/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

abstract contract Demily {
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract DemiHolim is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;
    using SafeMath for uint256;

    Demily private demily;

    string public baseURI;
    string public unrevealURI;

    uint256 public price = 0.08 ether;
    uint256 public pricee = 0.03344 ether;
    uint256 public priceee = 0.01314 ether;

    uint256 public saleStartDate;

    mapping(address => uint8) public allowlist;
    mapping(address => bool) private _blackList;
    
    address private s1 = 0x819A899c0325342CD471A485c1196d182F85860D ;
    address private s2 = 0xce64781985dA23D2007b958B804Ce11A5e1a821D ;

    bool public _isReveal = false;
    bool public _isSaleActive = false;
    bool public _isClaimActive = false;

    modifier onlyShareHolders() {
        require(msg.sender == s1 || msg.sender == s2 );
        _;
    }

    constructor( uint256 maxAmountPerMint, uint256 maxCollection, address demiContract) 
        ERC721A("DemiHolim", "DemiHolim", maxAmountPerMint, maxCollection) 
            {
                demily = Demily(demiContract);
            }

    function withdraw() external onlyShareHolders {
        uint256 _each = address(this).balance / 2;
        require(payable(s1).send(_each), "Send Failed");
        require(payable(s2).send(_each), "Send Failed");
    }

    function setAllowlist(address[] calldata addresses, uint8[] calldata mintAmount) external onlyOwner
    {
        require(addresses.length == mintAmount.length, "addresses does not match numSlots length");
        
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = mintAmount[i];
        }
    }

    function freeClaim(uint8 amount) external nonReentrant callerIsUser{
        require(_isClaimActive, "FreeClaim is not active");
        require(allowlist[msg.sender] >= amount, "not eligible for allowlist");
        require(totalSupply() + amount <= 3294, "reached max supply");
        allowlist[msg.sender] -= amount;
        mintDemiHolim(amount, msg.sender);
    }

    function demipassMint(uint8 amount) external payable nonReentrant callerIsUser {
        require(_isSaleActive, "Sales is not active");
        require(saleStartDate <= block.timestamp);
        require(totalSupply() + amount <= 3294, "reached max supply");
        require(_blackList[msg.sender] == false, "You have already minted"); 
        uint demipass_balance = demily.balanceOf(msg.sender);
        require(demipass_balance > 0, "You must hold at least one DemiPass");
        require(amount <= 3, "You can not mint over 3 at a time");
        require(amount > 0, "At least one should be minted");
        if( demipass_balance < 3) { 
            require( pricee * amount <= msg.value, "Not enough ether sent");
         } else {
            require( priceee * amount <= msg.value, "Not enough ether sent");
         }  
        _blackList[msg.sender] = true;
        mintDemiHolim(amount, msg.sender);
  }
    
    function publicMint(uint8 amount) external payable nonReentrant callerIsUser{
        require(_isSaleActive, "Sales is not active");
        require(saleStartDate <= block.timestamp);
        require(totalSupply() + amount <= 3294, "reached max supply");
        require( amount > 0, "At least one should be minted");
        require( price * amount <= msg.value, "Not enough ether sent");
        mintDemiHolim(amount, msg.sender);
    }

    function devMint(uint8 amount, address to) external nonReentrant onlyOwner{
        require(totalSupply() + amount <= collectionSize, "reached max supply");
        mintDemiHolim(amount, to);
    }
        
    function airdrop(uint256 amount, address to) public onlyOwner {
        require(totalSupply() + amount <= collectionSize, "reached max supply");
        mintDemiHolim(amount, to);
    }
  
    function airdropToMany(address[] memory recipients) external onlyOwner {
        require(totalSupply().add(recipients.length) <= collectionSize, "reached max supply");
        for (uint256 i = 0; i < recipients.length; i++) {
         airdrop(1, recipients[i]);
        }
    }

    function mintDemiHolim(uint256 _amount, address to) private {
        _safeMint(to, _amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        if(!_isReveal) {
            return unrevealURI;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        baseURI = newURI;
    }

    function setUnrevealURI(string calldata newURI) external onlyOwner {
        unrevealURI = newURI;
    }

    function setIsReveal(bool newReveal) external onlyOwner {
        _isReveal = newReveal;
    }

    function setIsSalesActive(bool newSales) external onlyOwner {
        _isSaleActive = newSales;
    }

    function setIsClaimActive(bool newClaim) external onlyOwner {
        _isClaimActive = newClaim;
    }

    function setSaleStartDate(uint256 newDate) public onlyOwner {
        saleStartDate = newDate;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}