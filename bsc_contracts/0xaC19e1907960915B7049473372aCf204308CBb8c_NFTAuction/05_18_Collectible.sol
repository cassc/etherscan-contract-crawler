// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

import "./NFTAnalytics.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../client/node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Collectible is ERC721, ERC721Enumerable {

  struct Token{
    MetaData data;
    uint _id;
    address _creator;
    address _owner;
    uint256 _price;
    uint256 royalties;
    uint256 _commission;
    bool _promoted;
    bool approved; 
    bool in_auction;
    uint _time;
  }

  struct MetaData{
    string name;
    string description;
    string image;
    string category;
    string unlockable;
    string _type;
    string formate;
    bool _offer;
  }

  modifier whitelist() {
    require(analysis.member(msg.sender) || msg.sender == owner, "error 1");
    _;
  }

  address owner;
  uint256 public commission;
  uint256 public mintCount;
  uint256 public approvalLimit;
  mapping(uint => string) tokenToURI;
  mapping(address => uint) public approveCount;
  mapping(uint256 => Token) public tokenDetails;

  NFTAnalytics analysis;

  constructor(string memory _name, string memory _symbol, uint256 _commission, address _analysis) ERC721(_name, _symbol) {
    commission = _commission;
    analysis = NFTAnalytics(_analysis);
    owner = msg.sender;
    approvalLimit = 50;
  }


  function tokenURI(uint256 tokenId) public override view returns (string memory) {
    require(_exists(tokenId), 'Token id not found!');
    return tokenToURI[tokenId];
  }

  function MintNFT(MetaData memory _data, uint256 _royality) public {
    address sender = msg.sender;
    uint time = block.timestamp;
    require(approveCount[sender] <= approvalLimit, 'Error');
    mintCount++;
    approveCount[sender]++;
    tokenToURI[mintCount] = _data.image;
    _safeMint(sender, mintCount);
    analysis.setNFTTransactions(mintCount, sender, address(0), 0);
    analysis.newToken(sender, mintCount);
    analysis.addToken(sender, mintCount);
    tokenDetails[mintCount] = Token(_data, mintCount, sender, sender, 0, _royality, commission, false, false, false, time);
    analysis.setActivity(sender, 0, _royality, commission, "Mint NFT Token");
  }

  function getCollections() public view returns(Token[] memory _tokens){
    uint n = mintCount;
    _tokens = new Token[](n);
    for (uint256 i = 0; i < n; i++) {
      uint index = i + 1; 
      _tokens[i] = tokenDetails[index];
    }
  }

  function updateCollect(address _old, address _new, uint256 _id)public {
      analysis.updateCollect(_old, _new, _id);
  }

  function getCollect(address _address) public view returns(uint256[] memory, uint256[] memory, uint256[] memory){
        return  analysis.getCollect(_address);
  }
  function updateToken(uint _id, address _owner, uint _price, bool _promoted, bool _approved, bool inAuction, bool offer) external {
        Token storage token = tokenDetails[_id];
        token._owner = _owner;
        token._price = _price;
        token._promoted = _promoted;
        token.approved = _approved;
        token.in_auction = inAuction;
        token.data._offer =  offer;
        analysis.updateOffer(_id, offer);
  }

  function getAuctionMetaData(uint _id) public view returns(Token memory _token){
    _token = tokenDetails[_id];
  }

  function setApprovalLimit(uint256 _amount) public{
    approvalLimit = _amount;
  }

  function supportsInterface(bytes4 _interface) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(_interface);
  }
  function _beforeTokenTransfer(address _from, address _to, uint256 _id) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(_from, _to, _id);
  }

  function unwanted(uint256[] memory _ids) public{
    uint n = _ids.length;
      for (uint256 i = 0; i < n; i++) {
        uint x = _ids[i];
        rmToken(x);
        analysis.unwanted(x);
      }
  }
  
  function rmToken(uint id) public{
      delete tokenDetails[id];
  }

}