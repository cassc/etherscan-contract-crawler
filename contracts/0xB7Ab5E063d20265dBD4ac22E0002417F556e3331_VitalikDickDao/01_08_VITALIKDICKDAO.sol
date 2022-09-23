//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@(((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@(((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@((((((((((((((((((((((((#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@(((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@((((((((((((((((((((@@@(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@(((((((((((((((@@@&((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@(((((((((@@@(((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@#(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@((((((((((,//////(((((((((@@@@@@@@&(((((@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((,,/@@@@((((((((((@(@@((((((#@@@@((@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((///((@@((((((((@((@(((((((((((((@@((@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((((((@@(@(@@(((((((((((((((@@(@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((@@%((@@(@((((((((((((((((@@(@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@((@@#(#@@&(((((((((((((((@(@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#%@@@@((@@((@@#(#@@(((((((((((((((@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((@@@@@@@@@@((@@#((@@@(((((((@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((((((((@@((@@@&(((((((((@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(((((((((((((((((@((@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%((((((((((((((((((@@(@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((@((((((((((((((((@((@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#(@@((((((((((((((@((@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((@@((((((((((@@(@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((%((((@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */


contract VitalikDickDao is Ownable, ERC721A, ReentrancyGuard {
 
    using Strings for uint;

     enum Step {
        Before,
        DICKSALE, 
        SoldOut 
     }    


    string public baseURI;
    Step public sellingStep;
      
     
    uint16 private constant MAX_SUPPLY = 10000; 
    uint16 private constant MAX_WHITELIST = 5000;
    uint16 private constant MAX_PUBLIC = 5000; 
    uint8 private maxMintPerWhitelist = 20;
    uint16 public publicMinted;
    uint16 public whitelistMinted; 
     
  
    bytes32 public merkleRoot;
      
    address founder = 0x3cb6A31Ac975470012F476f852308208CFaDbe1B;
    address dev = 0x29a1bE224E92b0E9E749456D7A8Db9577c734Bf4;

    uint256 founderCut;
    uint256 devCut;

    uint256 transactionGas = 50000;

    uint256 founderPercentage = 500;
    uint256 devPercentage = 500;

    uint128 public wlSalePrice = 0 ether;
    uint128 public publicSalePrice = 0.001 ether;
    mapping(address => uint) public amountNFTsperWalletWhitelistSale;
    
    
    constructor(bytes32 _merkleRoot, string memory _baseURI) ERC721A("VITALIK DICK DAO", "VDD") {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
         }
     
     
     modifier callerIsUser() {
       require(tx.origin == msg.sender, "The caller is another contract.");
      _;
      }

       function updateGas(uint256 _newGas) public onlyOwner{
        transactionGas = _newGas;
    }
      
    
     function isValid(bytes32[] memory merkleproof, bytes32 leaf)public view returns (bool){
         return MerkleProof.verify(merkleproof, merkleRoot, leaf);
      }
  function DICKMINTT(uint16 _quantity, bytes32[] calldata merkleproof) external payable callerIsUser{
        require(sellingStep == Step.DICKSALE, "Sale is not activated");
        require(isValid(merkleproof, keccak256(abi.encodePacked(msg.sender))),"Not in whitelist List");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= maxMintPerWhitelist, "You can only get 20 DICKS Bro");
        require(whitelistMinted + _quantity <= MAX_WHITELIST, "Max whitelist supply exceeded"); 
        require(whitelistMinted + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= wlSalePrice * _quantity, "Not enought funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        whitelistMinted = whitelistMinted + _quantity; 
      }
         
       
     function DICKMINT(uint16 _quantity) external payable callerIsUser {
        require(sellingStep == Step.DICKSALE, "VitalikDickDao sale is not  activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(publicMinted + _quantity <= MAX_PUBLIC, "Max public supply exceeded");
        require(msg.value >= publicSalePrice * _quantity, "Not enought funds");
        _safeMint(msg.sender, _quantity);
        publicMinted = publicMinted + _quantity;
      }

        
 
     function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
      }

   
     function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
      }

  
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

  
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }


    function WithdrawForTheDicks() public onlyOwner nonReentrant {

    founderCut = address(this).balance * founderPercentage /1000;
    devCut = address(this).balance * devPercentage /1000;
    
    (bool sentFounder, ) = payable(founder).call{gas: transactionGas, value: founderCut}("");     
    require(sentFounder, "eth not sent to Founder, not good");
    
    (bool sentDev, ) = payable(dev).call{gas: transactionGas, value: devCut}("");     
    require(sentDev, "eth not sent to Dev, not good");
        
  }    
  
   
}