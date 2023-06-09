//SPDX-License-Identifier: Unlicense
//Author: Goldmember#0001
                                                                                
// Inhabitants                                       ///                  
//                                            ,//////////////              
//                                           //////////////////            
//                                           ///////////////////           
//                                           ////////////////////          
//                                   %%      ////////////////////          
//                              #%%%%%%%      //////////////////           
//                               %%%%%%%%      ,///////////////            
//                            #, %%%%%%%%%        ///////////              
//                          #### %%%%%%%%%%                                
//                         #####  %%%%%%             ,,,                   
//                  %%%%  ///     %%   ((((  %%      ,,                    
//              %%%%%%%% ////////  ((((((((  %%%%%%  ,,                    
//         #%%%%%%%%%%%. //////// .(((((((( .%%%%%%% ,,                    
//      %%%%%%%%%%%%%%%  ////////  (((((((( %%%%%%%. ,, %%%                
//        %%%%%%%%%%%%%%   //////  (((((  %%%%%%%%%%%%%%%(                 
//     #####  %%%%%%%%%%%%%%%   /  (  %%%%%%%%%%%%%%%   ******             
//     #########  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  **********              
//     ############(  %%%%%%%%%%%%%%%%%%%%%%%  **************              
//     #################   %%%%%%%%%%%%%%%  *****************              
//     #####################   %%%%%%#  *********************              
//     #########################    *************************              
//     ##########################  **************************              
//    (########################## .**************************              
//      (######################## *************************                
//          *#################### *********************                    
//               ################ *****************                        
//                   ############ *************                            
//                        ####### **********                               
//                             ## ****** 


pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

// errors
error nothingToWithdraw();
error tokenDoesNotExist();

contract LykeInhabitants is ERC721A, IERC2981, Ownable {
    using Address for address;
    using ECDSA for bytes32;

    // collection details
    uint256 public constant PRICE = 0.06 ether; 
    uint256 public constant COLLECTION_SIZE = 3000;
    uint64 public constant MAX_MINTS_PER_PUBLIC_TX = 2;

    uint256 private royaltiesPercentage; // represents a percentage like 3 = 3%
    address public royaltiesAddress;

    // ECDSA
    address public signingAddress;

    // variables and constants
    string public baseURI = "nft://sorryDetective/";
    bool public isPublicMintActive = false;
    mapping(address => bool) public addressClaimMap;
    uint256 public maxReserveMintRemaining;

    constructor(
        address _signerAddress,
        address _royaltiesAddress,
        uint256 _royaltiesPercentage,
        uint256 _maxReserveMintRemaining
    ) 
    ERC721A("Lyke Inhabitants", "LYKEIN") 
    {
        signingAddress = _signerAddress;
        royaltiesAddress = _royaltiesAddress;

        maxReserveMintRemaining = _maxReserveMintRemaining;

        royaltiesPercentage = _royaltiesPercentage;

        isPublicMintActive = false;
        _startTokenId();
    }

    function verifySig(address _sender, uint256 _freeQuantity, uint256 _paidQuantity, uint256 _price, uint256 _saleStartTs, bytes memory _signature) 
        internal view returns(bool) 
    {
        bytes32 messageHash = keccak256(abi.encodePacked(_sender, _freeQuantity, _paidQuantity, _price, _saleStartTs));
        return signingAddress == messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /*
    * @dev Mints for public sale
    */
    function publicMint(uint256 _quantity) 
        external payable 
    {
        require(isPublicMintActive, "publicMintNotActive()");   
        require(msg.value == _quantity * PRICE, "insufficientPaid()");  
        require(_quantity <= MAX_MINTS_PER_PUBLIC_TX, "tooManyTokensPerTx()");    
        require(_quantity + totalSupply() <= COLLECTION_SIZE, "soldOut()");

        // mint
        _safeMint(msg.sender, _quantity);
    }

    /*
    * @dev Mints free amounts and paid amounts if sale has started. 
    */
    function saleMint(uint256 _freeQuantity, uint64 _paidQuantity, uint256 _price, uint256 _saleStartTs, bytes calldata _signature)
        external payable
    {
        require(verifySig(msg.sender, _freeQuantity, _paidQuantity, _price, _saleStartTs, _signature), "incorrectSignature");
        require(msg.value == _paidQuantity * _price, "insufficientPaid()");
        require(_paidQuantity + _freeQuantity + totalSupply() <= COLLECTION_SIZE, "soldOut()");
        require(_saleStartTs <= block.timestamp, "saleNotStarted()");
        require(!addressClaimMap[msg.sender], "saleAlreadyClaimed()");

        // mint and update mapping
        addressClaimMap[msg.sender] = true;
        _safeMint(msg.sender, _paidQuantity + _freeQuantity);
    }

    /*
    * @dev Mints a limited quantity into the community wallet
    */
    function reservedMint(uint256 _quantity) external onlyOwner {
        require(_quantity + totalSupply() <= COLLECTION_SIZE, "soldOut()");
        require(maxReserveMintRemaining >= _quantity, "soldOut()");

        // mint to first party wallet
        maxReserveMintRemaining -= _quantity;
        _safeMint(owner(), _quantity);
    }

    /*
    * @dev Sets the signer for ECDSA validation
    */
    function setSigningAddress(address _address) external onlyOwner {
        signingAddress = _address;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function togglePublicMint() public onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    } 

    function setRoyaltiesAddress(address _newAddress) public onlyOwner {
        royaltiesAddress = _newAddress;
    }

    function withdrawBalance() public onlyOwner {
        if(address(this).balance == 0) revert nothingToWithdraw();

        payable(owner()).transfer(address(this).balance);
    }

    // ERC165

    function supportsInterface(bytes4 _interfaceId) 
        public view override(ERC721A, IERC165) returns (bool) 
    {
      return _interfaceId == type(IERC2981).interfaceId 
        || super.supportsInterface(_interfaceId);
    }

    // IERC2981

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
      if(!_exists(_tokenId)) revert tokenDoesNotExist();
      royaltyAmount = (_salePrice / 1000) * royaltiesPercentage;
      return (royaltiesAddress, royaltyAmount);
    }

    // OVERRIDES

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

}