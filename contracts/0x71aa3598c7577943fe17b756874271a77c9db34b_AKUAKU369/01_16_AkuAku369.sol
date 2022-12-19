// SPDX-License-Identifier: MIT

/***
 *                                               
 *     _ _ _ _____ _____ _____ _____ ___ ___ ___ 
 *    | | | |   __|  _  | __  |   __|_  |  _| . |
 *    | | | |   __|     |    -|   __|_  | . |_  |
 *    |_____|_____|__|__|__|__|_____|___|___|___|
 *  
 *     _____ _____ __    __    _____ _ _ _ _____ _____ _____ _____ _____ _____ _____ _____ 
 *    |   __|     |  |  |  |  |     | | | |_   _|  |  |   __|   __|     |   __|   | |   __|
 *    |   __|  |  |  |__|  |__|  |  | | | | | | |     |   __|__   |-   -|  |  | | | |__   |
 *    |__|  |_____|_____|_____|_____|_____| |_| |__|__|_____|_____|_____|_____|_|___|_____|
 *                                          
 *           ___      ___   ___            ___ 
 *     _ _ _|___|    |___|_|___|_      _ _|___|
 *    |_|_|_|            |_|   |_|    |_|_|    
 *                                             
 *                                                                            
 */

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";

contract AKUAKU369 is ERC721, RevokableDefaultOperatorFilterer, Ownable {
  // mint price is in wei ( 10^18 wei = 1 ether ) 
  uint256 public mintPrice = 0;
  uint256 public totalSupply;
  uint256 public partMaxSupply;
  uint256 public maxSupply;
  bool public isPublicMintEnabled = false ;
  string internal baseTokenUri = 'ipfs://bafybeidh2dkgp3z73d2ica4nt7nwmufxrgsxllf2x4af46m6pgqcjmjkju/';
  address payable public withdrawWallet;
  bool public revealed = false ;
  bool public isAkuListActive = false;
  

  mapping(address => uint8) private _akuList;

  constructor() payable ERC721('AKUAKU', 'AKU') {
      
      totalSupply = 0;
      partMaxSupply = 368;
      
        }
 
      function setIsAkuListActive(bool _isAkuListActive) external onlyOwner {
        isAkuListActive = _isAkuListActive;
    }
  
        function setAkuList(address[] calldata addresses, uint8 numAllowedToMint , uint256 _mintPrice) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _akuList[addresses[i]] = numAllowedToMint;
        }
        mintPrice = _mintPrice ;
    }
 
        function setMaxSupply( uint256 _maxSupply) external onlyOwner {
          if(maxSupply != 0){
        require(_maxSupply <= maxSupply, " new maxSupply can't be bigger than old max supply");
        require(partMaxSupply <= _maxSupply, " new maxSupply can't be less than current partMaxSupply");
        maxSupply = _maxSupply ;
          }else{
            require(partMaxSupply <= _maxSupply, " First maxSupply can't be less than current partMaxSupply");
            maxSupply = _maxSupply ;
          }
        
    }
 
        function setPartMaxSupply( uint256 _partMaxSupply) external onlyOwner {
          if(maxSupply != 0){
          require(_partMaxSupply <= maxSupply, "partMaxSupply can't be bigger than maxSupply");
          }
        
        require(partMaxSupply <= _partMaxSupply, "partMaxSupply can't be less than old partMaxSupply");
        
        partMaxSupply = _partMaxSupply ;
    }
 
    function numAvailableToMint(address addr) external view returns (uint8) {
        return _akuList[addr];
    }

 
  
        function mintAkuList(uint8 numberOfTokens) public payable {
        require(isAkuListActive, "akuList mint is not enabled");
        require(numberOfTokens <= _akuList[msg.sender], "Exceeded max available to purchase");
        require(totalSupply + numberOfTokens <= partMaxSupply, "Purchase would exceed max tokens");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _akuList[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
          uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }
 
  function setIsPublicMintEnabled(bool isPublicMintEnabled_ , uint256 _mintPrice) external onlyOwner {
    isPublicMintEnabled = isPublicMintEnabled_;  
    mintPrice = _mintPrice  ;
  }
 
  function changeMintPrice(uint256 _mintPrice) public onlyOwner {

     mintPrice = _mintPrice   ;
  }


  function changeRevealed(bool revealed_ , string calldata baseTokenUri_) public onlyOwner {
    revealed = revealed_ ;
    baseTokenUri = baseTokenUri_;
  }
  
 function setwithdrawWallet(address payable withdrawWallet_) external onlyOwner {
   require(withdrawWallet_ != address(0) , 'Wallet address can not be zero !');
    withdrawWallet = withdrawWallet_;  
  }

 
  function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
      baseTokenUri = baseTokenUri_;
  }
  
  function tokenURI(uint256 tokenId_) public view override returns (string memory){
    require(_exists(tokenId_), 'Token does not exist !');

    if(revealed){
      return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }
    else {
      return string(abi.encodePacked(baseTokenUri,"UnRevealed.json"));
    }
  }
 
  function withdraw() external onlyOwner {
      (bool success, ) = withdrawWallet.call{ value: address(this).balance }('');
      require(success, 'withdraw failed');

  }
  
  function mint(uint256 quantity_) public payable {
      require(isPublicMintEnabled, 'Public mint is not enabled');
      require(msg.value == quantity_ * mintPrice, 'Ether value sent is not correct');
      require(totalSupply + quantity_ <= partMaxSupply, 'Purchase would exceed max tokens');
      for(uint256 i = 0; i < quantity_; i++ ){
          uint256 newTokenId = totalSupply + 1;
          totalSupply++;
          _safeMint(msg.sender, newTokenId);
      }
  }
   
  function airDrop(address  userWallet_ , uint256 quantity_) public  onlyOwner {
    
      require(totalSupply + quantity_ <= partMaxSupply, 'Airdrop number request would exceed max tokens');
      for(uint256 i = 0; i < quantity_; i++ ){
          uint256 newTokenId = totalSupply + 1;
          totalSupply++;
          _safeMint(userWallet_, newTokenId);
      }
  }
function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

}