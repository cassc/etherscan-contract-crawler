pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../libs/Initializable.sol";
import "../libs/Permission.sol";
import "./IdaMo.sol";
import "./IWishDaMo.sol";


contract MintDamo is Ownable,Initializable,Permission
{
     using Counters for Counters.Counter;
     Counters.Counter private _tokenIdTracker;
     using SafeMath for uint256; 
     using Strings for uint256;
     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IdaMo daMoContract;
    IWishDaMo wishDaMoContract;
   
   //price
    uint256 donateUint = 1*(10**15);
    
    address treasuryAddress;
    uint8 period = 1;
    uint256 total = 128;
    uint256 sq = 0;

    mapping(address => uint8) mintWhilte;
    address[] airdropList;
    mapping(address => uint8) addressMap;

    bool isPublicMint = false;
    bool isPublicSale = false;

    mapping(address => uint8) mintLocks;
    event mintEvt(address indexed,uint256 tokenId);
    event mintCardEvt(address indexed,uint256 tokenId);
    event airdropWishDamoEvt(string);
    event freeMintDamoEvt(address indexed,string);
    constructor(){
        treasuryAddress = 0x19FB6fe8fc5eb606eAfFE75D75ED1f5EaCfb2151;
        initWhilte();
    }
 
    modifier mintLock() {
        require(mintLocks[_msgSender()] == 0, "Locked");
        mintLocks[_msgSender()] == 1;
        _;
        mintLocks[_msgSender()] == 0;
    }

    function init(IdaMo _idaMo,IWishDaMo _iWishDaMo) public onlyOwner {
        daMoContract = _idaMo;
        wishDaMoContract = _iWishDaMo;
        initialized = true;
    }

    function setDonateUint(uint256 uintvalue) public onlyRole(MINTER_ROLE){
        donateUint = uintvalue;
    }

    function getDonateUint() public  returns(uint256){
       return donateUint;
    }

    function settreasuryAddress(address _treasuryAddr) public onlyRole(MINTER_ROLE){
        treasuryAddress = _treasuryAddr;
    }

    function setTotal(uint256 _total) public onlyRole(MINTER_ROLE){
        total = _total;
    }

    function setIsPublicMint(bool _isPublicMint) public onlyRole(MINTER_ROLE) {
        isPublicMint = _isPublicMint;
    }

    function setisPublicSale(bool _isPublicSale) public onlyRole(MINTER_ROLE) {
        isPublicSale = _isPublicSale;
    }

    function getIsPublicSale() public view returns(bool){
        return isPublicSale;
    }

    function getCount(address _addr) public view returns(uint8){
        return mintWhilte[_addr] ;
    }

    function setWhilte(address[] memory addrs,uint8[] memory counts) public onlyRole(MINTER_ROLE){
        require(addrs.length == counts.length,"params error");
        for (uint256 index = 0; index < addrs.length; index++) {
            mintWhilte[addrs[index]] = counts[index];
            if(addressMap[addrs[index]]==0){
                addressMap[addrs[index]]==1;
                airdropList.push(addrs[index]);
            }
        }
    }

    function freeMint() public  needInit mintLock{
        require(isPublicMint==true,"not start");
        require(mintWhilte[msg.sender]>0,"Not qualified");
        string memory tokenIdStr = "";
        uint256 tokenId = 0;
        uint8 number = mintWhilte[msg.sender];
        if(number>0){

            for (uint256 i = 0; i < uint256(number); i++) {
                tokenId = daMoContract.mintNFT(msg.sender,1);
                tokenIdStr = string(abi.encodePacked(tokenIdStr,tokenId.toString(),","));
            }
            mintWhilte[msg.sender] = 0;
            emit freeMintDamoEvt(msg.sender,tokenIdStr);
        }
        sq = sq.add(number);
    }

    /**
    func：free airdropDamo
     */
    function airdropDamo(address[] memory addrs,uint8[] memory counts) public  onlyRole(MINTER_ROLE){
         require(addrs.length == counts.length,"params error");
         
          for (uint256 index = 0; index < addrs.length; index++) {
              uint8 number = counts[index];
              require(number>0,"number errors");
              require(sq.add(number)<=total,"damo number not enough");
              sq = sq.add(number);
              if(number>0){
                    for (uint256 i = 0; i < uint256(number); i++) {
                        daMoContract.mintNFT(addrs[index],1);
                        wishDaMoContract.mintNFT(addrs[index],1,1);
                        wishDaMoContract.mintNFT(addrs[index],1,1);
                    }
              }
          }
    }

    function airdropDamoNoPDN(address[] memory addrs,uint8[] memory counts) public  onlyRole(MINTER_ROLE){
         require(addrs.length == counts.length,"params error");
         
          for (uint256 index = 0; index < addrs.length; index++) {
              uint8 number = counts[index];
              require(number>0,"number errors");
              require(sq.add(number)<=total,"damo number not enough");
              sq = sq.add(number);
              if(number>0){
                    for (uint256 i = 0; i < uint256(number); i++) {
                        daMoContract.mintNFT(addrs[index],1);
                    }
              }
          }
    }

    function airdropWishDamo(address[] memory addrs,uint8[] memory counts,uint8[] memory genes) public  onlyRole(MINTER_ROLE){
         require(addrs.length == counts.length,"params error");
         require(addrs.length == genes.length,"params error");

          string memory tokenIdStr = "";
          uint256 tokenId = 0;
          for (uint256 index = 0; index < addrs.length; index++) {
              uint8 number = counts[index];
            
              if(number>0){
                    for (uint256 i = 0; i < uint256(number); i++) {
                        tokenId = wishDaMoContract.mintNFT(addrs[index],genes[index],1);
                        tokenIdStr = string(abi.encodePacked(tokenIdStr,tokenId.toString(),","));
                    }
              }
          }

          emit airdropWishDamoEvt(tokenIdStr);
    }

    function initWhilte() private{
        //mintWhilte[0x6a9F14b8a95c65b65D4dff7659274Bf77D9f0A96]=2;
    }

     function mint(uint8 number) public  payable needInit mintLock{

        require(isPublicSale==true,"not start");
        require(number>0,"zero");
        //require(mintWhilte[msg.sender]>0,"Not qualified");
       // uint8 number = mintWhilte[msg.sender];
        uint256 totalAMount = uint256(number).mul(donateUint);
        require(msg.value>=totalAMount,"amount not enough");
        require(sq.add(number)<=total,"number not enough");
        if(number>0){

            for (uint256 i = 0; i < uint256(number); i++) {
                daMoContract.mintNFT(msg.sender,1);
            }
            //mintWhilte[msg.sender] = 0;
            sq = sq.add(number);
        }
        
        Address.sendValue(payable(treasuryAddress),totalAMount);
        // payable(treasuryAddress).transfer(donateUint);
        // (bool success, ) = treasuryAddress.call{value: totalAMount}("");
        //require(success, "Address: unable to send value, recipient may have reverted");
    }

}