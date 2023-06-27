// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Royalties.sol";

contract Superfood is ERC721A, Ownable , Royalties , Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public MAX_MINT = 100;
    uint256 public MAX_MINT_WHILTELIST = 20;
    uint256 public PRICE_PER_NFT = 0.0008 ether;
    uint256 public DISCOUNT_PRICE = 0.00008 ether;
    uint96 public CREATOR_FEE = 900;
    bool public isWhitelist = true;
    mapping (address => bool) public whitelisted;
    mapping (address => uint256) public mintCount;

    constructor() ERC721A("Superfood NFT", "SNFT") {
        whitelisted[_msgSender()] = true;
        _setDefaultRoyalty(_msgSender(), CREATOR_FEE);
        _pause();
    }

    function mintNFT(address to , uint256 quantity) public whenNotPaused payable{
        require(_currentIndex + quantity <= MAX_SUPPLY , "No tokens remaining to mint"); 
        require(quantity != 0 && getPrice(_msgSender()) * quantity == msg.value , "incorrect ethereum supply"); 
        require(getMaxMint(to) >= quantity + mintCount[to] , "cannot mint more NFTs");
             _mint(to , quantity);
             mintCount[to] += quantity;
        payable(owner()).transfer(msg.value);
    }

   

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft-backend.nexgenml.io/api/metadata/";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function tokenByIndex(uint256 index) external view virtual returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, Royalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function airDrop(address[] memory to , uint256[] memory quantity) public onlyOwner {
        require(to.length == quantity.length , "arrays must be equal;"); 
        uint256 total = 0;
        for (uint i = 0; i < quantity.length; i++) {
            total += quantity[i];
        }
        require(_currentIndex + total <= MAX_SUPPLY , "All tokens minted"); 
        for (uint i = 0; i < quantity.length; i++) {
             _mint(to[i] , quantity[i]);
        }     
    }

    function whitelist(address[] memory account , bool _con) external onlyOwner {
        for (uint i = 0; i < account.length; i++) {
            whitelisted[account[i]] = _con;
        } 
    }

    function getMaxMint(address account) public view returns(uint256) {
         uint256 limit = MAX_MINT;
         if(whitelisted[account]){
            limit = MAX_MINT_WHILTELIST;
         }
         return limit;
    }


    function getPrice(address account) public view returns(uint256) {
         uint256 price = PRICE_PER_NFT;
         if(whitelisted[account]){
            price = DISCOUNT_PRICE;
         }
         return price;
    }

    function setIsWhiteList(bool _bool) public onlyOwner {
        require(_bool != isWhitelist,"executed same condition");
        isWhitelist = _bool;
    }

    function set_MAX_MINT(uint256 _amount) external onlyOwner {
        MAX_MINT = _amount;
    }

    function set_MAX_MINT_Whitlist(uint256 _amount) external onlyOwner {
        MAX_MINT_WHILTELIST = _amount;
    }

    function set_PRICE_PER_NFT(uint256 _amount) external onlyOwner {
        PRICE_PER_NFT = _amount;
    }
    function set_DISCOUNT_PRICE(uint256 _amount) external onlyOwner {
        DISCOUNT_PRICE = _amount;
    }
    function set_CREATOR_FEE(uint96 _amount) external onlyOwner {
        CREATOR_FEE = _amount;
    }

    function pause() external virtual whenNotPaused onlyOwner {
       _pause();
    }

    function unpause() external virtual whenPaused onlyOwner {
        _unpause();
    }


}