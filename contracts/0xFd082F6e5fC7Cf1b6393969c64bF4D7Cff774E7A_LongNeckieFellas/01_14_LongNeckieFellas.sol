// SPDX-License-Identifier: MIT
// Author: Giovanni Vignone
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract LNL {
  function ownerOf(uint256 tokenId) public virtual view returns (address);

  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract LongNeckieFellas is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private LongNeckieFellasID;

    LNL private lnlConnection;

    bool redeemable;

    uint256 private maxsupply;
    
    bool salelive;

    uint256 private currentprice;

    address private contractdeployer;

    bool private metadatafrozen;

    string private metadataStorage;

    address private LNFVerify;

    mapping(uint256 => string) private _tokenURIs;

    mapping(string => bool) private _isTokenURISet;

    //We may have to potentially implement a mapping(string => uint256 to ensure no multiples)

    uint[3333] private isRedeemed; // 1 = yes, 0 = no

    constructor(address lnlContract, address _verification) ERC721("Long Neckie Fellas", "LNF") {
        maxsupply = 3333;
        contractdeployer = msg.sender;
        lnlConnection = LNL(lnlContract);
        redeemable = true;
        LNFVerify = _verification;
    }

   function checkValidData(string memory ipfsCID, bytes memory sig) public view returns(address){
       bytes32 message = keccak256(abi.encodePacked(maxsupply, ipfsCID));
       return (recoverSigner(message, sig));
   }

   function recoverSigner(bytes32 message, bytes memory sig) public pure returns (address)
     {
       uint8 v;
       bytes32 r;
       bytes32 s;
       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
   }

   function splitSignature(bytes memory sig) public pure returns (uint8, bytes32, bytes32)
     {
       require(sig.length == 65);
       bytes32 r;
       bytes32 s;
       uint8 v;
       assembly {
           r := mload(add(sig, 32))
           s := mload(add(sig, 64))
           v := byte(0, mload(add(sig, 96)))
       }
       return (v, r, s);
   }

    function changeSaleToPublic() public onlyOwner{
        redeemable = !redeemable;
        _changePrice(33000000000000000);
    }
    
    function _changePrice(uint256 updatedprice) public onlyOwner {
        currentprice = updatedprice;
    }

    function _changeVerifyAddress(address newVerification) public onlyOwner{
        LNFVerify = newVerification;
    }

    function changeSaleState() public onlyOwner{
        salelive = !salelive;
    }

    function _withdraw(uint256 amountinwei, bool getall, address payable exportaddress) onlyOwner public returns (bool){
        if(getall == true){
            exportaddress.transfer(address(this).balance);
            return true;
        }
        require(amountinwei<address(this).balance,"Contract is not worth that much yet");
        exportaddress.transfer(amountinwei);
        return true;
    }
    function mintAllLongNeckieFellas(string[] memory allLNF, uint256[] memory tokenURILNLs, bytes[] memory sigs) 
    public payable
    {
        require(salelive);
        require(redeemable);
        require(msg.sender != address(0) && msg.sender != address(this));
        require(allLNF.length == tokenURILNLs.length && allLNF.length == sigs.length, "Incorrect number of arguements passed");
        require(LongNeckieFellasID.current() + allLNF.length <= maxsupply-1, "Your mint would exceed max supply of Long Neckie Fellas");
        for (uint256 i = 0; i< allLNF.length; i++){
            require(!_isTokenURISet[allLNF[i]]);
            require(lnlConnection.ownerOf(tokenURILNLs[i]) == msg.sender);
            require(tokenURILNLs[i]<3333);
            require(isRedeemed[tokenURILNLs[i]] == 0);
            require(LNFVerify == checkValidData(allLNF[i], sigs[i]));
            uint256 uniquetokenID = LongNeckieFellasID.current();
            _safeMint(contractdeployer, uniquetokenID);
            _safeTransfer(contractdeployer, msg.sender, uniquetokenID, "");
            _setTokenURI(uniquetokenID, allLNF[i]);
            _isTokenURISet[allLNF[i]] = true;
            isRedeemed[tokenURILNLs[i]] = 1;
            LongNeckieFellasID.increment();
        }
    }

    function createLongNeckieFella(string memory ipfsCID, uint256 tokenURILNL, bytes memory sig)
        public payable
        returns (uint256)
    {
        require(LNFVerify == checkValidData(ipfsCID, sig));
        require(_isTokenURISet[ipfsCID] == false, "Token already minted");
        require(salelive, "Sale not live yet");
        require(msg.value >= currentprice, "Incorrect payment sent");
        require(LongNeckieFellasID.current() <= maxsupply-1, "Long Neckie Fellas are sold out!");
        require(msg.sender != address(0) && msg.sender != address(this));
        if(redeemable){
            require(lnlConnection.ownerOf(tokenURILNL) == msg.sender, "You are not the owner of this token");
            require(tokenURILNL<3333, "Queried non-existant LNL");
            require(isRedeemed[tokenURILNL] == 0, "Token is already redeemed");
            isRedeemed[tokenURILNL] = 1;
        }
        uint256 uniquetokenID = LongNeckieFellasID.current();
        _safeMint(contractdeployer, uniquetokenID);
        _safeTransfer(contractdeployer, msg.sender, uniquetokenID, "");
        _setTokenURI(uniquetokenID, ipfsCID);
        _isTokenURISet[ipfsCID] = true;
        LongNeckieFellasID.increment();
        return uniquetokenID;
    }


    //Metadata functions...
    function isLongNeckieLadyRedeemed(uint _LNLTokenId) public view returns (bool){
        require(_LNLTokenId<isRedeemed.length);
        uint tokeninfo = isRedeemed[_LNLTokenId];
        if (tokeninfo == 1){
            return true;
        }
        return false;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TokenURI query for nonexistent token");
        return string(abi.encodePacked(metadataStorage, _tokenURIs[tokenId]));
    }

    function changeStorageLocation(string memory url) public onlyOwner {
        require(!metadatafrozen);
        metadataStorage = url;
    }

    function _freezemetadata() onlyOwner public{
        metadatafrozen = true;
        //Metadata is permanently frozen once this function is called
    }

    function _changeMetadata(uint256 tokenId, string memory _tokenURI) onlyOwner public {
        require(!metadatafrozen);
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
        _isTokenURISet[_tokenURI] = true;
    }

    function _nextLNF() public view returns (uint256){
        return LongNeckieFellasID.current();
    }

    function _getAllMetadata() public view returns (string[] memory){
        string[] memory ret = new string[](LongNeckieFellasID.current());
        for(uint i = 0; i<LongNeckieFellasID.current();i++){
            ret[i] = _tokenURIs[i];
        }
        return ret;
    }
}