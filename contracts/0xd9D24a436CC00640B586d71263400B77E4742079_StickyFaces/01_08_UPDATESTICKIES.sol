//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*@@@@@@@@@@@@@@@@@@@@@# @@@@@#  /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@  &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@& #[email protected]@@@@@@@@@@@( (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@  ,[email protected]@@@@@@@@@@@@@, @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ *@@@@ @@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@& @@@@@@@@@@@@@@@@@ ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@% @@@@@@@# @@@@& #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@, @@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@@@#.    &@@@@@@@  @@@@@@@@@@ @@@@@@@ &@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  (@@@@@@@@@@@@@@  @@@@@@@ @@@@@@@@@@@@@@           @@@              @@    @@@@@           /@@@    @@@&    %@@@    @@@@@    @@@@@@
@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@    @@@. @@@@@@@@@@@@    @@@@@@@@@@@@@@@    @@@@@@@@    @@@     @@@@@@@@@@@@    &    #@@@@@@@    @@    @@@@@@@@
@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #@@@@@# @@@ @@@@@@@@@@@@         *@@@@@@@@@    @@@@@@@    @@@    &@@@@@@@@@@@@       (@@@@@@@@@@@&      @@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(/@@@@@@ &@@ @@@@@@@@@@@@@@@@@@     @@@@@@@    @@@@@@@@    @@@    @@@@@@@@@@@@@         @@@@@@@@@@@    @@@@@@@@@@@@
@@@@@@@@@@@@@ [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*@@@@@@@  @ (@@ @@@@@@ %@@@@@@    @@@@@@@    @@@@@@@    @@@@*    #@@@@@, @@@    @@@     @@@@@@@@@    @@@@@@@@@@@@@
@@@@@@@@@@, @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* @@@@@@@@@           @@@@@@@@    @@@@@@@@    @@@@@@%         @@@@    @@@@@.    @@@@@@.   &@@@@@@@@@@@@
@@@@@@@@( @@@@@@@@@@@    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@ @@@@@@@@@@@@ ,@@(.&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  &@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@% @@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,       @@@@@@@@@@@@@@@@@@@@@@@@@@@@ &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@* @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@% @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@( @@@@@@@@@@@@@@@   @@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@.   ,@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@           @@@@      @@@@@@@@           @@@@           @@@%          %@@@@@@@@@@@@@@@@@@@
@@@ @@@@@@@@@@@@@@@  @@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@  &@@@@@    %@@@@@@@@@@@@@@@@@@@@@@@@@@# @@@@@@@@@    @@@@@@@@@@@   *    @@@@@    @@@@@@@@@@@@    @@@@@@@@@@&   @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ @@@@@@@@@@@@@@@@  @@@@.  @   @@@@@@@@@@@@@@@@@@@@@@@@   @@@@@  @*  @@@@@@@@@@@@@@@@@@@@@@@@@@@ &@@@@@@@@          @@@    @@,   @@@@    @@@@@@@@@@@@@          @@@@@         @@@@@@@@@@@@@@@@@@@@@@
@ @@@@@@@@@@@@@@@@@             /@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@*   %@@@@@@@@    @@@@   ,@@@    @@@@@@@@@@@@    @@@@@@@@@@@@@@@@@.     @@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@*              @@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@ #@@@@@@    @@@@@@@,             @@@     @@@@@@,&@@@    @@@@@@@@@@ *@@@@@@(    @@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@*  @@&         @@@@@@@@@@@@@@@@@@@@@@@   @@@        @@@@@@@@@@@@@@@@@@@@@@@@% @@ /@@@@@,   %@@@@@@    @@@@@@@@   %@@@@          @@@           #@@@           @@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@#              @@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@(   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             (@@@@@@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@( @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@*            %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/


contract StickyFaces is Ownable, ERC721A, ReentrancyGuard {
 
    using Strings for uint;

    enum Step {
        Before,
        PublicSale, //1
        SoldOut
     }    
    //State Variables

    string public baseURI;
    Step public sellingStep;
      
    //Constant variables 
     
    uint16 private constant MAX_SUPPLY = 5000;
    uint16 private constant MAX_WHITELIST = 1500; 
    uint16 private constant MAX_PUBLIC = 3500;   
    uint16 public whitelistMinted; 
    uint16 public publicMinted; 
    uint8 private maxMintPerWhitelist = 3;
    uint8 private maxMintPerPublic = 20;
     
    bytes32 public merkleRoot;
    
   
    address founder = 0xC28f498b990DC256E6F04875c204d87a3d81FC33;
    address cm = 0xa6505933F4B6cbB3E71124Cf5Be9c5D6c04460A7;
    address dev = 0xb140fC484fA263da038ac24354e639F97A21Fc8e;
    address jamex = 0xdA00A06Ab3BbD3544B79C1350C463CAb9f196880;
    address pedro = 0xc9E620f61187813A7BeB4f174A6697004A065282;
    address nftfam = 0xdfAC3142F75e9E83eE17865eeD5bc7482e574F1c;

    

    uint256 founderCut; 
    uint256 cmCut; 
    uint256 devCut; 
    uint256 jamexCut; 
    uint256 pedroCut; 
    uint256 nftfamCut; 

    

    uint256 transactionGas = 50000;       
 

    uint256 founderPercentage = 240;         
    uint256 cmPercentage = 220;
    uint256 devPercentage = 220;
    uint256 jamexPercentage = 200;
    uint256 pedroPercentage = 100;
    uint256 nftfamPercentage = 20;      

   
    uint128 public wlSalePrice = 0 ether;
   
    uint128 public publicSalePrice = 0.01 ether;
   
    mapping(address => uint) public amountNFTsperWalletWhitelistSale;
    mapping(address => uint) public amountNFTsperWalletPublicSale;
    
    
    constructor(bytes32 _merkleRoot, string memory _baseURI) ERC721A("STICKY FACES", "STICKY") {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
         }
     
     modifier callerIsUser() {
       require(tx.origin == msg.sender, "The caller is another contract.");
      _;
      }
            
     function isValid(bytes32[] memory merkleproof, bytes32 leaf)public view returns (bool){
         return MerkleProof.verify(merkleproof, merkleRoot, leaf);
      }

   
    function updateGas(uint256 _newGas) public onlyOwner{
        transactionGas = _newGas;
    }

   
      function whitelistMint(uint16 _quantity, bytes32[] calldata merkleproof) external payable callerIsUser{
        require(sellingStep == Step.PublicSale, "Sale is not activated");
        require(isValid(merkleproof, keccak256(abi.encodePacked(msg.sender))),"Not in whitelist List");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= maxMintPerWhitelist, "You can only get 3 NFT on the Whitelist Sale");
        require(whitelistMinted + _quantity <= MAX_WHITELIST, "Max whitelist supply exceeded"); //this allow us to still mint the Diamond pass anytime even totalsupply reach 3.000 
        require(whitelistMinted + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= wlSalePrice * _quantity, "Not enought funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
        whitelistMinted = whitelistMinted + _quantity; 
      }
         
    
      function updatePrice() internal returns (uint256) {
        return publicSalePrice = publicMinted < 1000 ? 0.01 ether : 0.02 ether;
      }
             
   
     function publicSaleMint(uint16 _quantity) external payable callerIsUser {
        require(sellingStep == Step.PublicSale, "Public sale is not  activated");
        require(amountNFTsperWalletPublicSale[msg.sender] + _quantity <= maxMintPerPublic,"You can only get 20 NFT on the Public Sale");
        require(publicMinted + _quantity <= MAX_PUBLIC, "Max public supply exceeded");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= updatePrice() * _quantity, "Not enought funds");
        _safeMint(msg.sender, _quantity);
        publicMinted = publicMinted + _quantity;  
      }

    
    
     function gift(address _to, uint _quantity) external onlyOwner {
         require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply for the team");
        _safeMint(_to, _quantity);
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
    
    
    function withdraw() public onlyOwner nonReentrant {

    founderCut = address(this).balance * founderPercentage /1000;
    cmCut = address(this).balance * cmPercentage /1000;
    devCut = address(this).balance * devPercentage /1000;
    jamexCut = address(this).balance * jamexPercentage /1000;
    pedroCut = address(this).balance * pedroPercentage /1000;
    nftfamCut = address(this).balance * nftfamPercentage /1000; 


    (bool sentFounder, ) = payable(founder).call{gas: transactionGas, value: founderCut}("");     
    require(sentFounder, "eth not sent to Founder, not good");
    (bool sentCM, ) = payable(cm).call{gas: transactionGas, value: cmCut}("");     
    require(sentCM, "eth not sent to CM, not good");
    (bool sentDev, ) = payable(dev).call{gas: transactionGas, value: devCut}("");     
    require(sentDev, "eth not sent to Dev, not good");
    (bool sentJamex, ) = payable(jamex).call{gas: transactionGas, value: jamexCut}("");     
    require(sentJamex, "eth not sent to Jamex, not good");
    (bool sentPedro, ) = payable(pedro).call{gas: transactionGas, value: pedroCut}("");     
    require(sentPedro, "eth not sent to Pedro, not good");
    (bool sentNFTFam, ) = payable(nftfam).call{gas: transactionGas, value: nftfamCut}("");     
    require(sentNFTFam, "eth not sent to NFT Fam, not good");
  }
}