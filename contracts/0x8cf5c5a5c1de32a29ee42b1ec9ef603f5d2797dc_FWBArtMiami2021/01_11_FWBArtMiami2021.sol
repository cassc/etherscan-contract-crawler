pragma solidity >=0.6.2 <0.8.0;

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
                                                                                          
/*
                                                            :=-::--                       
                                                           +-     .+=                     
                                                           #=---+=  ==                    
                            .-==:                               .#   #                    
                           =-   :#:                              +.  #                    
                          =:     #:                              =-  #  ..                
                     .:. :=    .+-                               =-  #==:.*               
                    +-.# *   -+-                                 =: :*. .=:               
                   -= :+=: -+:                                   *.   .-:                 
                   =- .=- +-.==*.                                #   :+---                
                   =-   .-#=+.=+                          .:::: :*   ::  *:               
               .++.=:   .=-::=+.                          .=-::-*=    .==.                
               -- -=   .*      =-                        :=      *. -**                   
               .+ =--  +. -:    =.                       =    :-..* =:                    
                *. .:::+-#=%*   .-.:------:    :------:.-:   *%=#-+:=:.                   
     .-==---------=-     **=.   =+:-::.   .=-=+.   .::-:+=   .=+#     :=---------==-.     
    +-    :--.    =    .-+-    :+   :=:*.  :*#:  .*:=-   +:    :*-.    =    .--:    -+    
   --  .=* .#.     =-. -#%+-:-=-   .*==-   *:-*   -==*.   -=-:-+%#- .-=     .#: +=.  -:   
    -+.  .=*.*-     :===+.+=.     :#-=.  .*:  :*:  .=:#:     .-+.+===:     -*.*=.  .+-    
      -=-  .-+=*:       : ..     =*=-  .+*-:-::-*+:  -=*=      . :       :*=+-.  -=-      
        .#=-: .:=+-            :*-. :-=--::::::::--=-: .-*:            -+=-. :-=#.        
       :=   .-+--:-+=.        +#=---.                .---=#+        .=+-:--++.  .+.       
      -=     #.   ..:---.   =+.    .:........        :.    .+=    ---:..   +:     *:      
     -=    = *-         :--=.        =:   .......::=+        .=--:         # +-    *.     
    .+ -= +*+*:                       -=          =-                       =+=#..#..*     
    + =*::* =+                         :*        *:                         =.:* +=--:    
    +=.+:*  *                           :*      *:                           * :+*..=.    
       +*+:.+                            -+    +-                            +::+==       
          **-                             #   .#                             -**          
           #-                             *.  .*                             -#           
           -+                            .*    *:                            +-           
            =-                          =+      +=                          -=            
             :=:                     :==.        .==:                     :=:             
               .---=-:..     ..:-----.              .-----:..     ..:-=---.               
                   =:..::::::...:=                      =: ..::::::..:+                   
                    +           =:                      :=           +                    
                     +       .::#==-----:        :-----==#-:.       =.                    
            .:::=++=--::.       ..:----:..      ..:----::.       .::--=++=:::.            
            .::::                                                        .:::.            
                                                                                          
           :#############*  +%%%####=    =##-   -#%%#+   +#########*+=.                   
           [email protected]@%++++++++++= *+++++%*.     %@@.   %@@%.#@. #@@*+++++*#@@@#.                 
           [email protected]@*                -#-      :@@%     ::   @* #@@:        [email protected]@%                 
           [email protected]@*               *%.       [email protected]@=          *% #@@:         @@@                 
           [email protected]@*             .%@.        @@@.          *# #@@:       :#@@-                 
           [email protected]@@%%%%%%%%%%+ [email protected]@-        [email protected]@#           #= #@@@%%%%%@@@*-                   
           [email protected]@%==========- #@@         %@@+          .%  #@@+======+*%@#=                 
           [email protected]@*           :@@#        +*@@-          #.  #@@:         *@@+                
           [email protected]@*           [email protected]@%       [email protected]@=        .*.   #@@:         [email protected]@#                
           [email protected]@*           [email protected]@@=     ++ [email protected]@%:     .++     #@@:       [email protected]@@-                
           [email protected]@*            [email protected]@@%++**:   [email protected]@@%#*#%+.      #@@@@@@@@@@@@@*:                 
           .--:              :=+=-. .:    -=+==:         :----------:.                    
                                 .+%@-                                                    
                    -*%+       =##@%.                                                     
                  =#[email protected]+    .+#- #%.    .                            .                    
                -%=  *@.  .*#:  *@.    **.                          +*.                   
               *%.  [email protected]* :#*.   [email protected]          :-.    -#-                                    
             :%#    *@-**.    [email protected]+  .##.   =%*--   *#.  :    -=:  *#.                      
            [email protected]*    :@@#:     :@#  .%+   -%=  ++ .%= :*@@::++%@: %*                        
           [email protected]+     =#-      :@%   %=   #+ :[email protected]+  %--*-:@**- [email protected]: %=                         
           *+              :@%   .=   #%++--=  [email protected]*-  .+:   %:  =                          
                          [email protected]%          .        :          .                              
                         :#+                                                              
*/                                                                                          

