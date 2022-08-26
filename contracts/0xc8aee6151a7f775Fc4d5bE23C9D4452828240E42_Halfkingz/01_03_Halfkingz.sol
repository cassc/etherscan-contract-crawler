// SPDX-License-Identifier: MIT

/*///////////////////////////////////////////////////////////////////////////////
  _   _      _       _       _____   _  __                _   _     ____   _____  
 |'| |'| U  /"\  u  |"|     |" ___| |"|/ /       ___     | \ |"| U /"___|u|"_  /u 
/| |_| |\ \/ _ \/ U | | u  U| |_  u | ' /       |_"_|   <|  \| |>\| |  _ /U / //  
U|  _  |u / ___ \  \| |/__ \|  _|/U/| . \\u      | |    U| |\  |u | |_| | \/ /_   
 |_| |_| /_/   \_\  |_____| |_|     |_|\_\     U/| |\u   |_| \_|   \____| /____|  
 //   \\  \\    >>  //  \\  )(\\,-,-,>> \\,-.-,_|___|_,-.||   \\,-._)(|_  _//<<,- 
(_") ("_)(__)  (__)(_")("_)(__)(_/ \.)   (_/ \_)-' '-(_/ (_")  (_/(__)__)(__) (_/ 

*////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";

contract Halfkingz is ERC721A {

    address owner;
    uint256 supply;

    mapping(uint => bool) custom;
    mapping(uint => uint) URIindex;
    mapping(uint => string) public baseURIs;
    uint256 public newest = 0;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function renounceOwnership() public onlyOwner{
        owner = address(0);
    }

    function mint() external payable {
        require(totalSupply() + 1 <= supply, 'MINTED OUT!');

        _safeMint(msg.sender, 1);  

    }
    constructor()  ERC721A("Halfkingz","HALF"){
        baseURIs[0] = "ipfs://QmXuaVd8jqpK6KfRo4fPapE3vHJZK1Ls1wjwUcyS4QsMix/";
        supply= 10001;
        owner = msg.sender;
        _safeMint(msg.sender,1);
    }


    function mintedout() public view returns (bool){
        if(totalSupply() >= supply){
            return true;
        }else{
            return false;
        }
    }

    // function _baseURI(uint256 tokenID) internal view returns (string memory) {
    function _baseURI(uint256 tokenID) public view returns (string memory) {

        if(custom[tokenID] == true){
            return baseURIs[URIindex[tokenID]];

        } else {
            return baseURIs[newest];

        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if(newest == 0){
            return bytes(baseURIs[0]).length != 0 ? string(abi.encodePacked(baseURIs[0], "hidden.json")) : '';
        }
        else {
            string memory baseURI = _baseURI(tokenId);
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';

        }

    }

    function customURIindex (uint256 tokenID, uint256 index) public {
        require( ownerOf(tokenID) == msg.sender, "you don't own this token");
        require((keccak256(abi.encodePacked(baseURIs[index])) != keccak256(abi.encodePacked(""))));
        URIindex[tokenID] = index;
        custom[tokenID] = true;
    }

    function trackNewestURI(uint256 tokenID) public {
        require( ownerOf(tokenID)== msg.sender, "you don't own this token");
        require(custom[tokenID] == true);
        custom[tokenID] = false;
    }
    
    function addBaseURI (string memory URI, uint index) public onlyOwner {
        require((keccak256(abi.encodePacked(baseURIs[index])) == keccak256(abi.encodePacked(""))));
        baseURIs[index] = URI;
        newest = index;

    }

    function sacrifice(uint256 tokenId) public returns(string memory) {
        _burn(tokenId, true);
        return "sacrificed";
    }

    function contractURI() public view returns(string memory){
        return string(abi.encodePacked(baseURIs[newest],"contractURI.json"));
    }


}