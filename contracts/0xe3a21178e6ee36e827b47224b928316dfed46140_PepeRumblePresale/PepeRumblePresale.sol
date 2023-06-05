/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


//  _____                _____                 _     _      
// |  __ \              |  __ \               | |   | |     
// | |__) |__ _ __   ___| |__) |   _ _ __ ___ | |__ | | ___ 
// |  ___/ _ \ '_ \ / _ \  _  / | | | '_ ` _ \| '_ \| |/ _ \
// | |  |  __/ |_) |  __/ | \ \ |_| | | | | | | |_) | |  __/
// |_|   \___| .__/ \___|_|  \_\__,_|_| |_| |_|_.__/|_|\___|
//           | |                                            
//           |_|                                            
// Visit https://peperumble.com
// Join our Discord: https://discord.gg/HnVysC3VeH
// Follow our Twitter: https://twitter.com/peperumblegame
// Join our Telegram: https://t.me/peperumble

interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}


contract PepeRumblePresale is ReentrancyGuard {
	
	string public name = "Pepe Rumble Presale";
    address public owner;
    bool public isPaused;
    bool public isAffiliateOpen;
    address public rumbleTokenAddress;
    uint256 public eachRoundTotalTokens = 10000000000 * 10**18;// 10 Billion Tokens each round
    uint256 public totalPresaleTokens;
    uint256 public currentRoundMarketCap = 50 * 10**18; //Measured in ETH
    uint256 public currentRoundContribution = 0; // Measured in ETH
	mapping (address => uint256) public tokenAllocation;
    mapping (address => uint256) public ethForWithdrawal;

    uint256 public referralPercentage = 15;
    mapping (string => address) public promoCodeStringToAddress;
    mapping (address => string) public promoCodeAddressToString;
    
    constructor() {
        owner = msg.sender;
    }

    function purchasePresale(string calldata affiliateCode) public payable nonReentrant{

        require(isPaused == false, "Presale Not Active");
        require(msg.value > 0, "Invalid ETH Amount");

        uint256 contributionAmount = msg.value;
        uint256 thisRoundTotalContribution = contributionAmount + currentRoundContribution;
        uint256 thisRoundAllowedContribution = currentRoundMarketCap / 10;
        require(thisRoundTotalContribution <= ((thisRoundAllowedContribution * 103)/100), "Round Full"); // allow 3% buffer for oversubscription

        currentRoundContribution = thisRoundTotalContribution;
        if(currentRoundContribution >= thisRoundAllowedContribution){
            currentRoundMarketCap = currentRoundMarketCap * 2;
            currentRoundContribution = 0;
        }


        //ETH accounting
        address referrer = promoCodeStringToAddress[affiliateCode];
        if(referrer==address(0) || referrer == msg.sender){
            ethForWithdrawal[owner] = ethForWithdrawal[owner] + contributionAmount;
        }
        else{
            uint256 referrerPortion = contributionAmount * referralPercentage / 100;
            uint256 ownerPortion = contributionAmount - referrerPortion;
            ethForWithdrawal[referrer] = ethForWithdrawal[referrer] + referrerPortion;
            ethForWithdrawal[owner] = ethForWithdrawal[owner] + ownerPortion;
        }

        //Token recording
        uint256 tokenAmount = (contributionAmount * eachRoundTotalTokens) / thisRoundAllowedContribution;
        tokenAllocation[msg.sender] = tokenAllocation[msg.sender] + tokenAmount;
        totalPresaleTokens = totalPresaleTokens + tokenAmount;

    }
    function claimTokens() public nonReentrant{
        require(rumbleTokenAddress != address(0), "No Claim Yet");

        uint256 amountToClaim = tokenAllocation[msg.sender];
        tokenAllocation[msg.sender] = 0;
        if(amountToClaim > 0){
            IERC20(rumbleTokenAddress).transfer(msg.sender, amountToClaim);
        }
    }

    function setIsPaused(bool _isPaused) public {
        require(msg.sender == owner, "No Permission");
        isPaused = _isPaused;
    }
    function setIsAffiliateOpen(bool _isAffiliateOpen) public {
        require(msg.sender == owner, "No Permission");
        isAffiliateOpen = _isAffiliateOpen;
    }
    function setReferralPercentage(uint256 _referralPercentage) public {

        require(msg.sender == owner, "No Permission");
        referralPercentage = _referralPercentage;

    }
    function setTokenAddress(address _rumbleTokenAddress) public {
        require(msg.sender == owner, "No Permission");
        rumbleTokenAddress = _rumbleTokenAddress;
    }
    function withdrawEth() public nonReentrant{
        uint256 amountToWithdrawal = ethForWithdrawal[msg.sender];
        ethForWithdrawal[msg.sender] = 0;
        if(amountToWithdrawal > 0){
            bool sent = payable(msg.sender).send(amountToWithdrawal);
            require(sent, "ETH transfer failed");
        }

    }
    function emergencyWithdrawEth() public{
        require(msg.sender == owner, "No Permission");
        bool sent = payable(msg.sender).send(address(this).balance);
        require(sent, "ETH transfer failed");
    }
    function establishAffiliateAdmin(address affiliateAddress, string calldata affiliateCode) public{
        require(msg.sender == owner, "No Permission");
        require(bytes(affiliateCode).length > 0, "Invalid Code");
        require(bytes(promoCodeAddressToString[affiliateAddress]).length == 0, "1 Code Max");
        require(promoCodeStringToAddress[affiliateCode]==address(0), "Already Taken");

        promoCodeStringToAddress[affiliateCode] = affiliateAddress;
        promoCodeAddressToString[affiliateAddress] = affiliateCode;
    }
    function establishAffiliate(string calldata affiliateCode) public{
        require(isAffiliateOpen == true, "No Permission");
        require(bytes(affiliateCode).length > 0, "Invalid Code");
        require(bytes(promoCodeAddressToString[msg.sender]).length == 0, "1 Code Max");
        require(promoCodeStringToAddress[affiliateCode]==address(0), "Already Taken");

        promoCodeStringToAddress[affiliateCode] = msg.sender;
        promoCodeAddressToString[msg.sender] = affiliateCode;
    }
}