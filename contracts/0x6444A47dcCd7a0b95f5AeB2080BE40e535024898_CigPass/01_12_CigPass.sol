// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract CigPass is ERC721,Ownable {
    using Counters for Counters.Counter;
    // the whitelist mapping(address,address)
    mapping(address => address) public whiteLists;
    // all the whitelist address
    address[] private whiteListAddressList ;

    address[] private alreadyPurchasedWhiteList ;

    address[] private alreadyExchangeBadge ;
    

    Counters.Counter private _tokenIdCounter;
    // Total amount from pass sales
    uint256 public balanceReceived;
    // the bagage
    uint256[] public badgeExchangePassz;

    uint256 private _totalSupply ;
    uint256 private _airDropTotalSupply;
    uint256 private _whitelistTotalSupply;
    uint256 private _publicMintTotalSupply;
    uint256 private _badgeExchangeTotalSupply;

    uint256 private allowTotalSupply = 1777 ;
    uint256 private allowAirDropTotalSupply ;
    uint256 private allowWhitelistTotalSupply ;
    uint256 private allowPublicMintTotalSupply ;
    uint256 private allowBadgeExchangeTotalSupply ; 

    bool private _whiteListSwithch = true;

    struct Item {
        uint256 id;
        address owner;
    }

    mapping(uint256 => Item) public Items; //id => Item


    constructor() ERC721("CigPass", "CPass") {
        allowAirDropTotalSupply = 77;
        allowWhitelistTotalSupply = 300;
        allowPublicMintTotalSupply = 300 ;
        allowBadgeExchangeTotalSupply = 100; 

    }

    function setAllowAirDropTotalSupply(uint256 value) public  onlyOwner{
        allowAirDropTotalSupply = value;
    }

    function setAllowWhitelistTotalSupply(uint256 value) public  onlyOwner{
        allowWhitelistTotalSupply = value;
    }

    function setAllowPublicMintTotalSupply(uint256 value) public  onlyOwner{
        allowPublicMintTotalSupply = value;
    }


    function setAllowBadgeExchangeTotalSupply(uint256 value) public  onlyOwner{
        allowBadgeExchangeTotalSupply = value;
    }

     function getAllowPublicMintTotalSupply() public  view returns (uint256){
        return allowPublicMintTotalSupply;
    }


    function airDropTotalSupply() public view  returns (uint256) {
        return _airDropTotalSupply;
    }

    function whitelistTotalSupply() public view  returns (uint256) {
        return _whitelistTotalSupply;
    }

    function totalSupply()  public view  returns (uint256) {
        return _totalSupply;
    }

    function publicMintTotalSupply()  public view  returns (uint256) {
        return _publicMintTotalSupply;
    }

    function badgeExchangeTotalSupply()  public view  returns (uint256) {
        return _badgeExchangeTotalSupply;
    }

    function checkAirDropTotalSupply() view internal {
            uint256 will_num = airDropTotalSupply() + 1;
            require(will_num > 0 && will_num <= allowAirDropTotalSupply, "Exceeds airdrop supply");
     }

    function checkWhitelistTotalSupply() view internal {
            uint256 will_num = whitelistTotalSupply() + 1;
            require(will_num > 0 && will_num <= allowWhitelistTotalSupply, "Exceeds whitelist supply");
     } 


    function checkTotalSupply() view internal {
            uint256 will_num = totalSupply() + 1;
            require(will_num > 0 && will_num <= allowTotalSupply, "Exceeds token supply");
     }

    function checkBadgeExchangeTotalSupply() view internal {
            uint256 will_num = badgeExchangeTotalSupply() + 1;
            require(will_num > 0 && will_num <= allowBadgeExchangeTotalSupply, "Exceeds badgeExchangeTotalSupply supply");
     }

    function checkPublicMintTotalSupply() view internal {
        uint256 will_num = publicMintTotalSupply() + 1;
        require(will_num > 0 && will_num <= allowPublicMintTotalSupply, "Exceeds publicMintTotalSupply supply");
    }


