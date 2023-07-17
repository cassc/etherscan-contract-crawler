// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
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

contract METAVATARS is ERC721Enumerable, PaymentSplitter, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public _tokenIdCounter;

    uint256 public constant MAX_TOTAL_SUPPLY = 7777;
    uint256 public constant MAX_MINT_PER_RAFFLE_SALE_WALLET = 4;
    uint256 public MAX_MINT_PER_PUBLIC_SALE_WALLET = 4;
    uint256 public constant RAFFLE_SALE_PRICE = 0.33 ether; 
    uint256 public PUBLIC_SALE_PRICE = 0.33 ether; 
    uint256 public constant MAX_MINT_PRICE = 1.2 ether;
    uint256 public MAX_MINT_PUBLIC_PRICE = 1.2 ether;

    string public baseURI;
    string public legendaryBaseUri;
    string public soonBaseUri;

    bool public legendaryReveal = false;
    bool public officialReveal = false;

    enum currentStatus {
        Before,
        PrivateSale,
        PublicSale,
        SoldOut, 
        Pause
    }

    currentStatus public status;

    address private _owner;
    address[] private contributors = [0x00FEF5e48159d94e80C5209FD46beF5F1AC4f3C8,
                                        0x2211210B50c2691712CFa66DCF57944c2a86F559, 
                                        0x9FC332c8d51a353c453e60776b0531779a480B35,
                                        0x4054488E49A07ea84f1f9EA62ac6C7ee915b6C5C,
                                        0x2944c28A0edAB0727cAf102Bef961CC7864eb04a,
                                        0xF2A6333EF506DEf8100854BBeE0E7d0D8c25822B,
                                        0xfFb1023d45087A217690eDCB8642DdbD548519c3,
                                        0xF173C71309688637296AEc5CBD097f62f679Ab03,
                                        0x1511719f5011c4F9C035C4B3bBc89053d71d97E7,
                                        0x04b025847C00Cd337A1B745d71f57aAb84ABF561,
                                        0x48aE356Fb7f429754aB6469CDd92D62f6642a473,
                                        0x56C91e628b93323c1b78E40F396c9Eb8049983C3,
                                        0xDFe5AE84704bBf69c179Bb51B4F9Aa784620cDF5,
                                        0xEC900CF111a48a6874fEf9248619C730b166b228,
                                        0xE07E4B926454Eb84C80eA26B5C855616CE78d5bE,
                                        0x6406459a3CFC8EF866b5522dc2527e5abB6E1210,
                                        0x67982E9166dCef4D24B0aF0D4f0Dd2b8df70E70E,
                                        0x44764Cc3A81695Ee5D3265B85F41D6B79C8F7522
                                    ];
    uint256[] private sharesContributors = [5350, 500, 500, 500, 500, 500, 500, 300, 200, 200, 200, 200, 100, 100, 100, 100, 100, 50];

    mapping(address => uint256) public tokensPerWallet;

    bytes32 public privatelistRootTree;

    event liveMinted(uint256 nbMinted);

    constructor( 
        string memory _initSoonBaseURI,
        bytes32 privatelistMerkleRoot
    ) ERC721("METAVATARS", "MA") PaymentSplitter(contributors, sharesContributors) {
        status = currentStatus.Before;
        setSoonBaseURI(_initSoonBaseURI);
        privatelistRootTree = privatelistMerkleRoot;
    }

    function getCurrentStatus() public view returns(currentStatus) {
        return status;
    }

    function getActualPrice() public view returns(uint256 actualPrice){
        if (status == currentStatus.PrivateSale){
            actualPrice = RAFFLE_SALE_PRICE;
            return actualPrice;
        }
        if (status == currentStatus.PublicSale){
            actualPrice = PUBLIC_SALE_PRICE;
            return actualPrice;
        }
    }

    function setInPause() external onlyOwner {
        status = currentStatus.Pause;
    }

    function startPrivateSale() external onlyOwner {
        status = currentStatus.PrivateSale;
    }

    function startPublicSale() external onlyOwner {
        status = currentStatus.PublicSale;
    }

    function setLegendaryReveal() public onlyOwner {
        legendaryReveal = true;
    }

    function setOfficialReveal() public onlyOwner {
        legendaryReveal = false;
        officialReveal = true;
    }

    function setSoonBaseURI(string memory _soonBaseURI) public onlyOwner {
        soonBaseUri = _soonBaseURI;
    }

    function setLegendaryBaseURI(string memory _legendaryBaseURI) public onlyOwner {
        legendaryBaseUri = _legendaryBaseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function leafMerkle(address accountListed) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(accountListed));
    }

    function verifyPrivatelistLeafMerkle(bytes32 leafPrivatelist, bytes32[] memory proofPrivateMerkle) internal view returns(bool) {
        return MerkleProof.verify(proofPrivateMerkle, privatelistRootTree, leafPrivatelist);
    }

    function isPrivateListed(address account, bytes32[] calldata proofPrivateMerkle) public view returns(bool){
        return verifyPrivatelistLeafMerkle(leafMerkle(account), proofPrivateMerkle);
    }

    function setPrivateList(bytes32 privateList_) public onlyOwner {
        privatelistRootTree = privateList_;
    }

    function setPublicSaleMaxWallet(uint256 maxMintPublicSaleWallet_) public onlyOwner {
        MAX_MINT_PER_PUBLIC_SALE_WALLET = maxMintPublicSaleWallet_;
    }

    function setPublicSalePrice(uint256 publicSalePrice_) public onlyOwner {
        PUBLIC_SALE_PRICE = publicSalePrice_;
    }

    function setPublicMAXPrice(uint256 publicMaxPrice_) public onlyOwner {
        MAX_MINT_PUBLIC_PRICE = publicMaxPrice_;
    }

    function privateSaleMint (bytes32[] calldata proofPrivateMerkle, uint32 amount) external payable {
        uint256 totalSupply = totalSupply();
        require(status != currentStatus.SoldOut, "METAVATARS: We're SOLD OUT !");
        require(status == currentStatus.PrivateSale, "METAVATARS: Private Sale is not Open !");
        if (amount <= 3) {
        require(msg.value >= RAFFLE_SALE_PRICE * amount, "METAVATARS: Insufficient Funds !");
        } else if (amount == 4) {
        require(msg.value >= MAX_MINT_PRICE, "METAVATARS: Insufficient Funds !");
        }
        require(isPrivateListed(msg.sender, proofPrivateMerkle), "METAVATARS: You're not Eligible for the Private Sale !");
        require(amount <= MAX_MINT_PER_RAFFLE_SALE_WALLET, "METAVATARS: Max 4 Tokens mint at once !");
        require(totalSupply + amount <= MAX_TOTAL_SUPPLY, "METAVATARS: You're mint amount is too large for the remaining tokens !");
        require(tokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_RAFFLE_SALE_WALLET, "METAVATARS: Max 4 Tokens Mintable per Wallet !");

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

    function publicSaleMint (uint32 amount) public payable {
        uint256 totalSupply = totalSupply();
        require(status != currentStatus.SoldOut, "METAVATARS: We're SOLD OUT !");
        require(status == currentStatus.PublicSale, "METAVATARS: Public Sale is not Open !");
        require(msg.value >= PUBLIC_SALE_PRICE * amount, "METAVATARS: Insufficient Funds !");
        require(amount <= MAX_MINT_PER_PUBLIC_SALE_WALLET, "METAVATARS: Max Tokens mint at once !");
        require(totalSupply + amount <= MAX_TOTAL_SUPPLY, "METAVATARS: You're mint amount is too large for the remaining tokens !");
        require(tokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_PUBLIC_SALE_WALLET, "METAVATARS: Max Tokens Mintable per Wallet !");

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
        require(amount > 0, "METAVATARS: Need to gift 1 METAVATARS min !");
        require(totalSupply + amount <= MAX_TOTAL_SUPPLY, "METAVATARS: You're mint amount is too large for the remaining tokens !");

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
        if (officialReveal == false && legendaryReveal == false) {
            return soonBaseUri;
        }

        if (officialReveal == false && legendaryReveal == true) {
            string memory currentLegendaryBaseURI = legendaryBaseUri;
            return bytes(currentLegendaryBaseURI).length > 0 ? string(abi.encodePacked(currentLegendaryBaseURI, tokenId.toString())) : "";
        }

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