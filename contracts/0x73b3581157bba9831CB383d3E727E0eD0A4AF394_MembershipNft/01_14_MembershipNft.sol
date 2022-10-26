//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
@title MembershipNft
@author Marco Huberts & Javier Gonzalez
@dev Implementation of a Membership Non Fungible Token using ERC721.
*/

contract MembershipNft is ERC721, IERC2981, AccessControl, ReentrancyGuard {

    string public URI;

    uint256 public PRICE_PER_WHALE_TOKEN;
    uint256 public PRICE_PER_SEAL_TOKEN;
    uint256 public PRICE_PER_PLANKTON_TOKEN;

    uint256 public whaleTokensLeft;
    uint256 public sealTokensLeft;
    uint256 public planktonTokensLeft;

    uint256 public allMycelia;
    uint256 public allObsidian;
    uint256 public allDiamond;
    uint256 public allGold;
    uint256 public allSilver;

    bool internal frozen = false;

    address[] public royaltyRecipients;
    address[] public royaltyDistributorAddresses;
    
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    mapping(MintType => TokenIds) public TokenIdsByMintType;

    enum MintType { Whale, Seal, Plankton }

    struct TokenIds {
      uint256 startingMycelia;
      uint256 endingMycelia;
      uint256 startingObsidian;
      uint256 endingObsidian;
      uint256 startingDiamond;
      uint256 endingDiamond;
      uint256 startingGold;
      uint256 endingGold;
      uint256 startingSilver;
      uint256 endingSilver;
    }

  event MintedTokenInfo(uint256 tokenId, string rarity);
  event RecipientUpdated(address previousRecipient, address newRecipient);

  constructor(
    string memory _URI,
    uint256[] memory _whaleCalls, 
    uint256[] memory _sealCalls, 
    uint256[] memory _planktonCalls,
    address[] memory _royaltyRecipients, 
    address[] memory _royaltyDistributorAddresses
  ) ERC721("VALORIZE_MEMBERSHIP_NFT", "VMEMB") {
    URI = _URI;
    
    royaltyRecipients = _royaltyRecipients;
    royaltyDistributorAddresses = _royaltyDistributorAddresses;
    
    uint i;
    uint totalWhaleCalls = 0;
    uint totalSealCalls = 0;
    uint totalPlanktonCalls = 0;
      
    for(i = 0; i < _whaleCalls.length; i++) {
      totalWhaleCalls = totalWhaleCalls + _whaleCalls[i];
      totalSealCalls = totalSealCalls + _sealCalls[i];
      totalPlanktonCalls = totalPlanktonCalls + _planktonCalls[i];
    }

    whaleTokensLeft = totalWhaleCalls;
    sealTokensLeft = totalSealCalls;
    planktonTokensLeft = totalPlanktonCalls;

    allMycelia = _whaleCalls[0] + _sealCalls[0] + _planktonCalls[0];
    allObsidian = _whaleCalls[1] + _sealCalls[1] + _planktonCalls[1];
    allDiamond = _whaleCalls[2] + _sealCalls[2] + _planktonCalls[2];
    allGold = _whaleCalls[3] + _sealCalls[3] + _planktonCalls[3];
    allSilver = _whaleCalls[4] + _sealCalls[4] + _planktonCalls[4];

    TokenIdsByMintType[MintType.Whale] = TokenIds(
        1,                
        _whaleCalls[0],
        allMycelia + 1,
        allMycelia + _whaleCalls[1],
        allMycelia + allObsidian + 1,
        allMycelia + allObsidian + _whaleCalls[2],
        _whaleCalls[3],
        _whaleCalls[3],
        _whaleCalls[4],
        _whaleCalls[4]
    );

    TokenIdsByMintType[MintType.Seal] = TokenIds(
      _whaleCalls[0] + 1,
      _whaleCalls[0] + _sealCalls[0],
      allMycelia + _whaleCalls[1] + 1,
      allMycelia + _whaleCalls[1] + _sealCalls[1], 
      allMycelia + allObsidian + _whaleCalls[2] + 1, 
      allMycelia + allObsidian + _whaleCalls[2] + _sealCalls[2], 
      allMycelia + allObsidian + allDiamond + 1, 
      allMycelia + allObsidian + allDiamond + _sealCalls[3], 
      _sealCalls[4],
      _sealCalls[4] 
    );

    TokenIdsByMintType[MintType.Plankton] = TokenIds(
      _whaleCalls[0] + _sealCalls[0] + 1,
      allMycelia, 
      allMycelia + _whaleCalls[1] + _sealCalls[1] + 1, 
      allMycelia + allObsidian, 
      allMycelia + allObsidian + _whaleCalls[2] + _sealCalls[2] + 1, 
      allMycelia + allObsidian + allDiamond, 
      allMycelia + allObsidian + allDiamond + _sealCalls[3] + 1, 
      allMycelia + allObsidian + allDiamond + allGold, 
      allMycelia + allObsidian + allDiamond + allGold + 1, 
      allMycelia + allObsidian + allDiamond + allGold + allSilver
    );

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DEFAULT_ADMIN_ROLE, 0xCAdC6f201822C40D1648792C6A543EdF797e7D65);
          
    for (uint256 j=0; j < _royaltyRecipients.length; j++) {
      _grantRole(keccak256(abi.encodePacked(j)), royaltyRecipients[j]);
      _setRoleAdmin(keccak256(abi.encodePacked(j)), keccak256(abi.encodePacked(j)));
    }

    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingObsidian, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingObsidian, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingDiamond, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingDiamond, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingGold, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingGold, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingSilver, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingSilver, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingSilver, MintType.Plankton);
    _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingSilver, MintType.Plankton);
    planktonTokensLeft = planktonTokensLeft-10;
    setTokenPrice();  
  }

  function freeze() external onlyRole(DEFAULT_ADMIN_ROLE) {
    frozen = true;
  }

  function _baseURI() internal view override returns (string memory) {
    return URI;
  }

  function setURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!frozen);
    URI = baseURI;
  }
  
  function setTokenPrice() internal {
    PRICE_PER_WHALE_TOKEN = 0.3 ether;
    PRICE_PER_SEAL_TOKEN = 0.2 ether;
    PRICE_PER_PLANKTON_TOKEN = 0.1 ether;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
  *@dev Sends ether stored in the contract to admin.
  */
  function withdrawEther() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }

  function _safeMint(address to, uint256 tokenId) override internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
  *@dev Returns a random number when the total token amount is given.
  *     The random number will be between the given total token amount and 1.
  *@param tokenIdsToPickFrom is the amount of tokens that are available per mint type.    
  */
  function _getRandomNumber(uint256 tokenIdsToPickFrom) internal view returns (uint256 randomNumber) {
    uint256 i = uint256(uint160(address(msg.sender)));
    randomNumber = (block.difficulty + i) % tokenIdsToPickFrom + 1;
  }

  /**
  *@dev This function determines which rarity should be minted based on the random number.
  *@param determinant determines which range of token Ids will minted. 
  *@param mintType is the mint type which determines which predefined set of 
  *       token Ids will be minted (see constructor).   
  */
  function _mintFromDeterminant(uint256 determinant, MintType mintType) internal {
    if (determinant <= allMycelia) {      
      _myceliaMint(mintType);

    } else if (determinant <= (allMycelia + allObsidian)) {
      _obsidianMint(mintType);

    } else if (determinant <= (allMycelia + allObsidian + allDiamond)) {
      _diamondMint(mintType);

    } else if (determinant <= (allMycelia + allObsidian + allDiamond + allGold)) {
      _goldMint(mintType);
      
    } else if (determinant <= (allMycelia + allObsidian + allDiamond + allGold + allSilver)) {
      _silverMint();
    }
  }

  /**
  *@dev This mints a mycelia NFT when the startingMycelia is lower than the endingMycelia
  *     After mint, the startingMycelia will increase by 1.
  *     If startingMycelia is higher than endingMycelia the Obsidian rarity will be minted.
  *@param mintType is the mint type which determines which predefined set of 
  *     token Ids will be minted (see constructor).   
  */
  function _myceliaMint(MintType mintType) internal { 
    if (TokenIdsByMintType[mintType].startingMycelia > TokenIdsByMintType[mintType].endingMycelia) {
      _mintFromDeterminant((TokenIdsByMintType[mintType].startingObsidian), mintType);
    
    } else {
      _safeMint(msg.sender, TokenIdsByMintType[mintType].startingMycelia);
      emit MintedTokenInfo(TokenIdsByMintType[mintType].startingMycelia, "Mycelia");
      TokenIdsByMintType[mintType].startingMycelia++;
    }
  }

  /**
  *@dev This mints an obsidian NFT when the startingObsidian is lower than the endingObsidian
  *     After mint, the startingObsidian will increase by 1.
  *     If startingObsidian is higher than endingObsidian the Diamond rarity will be minted.
  *@param mintType is the mint type which determines which predefined set of 
  *     token Ids will be minted (see constructor).   
  */
  function _obsidianMint(MintType mintType) internal {
    if (TokenIdsByMintType[mintType].startingObsidian > TokenIdsByMintType[mintType].endingObsidian) {
      _mintFromDeterminant(TokenIdsByMintType[mintType].startingDiamond, mintType);
    
    } else {
      _safeMint(msg.sender, TokenIdsByMintType[mintType].startingObsidian);
      emit MintedTokenInfo(TokenIdsByMintType[mintType].startingObsidian, "Obsidian");
      TokenIdsByMintType[mintType].startingObsidian++;
    }
  }
  /**
  *@dev This mints a diamond NFT when the startingDiamond is lower than the endingDiamond
  *     In other words, a diamond NFT will be minted when there are still diamond NFTs available.
  *     After mint, the startingDiamond will increase by 1.
  *     If startingDiamond from mint type whale is higher than endingDiamond from mint type whale
  *     then startingMycelia (or startingObsidian) will be minted.
  *     If startingDiamond is higher than endingDiamond the Gold rarity will be minted.
  *@param mintType is the mint type which determines which predefined set of 
  *     token Ids will be minted (see constructor).   
  */
  function _diamondMint(MintType mintType) internal { 
    if (
      mintType == MintType.Whale && 
      TokenIdsByMintType[MintType.Whale].startingDiamond > TokenIdsByMintType[MintType.Whale].endingDiamond) {
      _mintFromDeterminant(TokenIdsByMintType[MintType.Whale].startingMycelia, MintType.Whale);
    
    } else if(TokenIdsByMintType[mintType].startingDiamond > TokenIdsByMintType[mintType].endingDiamond) {
      _mintFromDeterminant(TokenIdsByMintType[mintType].startingGold, mintType);
    
    } else {
      _safeMint(msg.sender, TokenIdsByMintType[mintType].startingDiamond);
      emit MintedTokenInfo(TokenIdsByMintType[mintType].startingDiamond, "Diamond");
      TokenIdsByMintType[mintType].startingDiamond++;
    }
  }

  /**
  *@dev This mints a gold NFT when the startingGold is lower than the endingGold
  *     After mint, the startingGold will increase by 1.
  *     If startingGold from mint type seal is higher than endingGold from mint type seal
  *     then startingMycelia (or higher rarity) should be minted.
  *     If startingGold from mint type plankton is higher than endingGold from mint type plankton
  *     then the startingSilver should be minted.
  *@param mintType is the mint type which determines which predefined set of 
  *     token Ids will be minted (see constructor).   
  */
  function _goldMint(MintType mintType) internal {
    if (
      mintType == MintType.Plankton &&
      TokenIdsByMintType[MintType.Plankton].startingGold > TokenIdsByMintType[MintType.Plankton].endingGold) {
      _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingSilver, mintType);
      
    } else if(
      mintType == MintType.Seal &&
      TokenIdsByMintType[MintType.Seal].startingGold > TokenIdsByMintType[MintType.Seal].endingGold) {
      _mintFromDeterminant(TokenIdsByMintType[MintType.Seal].startingMycelia, MintType.Seal);
    
    } else {
      _safeMint(msg.sender, TokenIdsByMintType[mintType].startingGold);
      emit MintedTokenInfo(TokenIdsByMintType[mintType].startingGold, "Gold");
      TokenIdsByMintType[mintType].startingGold++;
    }
  }

  /**
  *@dev This mints a silver NFT only for mint type plankton when the startingSilver is lower than the endingSilver
  *     After mint, the startingSilver will increase by 1.
  *     If startingSilver from mint type plankton is higher than endingSilver from mint type plankton
  *     then startingMycelia (or higher rarity) should be minted. 
  */
  function _silverMint() internal {
    if(TokenIdsByMintType[MintType.Plankton].startingSilver > TokenIdsByMintType[MintType.Plankton].endingSilver) {
      _mintFromDeterminant(TokenIdsByMintType[MintType.Plankton].startingMycelia, MintType.Plankton);
    
    } else {
      _safeMint(msg.sender, TokenIdsByMintType[MintType.Plankton].startingSilver);
      emit MintedTokenInfo(TokenIdsByMintType[MintType.Plankton].startingSilver, "Silver");
      TokenIdsByMintType[MintType.Plankton].startingSilver++;
    }
  } 

  /**
  *@dev Random minting of token Ids associated with the whale mint type.
  */
  function randomWhaleMint() public payable {
      require(PRICE_PER_WHALE_TOKEN <= msg.value, "Incorrect Ether value");
      require(whaleTokensLeft > 0, "Whale sold out");
      uint256 randomNumber = _getRandomNumber(TokenIdsByMintType[MintType.Whale].endingDiamond);
      _mintFromDeterminant(randomNumber, MintType.Whale);
      whaleTokensLeft--;
  }

  /**
  *@dev Random minting of token Ids associated with the seal mint type.
  */
  function randomSealMint() public payable {
      require(PRICE_PER_SEAL_TOKEN <= msg.value, "Incorrect Ether value");
      require(sealTokensLeft > 0, "Seal sold out");
      uint256 randomNumber = _getRandomNumber(TokenIdsByMintType[MintType.Seal].endingGold);
      _mintFromDeterminant(randomNumber, MintType.Seal);
      sealTokensLeft--;
  }

  /**
  *@dev Random minting of token Ids associated with the plankton mint type.
  */
  function randomPlanktonMint() public payable {
      require(PRICE_PER_PLANKTON_TOKEN <= msg.value, "Incorrect Ether value");
      require(planktonTokensLeft > 0, "Plankton sold out");
      uint256 randomNumber = _getRandomNumber(TokenIdsByMintType[MintType.Plankton].endingSilver);
      _mintFromDeterminant(randomNumber, MintType.Plankton);
      planktonTokensLeft--;
  }

  /**
  *@dev Returns the rarity of a token Id.
  *@param _tokenId the id of the token of interest.
  */
  function rarityByTokenId(uint256 _tokenId) external view returns (string memory) {
    if ((_tokenId >= 1 && _tokenId <= allMycelia)) {
      return "Mycelia";
    
    } else if ((_tokenId > allMycelia && _tokenId <= (allMycelia + allObsidian))) {
      return "Obsidian";
    
    } else if((_tokenId > (allMycelia + allObsidian) && _tokenId <= (allMycelia + allObsidian + allDiamond))) {
      return "Diamond";
    
    } else if((_tokenId > (allMycelia + allObsidian + allDiamond) && _tokenId <= (allMycelia + allObsidian + allDiamond + allGold))) {
      return "Gold";
    
    } else {
      return "Silver";
    }
  }

  /**
  *@dev Using this function a role name is returned if the inquired 
  *     address is present in the royaltyReceivers array.
  *@param inquired is the address used to find the role name
  */
  function getRoleName(address inquired) external view returns (bytes32) {
    for(uint256 i=0; i < royaltyRecipients.length; i++) {
      if(royaltyRecipients[i] == inquired) {
        return keccak256(abi.encodePacked(i));
      }
    }
    revert("Incorrect address");
  }

  /**
  *@dev This function updates the royalty receiving address
  *@param previousRecipient is the address that was given a role before
  *@param newRecipient is the new address that replaces the previous address
  */
  function updateRoyaltyRecipient(address previousRecipient, address newRecipient) external {
    for(uint256 i=0; i < royaltyRecipients.length; i++) {
      if(royaltyRecipients[i] == previousRecipient) {
        require(hasRole(keccak256(abi.encodePacked(i)), msg.sender));
        royaltyRecipients[i] = newRecipient;
        emit RecipientUpdated(previousRecipient, newRecipient);
        return;
      }
    }
    revert("Incorrect address for previous recipient");
  } 

  /**
  * @dev  Information about the royalty is returned when provided with token id and sale price. 
  *       Royalty information depends on token id: if token id is a Mycelia NFT than the artist address is returned.
  *       If token id is not a Mycelia NFT than the funds will be sent to the contract that distributes royalties.    
  * @param _tokenId is the tokenId of an NFT that has been sold on the NFT marketplace
  * @param _salePrice is the price of the sale of the given token id
  */
  function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (
        address,
        uint256 royaltyAmount
    ) {
      royaltyAmount = (_salePrice / 100) * 10; 

      if (_tokenId >= 1 && _tokenId <= allMycelia) {
        return(royaltyRecipients[((_tokenId - 1) % royaltyRecipients.length)], royaltyAmount);  
  
      } else {
        return(royaltyDistributorAddresses[((_tokenId -1) % royaltyDistributorAddresses.length)], royaltyAmount); 
    }
  }      
}