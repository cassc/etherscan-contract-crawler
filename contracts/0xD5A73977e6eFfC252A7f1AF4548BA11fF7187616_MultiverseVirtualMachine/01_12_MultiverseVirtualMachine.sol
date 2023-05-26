// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract MultiverseVirtualMachine is 
    ERC721Enumerable 
    {

    using Strings for uint256;
    
    constructor (string memory uribasein,uint maxusertokens,uint mversetokens,uint maxlinkcountin,uint mintprice,bool initpause) ERC721 ("MultiverseVM", "MVM"){
        owner=msg.sender;
        uribase=uribasein;

        tokenCounterMax=maxusertokens;
        mverseCounterMax=mversetokens;
        
        price=mintprice;
        maxlinkcount=maxlinkcountin;

        //mint one initial token
        _safeMint(owner, tokenCounter);
        tokenCounter=tokenCounter+1;

        mintpause=initpause;
    }

    //modifier---------------/

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    modifier tokenShouldExist(uint256 tokenId) {
        require(_exists(tokenId), "Query for nonexistent token");
        _;
    }
    

    //token count---------------/
    uint256 public tokenCounter=0; 
    uint256 public tokenCounterMax;
    //mverse tokens (tokens special use cases & public spaces)
    uint256 public mverseCounterMax; 
    
    //extra metadata
    string[] public tokenExtraMetadata;
    uint256 maxlinkcount;

    //owner edit---------------/

    //price/uribase/owner
    uint256 public price;
    string uribase;
    address owner;
    string mverseuribase;
    bool baselocked=false;
    bool mintpause=true;

    //owner only---------------/

    function transferOwner(address ownerin) public onlyOwner {
        owner=ownerin;
    }

    function lockBaseURI() public onlyOwner {
        baselocked=true;
    }

    function setpause(bool pausein) public onlyOwner {
        mintpause=pausein;
    }

    function createMverseToken(address _to, uint mversetokenid) public onlyOwner {
        require(mversetokenid>=tokenCounterMax&&mversetokenid<tokenCounterMax+mverseCounterMax
                ,"token out of range");
        require(!_exists(mversetokenid), "token exists");
        
        _safeMint(_to, mversetokenid);
    }

    function setBase(string memory uribasein,string memory mverseuribasein) public onlyOwner {
        require(!baselocked, "set base uri is locked");
        uribase=uribasein;
        mverseuribase=mverseuribasein;
    }

    function setPrice(uint mintprice) public onlyOwner {
        price=mintprice;
    }

    function withdraw() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }

    function withdraw(uint amount) public onlyOwner{
        require(amount<=address(this).balance,"amount should be smaller than contract balance");
        payable(owner).transfer(amount);
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
        }else if(tokenId<tokenCounterMax+mverseCounterMax){
            tbase=mverseuribase;
        }
    
        return bytes(tbase).length > 0 ? string(abi.encodePacked(tbase, tokenId.toString())) : "";
    }

    function maxTokens() public view returns (uint256) {
        return tokenCounterMax+mverseCounterMax;
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
        

        for (uint i = 0; i < count; i++) {

            _safeMint(_to, tokenCounter);
            tokenCounter = tokenCounter + 1;
        }

        return tokenCounter-1;
    }
    
    //links between tokens---------------/

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function _GetLinks(uint256 tokenid,address addr,uint256 resultcount) internal view 
        tokenShouldExist(tokenid)
        returns (uint[] memory results) {
       
        uint256 rand = random(string(abi.encodePacked(tokenid, abi.encodePacked(addr))));
        uint count=rand%resultcount;//maximum connected planets

        if(count==0){
            count=1;    
        }

        uint[] memory returnvalues = new uint[](count);
        
        for (uint i = 0; i < count; i++) {
            returnvalues[i]=random(
                string(
                        abi.encodePacked(i,addr,tokenid,rand)
                    )
                )%(tokenCounterMax+mverseCounterMax);
        }

        return returnvalues;
    }

    function GetLinks(uint256 tokenid) public view 
        tokenShouldExist(tokenid)
        returns (uint[] memory results) {
        return _GetLinks(tokenid,address(this),maxlinkcount);
    }

    function GetDynamicLinks(uint256 tokenid) public view 
        tokenShouldExist(tokenid)
        returns (uint[] memory results) {
        return _GetLinks(tokenid,ownerOf(tokenid),2);
    }

    //multi token uri for expansion packs---------------/

    function tokenURIMulti(uint256 tokenId) public view  tokenShouldExist(tokenId) returns (string[] memory extradata) {

        string[] memory urilist=new string[](tokenExtraMetadata.length);        
        for(uint i=0;i<tokenExtraMetadata.length;i++){
            urilist[i]=string(abi.encodePacked(tokenExtraMetadata[i], tokenId.toString()));
        }
        return urilist;
    }
    
}