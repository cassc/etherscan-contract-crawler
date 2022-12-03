// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; 
import "./ERC721A.sol";
 
//........................................................................
//...........POWER FOR THE PEOPLE......................................... 
//........................................................................
//.....................................................PFP WORLD  
//........................................................................

contract HEX01 is Ownable, ERC721A  { 
    using ECDSA for bytes32;
    using Strings for uint256; 
  
    string _baseTokenURI;  
    uint256 private _HexPrice = 0.05 ether; 
    uint256 private _AlphaPrice = 0.04 ether; 
    uint256 private _ClaimPrice = 0 ether; 
     
    bool public _pausedHex = true;        
    bool public _pausedAlpha = true;   
    bool public _pausedClaim = true;    
 
    uint256 private supply;

    mapping(string => bool) private _mintedNonces; 
    mapping(address => uint256) public mintedAlphaAddress;
    mapping(address => uint256) public mintedAddress; 
    
    mapping(uint256 => bool) public claimedPhysical;
      
    address f1 = 0x64d7Da2d7e71f927A3f7AF440312Cf6C345Ef02B;
    address l1 = 0xaF3aaF0369B374e8B56a4eECEA430e0e589592dA;
    address f2 = 0xb38Cf1583306C378a613409ED0eF9d0f815dae0f;

    address private _signatureAddress = 0x527866865Bf4a75fe9c293E342F46BF52f9d7C31;
 
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) 
    ERC721A(name,symbol) {
        setBaseURI(baseURI); 
    } 
    modifier notContract() {
        require(tx.origin == msg.sender, "9");
        _;
    }
    function giveAway(address _to, uint256 _amount, bool blnPhysicalClaim, bool blnAlpha) external onlyOwner() {
        supply = totalSupply();  
        mintedAddress[_to] += _amount; 

        if(blnAlpha)
            mintedAlphaAddress[_to] += _amount; 

        if (blnPhysicalClaim) {
 
             _safeMint(_to, _amount);
            for(uint256 i; i < _amount; i++){ 
                claimedPhysical[supply + i] = true;  
            }
            
        }else{

             _safeMint(_to, _amount);
         
        }

    }  

    function ownerPhysicalClaim(uint256 tokenID,bool blnPhysicalClaim) external onlyOwner() {
            
        if(blnPhysicalClaim){ 
            claimedPhysical[tokenID] = true;  
        }else{ 
            claimedPhysical[tokenID] = false;  
        }
          
    } 

    //alpha mint for alphas only.  
    function Hex01AlphaMint(uint256 num, bool blnPhysicalClaim, bytes memory signature, string memory nonce) public payable notContract {
        supply = totalSupply(); 
        //pause alpha mint
        require( !_pausedAlpha, "1" ); 
        //prevent user from claiming directly on smart contract, only on claim
        require( matchAddresSignature(hashTransaction(msg.sender, num, nonce), signature),   "4");
        require(!_mintedNonces[nonce], "5");   
        //make sure price is correct
        require( msg.value >= _AlphaPrice * num, "4" );  
        //track who minted alpha
        mintedAlphaAddress[msg.sender] += num; 
        mintedAddress[msg.sender] += num; 
       
         //claim this token. 
        if (blnPhysicalClaim) {
             require( num < 11,   "You can mint a maximum of 10 Digitals when claiming a physicals" );  
            _safeMint(msg.sender, num);
            for(uint256 i; i < num; i++){ 
                claimedPhysical[supply + i] = true;  
            }

        }else{
            require( num < 31,   "You can mint a maximum of 30 Digitals Only" ); 
            _safeMint(msg.sender, num);
        }
        //set nonce
        _mintedNonces[nonce] = true;  

    }   
   
    function Hex01Mint(uint256 num, bool blnPhysicalClaim, bytes memory signature, string memory nonce) public payable notContract {
        supply = totalSupply(); 
        //pause hex mint
        require( !_pausedHex, "1" ); 
        //prevent user from claiming directly on smart contract, only on claim
        require( matchAddresSignature(hashTransaction(msg.sender, num, nonce), signature),   "4");
        require(!_mintedNonces[nonce], "5");   
        //make sure price is correct
        require( msg.value >= _HexPrice * num, "4" );   
        //track who minted
        mintedAddress[msg.sender] += num; 
        //_safeMint(msg.sender, num);
        //claim this token. 
        if (blnPhysicalClaim) { 
            require( num < 11,   "You can mint a maximum of 10 Digital when claiming a physicals" );  
            _safeMint(msg.sender, num);
            for(uint256 i; i < num; i++){ 
                claimedPhysical[supply + i] = true;  
            }

        }else{ 
            require( num < 31,   "You can mint a maximum of 30 Digitals Hexes Only" ); 
            _safeMint(msg.sender, num); 
        } 
        //set nonce
        _mintedNonces[nonce] = true;  
    }   

    //should be performed only through pfp world using signature
    //might cost extra in the future to claim if you dont claim the physical immediately
	function Hex01PhysicalClaim(uint256 _tokenId, bytes memory signature, string memory nonce)  public payable notContract {
        //pause claim
		require( !_pausedClaim,  "Claim paused." );
        //prevent user from claiming directly on smart contract
        require( matchAddresSignature(hashTransaction(msg.sender, _tokenId, nonce), signature),   "4");
        require(!_mintedNonces[nonce], "5");   
        //user must own token
        require(ERC721A.ownerOf(_tokenId) == msg.sender, "You do not own this token.");
        //has token been claimed? 
		require(!claimedPhysical[_tokenId], "Physical: claimed already");
        //charge the user for claim
        require( msg.value >= _ClaimPrice, "4" );  
        //set nonce
        _mintedNonces[nonce] = true;  
         //set that this token has been claimed   
         claimedPhysical[_tokenId] = true; 
         
	}
   
    function setPrice(uint256 _nPrice) public onlyOwner() {
        _HexPrice = _nPrice;
    }
    function getPrice() public view returns (uint256){
        return _HexPrice;
    } 
    function setPriceAlpha(uint256 _nPrice) public onlyOwner() {
        _AlphaPrice = _nPrice;
    }
    function getPriceAlpha() public view returns (uint256){
        return _AlphaPrice;
    }
    function setPriceClaim(uint256 _nPrice) public onlyOwner() {
        _ClaimPrice = _nPrice;
    }
    function getPriceClaim() public view returns (uint256){
        return _ClaimPrice;
    }
 
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    function pauseAlpha(bool val) public onlyOwner {
        _pausedAlpha = val;
    } 
    function pauseHex(bool val) public onlyOwner {
        _pausedHex = val;
    }  
    function pauseClaim(bool val) public onlyOwner {
        _pausedClaim = val;
    } 
 
    function withdrawAll1(uint256 amount) public payable onlyOwner {

        uint256 percent = amount / 100;    

        (bool success1, ) = f1.call{value: percent * 95}("");
        require(success1, "Transfer failed.");

        (bool success2, ) = f2.call{value: percent * 5}("");
        require(success2, "Transfer failed.");   
    }
    function withdrawAll2(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;  
        require(payable(l1).send(percent * 95));
        require(payable(f2).send(percent * 5)); 
    }
  

    function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
      bytes32 hash = keccak256(abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          keccak256(abi.encodePacked(sender, qty, nonce)))
      ); 
      return hash;
    }
    function matchAddresSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
        return _signatureAddress == hash.recover(signature);
    }
    function setSignatureAddress(address addr) external onlyOwner {
        _signatureAddress = addr;
    }
 
}