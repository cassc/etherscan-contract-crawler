// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./extensions/ERC721AQueryable.sol";

import "./TeamAccess.sol";
import "./ITokenURIInterface.sol";
import "./DefaultOperatorFilterer.sol";
import "hardhat/console.sol";

contract ClosePaPremiumPass is ERC721AQueryable ,ERC2981 ,TeamsAccess ,DefaultOperatorFilterer  {

    using Strings for uint256;

    uint256 public maxSupply    = 1500;
    uint96  constant private DEFAULT_ROYALTYFEE = 1000; // 10%

    uint256 private prePrice     = 0.025 ether;//presale price.
    uint256 private publicPrice  = 0.025 ether;//publicSale price.

    enum SaleState { NON, NOT/*1*/, PRE/*2*/,PAUSE/*3*/ , PRE2/*4*/, PUB/*5*/, FIN /*6*/} // Enum
    SaleState public saleState = SaleState.NOT;

    uint256 private max_Mint_AL    = 2;
    uint256 private max_Mint_AL2nd_Total = 5;
    uint256 private _maxMintOwner = 100;
    uint256 constant private _max_mint_PER_TX = 5;

    mapping(address => uint256) private _MintedAL;
    mapping(address => uint256) private _MintedAL2nd;
    uint256 private MintedOwner;

    string private baseTokenURI;
    string constant private uriExt = ".json";

    bool public externalContractEn = false;
    ITokenURIInterface public tokenURIContract;

    bytes32 public merkleRoot;

    struct HoldStatus {
        uint256 startTime;
        uint256 minted;
    }

    string private _contractURI;

    mapping(uint256 => HoldStatus) private holdStatus;
    uint256 private constant ONE_DAY = 1 days; // for production

    address internal constant TEAM_ADDRESS1 = address(0x1d1b1e30a9d15dBA662f85119122e1D651090434);

    constructor() ERC721A("ClosePaPremiumPass", "CPP") {
        _contractURI = "data:application/json;base64,eyJzZWxsZXJfZmVlX2Jhc2lzX3BvaW50cyI6MTAwMCwgImZlZV9yZWNpcGllbnQiOiIweDFkMWIxZTMwYTlkMTVkQkE2NjJmODUxMTkxMjJlMUQ2NTEwOTA0MzQifQ==";
        setAccess(msg.sender,true);
        setAccess(TEAM_ADDRESS1,true);
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTYFEE);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyTeam {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _prePrice,uint256 _publicPrice) external onlyOwner {
        prePrice = _prePrice;
        publicPrice = _publicPrice;
    }
    function getCurrentPrice() public view returns(uint256) {
        if(SaleState.PRE2 >= saleState){
            return prePrice;
        }else{
            return publicPrice;
        }
    }

    function setMaxSupply(uint256 _maxSupply) external virtual onlyOwner {
        require(totalSupply() <= _maxSupply);
        maxSupply = _maxSupply;
    }

    function getMaxMints() external view virtual
    returns (uint256 ,uint256 ,uint256) 
    {
        //AL1st
        //AL2nd
        //Owner
        return (max_Mint_AL,
                max_Mint_AL2nd_Total - max_Mint_AL,
                _maxMintOwner);
    }

    function setBaseURI(string memory uri) external virtual onlyTeam {
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

    // public mint
    function publicMint(uint256 _amount) external 
    payable {
        require(saleState == SaleState.PUB, "Publicsale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = publicPrice * _amount;

        require(_amount <= _max_mint_PER_TX && _amount > 0 && supply + _amount <= maxSupply, "Invalid mint amount!");
        //require(supply + _amount <= maxSupply,"max supply over");
        require(msg.value >= cost, "ETH value is not correct");

        _safeMint(msg.sender, _amount);
    }

    function preMint(uint256 _amount, bytes32[] calldata _merkleProof) external 
    payable {
        require(saleState == SaleState.PRE || saleState == SaleState.PRE2, 
                "Presale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = prePrice * _amount;

        require(_amount > 0 && supply + _amount <= maxSupply, "Invalid mint amount!");
        //require(supply + _amount <= maxSupply,"max supply over");
        require(msg.value >= cost, "ETH value is not correct");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require(_MintedAL[msg.sender] + _amount <= 
            (saleState == SaleState.PRE ? max_Mint_AL : max_Mint_AL2nd_Total),
            "Over max minted");

        _safeMint(msg.sender, _amount);
        _MintedAL[msg.sender]+=_amount;
    }

    function ownerMint(address _transferAddress, uint256 _amount) external onlyOwner {
        require(_maxMintOwner >= MintedOwner + _amount);
        _safeMint(_transferAddress, _amount);
        MintedOwner+=_amount;
    }

    function setMintPhaseMax(uint256 _mintAL, uint256 _mintAL2nd) external virtual onlyOwner {
        max_Mint_AL = _mintAL;
        max_Mint_AL2nd_Total = _mintAL2nd + _mintAL;
    }

    function setOwnerMax(uint256 _max) external virtual onlyOwner {
        _maxMintOwner = _max;
    }

    function setNextSale() external virtual onlyTeam {
        require(saleState < SaleState.FIN);
        saleState = SaleState(uint256(saleState) + 1);
    }

    function setSaleState(uint256 _state) external virtual onlyTeam {
        //1:Not Sale, 2:PreSale1, 3:PreSale2, 4:PublicSale, 5:Fin /*5*/
        require(_state <= uint256(SaleState.FIN));
        saleState = SaleState(uint256(_state));
    }

    //for ERC2981 Opensea
    function contractURI() external view virtual returns (string memory) {
        return _contractURI;
    }
    //make contractURI
    function setContractURI(string memory _uri) external virtual {
        _contractURI = _uri;
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

    function getHoldStatus(uint256 _tokenId) public view virtual returns (uint256,uint256){
        require( _exists(_tokenId));
        uint256 _holdDay = (block.timestamp - holdStatus[_tokenId].startTime) / ONE_DAY;
        return (_holdDay,holdStatus[_tokenId].minted);
    }

    function getHoldToken(uint256 _days) public view virtual returns (uint256[] memory){
        require(_days > 0);
        uint256[] memory _tokenlist = new uint256[](maxSupply);
        uint256 listIndex;
        for(uint256 id = 1; id <= maxSupply; id++)
        {
            uint256 holdDay = (block.timestamp - holdStatus[id].startTime) / ONE_DAY;
            if (_days >= holdDay){
                _tokenlist[listIndex++] = id;
            }
        }
        return _tokenlist;
    }
    
    function setExtContract(address _addr, bool _enable) external onlyOwner{
        tokenURIContract = ITokenURIInterface(_addr);
        externalContractEn = _enable;
    }

    function setMinted(uint256 tokenId, uint256 minted) external onlyTeam{
        HoldStatus storage HS = holdStatus[tokenId];
        HS.minted = minted;
    }

    function _beforeTokenTransfers(address from,address to,uint256 startTokenId,uint256 quantity) internal virtual override(ERC721A) {
        for(uint256 i = 0;i<quantity;i++)
        {
            HoldStatus storage HS = holdStatus[startTokenId + i];
            HS.startTime = block.timestamp;
            HS.minted = 0;
        }
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
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC721A,ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}