contract FWBArtMiami2021 is ERC1155, Ownable {

    uint public price = 0.05 ether;
    uint public maxPerWallet = 2;
    uint public constant editionSize = 300;
    uint public constant reserveSize = 23;
    uint public mintLimit = 0;
    mapping(uint => uint) public amountMintedPerArtist;
    mapping(uint => uint) public reservePerArtist;

    struct WalletMints {
        mapping(uint => uint) mintsPerArtist;
    }
    
    mapping(address => WalletMints) private amountMintedPerWallet;

    constructor() public ERC1155("https://gateway.pinata.cloud/ipfs/QmPuwLFsB7uWKvvxyEzcHpSGPFGyVy1eW83eNPASpqaMPr/{id}.json") {
        // reserve editions from each artist for team
        for (uint i = 1; i <= 8; i++) {
            reservePerArtist[i] = reserveSize;
        }
    }

    function setBaseURI(string memory newUri) public onlyOwner {
        _setURI(newUri);
    }

    function setMintLimit(uint limit) public onlyOwner {
        require(limit <= editionSize, "limit exceeds edition size");
        mintLimit = limit;
    }

    function reserve(address to, uint artist, uint numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0, "mint more than zero");
        require(to != address(0), "dont mint to zero address");
        require(artist > 0 && artist <= 8, "invalid artist");
        require((reservePerArtist[artist] - numberOfTokens) >= 0, "not enough reserve");
        require(amountMintedPerArtist[artist] + numberOfTokens <= editionSize, "no more editions left");
        _mint(to, artist, numberOfTokens, "");
        reservePerArtist[artist] -= numberOfTokens;
        amountMintedPerArtist[artist] += numberOfTokens;
    }

    function withdraw() public onlyOwner {
        uint fwbCut = address(this).balance * 30/100;
        uint devCut = address(this).balance * 10/100;
        uint artistCut = address(this).balance * 75/1000;

        address fwb = 0x33e626727B9Ecf64E09f600A1E0f5adDe266a0DF;
        address dev = 0xEca3B7627DEef983A4D4EEE096B0B33A2D880429;
        address artist1 = 0x7200eF22d5e2052F8336dcFf51dd08119aFAcE87;
        address artist2 = 0x9011Eb570D1bE09eA4d10f38c119DCDF29725c41;
        address artist3 = 0xea7Fb078acB618F2074b639Ba04f77161Da6Feea;
        address artist4 = 0xD2b783513Ef6De2415C72c1899E6d0dE470787C6;
        address artist5 = 0x518201899E316bf98c957C73e1326b77672Fe52b;
        address artist6 = 0xD3f248C1004CaB5d51Eb50b05829b1614A277c8a;
        address artist7 = 0x3F93dFd9a05027b26997ebCED1762FeE0E1058C0;
        address artist8 = 0x3942c585Afe697394E40df0e4bfe75CB3C5D919e;

        require(payable(fwb).send(fwbCut));
        require(payable(dev).send(devCut));
        require(payable(artist1).send(artistCut));
        require(payable(artist2).send(artistCut));
        require(payable(artist3).send(artistCut));
        require(payable(artist4).send(artistCut));
        require(payable(artist5).send(artistCut));
        require(payable(artist6).send(artistCut));
        require(payable(artist7).send(artistCut));
        require(payable(artist8).send(artistCut));
    }

    function name() public pure returns (string memory) {
        return "FWB.art Miami Basel 2021";
    }

    function symbol() public pure returns (string memory) {
        return "FWBART";
    } 

    function mint(uint artist, uint numberOfTokens) public payable {
        require(mintLimit > 0, "minting not active");
        require(tx.origin == msg.sender && msg.sender != address(0), "no contracts pls");
        require(artist > 0 && artist <= 8, "invalid artist");
        require(numberOfTokens > 0 && numberOfTokens <= 2, "invalid token amount");
        require(msg.value >= price.mul(numberOfTokens), "invalid eth amount");
        require(amountMintedPerArtist[artist] + numberOfTokens <= (mintLimit - reservePerArtist[artist]), "no more mints left");
        require(amountMintedPerArtist[artist] + numberOfTokens <= editionSize, "no more editions left");
        require(amountMintedPerWallet[msg.sender].mintsPerArtist[artist] < maxPerWallet, "wallet has minted too many");

        _mint(msg.sender, artist, numberOfTokens, "");
        amountMintedPerArtist[artist] += numberOfTokens;
        amountMintedPerWallet[msg.sender].mintsPerArtist[artist] += numberOfTokens;
    }
}