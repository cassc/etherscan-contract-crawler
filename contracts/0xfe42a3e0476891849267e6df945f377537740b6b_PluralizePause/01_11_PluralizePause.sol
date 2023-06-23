// SPDX-License-Identifier: MIT

//   ____  _                 _ _                   ____                      
//  |  _ \| |_   _ _ __ __ _| (_)_______          |  _ \ __ _ _   _ ___  ___ 
//  | |_) | | | | | '__/ _` | | |_  / _ \  _____  | |_) / _` | | | / __|/ _ \
//  |  __/| | |_| | | | (_| | | |/ /  __/ |_____| |  __/ (_| | |_| \__ \  __/
//  |_|   |_|\__,_|_|  \__,_|_|_/___\___|         |_|   \__,_|\__,_|___/\___|
//                                | |__  _   _                               
//                                | '_ \| | | |                              
//                                | |_) | |_| |                              
//      _   _          _          |_.__/ \__, |                  __ _        
//     | |_| |__   ___| |__  _   _ _ __ _|___/____      ___ __  / _| |_      
//     | __| '_ \ / _ \ '_ \| | | | '__| '__/ _ \ \ /\ / / '_ \| |_| __|     
//     | |_| | | |  __/ |_) | |_| | |  | | | (_) \ V  V /| | | |  _| |_      
//      \__|_| |_|\___|_.__/ \__,_|_|  |_|  \___/ \_/\_/ |_| |_|_|  \__|     
// 
// 
// 
//                     %%                               %%                      
//                     %%                               %%                      
//                     %%%    %%%%%%%%     %%%%%%%%    %%%                      
//                     %% (%%  #%%%%   %%%   %%%%   %%  %%                      
//                     %%  %  %%    %%  %  %%    %%  %  %%                      
//                     %%  %  %%    %% %%% %%    %% .%  %%                      
//                     %%   %%   ,   %%   %%  .    %%   %%                      
//                     %%    %%%%%%%%%%   %%%%%%%%%%    %%                      
//                     %%    %%        %%%        %%    %%                      
//                     %%    %%                   %%    %%                      
//                     %%    %%                   %%    %%                      
//                     %%    %%                   %%    %%                      
//                     %%    %%                   %     %%                      
//                      %     %%                 %     %%                       
//                      %%      %%             %%      %%                       
//                       %%        %%%%   %%%%        %.                        
//                         %%                       %%                          
//                           %%                   %%                            
//                             %%%%/         %%%%%                              
//                             %       %%%       %                              
//                         %%%%%%%%           %%%%%%%%                          

//Collective: The Burrow NFT - https://twitter.com/theburrownft
//Coder: Orion Solidified, Inc. - https://twitter.com/DevOrionNFTs


pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract PluralizePause is ERC721, Ownable {

    string public PLRZP_PROVENANCE;

    uint256 public totalSupply;
    uint256 public maxSupply;

    bool public collectorMintingPaused;
    bool public allowListMintingPaused;
    bool public publicMintingPaused;

    string internal baseTokenUri;
    string public hiddenMetadataUri;
    bool public isRevealed;

    uint256 public maxAdditionalMintPerTxForCollectors;
    uint256 public maxMintPerTxForPublic;

    uint256 public collectorMintCost;
    uint256 public publicMintCost;

    mapping(address => uint8) public WalletMints;
    mapping(address => uint8) public CollectorList;
    mapping(address => uint8) public AllowList;

    //Fund Withdrawing Wallet
    address public withdrawalWallet;


    constructor() payable ERC721('Pluralize Pause', 'PLRZP') {

        PLRZP_PROVENANCE = "TBD";

        totalSupply = 0;
        maxSupply = 100;

        collectorMintingPaused = true;
        allowListMintingPaused = true;
        publicMintingPaused = true;

        setHiddenMetadataUri("https://orion.mypinata.cloud/ipfs/QmR75pda4kXzy72XUo5YLJ1GGfxJPQv6CowZr1KywpDnEs");
        isRevealed = false;

        maxAdditionalMintPerTxForCollectors = 5;
        maxMintPerTxForPublic = 5;

        collectorMintCost = 0.2 ether;
        publicMintCost = 0.25 ether;

        isRevealed = false;

        withdrawalWallet = 0xe3b41ca3aDc6653EA64bF23e9d01c8Fa5B06F29b;

    }

    modifier callerIsAWallet() {
        require(tx.origin ==msg.sender, "Another contract detected");
        _;
    }

    //Toggle Minting Phases

    function toggleCollectorMinting() external onlyOwner {
        collectorMintingPaused = !collectorMintingPaused;
    } //starts on 14th 10:30 pm IST - ends on 16th 9:30 pm IST

    function toggleAllowListMinting() external onlyOwner {
        allowListMintingPaused = !allowListMintingPaused;
    } //starts on 15th 10:30 pm IST - ends on 16th 9:30 pm IST

    function togglePublicMinting() external onlyOwner {
        publicMintingPaused = !publicMintingPaused;
    } //starts on 16th 10:30 pm IST


    //Change Withdrawal Wallets - Failsafe
    function changeWithdrawWallet(address withdrawWallet_) external onlyOwner {
        withdrawalWallet = withdrawWallet_;
    }

    //Add Addresses for Collector Mint
    function addToCollectorList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            CollectorList[addresses[i]] = numAllowedToMint;
        }
    }

    //Add Addresses for Allowlist Mint
    function addToAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            AllowList[addresses[i]] = numAllowedToMint;
        }
    }    

    //Returns number of mints allowed for each collector
    function numAvailableToMintForCollector(address addr) external view returns (uint8) {
        return CollectorList[addr];
    }

    //Returns number of mints allowed for each address
    function numAvailableToMintForAllowList(address addr) external view returns (uint8) {
        return AllowList[addr];
    }

    //Returns number of mints per each address
    function numMintsPerWallet(address addr) external view returns (uint8) {
        return WalletMints[addr];
    }    


    //Update Hidden Metadata URI
    function setHiddenMetadataUri(string memory hiddenMetadataUri_) public onlyOwner {
        hiddenMetadataUri = hiddenMetadataUri_;
    }

    //Token URI change - More utility is coming!
    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {

        if (isRevealed == false) {
            return hiddenMetadataUri;
            }

        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    string private customContractURI = "https://orion.mypinata.cloud/ipfs/QmZfchpSNFVAAS4PV34VHC377k2o6JuRHXo5XvFgDxhvPu";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }    

    //Reserving NFT for The Burrow
    function reserveForBurrow(uint8 n) public onlyOwner {

      for (uint256 i = 0; i < n; i++) {
        uint256 newTokenId = totalSupply + 1;

        WalletMints[msg.sender]++;
        totalSupply++;        
        
        _safeMint(msg.sender, newTokenId);
      }

    }

    function getTotalMintPrice(address addr, uint8 quantity_) public view returns(uint256) {
        uint8 numMintsAtCollectorMintCost = CollectorList[addr];

        // uint8 numMintsAtPublicMintCost = ;

        if(quantity_ <= numMintsAtCollectorMintCost){
            return quantity_ * collectorMintCost;
        } else {
            uint256 numAdditionalMintsRequested = quantity_ - numMintsAtCollectorMintCost;
            require(numAdditionalMintsRequested <= maxAdditionalMintPerTxForCollectors, "Asking too many mints");

            return (numMintsAtCollectorMintCost * collectorMintCost) + (numAdditionalMintsRequested * publicMintCost);
        }

    }

    //Collectors Mint with Additional Quota
    function mintForCollectorWithAdditionalMints(uint8 quantity_) external payable callerIsAWallet {
        
        uint8 numMintsAtCollectorMintCost = CollectorList[msg.sender];

        require(!collectorMintingPaused, 'collector minting is paused');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(numMintsAtCollectorMintCost > 0, 'address not found');

        require(numMintsAtCollectorMintCost < quantity_, "Mints requested via wrong function");
       
        uint256 numAdditionalMintsRequested = quantity_ - numMintsAtCollectorMintCost;

        require(numAdditionalMintsRequested <= maxAdditionalMintPerTxForCollectors, "Asking too many mints");

        uint256 totalMintPrice = uint256((numMintsAtCollectorMintCost * collectorMintCost) + (numAdditionalMintsRequested * publicMintCost));
                
        require(msg.value >= totalMintPrice, 'wrong mint value');

        
        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;

            WalletMints[msg.sender]++;

            if(CollectorList[msg.sender] > 0){
                CollectorList[msg.sender]--;
            }

            totalSupply++;
            
            _safeMint(msg.sender, newTokenId);
        }

    }

    //Collectors Mint against Maximum collected from Rising Hope
    function mintForCollectorMints(uint8 quantity_) external payable callerIsAWallet {
        
        uint8 numMintsAtCollectorMintCost = CollectorList[msg.sender];

        require(!collectorMintingPaused, 'collector minting is paused');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(numMintsAtCollectorMintCost > 0, 'address not found');

        require(numMintsAtCollectorMintCost >= quantity_, "Mints requested via wrong function");
       
        uint256 totalMintPrice = quantity_ * collectorMintCost;
                
        require(msg.value >= totalMintPrice, 'wrong mint value');

        
        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;

            WalletMints[msg.sender]++;

            CollectorList[msg.sender]--;

            totalSupply++;
            
            _safeMint(msg.sender, newTokenId);
        }

    }    


    //Allow List Mints
    function mintForAllowList() external payable callerIsAWallet {
        
        uint8 numMintsForAllowList = AllowList[msg.sender];
        uint256 newTokenId = totalSupply + 1;

        require(!allowListMintingPaused, 'allowlist minting is paused');
        require(newTokenId <= maxSupply, 'sold out');
        require(numMintsForAllowList > 0, 'address not found');

        require(msg.value >= publicMintCost, 'wrong mint value');

        WalletMints[msg.sender]++;

        AllowList[msg.sender]--;

        totalSupply++;
        
        _safeMint(msg.sender, newTokenId);

    }

    //Public Mint
    function mintForPublic(uint8 quantity_) external payable callerIsAWallet {
        
        uint8 numCurrentMints = WalletMints[msg.sender];

        require(!publicMintingPaused, 'public minting is paused');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(numCurrentMints + quantity_ <= maxMintPerTxForPublic, 'Max mints per wallet exceeded');

        uint256 totalMintPrice = quantity_ * publicMintCost;
                
        require(msg.value >= totalMintPrice, 'wrong mint value');

        
        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;

            WalletMints[msg.sender]++;

            totalSupply++;
            
            _safeMint(msg.sender, newTokenId);
        }

    }


    //Withdrawal Pattern
    function withdraw() external onlyOwner {
        (bool success, ) = withdrawalWallet.call{ value: address(this).balance }('');
        require(success, 'withdraw failed');
    }
 
}