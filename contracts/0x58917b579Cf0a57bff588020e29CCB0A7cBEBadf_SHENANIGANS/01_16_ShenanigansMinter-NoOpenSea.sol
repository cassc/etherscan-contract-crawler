// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract SHENANIGANS is ERC721, ERC2981, Pausable, Ownable, ReentrancyGuard { 

   // "SHENANIGANS" is: "OAAC", EP5-A3   <---  <-----  <------  < < <<--  ---   <--  < --    <---

   using Counters for Counters.Counter;
   using Strings for uint256;

   // Mappings ("Dictionaries"):
   mapping(uint256 => string) private tokenURIsDictionary;
   mapping(uint256 => bool) private tokensWithFinalizedURIsDictionary;

   // "totalSupply":
   Counters.Counter public ShenanigansInWild;


   // EVENTS:
   event ShenaniganMinted(uint indexed mintedTokenID, string mintedTokenURI);         
   event TokenURIUpdated(uint indexed updatedTokenID, string newlyUpdatedURI);
   event LockedURIofTokenNumber(uint256 indexed tokenNumber);




   constructor() ERC721("SHENANIGANS", unicode"ש") {
      // Use ERC2981 to set the default Royalty-Rate to 7.5%:
      _setDefaultRoyalty(msg.sender, 750);   
   }




   // MINTING.
   // ONLY the CONTRACT'S OWNER is allowed to do this:
   function safeFreeMint(address to, string memory metadataURI) public onlyOwner whenNotPaused {
      _safeMint(to, ShenanigansInWild.current());
      setTokenURI(ShenanigansInWild.current(), metadataURI);

      _setTokenRoyalty(ShenanigansInWild.current(), to, 750);
     
      emit ShenaniganMinted(ShenanigansInWild.current(), metadataURI);

      // Iterate the Counter of NFTs minted:
      ShenanigansInWild.increment();
   }




  
   // GETTER: returns any given Token's URI
   function tokenURI(uint256 tokenId) public view override(ERC721) returns(string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return tokenURIsDictionary[tokenId];
   }



   // SETTER ("UPDATER"):
   // It's often been the case I've gotten a really great idea on how to make an already-minted work even better. 
   // I'm therefore creating this function so that I can edit a Token's URI *after* it was already minted. Theorerically,
   // I could do this multiple times, updating a work and its Token's URI any number of times, until I feel it's "done." 
   // At that point, I'll call the "lockTokenURI()" function, which will forever *LOCK* that Token's URI and prevent
   // me or anyone else from ever changing it again. From that moment on, the NFT will become truly IMMUTABLE.
   function setTokenURI(uint256 tokenId, string memory theTokenURI) public onlyOwner whenNotPaused {
      require(_exists(tokenId), "'setTokenURI()' ERROR! Trying to set URI of nonexistent token!");
      require(tokensWithFinalizedURIsDictionary[tokenId] == false, "'setTokenURI()' ERROR! TOKEN LOCKED!!! This Token's URI has already been FINALIZED!");
      
      // Otherwise:
      tokenURIsDictionary[tokenId] = theTokenURI;
      emit TokenURIUpdated(tokenId, theTokenURI);
   }




   // This lets me Finalize and FOREVER-LOCK a Token's Metadata URI prior to listing
   // it, that way the buyer is assured the NFT they're buying is truly immutable:
   function lockTokenURI(uint256 tokenId) public onlyOwner whenNotPaused {
      require(_exists(tokenId), "ERROR!!! Trying to set URI of nonexistent token!");

      tokensWithFinalizedURIsDictionary[tokenId] = true;

      emit LockedURIofTokenNumber(tokenId);
   }




   // Lets me know if a given Token's Metadata-URI is locked or not:
   function getTokenURILockStatus(uint256 tokenId) public view returns(bool isLocked) {
      require(_exists(tokenId), "'getTokenURILockStatus()' ERROR!!! URI query for nonexistent token!");
      return tokensWithFinalizedURIsDictionary[tokenId];
   }




   function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns(bool) {
      return super.supportsInterface(interfaceId);
   }



   function pause() public onlyOwner {
      _pause();
   }


   function unpause() public onlyOwner {
      _unpause();
   }



}