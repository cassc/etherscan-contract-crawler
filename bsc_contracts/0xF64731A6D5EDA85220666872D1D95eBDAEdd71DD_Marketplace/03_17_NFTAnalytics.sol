// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17 <8.10.0;

import "./UserInfo.sol";

contract NFTAnalytics{

  struct Sender{
    address _address;
    string _name;
    string _avatar;
  }
  struct NFTTransactions{
    Sender from;
    Sender to;
    uint256 time;
    uint256 price;
  }
  struct Transaction{
    Sender _from;
    Sender _to;
    uint256 _id;
    uint256 _price;
    uint256 _time;
  }

  UserInfo user;
  Transaction[] public transactions;
  mapping(uint256 => bool) public offers;
  mapping(address => uint256[]) public creations;
  mapping(address => uint256[]) public collections;
  mapping(address => uint256[]) public removedCollections;
  mapping(uint256 => NFTTransactions[]) public nftTransactions;

  constructor(address _user){
    user = UserInfo(_user);
  }
  /*==========================================
              NFT Transactions
  ===========================================*/ 
  function setNFTTransactions(uint256 _id, address _from, address _to, uint _price) public{
    NFTTransactions memory nft = NFTTransactions(getSender(_from), getSender(_to), block.timestamp, _price); 
     nftTransactions[_id].push(nft);
  }
  function getNFTTransactions(uint256 _id) public view returns(NFTTransactions[] memory){
     return nftTransactions[_id];
  }
  /*==========================================
               Transactions
  ===========================================*/
  function setTransaction(uint256 _id, address _from, address _to, uint _price) public{
      Transaction memory _transaction = Transaction(getSender(_from), getSender(_to), _id, _price, block.timestamp);
        transactions.push(_transaction);
  }
  function get_transactions() public view returns(Transaction[] memory){
        uint256 length = transactions.length;
        Transaction[] memory _transactions = new Transaction[](length);
        for (uint256 i = 0; i < length; i++) {
        _transactions[i] = transactions[i];
        }
        return _transactions;
  }
  function removeTransaction(uint256 _id) public{
        for (uint256 i = 0; i < transactions.length; i++) {
            if (transactions[i]._id == _id) {
                delete transactions[i];
            }
        }
  }
  /*==========================================
              Record New Action (Method)
  ===========================================*/
  function setActivity(address _address, uint _price, uint _royality, uint _commission, string memory _status) public{
    user.setActivity(_address, _price, _royality, _commission, _status);
   }

/*==========================================
        Check Whitelist Member (Method)
  ===========================================*/
   function member(address _address) public view returns(bool)
   {
    return user.whitelistMember(_address);
   }

/*==========================================
            Add offer to token
  ===========================================*/
   function setOffer(uint id) public
   {
    offers[id] = true;
   }

   function updateOffer(uint id, bool offer) public
   {
    offers[id] = offer;
   }
   /*==========================================
         Block unwanted nft (Method)
  ===========================================*/
   function unwanted(uint id) public
   {
    delete nftTransactions[id];
    removeTransaction(id);
   }

   function newToken(address sender, uint id) public
   {
    creations[sender].push(id);
   }

   function addToken(address sender, uint id) public
   {
    collections[sender].push(id);
   }

   function updateCollect(address _old, address _new, uint256 _id) public 
   {
      removedCollections[_old].push(_id);
      collections[_new].push(_id);
   }

   function getCollect(address _address) public view returns(uint256[] memory, uint256[] memory, uint256[] memory){
      return (creations[_address], collections[_address], removedCollections[_address]);
   }
  
  /*==========================================
         Get user details (Method)
  ===========================================*/
  function getSender(address _address) private view returns(Sender memory){
        return Sender(_address, user.getUser(_address)._fullName, user.getUser(_address)._avatar);
  }

}