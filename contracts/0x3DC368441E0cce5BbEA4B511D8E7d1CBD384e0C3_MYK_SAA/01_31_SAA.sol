// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
                 &#GP5YYJJJJ?JJJJJY5PB#&                    
              #G55PPY??????777!!77!!!7?JYP#&                
           &GY??B    #J?????77JB&&#5~~7JPGP5G#              
         #PJ????G    BJ??????7#     J~^^~JB &BB&            
       &PJ??J5YJ?J55Y?????YY?7JG##B5!!~~^::J   &@           
      #Y???JB  &BGY?????YB  &BPY?77!!!!~~^^:7&              
     #J?J??B     #Y?J??P       #577777!!!~~^:Y     &        
    &JJJ??5     BJ?J??G      &5????7777!!!~~^7     ##       
    55Y??J#    BJ?J??G      GJ??????77777!!!~?     BY       
   #PG?J?Y    &J?JJ?P     &5??????????7777!!!B     5?B      
   B&5?J?5   @G?JJ?J     &Y????????????777!7G     5~JP      
   & 5?J?5   Y?JJ?P    @5?JJJ??????????77Y#     5~~J5      
   &  ??Y&   Y?JJ?B    B??JJJJ?????????YB     BJ!!!JP      
   :  :J?B   Y?J??B   @5?JJJJJ?????JYG&     BY?77!?JB      
       u&GP   5????   &J??????JJYPB&     &G5JJ???JJ5       
     #        #5YYJP  @&YY55PGB#&     &#BPYYYYJJJYYY#       
      ###&&                       &#BGP555555YYYYYYB        
       ######&  &&&&   @@&&&##BBGPPPPPPP5555555YY5#         
        &###BB&  BBBB  #GGGGGPPPPPPPPPPP5555555G&          
          &#BBB#  BBB&  BGGGGGGPPPPPPPPPP5555G#            
            &##B#& BBBB& &GGGGGGGGPPPPPPP55PB&              
               &### #BBB# #GGGGGGGPPPPPPGB&                 
                  && ##BB# BGGGGGGGBB#&                     
                         &@@&&&&@@@*/

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  *
 * .d8888b.  888                            8888888b.           *
 *d88P  Y88b 888                            888   Y88b          *
 *888    888 888                            888    888          *
 *888        888  .d88b.  .d8888b   .d88b.  888   d88P 8888b.   *
 *888        888 d88""88b 88K      d8P  Y8b 8888888P"     "88b  *
 *888    888 888 888  888 "Y8888b. 88888888 888       .d888888  *
 *Y88b  d88P 888 Y88..88P      X88 Y8b.     888       888  888  *
 * "Y8888P"  888  "Y88P"   88888P'  "Y8888  888       "Y888888  *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  */


//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

//import "./TeamAccess.sol";
import "./ITokenURIInterface.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "hardhat/console.sol";

contract MYK_SAA is ERC721AQueryable ,ERC2981 ,AccessControl , Ownable2Step, DefaultOperatorFilterer  {

    using Strings for uint256;

    uint256 public maxSupply    = 800;
    uint96  constant private DEFAULT_ROYALTYFEE = 1000; // 10%

    uint256 private prePrice     = 0.005 ether;//presale price.
    uint256 private pubPrice     = 0.007 ether;

    enum SaleState { NON, NOT/*1*/, PRE/*2*/ , PUB /*3*/,  FIN /*4*/} // Enum
    SaleState public saleState = SaleState.NOT;

    mapping(address => uint256) private _MintedAL;
    uint256 private MintedOwner;

    string private baseTokenURI;
    string constant private uriExt = ".json";

    bool public externalContractEn = false;
    ITokenURIInterface public tokenURIContract;

    bytes32 public merkleRoot;

    address internal constant TEAM_ADDRESS1 = address(0x1d1b1e30a9d15dBA662f85119122e1D651090434);

    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    constructor() ERC721A("MIYAKO_SAA", "MYKSAA") {
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTYFEE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEAM_ROLE, TEAM_ADDRESS1);
        _setupRole(TEAM_ROLE, msg.sender);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(TEAM_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function getCurrentPrice() public view returns(uint256) {
        if(saleState <= SaleState.PRE){
            return prePrice;
        }
        return pubPrice;
    }

    function setMaxSupply(uint256 _maxSupply) external virtual onlyOwner {
        require(totalSupply() <= _maxSupply);
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory uri) external virtual onlyRole(TEAM_ROLE) {
        baseTokenURI = uri;
    }

    function _baseURI() internal view override
    returns (string memory) {
        return baseTokenURI;
    }

    //start from 1.djust for bueno.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function preMint(uint256 _amount ,uint256 _allowedMaxMint ,bytes32[] calldata _merkleProof) external 
    payable {
        require(saleState == SaleState.PRE, "Presale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = prePrice * _amount;

        require(_amount > 0 && supply + _amount <= maxSupply, "Invalid mint amount!");
        require(msg.value >= cost, "ETH value is not correct");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _allowedMaxMint));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(_MintedAL[msg.sender] + _amount <= _allowedMaxMint, "Over max minted");

        _safeMint(msg.sender, _amount);
        _MintedAL[msg.sender]+=_amount;
    }

    function publicMint(uint256 _amount) external 
    payable {
        require(saleState == SaleState.PUB , "Publicsale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = pubPrice * _amount;

        require(_amount > 0 && supply + _amount <= maxSupply , "Invalid mint amount!");
        require(msg.value >= cost, "ETH value is not correct");
        _safeMint(msg.sender, _amount);
    }

    function ownerMint(address _transferAddress, uint256 _amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply);
        _safeMint(_transferAddress, _amount);
        MintedOwner+=_amount;
    }

    function setNextSale() external virtual onlyRole(TEAM_ROLE) {
        require(saleState < SaleState.FIN);
        saleState = SaleState(uint256(saleState) + 1);
    }

    function setSaleState(uint256 _state) external virtual onlyRole(TEAM_ROLE) {
        require(_state <= uint256(SaleState.FIN));
        saleState = SaleState(uint256(_state));
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A,IERC721A) returns (string memory){
        require( _exists(tokenId), "token does not exist" );
        return !externalContractEn ? 
        string(abi.encodePacked(_baseURI(), tokenId.toString() ,uriExt))
        : tokenURIContract.createTokenURI(tokenId);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function setRoyaltyFee(uint96 _fee ,address _royaltyAddress) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _fee);
    }

    function setExtContract(address _addr, bool _enable) external onlyOwner{
        tokenURIContract = ITokenURIInterface(_addr);
        externalContractEn = _enable;
    }

    function _beforeTokenTransfers(address from,address to,uint256 startTokenId,uint256 quantity) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
    
    function setApprovalForAll(address operator, bool approved) 
    public override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A,IERC721A)
        payable 
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC721A,ERC721A,ERC2981,AccessControl) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}