/**
    Members on the whitelist can buy the pass at the whitelist price
 */

    function addWhiteList(address[] memory addresses) public onlyOwner {

       for(uint256 i = 0 ; i < addresses.length; i++){
            address to = addresses[i];
            whiteLists[to] = to;
            whiteListAddressList.push(to);
       }
    }

/**
  *   Those on the whitelist can buy the pass at 0.1 eth
 */

    function getWhiteList() public view returns (address[] memory){
       return whiteListAddressList;
    }

/**
 *     The admin can give someone a pass for free
 */
    function mintAirDropBatch(address[] memory addresses) public onlyOwner {
        checkAirDropTotalSupply();
        for(uint256 i = 0 ; i < addresses.length; i++){
            address to = addresses[i];
            _mint(to);    
            _airDropTotalSupply += 1;
        }
        
    }


/**
*  Exchange 100 regular badges for 1 pass or for members with the Professional badge, Honour badge or 50 Contribution badges, they can exchange for 1 pass
 */
    function badgeExchangePass(address to) public onlyOwner returns (uint256){
        checkBadgeExchangeTotalSupply();

        for(uint256 i = 0 ; i < alreadyExchangeBadge.length; i++){
            address addr = alreadyExchangeBadge[i];
            if(addr == to){
                   revert("only 1 pass can be exchanged for an account  ");
            }
        }
        uint256 tokenId = _mint(to);
        _badgeExchangeTotalSupply += 1;
        badgeExchangePassz.push(tokenId);
        alreadyExchangeBadge.push(to);
        return tokenId;

    }

    function setWhiteListSwithch(bool flag)public onlyOwner{
        _whiteListSwithch = flag;
    }

    

    
    /**
    *  Buy the pass with whitelist price of 0.1 eth
    */

    function mintWithWhiteList(address to)
        public
        payable
        returns (uint256)
    {
        if(!_whiteListSwithch){
            revert("Whitelist mode has been disabled ");
        }
        checkWhitelistTotalSupply();
        require(whiteLists[to] != address(0),"the address does not exist in the  whitelist");
       
        for(uint256 i = 0 ; i < alreadyPurchasedWhiteList.length; i++){
            address addr = alreadyPurchasedWhiteList[i];
            if(addr == to){
                   revert("whitelist can buy pass only once ");
            }
        }
        require(msg.value == .1 ether, "Not enough ETH sent: check price.");
        balanceReceived += msg.value;
        uint256 tokenId = _mint(to);
        alreadyPurchasedWhiteList.push(to);
        _whitelistTotalSupply += 1;
        return tokenId;
    }

    /**
        Buy the pass with the public sale price of 0.2 eth
    */

    function mintPublic(address to)
        public
        payable
        returns (uint256)
    {
        checkPublicMintTotalSupply();
        _checkPublicMint(to);
        require(msg.value == .2 ether, "Not enough ETH sent: check price.");
        balanceReceived += msg.value;
        uint256 tokenId = _mint(to);
        _publicMintTotalSupply += 1;
        return tokenId;
    }

    function _checkPublicMint(address to) view internal{
         uint256 token_total = _tokenIdCounter.current();
         uint256 alreadyBuyNum = 0;
         for(uint256 i = 1 ; i <= token_total; i++){
             address current_owner  = Items[i].owner;
             if(current_owner == to){
                alreadyBuyNum = alreadyBuyNum + 1;
             }
         }
         if(alreadyBuyNum >= 2){
             revert("Already Purchased 2 times  ");
         }

    }

    function getNftTotal(address addr)public view returns (uint256){
         uint256 token_total = _tokenIdCounter.current();
         uint256 total = 0;
         for(uint256 i = 1 ; i <= token_total; i++){
             address t_add  = Items[i].owner;
             if(t_add == addr){
                total = total + 1;
             }
         }
         return total;
    }

    function _mint(address to) internal returns (uint256) {
        checkTotalSupply();
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        Items[tokenId] = Item({id: tokenId, owner: to});
        _totalSupply += 1;
        return tokenId;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
    *  The admin can withdraw the balance
    */

    function withdrawMoney() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
    
}