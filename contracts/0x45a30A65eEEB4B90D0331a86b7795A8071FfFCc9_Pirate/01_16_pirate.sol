// SPDX-License-Identifier: GPL-3.0
/*
 *                  uuuuuuu
 *              uu$$$$$$$$$$$uu
 *           uu$$$$$$$$$$$$$$$$$uu
 *          u$$$$$$$$$$$$$$$$$$$$$u
 *         u$$$$$$$$$$$$$$$$$$$$$$$u
 *        u$$$$$$$$$$$$$$$$$$$$$$$$$u
 *        u$$$$$$$$$$$$$$$$$$$$$$$$$u
 *        u$$$$"     "$$$"     "$$$$u
 *        "$$$$       u$u       $$$$"
 *         $$$u       u$u       u$$$
 *         $$$u"     u$$$u     "u$$$
 *          "$$$$uu$$$   $$$uu$$$$"
 *           "$$$$$$$"   "$$$$$$$"
 *             u$$$$$$$u$$$$$$$u
 *              u$"$"$"$"$"$"$u
 *   uuu        $$u$ $ $ $ $u$$       uuu
 *  u$$$$        $$$$$u$u$u$$$       u$$$$
 *   $$$$$uu      "$$$$$$$$$"     uu$$$$$$
 * u$$$$$$$$$$$uu    """""    uuuu$$$$$$$$$$
 * $$$$"""$$$$$$$$$$uuu   uu$$$$$$$$$"""$$$"
 *  """      ""$$$$$$$$$$$uu ""$"""
 *            uuuu ""$$$$$$$$$$uuu
 *   u$$$uuu$$$$$$$$$uu ""$$$$$$$$$$$uuu$$$
 *   $$$$$$$$$$""""           ""$$$$$$$$$$$"
 *    "$$$$$"                      ""$$$$""
 *      $$$"                         $$$$"
 */
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";


import "./flag.sol";

contract Pirate is ERC721, IERC2981, Ownable {
   using Strings for uint256;
   
   constructor() ERC721("Pirate Insults", "\u03C0RATE") {}

   uint public price = 0.025 ether;
   bool private _unlocked; 
   mapping(uint => bool) private trueInsult;
   mapping(uint => uint) private victories;
   uint private _tokenCount;
   bytes32 private _validTokens;
   address private _royalties;

   

   function _performMint(bytes32[] calldata proof, address destination, uint tokenId) internal  {     
      //require(!_exists(tokenId), "Token already claimed");
            
      bool verified = _verify(proof, tokenId);
      require( !_exists(tokenId) && (((tokenId >> 5) & 0x1F) < 32 && (tokenId & 0x1F) < 16) && (verified || _unlocked), "Token exists or is invalid");

      _safeMint(destination, tokenId);      
      if(verified) trueInsult[tokenId] = true;
      _tokenCount++;

/*
      if(_tokenCount == 31)
         price = 0.015 ether; 
*/
   }


   function isClaimed(uint tokenId) public view returns (bool)
   {
      return _exists(tokenId);
   }

   event BattleWon();
   event BattleLost();
   function battle(bytes32[] calldata proof, uint tokenId, uint response) public
   {
      require(ownerOf(tokenId) == msg.sender && _verify(proof, tokenId), "No ownership");            
        if((tokenId & 0x1F) != response) //check correct reply again opponents response (implicitly rejects alternative reply)
        {
            victories[tokenId]++; 
            emit BattleWon();       
        }
        else
            emit BattleLost();
   }

   function totalSupply() public view returns (uint)
   {
      return _tokenCount;
   }

   
   function tokenURI(uint tokenId) public view override returns (string memory)
   {
      //require(_exists(tokenId), "Token not minted");
      if(_exists(tokenId))
      {      
         return string(abi.encodePacked("data:application/json;base64,", Flag.generateMetadata(tokenId, trueInsult[tokenId], victories[tokenId])));
      }
      else 
         return "No token";
      
   }

   function mintFor(bytes32[] calldata proof, address walletAddress, uint tokenId) public payable virtual {
        require(msg.value >= price, "Price not met.");
        _performMint(proof, walletAddress, tokenId);
    }
   
    function mint(bytes32[] calldata proof, address destination, uint tokenId) public onlyOwner {
        _performMint(proof, destination, tokenId);
    }

   function setPrice(uint newPrice) public onlyOwner {
        price = newPrice;
    }

   function _verify(bytes32[] calldata proof, uint tokenId) private view returns (bool)
   {        
        return MerkleProof.verify(proof, _validTokens, keccak256(abi.encodePacked(Strings.toString(tokenId))));
   }

   function setLock(bool lock) public onlyOwner {
      _unlocked = !lock;
   }

   function setValidTokens(bytes32 tokenHexRoot) public onlyOwner {
      _validTokens = tokenHexRoot;
   }

   function setRoyalty(address newAddress) public onlyOwner {
        _royalties = newAddress;
    }

   function withdrawAll() public payable onlyOwner {
      require(payable(msg.sender).send(address(this).balance));
   }
   
   
   function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {   
      return (_royalties, (_salePrice / 100) * (trueInsult[_tokenId] ? 6 : 3));      
  }

   function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
      return 
         interfaceId == type(IERC2981).interfaceId || 
         super.supportsInterface(interfaceId);
   }


}