// contracts/SIMPresale.sol
// SPDX-License-Identifier: MIT

/*
  ______   ______  __       __  _______          ______    ______   __        ________ 
 /      \ /      |/  \     /  |/       \        /      \  /      \ /  |      /        |
/$$$$$$  |$$$$$$/ $$  \   /$$ |$$$$$$$  |      /$$$$$$  |/$$$$$$  |$$ |      $$$$$$$$/ 
$$ \__$$/   $$ |  $$$  \ /$$$ |$$ |__$$ |      $$ \__$$/ $$ |__$$ |$$ |      $$ |__    
$$      \   $$ |  $$$$  /$$$$ |$$    $$/       $$      \ $$    $$ |$$ |      $$    |   
 $$$$$$  |  $$ |  $$ $$ $$/$$ |$$$$$$$/         $$$$$$  |$$$$$$$$ |$$ |      $$$$$/    
/  \__$$ | _$$ |_ $$ |$$$/ $$ |$$ |            /  \__$$ |$$ |  $$ |$$ |_____ $$ |_____ 
$$    $$/ / $$   |$$ | $/  $$ |$$ |            $$    $$/ $$ |  $$ |$$       |$$       |
 $$$$$$/  $$$$$$/ $$/      $$/ $$/              $$$$$$/  $$/   $$/ $$$$$$$$/ $$$$$$$$/


 Website: https://simp.trade/
Twitter: https://twitter.com/simpcoinETH_
*/
pragma solidity ^0.8.18;

import "./SIMPCoin.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SIMPresale is Ownable {
    using SafeMath for uint256;

    SIMPCoin public tokenContract;
    uint256 public presaleEndTime;
    uint256 public presaleDuration = 48 hours;
    uint256 public presaleTotalSupply = 41600000000000 * (10**18);
    uint256 public tokensPerLowPurchase = 260000000000 * (10**18);  // 0.05 ETH purchase
    uint256 public tokensPerHighPurchase = 520000000000 * (10**18); // 0.1 ETH purchase
    uint256 public highPurchaseCount = 0;
    uint256 public maxHighPurchases = 40; 
    uint256 public maxCap = 8.0 ether;
    mapping(address => bool) public hasParticipated;
    mapping(address => uint256) public purchasedTokens;
    uint256 private receivedEth = 0;

    constructor(address _tokenContract) {
        tokenContract = SIMPCoin(_tokenContract);
    }

    modifier duringPresale() {
        require(block.timestamp <= presaleEndTime, "Presale has ended");
        _;
    }

    modifier presaleEnded() {
        require(block.timestamp > presaleEndTime, "Presale is still active");
        _;
    }

    function startPresale() external onlyOwner {
        require(presaleEndTime == 0, "Presale has already started");
        presaleEndTime = block.timestamp.add(presaleDuration);
    }

    function endPresale() external onlyOwner {
        require(presaleEndTime > 0, "Presale has not started yet");
        presaleEndTime = block.timestamp;
    }

    function presaleIsActive() public view returns (bool) {
        return block.timestamp <= presaleEndTime;
    }

    function fundContract() external payable onlyOwner {
        // No need to calculate token buy amount in this function
        // The purpose is to simply fund the contract with ETH
    }

    function buyTokens() external payable duringPresale {
        require(hasParticipated[msg.sender] == false, "Address has already participated in presale");
        require(msg.value == 0.05 ether || msg.value == 0.1 ether, "You can only send exactly 0.05 or 0.1 ETH");
        require(receivedEth.add(msg.value) <= maxCap, "Max cap reached");
        
        if(msg.value == 0.1 ether) {
            require(highPurchaseCount < maxHighPurchases, "Max 0.1 ETH purchases reached");
            highPurchaseCount = highPurchaseCount.add(1);
            purchasedTokens[msg.sender] = tokensPerHighPurchase;
        } else {
            purchasedTokens[msg.sender] = tokensPerLowPurchase;
        }

        receivedEth = receivedEth.add(msg.value);
        hasParticipated[msg.sender] = true;
    }

    function claimTokens() external presaleEnded {
        require(purchasedTokens[msg.sender] > 0, "No tokens to claim");

        uint256 tokensToClaim = purchasedTokens[msg.sender];
        purchasedTokens[msg.sender] = 0;
        tokenContract.transferFrom(owner(), msg.sender, tokensToClaim);
    }

    function withdrawFunds() external onlyOwner presaleEnded {
        uint256 remainingTokens = tokenContract.balanceOf(address(this));
        if (remainingTokens > 0) {
            tokenContract.transfer(owner(), remainingTokens);
        }

        uint256 contractBalance = address(this).balance;
        if (contractBalance > 0) {
            payable(owner()).transfer(contractBalance);
        }
    }

}