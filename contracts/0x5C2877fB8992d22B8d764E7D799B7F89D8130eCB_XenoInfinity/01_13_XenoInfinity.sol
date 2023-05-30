// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XenoInfinity is 
    ERC721Enumerable, Ownable
    {

    using Strings for uint256;
    
    constructor (string memory uribasein,
    uint maxusertokens,
    uint Xtokens,
    uint mintprice,
    bool initpause) ERC721 ("XenoInfinity", "XENO"){
        
        uribase=uribasein;

        tokenCounterMax=maxusertokens;
        XCounterMax=Xtokens;
        
        price=mintprice;

        //mint one initial token to initial sender
        _safeMint(_msgSender(), tokenCounter);
        tokenCounter=tokenCounter+1;

        mintpause=initpause;
    }

    //modifier---------------/

    modifier tokenShouldExist(uint256 tokenId) {
        require(_exists(tokenId), "Query for nonexistent token");
        _;
    }
    

    //token count---------------/
    uint256 public tokenCounter=0; 
    uint256 public tokenCounterMax;
    //X tokens (tokens special use cases)
    uint256 public XCounterMax; 
    
    //extra metadata
    string[] public tokenExtraMetadata;

    //owner edit---------------/

    //price/uribase/owner
    uint256 public price;
    string uribase;
    string Xuribase;
    bool baselocked=false;
    bool public mintpause=true;

    //owner only---------------/


    function lockBaseURI() public onlyOwner {
        baselocked=true;
    }

    function setpause(bool pausein) public onlyOwner {
        mintpause=pausein;
    }

    function createXToken(address _to, uint Xtokenid) public onlyOwner {
        require(Xtokenid>=tokenCounterMax&&Xtokenid<tokenCounterMax+XCounterMax
                ,"token out of range");
        require(!_exists(Xtokenid), "token exists");
        
        _safeMint(_to, Xtokenid);
    }

    function setBase(string memory uribasein,string memory Xuribasein) public onlyOwner {
        require(!baselocked, "set base uri is locked");
        uribase=uribasein;
        Xuribase=Xuribasein;
    }

    function setPrice(uint mintprice) public onlyOwner {
        price=mintprice;
    }

    function withdraw() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    function withdraw(uint amount) public onlyOwner{
        require(amount<=address(this).balance,"amount should be smaller than contract balance");
        payable(owner()).transfer(amount);
    }

    function AddMultiURI(string memory uribasein) public onlyOwner {
        tokenExtraMetadata.push(uribasein);
    }

    //public token uri and max tokens---------------/

    /**
    return a token uri depending on the version
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory tbase="";

        if(tokenId<tokenCounterMax){
            tbase=uribase;
        }else if(tokenId<tokenCounterMax+XCounterMax){
            tbase=Xuribase;
        }
    
        return bytes(tbase).length > 0 ? string(abi.encodePacked(tbase, tokenId.toString())) : "";
    }

    function maxTokens() public view returns (uint256) {
        return tokenCounterMax+XCounterMax;
    }
    
    //purchasing tokens---------------/

    //purchases amount of tokens, and then returns the tokenid 
    function purchase(uint count) public payable returns (uint256 _tokenId) {
        return purchaseTo(msg.sender,count);
    }

    function purchaseTo(address _to, uint count) public payable returns (uint256 _tokenId) {
       
        require(!mintpause,"minting is paused");
        require(tokenCounter<tokenCounterMax,"all tokens minted");
        //verify count;
        require(count>=1&&count<=tokenCounterMax-tokenCounter&&count<=200,"minting too little or too many tokens");

        //verify price        
        require(msg.value >=price*count, "Must send at least current price for token * amount of tokens");
        
        //verify wl if needed
        require(CanWLPurchase(msg.sender), "Must meet wl requirements (own a number of wl nfts)");
        


        for (uint i = 0; i < count; i++) {

            _safeMint(_to, tokenCounter);
            tokenCounter = tokenCounter + 1;
        }

        return tokenCounter-1;
    }

    //multi token uri for expansion packs---------------/

    function tokenURIMulti(uint256 tokenId) public view  tokenShouldExist(tokenId) returns (string[] memory extradata) {

        string[] memory urilist=new string[](tokenExtraMetadata.length);        
        for(uint i=0;i<tokenExtraMetadata.length;i++){
            urilist[i]=string(abi.encodePacked(tokenExtraMetadata[i], tokenId.toString()));
        }
        return urilist;
    }

    


    //wlist ---------------/


    address wlistcontract;
    uint256 public minwlbalance=0;//=0 default all open

    //owner only ---------------/

    function SetWlContract(address wlistcontractin) public onlyOwner {
        wlistcontract = wlistcontractin;
    }

    function SetThreshold(uint256 minimumin) public onlyOwner {
        minwlbalance = minimumin;
    }

    //wl view ---------------/
    
    function WlBalance(address purchaser) public view returns (uint256){
        return IERC721(wlistcontract).balanceOf(purchaser);
    }

    function CanWLPurchase(address purchaser) public view returns (bool){
        if(minwlbalance==0)
        {
            return true;
        }else{
            return WlBalance(purchaser)>=minwlbalance;
        }
    }
    
}