/*

 __          ___     _               _     
 \ \        / (_)   | |             | |    
  \ \  /\  / / _ ___| |__  _   _  __| |___ 
   \ \/  \/ / | |_  / '_ \| | | |/ _` / __|
    \  /\  /  | |/ /| |_) | |_| | (_| \__ \
     \/  \/   |_/___|_.__/ \__,_|\__,_|___/
                                           
                                           
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Wizbuds is ERC721, ERC721Enumerable, Ownable, Pausable {

    using Strings for uint256;

    string public baseURI;       
    uint256 public maxMint;            
    uint256 public currentTokenId;    
    uint256 public pos;
    uint256[] private availableTokens = [2,3,4,5,6,7,10,11,12,13,14,15,16,19,20,21,22,24,25,26,27,28,29,30,31,32,33,34,35,38,39,40,41,42,43,44,45,46,47,48,49,51,52,53,54,55,56,58,59,61,63,64,65,66,67,68,69,70,71,72,73,74,75,77,78,79,80,81,82,83,86,87,88,89,90,91,92,93,94,96,97,98,99,100];
    bool public validateAddress = true;
    bool public isPayable = false;
    uint256 public price;
    uint256[] private mintedTokensList;

    using MerkleProof for bytes32[];    
    bytes32 public merkleRoot;
    
    mapping(address => uint256) public reservedAddressList; 
    mapping(uint256 => address) public reservedTokenList;
    mapping(uint256 => bool) public reservedAuctionTokenList;
    mapping(address => uint256[]) private tokensOfOwnerList;
    mapping(address => bool) public addressUsedList;

    constructor() ERC721("Elder Wizbuds", "ELDER") {
        baseURI = "https://metadata.wizbuds.io/data/";        
        pos = 0;
        maxMint = 90;
       
        reservedAddressList[0x7903076ECB01627d264c04AA3e597E56Fe707E47] = 1;
        reservedAddressList[0xd8CdBB46AA4Ae67b28C48ed08b9E4415483B2fFc] = 9;
        reservedAddressList[0xdEf8372Ff01146fA89fb08ac5bE7d49700f8ABbd] = 36;
        reservedAddressList[0xa63aC1AC70A037CE317D1e928B56c73d5A95a26d] = 37;
        reservedAddressList[0x42a6a325cA28D6acda06af8618b149F4597382F7] = 57;
        reservedAddressList[0x3A16534203998e34A0531EBD2c95C84E81bFDfB7] = 85; 

        reservedTokenList[1] = 0x7903076ECB01627d264c04AA3e597E56Fe707E47;
        reservedTokenList[9] = 0xd8CdBB46AA4Ae67b28C48ed08b9E4415483B2fFc;
        reservedTokenList[36] = 0xdEf8372Ff01146fA89fb08ac5bE7d49700f8ABbd;
        reservedTokenList[37] = 0xa63aC1AC70A037CE317D1e928B56c73d5A95a26d;
        reservedTokenList[57] = 0x42a6a325cA28D6acda06af8618b149F4597382F7;
        reservedTokenList[85] = 0x3A16534203998e34A0531EBD2c95C84E81bFDfB7;

        // Auction
        reservedAuctionTokenList[8] = true;
        reservedAuctionTokenList[17] = true;
        reservedAuctionTokenList[18] = true;
        reservedAuctionTokenList[23] = true;
        reservedAuctionTokenList[50] = true;
        reservedAuctionTokenList[60] = true;
        reservedAuctionTokenList[62] = true;
        reservedAuctionTokenList[76] = true;
        reservedAuctionTokenList[84] = true;
        reservedAuctionTokenList[95] = true;        

    }
      
    function setBaseURI(string memory _baseURI) public onlyOwner{
        require(bytes(_baseURI).length > 0, "empty");
        baseURI = _baseURI;        
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function renounceOwnership() public override virtual onlyOwner { }

    function safeMint(bytes32 leaf, bytes32[] memory proof) public payable whenNotPaused returns(uint256){
        require(totalSupply() < maxMint, "Max mint maximum exceeded");
        require(addressUsedList[msg.sender] == false, "The address already minted");

        require( keccak256(abi.encodePacked(msg.sender)) == leaf, "no equal" );    
        require( proof.verify(merkleRoot, leaf), "You are not in the list" );
        
        if(validateAddress == true && reservedAddressList[msg.sender] > 0){
            currentTokenId = reservedAddressList[msg.sender];            
        }else{
            require(pos < availableTokens.length, "invalid token");            
            currentTokenId = availableTokens[pos];
            require(reservedTokenList[currentTokenId] == address(0),"reserved token");
            require(reservedAuctionTokenList[currentTokenId] == false, "reserved auction token");
            pos++;
        }

        if(isPayable){
            require(msg.value == price, "invalid value");
        }

        tokensOfOwnerList[msg.sender].push(currentTokenId);
        mintedTokensList.push(currentTokenId);
        addressUsedList[msg.sender] = true;

        _safeMint(msg.sender, currentTokenId);

        return currentTokenId;
    }

    function auctionMint(address _to, uint256 _tokenId) public onlyOwner{
        require(totalSupply() < maxMint, "Max mint maximum exceeded");        
        _safeMint(_to, _tokenId);
    }

    function withdraw() public onlyOwner {        
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setMaxMint(uint256 _newMaxMint) public onlyOwner{        
        maxMint = _newMaxMint;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        string memory uri = string(abi.encodePacked(baseURI, _tokenId.toString(),'.json'));
        return uri;
    }   

    function setReservedAddressList(address  _reversedAddress, uint256 _reversedTokensId, uint256[] memory _availableTokens) public onlyOwner{        
        require(_reversedAddress != address(0), "invalid address");
        require(_reversedTokensId > 0, "invalid tokenId");
        require(_availableTokens[0] > 0, "invalid available tokens");
        if(reservedTokenList[_reversedTokensId] != address(0) ){
            reservedAddressList[ reservedTokenList[_reversedTokensId] ] = 0;
        }
        reservedAddressList[_reversedAddress] = _reversedTokensId;
        reservedTokenList[_reversedTokensId] = _reversedAddress;
        availableTokens = _availableTokens;
        pos = 0;
    }

    function setValidateAddress(bool _flag) public onlyOwner{
        validateAddress = _flag;
    }

    function setAvailableTokens(uint256[] memory _availableTokens) public onlyOwner{
        availableTokens = _availableTokens;
        pos = 0;
    }

    function setIsPayable(bool _flag) public onlyOwner{
        isPayable = _flag;
    }

    function setPrice(uint256 _price) public onlyOwner{
        price = _price;
    }

    function getAvailableTokens() public view returns(uint256[] memory){
        return availableTokens;
    }

    function tokensOfOwner(address _address) public view returns(uint256[] memory){        
        return tokensOfOwnerList[_address];
    }
    
    function mintedTokens() public view returns(uint256[] memory){
        return mintedTokensList;
    }   

    function setReservedAuctionTokenList(uint256 _tokenId, uint256[] memory _availableTokens, bool _flag) public onlyOwner{
        reservedAuctionTokenList[_tokenId] = _flag;
        availableTokens = _availableTokens;
        pos = 0;
    }

    function setAddressUsedList(address _address, bool _flag) public onlyOwner{
        addressUsedList[_address] = _flag;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;    
    }
   
}