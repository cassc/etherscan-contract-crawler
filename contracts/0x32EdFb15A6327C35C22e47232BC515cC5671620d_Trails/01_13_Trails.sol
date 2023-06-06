// SPDX-License-Identifier: MIT

//                        888                                                                   d8b 888 888                                    
//                        888                                                                   Y8P 888 888                                    
//                        888                                                                       888 888                                    
// 888  888 88888b.   .d88888  .d88b.  888d888      .d8888b  888  888 888d888 888  888  .d88b.  888 888 888  8888b.  88888b.   .d8888b .d88b.  
// 888  888 888 "88b d88" 888 d8P  Y8b 888P"        88K      888  888 888P"   888  888 d8P  Y8b 888 888 888     "88b 888 "88b d88P"   d8P  Y8b 
// 888  888 888  888 888  888 88888888 888          "Y8888b. 888  888 888     Y88  88P 88888888 888 888 888 .d888888 888  888 888     88888888 
// Y88b 888 888  888 Y88b 888 Y8b.     888               X88 Y88b 888 888      Y8bd8P  Y8b.     888 888 888 888  888 888  888 Y88b.   Y8b.     
//  "Y88888 888  888  "Y88888  "Y8888  888           88888P'  "Y88888 888       Y88P    "Y8888  888 888 888 "Y888888 888  888  "Y8888P "Y8888  
                                                                                                                                            

//Arist: Ivona Tau - https://twitter.com/ivonatau
//Coder: Orion Solidified, Inc. - https://twitter.com/DevOrionNFTs
//Event: NFC Lisbon 2023 - https://twitter.com/NFCSummit

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Trails is ERC721, Ownable {

    uint256 public totalSupply;
    uint256 public maxSupply;

    bool public mintingPaused;

    string internal baseTokenUri;
    string public hiddenMetadataUri;
    bool public isRevealed;

    uint256 public mintCost;

    address public ivonaWallet;
    address public orionWallet;
    address public nfcWallet;
    address public otherWallet;


    mapping(address => uint256) public WalletMints;
    mapping(address => uint256) public DevList;

    constructor() payable ERC721("Trails of Data Doppelgangers", "TDD") {
        totalSupply = 0;
        maxSupply = 2000;

        mintingPaused = true;

        setHiddenMetadataUri("https://orion.mypinata.cloud/ipfs/QmcTWf4X2k1zG3LotABPPmXNsnkTyFj47B7A3A1H8d54f8/");
        isRevealed = false;

        mintCost = 0.1 ether;

        ivonaWallet = 0x6925b22105664506D2d7e449B9cEdE78cBb1eCfE;
        orionWallet = 0x0F574D45D73F5c8F4189CCf4D98Cd22eaDFA9532;
        nfcWallet = 0x8C7976922ADD1c35f14c62C34E96f0d562710Ef9;
        otherWallet = 0xd5dABEfF7C747cfC9E5dF70dD0dbe4eCc34468ba;


    }

    modifier callerIsAWallet() {
        require(tx.origin ==msg.sender, "Another contract detected");
        _;
    }

    //Change Wallets - Failsafe
    function changeIvonaWallet(address withdrawWallet_) external onlyOwner {
        ivonaWallet = withdrawWallet_;
    }

    //Change Mint Cost - Failsafe
    function changeMintCost(uint256 mintCost_) external onlyOwner {
        mintCost = mintCost_;
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

    string private customContractURI = "https://orion.mypinata.cloud/ipfs/QmQHS7rAVHy5H13B1zpF1BEqC5xTTgXBfSYeoMssjYbg1Z/";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }    

    function reveal() external onlyOwner {
        isRevealed = true;
    }
    
    //Trail mint
    function premint(uint256 quantity_) public payable callerIsAWallet {

        require(!mintingPaused, 'minting is paused');
        require(msg.value >= quantity_ * mintCost, 'wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        
        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;

            WalletMints[msg.sender]++;
            totalSupply++;
            
            _safeMint(msg.sender, newTokenId);
        }
    }
    

    function pauseMinting() public onlyOwner {
        mintingPaused = !mintingPaused;
    }


    function withdraw() external onlyOwner {
        uint256 totalToWithdraw = address(this).balance;
        uint256 fivepercent = totalToWithdraw / 40;
        uint256 ivonaShare = fivepercent * 26;
        uint256 orionShare = fivepercent * 5;
        uint256 nfcShare = fivepercent * 5;
        uint256 otherShare = totalToWithdraw - ivonaShare - orionShare - nfcShare;

        (bool successIvona, ) = ivonaWallet.call{ value: ivonaShare }('');
        require(successIvona, 'withdraw failed');

        (bool successOrion, ) = orionWallet.call{ value: orionShare }('');
        require(successOrion, 'withdraw failed');

        (bool successNfc, ) = nfcWallet.call{ value: nfcShare }('');
        require(successNfc, 'withdraw failed');

        (bool successOther, ) = otherWallet.call{ value: otherShare }('');
        require(successOther, 'withdraw failed');                

    }
 
}