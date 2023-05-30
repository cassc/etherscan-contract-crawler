// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


// ************************ @author: THE ARCHITECT // ************************ //
/*                                    ,                                           
                          %%%%%%%%%%%%     (%%%%%%%%%&/                         
                     %%%%%%%%%  %%%%%%.    (%%%%,   #%%&&&&(                    
                    (%%%%%% #%%% %%%%%.   #%%%%%#  %%%%%&&&&                    
             .%%     /%%%%%%%###(#####.    ######### %%%%%%      ##             
           /%%%%%(     %%%##((((((,          ,(((((((##%%,    /%%%%%%%#         
          %%%%%%%%%(    .##(.                       .(##     %%%%%%%%%%%        
       *%%%,/%%%%%%###                                     %%%%%( # %%%%%%      
      %%%%%/*%%% ###*         #%%%%%%%%%%%%%%%%%%%(        .###%%( %#.%%%%%#    
    (%%%%%%,*# ((/        %%%%%%%%%%%%%%%%%%%%%%%%%%%%#       .(((# %%%%%%%%,   
    %%%%%%###(((,      (%%%%%%%%%%%%.         ,%%%%%%%%%%%      (((##%%%%%%%%   
          ,#(((      #%%%%%%%%%(                   ,%%%%%%%%     ((####         
                    %%%%%%%%%         /%%%%%%%/        %%%%%%               *./  
 %%%%%%%%%%/,      %%%%%%%%       #%%%%%%%%%%%%%%%%/     #%%%%,     .%%%%%%%%%%/
 %%%%%%%%%%#*     %%%%%%%%      %%%%%%%%%%%%%%%%%%%%%.     %%%%    *##%%%%%%%%%%
 %%%%%,,%%##(    .%%%%%%%     ,%%%%%%%%%%%%%%%%%%%%%%%/     %%%/   *###   // %%%
%%%%%  %%#(((    ,%%%%%%#     %%%%%%%%%%%Q%%%%%%%%%%%%%      %%/   (((( ,%%% %%%
%%%%%     ,#*    .#######     %%%%%%%%%%%%%%%%%%%%%%%%%       %/   *((#%%%%* %%%
 %%%%%%%%%%##     ########    (%%%%%%%%%%%%%%%%%%%%%%%%       %    *###%%%%%%&&%
 *&&&%%/           ########    (#%#############%%%%%%%%      #.         #%%%&&& 
                    #########*   *#######*##########%%                          
        ,,%###((     ,##########((((((((((((((######/            ##%%%%%%.      
    .%%%%%%%###((.      ###((((((((((((((((((((((#(            *(###%%%%%%%%,   
     (%%  ,  ,,((((.       /((((((((((((((((((((             /(((#%%%  %%%%%    
      /%%% %%%( ####(*           /((((((((/                (((((##%  ,%%%%%     
        %%%*%/%%%%%%#(                                      (####%%%%%%%%%/      
          %%%%%%%%      ((((((*.                   (####.     %%%%%%%%%#        
             #%%%     .####(((((((####     ((((((/(#,%%%%%      #%%%%           
                     /%%%%% #%%## /%##.    ####  % %% %%%%%%                    
                    (%%%%%%%%%    %%%%.    %%%%.(%% %% %%%%%                    
                      %%%%%%%%%%%%%%%%    %%%%%%,*%%%%%%%%%                     
                             %%%%%%%%     %%%%%%%%                                   
*/
// *************************************************************************** //

