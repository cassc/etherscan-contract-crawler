//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//@0xSimon_ 

error SaleNotActive();
error NotOwner();
error PassStillActive();
error ArraysDontMatch();
contract ChampsOnlyKaijuz is ERC721A, Ownable{
    //@notice not relying on ERC721A startTimestamp from TokenOwnership since it updates on each transfer as noted in ERC721A Documentation
    mapping(uint => uint) public startTimestamp;

    //@dev if a token + tokenTTL > block.timestamp a token is active
    //else it is expired 
    string public activeURI = "ipfs:/QmbncT9BXvUak15pmpkvZWyJQCEdeZGvwkYsXdHANqLEzF/active.json";
    string public expiredURI = "ipfs://QmbncT9BXvUak15pmpkvZWyJQCEdeZGvwkYsXdHANqLEzF/expired.json";

    //@dev a token expires after 7 days
    uint public tokenTTL = uint(7 days);
    
    IERC20 public RWASTE = IERC20(0x5cd2FAc9702D68dde5a94B1af95962bCFb80fC7d);
    uint public RWASTE_PRICE = 150 ether; //decimals 18

    IERC20 public SCALES = IERC20(0x27192b750fF796514f039512aaf5A3655a095ea0);
    uint public SCALES_PRICE = 600 ether; //decimals 18

    bool public saleActive = true;


    constructor() ERC721A("Champs Only x Kaiju Kingz","COJU"){
          teamMint(msg.sender, 1);
    }

    function teamMint(address to, uint amount) public onlyOwner{
        for(uint i; i<amount; i++){
        startTimestamp[_nextTokenId() + i] = block.timestamp;
        }
        _mint(to,amount);
    }

    /*/////////////////////////////////////////
                      MINTING
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function mintWithRWASTE(uint amount) external {
        if(!saleActive) revert SaleNotActive();
        RWASTE.transferFrom(msg.sender, address(this), RWASTE_PRICE* amount);
        for(uint i; i<amount; i++){
            startTimestamp[_nextTokenId() + i] = block.timestamp;
        }
        _mint(msg.sender,amount);
    }
    function mintWithSCALES(uint amount) external {
        if(!saleActive) revert SaleNotActive();
        SCALES.transferFrom(msg.sender, address(this), SCALES_PRICE  * amount);
        for(uint i; i<amount; i++){
            startTimestamp[_nextTokenId() + i] = block.timestamp;
        }
        _mint(msg.sender,amount);
    }
    function burnSingle(uint tokenId) external onlyOwner{
        _burn(tokenId);
    }

    function burnBatch(uint startTokenId,uint endTokenId) external onlyOwner{
     
            require(!isTokenActive(endTokenId), "Token is still active");
            uint augemenntedEnd = endTokenId + 1;
            for(uint i = startTokenId; i< augemenntedEnd; i++){
                _burn(i);
            }
        
    
    }
    /*/////////////////////////////////////////
                  TOKEN EXPIRATION
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function isTokenActive(uint tokenId) public view returns(bool){
        return startTimestamp[tokenId] + tokenTTL > block.timestamp;
    }

    /*/////////////////////////////////////////
                      SETTERS
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function setTokenTTL(uint newTTL) public onlyOwner {
        tokenTTL = newTTL;
    }
    function setActiveURI(string memory _activeURI) external onlyOwner{
        activeURI = _activeURI;
    }
    function setExpiredURI(string memory _expiredURI) external onlyOwner{
        expiredURI = _expiredURI;
    }
    function setRWASTE(address _rwaste_address) external onlyOwner{
        RWASTE = IERC20(_rwaste_address);
    }
    function setSCALES(address _scales_address) external onlyOwner{
        SCALES = IERC20(_scales_address);
    }
    function setSaleStatus(bool status) external onlyOwner{
        saleActive = status;
    }
    function setRWASTE_PRICE(uint newPrice) external onlyOwner{
        RWASTE_PRICE = newPrice;
    }
    function setSCALES_PRICE(uint newPrice) external onlyOwner{
        SCALES_PRICE = newPrice;
    }
    
    /*////////////////////////////////////////
                    TOKEN FACTORY
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function tokenURI(uint256 tokenId) public view override(ERC721A) 
    returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(isTokenActive(tokenId)){
            return activeURI;
        }
        else{
            return expiredURI;
        }
    }

    /*/////////////////////////////////////////
                      WITHDRAW
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function withdraw() external onlyOwner{
        uint RWASTE_BALANCE = RWASTE.balanceOf(address(this));
        uint SCALE_BALANCE = SCALES.balanceOf(address(this));
        RWASTE.transfer(msg.sender, RWASTE_BALANCE);
        SCALES.transfer(msg.sender, SCALE_BALANCE);
    }
    
}


interface IERC20{
    function transferFrom(address from, address to, uint amount) external;
    function transfer(address to, uint amount) external;
    function balanceOf(address account) external view returns(uint);
}