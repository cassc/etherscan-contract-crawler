// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./approving-bone.sol";

contract ApprovingCorgis is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public baseURI;
    uint256 public team = 10;
    uint256 public custom = 30;
    uint256 public giveaway = 60;
    uint256 public constant price = 0.05 ether;
    uint8 public constant maxEarlyAccessPurchase = 5;
    uint8 public constant maxPublicPurchase = 10;
    uint256 public maxEarlyAccess = 2000;
    uint256 public maxCorgis = 9999;
    bool public corgiSaleIsActive = false;
    bool public earlyAccessIsActive = false;

    uint256 public donationToCharity = 20 ether;
    uint256 public sendToCommunityVault = 30 ether;

    address public communityVault = 0xcCa72c0C787df0293e126EA1Ade1B6936e000204;
    address public charityFundWallet = 0xC5816243E05851E8d838cf2a56dfcC1e5a0F8132;

    mapping (uint256 => uint256) public numberOfCorgisMintedPerBone;
    mapping(address => uint256) addressBlockBought;

    ApprovingBone public approvingBoneContract;

    constructor(string memory tokenBaseUri, address boneContractAddress) ERC721("Approving Corgis", "ACORGIS")  {
        // setBaseURI for metadata
        setBaseURI(tokenBaseUri);
        mintTeamCorgis();
        approvingBoneContract = ApprovingBone(boneContractAddress);
    }

    /**
     * Mint reserved Corgis
     */
    function mintTeamCorgis() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < team; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    /**
     * mint Early Access Corgis
     */

    function earlyAccessMint(uint256 boneTokenId, uint256 numberOfTokens) public payable {
        uint256 supply = totalSupply();
        uint256 boneCount = approvingBoneContract.balanceOf(msg.sender);
        uint256 corgiPerBoneCount = numberOfCorgisMintedPerBone[boneTokenId];
        bool bonesOfOwner = findBonesOfOwner(msg.sender, boneTokenId, boneCount);

        require(addressBlockBought[msg.sender] < block.timestamp, "Not allowed to Mint on the same Block");
        require(!Address.isContract(msg.sender),"Contracts are not allowed to mint");
        require(bonesOfOwner,"You do not own this bone");
        require(corgiPerBoneCount + numberOfTokens < 6,"You cannot mint more than 5 Corgis per Bone");
        require(earlyAccessIsActive, "Early Access Mint is not active yet");
        require(boneCount > 0, "You don't have a mint pass");
        require(msg.value >= price * numberOfTokens, "Payment is Insufficient");
        require(supply + numberOfTokens <= maxEarlyAccess, "Exceeds maximum Corgis early access supply" );

        addressBlockBought[msg.sender] = block.timestamp;
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
        }

        numberOfCorgisMintedPerBone[boneTokenId] = numberOfCorgisMintedPerBone[boneTokenId].add(numberOfTokens);
    }

    /**
     * mint Corgis
     */
    function mintCorgis(uint256 numberOfTokens) public payable {
        uint256 supply = totalSupply();

        require(addressBlockBought[msg.sender] < block.timestamp, "Not allowed to Mint on the same Block");
        require(!Address.isContract(msg.sender),"Contracts are not allowed to mint");
        require(corgiSaleIsActive, "Sale is not active yet");
        require(msg.value >= price * numberOfTokens, "Payment is Insufficient");
        require(numberOfTokens <= maxPublicPurchase, "You can adopt a maximum of 10 Corgis");
        require(supply + numberOfTokens <= maxCorgis, "Exceeds maximum Corgis supply" );

        addressBlockBought[msg.sender] = block.timestamp;

        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );

            if (totalSupply() == 6500) {
                // send to charity fund
                sendToCommunityAndCharityWallets(charityFundWallet, donationToCharity);
            } else if (totalSupply() == 9000) {
                // send to community vault
                sendToCommunityAndCharityWallets(communityVault, sendToCommunityVault);
            }
        }
    }

    /**
     * reserve Corgis for giveaways
     */
    function mintCorgisForGiveaway() public onlyOwner {
        uint256 supply = totalSupply();
        require(giveaway > 0, "Giveaway has been minted!");

        for (uint256 i = 0; i < custom + giveaway; i++) {
            _safeMint(msg.sender, supply + i);
        }

        giveaway -= giveaway;
    }

    /**
     * check if bone can still be used
     */
    function checkBoneBalance(uint256 boneId) public view returns(uint256) {
        return numberOfCorgisMintedPerBone[boneId];
    }

    function findBonesOfOwner(address _owner, uint256 tokenId, uint256 tokenCount) internal view returns(bool) {
        bool isBone = false;

        for(uint256 i; i < tokenCount; i++){
            uint256 tokensId = approvingBoneContract.tokenOfOwnerByIndex(_owner, i);
            if(tokensId == tokenId) {
                return true;
            } 
        }

        return isBone;
    }

    /**
     * Returns Corgis of the Caller
     */
    function corgisOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function toggleSaleActive() public onlyOwner {
        corgiSaleIsActive = !corgiSaleIsActive;
    }

    function toggleEarlyAccessActive() public onlyOwner {
        earlyAccessIsActive = !earlyAccessIsActive;
    }

    function setCommunityVault(address communityVaultAddress) public onlyOwner {
        communityVault = communityVaultAddress;
    }

    function setCharityFund(address charityFundAddress) public onlyOwner {
        charityFundWallet = charityFundAddress;
    }
    
    function approvingBoneContractAddress() public view returns (address) {
        return address(approvingBoneContract);
    }

    /**
     * Withdraw Ether
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }

    /**
     * Send to Community and Charity Wallets
     */
    function sendToCommunityAndCharityWallets(address _address, uint256 amount) private {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool sendToWalletSuccess, ) = _address.call{value: amount}("");
        require(sendToWalletSuccess, "Failed to send wallets");
    }
}