contract CONSORTIUM is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public _tokenIdCounter;

    uint256 public constant MAX_TOTAL_SUPPLY = 777;
    uint256 public constant PRICE = 0 ether; 
    uint256 public MAX_MINT_PER_WALLET = 1;

    string public baseURI;

    enum currentStatus {
        Before,
        OwnersMint,
        SoldOut, 
        Pause
    }

    currentStatus public status;
    address private _owner;    
    
    mapping(address => uint256) public tokensPerWallet;
    bytes32 public ownersRootTree;

    constructor( 
        string memory _initBaseURI,
        bytes32 ownersListMerkleRoot
    ) ERC721("CONSORTIUM STONE", "CS") {
        status = currentStatus.Before;
        setBaseURI(_initBaseURI);
        ownersRootTree = ownersListMerkleRoot;
    }

    function getCurrentStatus() public view returns(currentStatus) {
        return status;
    }

    function setInPause() external onlyOwner {
        status = currentStatus.Pause;
    }

    function startOwnersMint() external onlyOwner {
        status = currentStatus.OwnersMint;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function leafMerkle(address accountListed) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(accountListed));
    }

    function verifyPrivatelistLeafMerkle(bytes32 leafPrivatelist, bytes32[] memory proofPrivateMerkle) internal view returns(bool) {
        return MerkleProof.verify(proofPrivateMerkle, ownersRootTree, leafPrivatelist);
    }

    function isPrivateListed(address account, bytes32[] calldata proofPrivateMerkle) public view returns(bool){
        return verifyPrivatelistLeafMerkle(leafMerkle(account), proofPrivateMerkle);
    }

    function setPrivateList(bytes32 privateList_) public onlyOwner {
        ownersRootTree = privateList_;
    }

    function setMaxWallet(uint256 maxMintWallet_) public onlyOwner {
        MAX_MINT_PER_WALLET = maxMintWallet_;
    }

    function consortiumMint (bytes32[] calldata proofPrivateMerkle, uint32 amount) external {
        uint256 totalSupply = totalSupply();
        require(status != currentStatus.SoldOut, "METAVATARS CONSORTIUM STONE: We're SOLD OUT !");
        require(status == currentStatus.OwnersMint, "METAVATARS CONSORTIUM STONE: Owners Mint is not Open !");
        require(isPrivateListed(msg.sender, proofPrivateMerkle), "METAVATARS CONSORTIUM STONE: You're not Eligible for the Private Mint !");
        require(amount <= MAX_MINT_PER_WALLET, "METAVATARS CONSORTIUM STONE: Max Stone mint at once !");
        require(totalSupply + amount <= MAX_TOTAL_SUPPLY, "METAVATARS CONSORTIUM STONE: You're mint amount is too large for the remaining tokens !");
        require(tokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET, "METAVATARS CONSORTIUM STONE: Max Stone Mintable per Wallet !");

        tokensPerWallet[msg.sender] += amount;
        uint256 amountNb = amount;
        for (uint256 i = 1; i <= amountNb; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current()); 
        }
        if (totalSupply + amount == MAX_TOTAL_SUPPLY){
            status = currentStatus.SoldOut;
        }
    }

    function gift(uint256 amount, address giveawayAddress) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(amount > 0, "METAVATARS CONSORTIUM STONE: Need to gift 1 min !");
        require(totalSupply + amount <= MAX_TOTAL_SUPPLY, "METAVATARS CONSORTIUM STONE: You're mint amount is too large for the remaining tokens !");

        uint256 amountNb = amount;
        for (uint256 i = 1; i <= amountNb; i++) {
            _tokenIdCounter.increment();
            _safeMint(giveawayAddress, _tokenIdCounter.current()); 
        }
        if (totalSupply + amount == MAX_TOTAL_SUPPLY){
            status = currentStatus.SoldOut;
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }
}




// ************************ @author: THE ARCHITECT // ************************ //
/*                                    ,                                           
                          %%%%%%%%%%%%     (%%%%%%%%%&/                         
                     %%%%%%%%%  %%%%%%.    (%%%%,   #%%&&&&(                    
                    (%%%%%% #%%% %%%%%.   #%%%%%#  %%%%%&&&&                    
             .%%     /%%%%%%%###(#####.    ######### %%%%%%      ##             
           /%%%%%(     %%%##((((((,          ,(((((((##%%,    /%%%%%%%#         
          %%%%%%%%%(    .##(.                       .(##     %%%%%%%%%%%        
       *%%%,/%%%%%%###                                     %%%%%( # %%%%%%      
      %%%%%/*%%% ###*         #%%%%%%%%%%%%%%%%%%%(        .###%%( %#.%%%%%#    
    (%%%%%%,*# ((/        %%%%%%%%%%%%%%%%%%%%%%%%%%%%#       .(((# %%%%%%%%,   
    %%%%%%###(((,      (%%%%%%%%%%%%.         ,%%%%%%%%%%%      (((##%%%%%%%%   
          ,#(((      #%%%%%%%%%(                   ,%%%%%%%%     ((####         
                    %%%%%%%%%         /%%%%%%%/        %%%%%%               *./  
 %%%%%%%%%%/,      %%%%%%%%       #%%%%%%%%%%%%%%%%/     #%%%%,     .%%%%%%%%%%/
 %%%%%%%%%%#*     %%%%%%%%      %%%%%%%%%%%%%%%%%%%%%.     %%%%    *##%%%%%%%%%%
 %%%%%,,%%##(    .%%%%%%%     ,%%%%%%%%%%%%%%%%%%%%%%%/     %%%/   *###   // %%%
%%%%%  %%#(((    ,%%%%%%#     %%%%%%%%%%%Q%%%%%%%%%%%%%      %%/   (((( ,%%% %%%
%%%%%     ,#*    .#######     %%%%%%%%%%%%%%%%%%%%%%%%%       %/   *((#%%%%* %%%
 %%%%%%%%%%##     ########    (%%%%%%%%%%%%%%%%%%%%%%%%       %    *###%%%%%%&&%
 *&&&%%/           ########    (#%#############%%%%%%%%      #.         #%%%&&& 
                    #########*   *#######*##########%%                          
        ,,%###((     ,##########((((((((((((((######/            ##%%%%%%.      
    .%%%%%%%###((.      ###((((((((((((((((((((((#(            *(###%%%%%%%%,   
     (%%  ,  ,,((((.       /((((((((((((((((((((             /(((#%%%  %%%%%    
      /%%% %%%( ####(*           /((((((((/                (((((##%  ,%%%%%     
        %%%*%/%%%%%%#(                                      (####%%%%%%%%%/      
          %%%%%%%%      ((((((*.                   (####.     %%%%%%%%%#        
             #%%%     .####(((((((####     ((((((/(#,%%%%%      #%%%%           
                     /%%%%% #%%## /%##.    ####  % %% %%%%%%                    
                    (%%%%%%%%%    %%%%.    %%%%.(%% %% %%%%%                    
                      %%%%%%%%%%%%%%%%    %%%%%%,*%%%%%%%%%                     
                             %%%%%%%%     %%%%%%%%                                   
*/
// *************************************************************************** //