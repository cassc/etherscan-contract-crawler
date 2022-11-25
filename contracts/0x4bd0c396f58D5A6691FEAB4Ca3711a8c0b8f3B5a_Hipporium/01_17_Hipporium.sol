//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error SaleNotStarted();
error MaxMints();
error SoldOut();
error Underpriced();
error NotWL();
error ArraysNotSameLength();

/*
@0xSimon
*/
/// @title Hipporium 
/// @author @0xSimon_
/// @notice Classic NFT Mint with whitelist. Users mint an NFT and get an NFT. Families are assigned on-chain post-mint.
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";



contract Hipporium is ERC721AQueryable, Ownable, ReentrancyGuard,ERC2981,DefaultOperatorFilterer {

    using ECDSA for bytes32;
    uint256 private constant TOTAL_MAX_SUPPLY = 5000;
    uint256 public MAX_SUPPLY = 1000;
    uint256 public publicPrice = .1 ether;
    uint256 public presalePrice = .1 ether;
    uint256 public maxPublicMints = 1000;
    address private signer = 0x6884efd53b2650679996D3Ea206D116356dA08a9;
    enum SaleStatus{INACTIVE,PRESALE,PUBLIC}
    SaleStatus public saleStatus = SaleStatus.INACTIVE; 

    string public baseURI = "ipfs://QmY2ymDp3grq77kXgzNMDpXw4EYCQ4sVpJ2LniEoaePFjf/";
    string public uriSuffix = ".json";

    mapping(uint => uint) private familyOfToken;
    /*
    1 - Maori Tattoo
    2 - Predator Hunter
    3 - Yamashita Gold
    4 - Desert Planet
    5 - Kamakura
    6 - Psychedelic
    7 - Space Traveller
    8 - Inter Galactic
    9 - Flag Earth
    10 - Meta Fusion
    */
    


    constructor()
        ERC721A("Hipporium", "HPPO")

    {
        //Mint 500 to Team Wallet
        _mintERC2309(_msgSender(),500);
        //10% Royalty
        _setDefaultRoyalty(_msgSender(), 1000);
   
    }
    /* MINTING */

    ///@param accounts - array of wallet addresses we want to airdrop to
    ///@param amounts -array of amounts to airdrop each wallet
    ///@notice accounts and amounts holds a 1-1 relationship
    function airdrop(address[] calldata accounts ,uint256[] calldata amounts) external onlyOwner{
      uint supply = totalSupply();
      for(uint i; i < accounts.length;){
        if(amounts[i] + supply > MAX_SUPPLY) revert SoldOut();
        unchecked{
            supply += amounts[i];
        }
        _mint(accounts[i],amounts[i]);
        unchecked{
            ++i;
        }
      }
    }

    ///@param amount is the amount of NFTs a user wishes to mint
   function publicMint(uint amount) external payable  {
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        if(amount + totalSupply() > MAX_SUPPLY) revert SoldOut();
        if(msg.value < amount * publicPrice) revert Underpriced();
        uint64 numMintedPublic = _getAux(msg.sender);
        if(numMintedPublic + amount > maxPublicMints) revert MaxMints();
        //Imposible To Overflow Since Max Will Be Less Than 10 and MAX_SUPPLY = 5000
        _setAux(msg.sender, numMintedPublic + uint64(amount));
        _mint(msg.sender,amount);
    }

    ///@param amount - amount of nts to mint
    ///@param max  - the max amount of NFTs a user is allowed to mint.abi
    ///@notice max is encoded into the signature
    ///@param signature - the ECDSA signature signed by the signer. Acts as a whitelist method
    function whitelistMint(uint amount,uint max, bytes memory signature) external payable  {
        if(saleStatus != SaleStatus.PRESALE) revert SaleNotStarted();
        if(amount + totalSupply() > MAX_SUPPLY) revert SoldOut();
        if(msg.value < amount * presalePrice) revert Underpriced();
        bytes32 hash = keccak256(abi.encodePacked(max,msg.sender));
        if(hash.toEthSignedMessageHash().recover(signature) != signer) revert NotWL();
        if(_numberMinted(msg.sender) + amount > max) revert MaxMints();
        _mint(msg.sender,amount);
   } 

  //GETTERS

  ///@param account - user's address
  ///@return the number of public mints a user has made
  function getNumMintedPublic(address account) external view returns (uint){
    return _getAux(account);
   }
  ///@param account - user's address
  ///@return the number of whitelist mints a user has made
   function getNumMintedWhitelist(address account) external view returns(uint){
    return _numberMinted(account);
   }

 
 ///@param tokenId - tokenID
 ///@return the family of a token ID
function getTokenFamilyId(uint tokenId) external view returns (uint){
  return familyOfToken[tokenId];
}

    //SETTERS




    ///@param price - the new whitelistSale price
    function setPresalePrice(uint price) external onlyOwner {
        presalePrice = price;
    }

    ///@param price - the new publicMintSale Price
    function setPublicPrice(uint price) external onlyOwner {
        publicPrice = price;
    }



    ///@dev sets the revealed metadata
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

   ///@dev sets the metadata uri suffix
    function setUriSuffix(string memory _newSuffix) external onlyOwner{
        uriSuffix = _newSuffix;
    }

    ///@dev - turns public sale on
    function setPublicSaleOn() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    
    ///@dev - turns presale on
    function setPresaleOn () external onlyOwner {
        saleStatus = SaleStatus.PRESALE;
    }

    ///@dev turns all sales off
    function setSaleOff() external onlyOwner {
        saleStatus = SaleStatus.INACTIVE;
    }

    ///@dev - sets the signer
    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0));
        signer = _signer;
    }
    function setMaxSupply(uint newSupply) external onlyOwner {
        if(newSupply > TOTAL_MAX_SUPPLY) revert ("Exceed Max Total Supply");
        MAX_SUPPLY = newSupply;
    }

    ///@param tokenIds - an array of tokenIds
    ///@param familyIds -an array of familyIds 
    ///@notice tokenIds and familyIds are 1-1
    ///@notice since onlyOwner can use this function, we don't need safety checks to bound  1 <= familyId <= 10
    function uploadFamilyArray(uint[] calldata tokenIds, uint[] calldata familyIds) external onlyOwner{
        if(tokenIds.length != familyIds.length) revert ArraysNotSameLength();
        for(uint i; i < tokenIds.length;++i){
          familyOfToken[tokenIds[i]] = familyIds[i];
   
        }
      }

    function setMaxPublicMints(uint max) external onlyOwner {
        maxPublicMints = max;
    }

    //---- Token Metadata -----//
    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A,ERC721A)
        returns (string memory)
    {
    
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId),uriSuffix))
                : "";
    }

    //------- Withdraw ------ //
    function withdraw() external  onlyOwner nonReentrant{
        uint256 balance = address(this).balance;
        (bool r1, ) = payable(msg.sender).call{value: balance }("");
        require(r1);
        }



    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A,ERC721A, ERC2981) returns (bool) {

        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
    function transferFrom(address from, address to, uint256 tokenId) public   override (IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public   override (IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public   
        override (IERC721A,ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }



  
    

}