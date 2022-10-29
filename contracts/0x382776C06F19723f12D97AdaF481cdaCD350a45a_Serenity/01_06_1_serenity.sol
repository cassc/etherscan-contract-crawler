// SPDX-License-Identifier: Proprietary

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Serenity is Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct StakeStatus {
        uint staked;
        uint alcohol;
        uint refunded;
    }

    event SerenityStake(address indexed staker, bool indexed alcoholic, uint stakeAmount, uint alcoholAmount);
    event SerenityAddAlcohol(address indexed staker, uint alcoholAmount);
    event SerenityUnstake(address indexed staker, uint unstakeAmount);
    event SerenityRefund(address indexed staker, uint refundAmount);
    event SerenityNewStakePrice(uint newStakeAmount);
    event SerenityNewAlcoholPrice(uint newAlcoholAmount);
    event SerenityNewAlcoholCollector(address indexed collector);
    event SerenityNewRefunder(address indexed refunder);
    event SerenityNewPartyStatus(uint8 newPartyStatus);

    mapping (address => StakeStatus) private stakers;
    EnumerableSet.AddressSet private stakedAddresses;
    uint private stakePrice;
    uint private alcoholPrice;
    address payable private alcoholCollector;
    uint8 private partyStatus; // 0 = before, 1 = during, 2 = after
    address private refunder;

    modifier beforeParty {
      require(partyStatus == 0);
      _;
    }

    modifier beforeOrDuringParty {
      require(partyStatus == 0 || partyStatus == 1);
      _;
    }

    modifier onlyRefunder {
        require(msg.sender == refunder);
        _;
    }

    constructor(uint stakePrice_, uint alcoholPrice_, address alcoholCollector_, address refunder_) {
        stakePrice = stakePrice_;
        alcoholPrice = alcoholPrice_;
        alcoholCollector = payable(alcoholCollector_);
        partyStatus = 0;
        refunder = refunder_;
    }

    function stake(bool alcohol) public payable whenNotPaused beforeOrDuringParty nonReentrant {
        StakeStatus memory status = stakers[msg.sender];
        
        require(status.staked == 0, "Already staked.");
        require(status.refunded == 0, "Already refunded.");
        
        uint requiredAlcoholAmount = alcohol ? alcoholPrice - status.alcohol : 0 ether;
        require(msg.value >= stakePrice + requiredAlcoholAmount, "Not enough ether sent.");

        if (alcohol && requiredAlcoholAmount > 0) {
            (bool alcoholSent, ) = alcoholCollector.call{value: requiredAlcoholAmount}("");
            require(alcoholSent, "Failed to send eth to alcohol collector.");
        }

        status.staked = stakePrice;
        status.alcohol += requiredAlcoholAmount;
        stakers[msg.sender] = status;
        stakedAddresses.add(msg.sender);

        // somehow, more eth was sent than necessary. immediately give it back
        if (msg.value > stakePrice + requiredAlcoholAmount) {
            uint overpaymentRefundAmount = msg.value - stakePrice - requiredAlcoholAmount;
            (bool overpaymentRefundSent, ) = payable(msg.sender).call{value: overpaymentRefundAmount}("");
            require(overpaymentRefundSent, "Failed to refund overpayment.");
        }

        emit SerenityStake(msg.sender, alcohol, stakePrice, requiredAlcoholAmount);
    }

    function addAlcohol() public payable whenNotPaused beforeOrDuringParty nonReentrant {
        StakeStatus memory status = stakers[msg.sender];
        
        require(status.staked > 0, "Not staked.");
        require(status.refunded == 0, "Already refunded.");
        require(status.alcohol == 0, "Already alcoholic.");
        require(msg.value >= alcoholPrice, "Not enough ether sent.");

        (bool alcoholSent, ) = alcoholCollector.call{value: alcoholPrice}("");
        require(alcoholSent, "Failed to send eth to alcohol collector.");

        status.alcohol = alcoholPrice;
        stakers[msg.sender] = status;

        // somehow, more eth was sent than necessary. immediately give it back
        if (msg.value > alcoholPrice) {
            uint overpaymentRefundAmount = msg.value - alcoholPrice;
            (bool overpaymentRefundSent, ) = payable(msg.sender).call{value: overpaymentRefundAmount}("");
            require(overpaymentRefundSent, "Failed to refund overpayment.");
        }

        emit SerenityAddAlcohol(msg.sender, alcoholPrice);
    }

    function unstake() public whenNotPaused beforeParty nonReentrant {
        StakeStatus memory status = stakers[msg.sender];
        
        require(status.staked > 0, "Not staked.");
        require(status.refunded == 0, "Already refunded.");

        (bool unstakeSent, ) = payable(msg.sender).call{value: status.staked}("");
        require(unstakeSent, "Failed to send eth to unstaker.");
        emit SerenityUnstake(msg.sender, status.staked);

        status.staked = 0;
        stakers[msg.sender] = status;
        stakedAddresses.remove(msg.sender);
    }

    function refund(address addy) public onlyRefunder {
        StakeStatus memory status = stakers[addy];
        
        require(status.staked > 0, "Not staked.");
        require(status.refunded == 0, "Already refunded.");

        (bool refundSent, ) = payable(addy).call{value: status.staked}("");
        require(refundSent, "Failed to refund eth to staker.");

        status.refunded = status.staked;
        stakers[addy] = status;

        emit SerenityRefund(msg.sender, status.staked);
    }

    function withdraw(address to) public onlyOwner {
        (bool withdrawSent, ) = payable(to).call{value: address(this).balance}("");
        require(withdrawSent, "Failed to withdraw eth.");
    }

    function getStatus(address addy) public view returns (uint staked, uint alcohol, uint refunded) {
        StakeStatus memory status = stakers[addy];
        
        staked = status.staked;
        alcohol = status.alcohol;
        refunded = status.refunded;
    }

    function getStakers() public view returns (address[] memory) {
        return stakedAddresses.values();
    }

    function setStakeAmount(uint newStakeAmount) public onlyOwner {
        stakePrice = newStakeAmount;
        emit SerenityNewStakePrice(newStakeAmount);
    }

    function setAlcoholAmount(uint newAlcoholAmount) public onlyOwner {
        alcoholPrice = newAlcoholAmount;
        emit SerenityNewAlcoholPrice(newAlcoholAmount);
    }

    function setAlcoholCollector(address newAlcoholCollector) public onlyOwner {
        alcoholCollector = payable(newAlcoholCollector);
        emit SerenityNewAlcoholCollector(newAlcoholCollector);
    }

    function setRefunder(address newRefunder) public onlyOwner {
        refunder = newRefunder;
        emit SerenityNewRefunder(newRefunder);
    }

    function setPartyStatus(uint8 newPartyStatus) public onlyOwner {
        partyStatus = newPartyStatus;
        emit SerenityNewPartyStatus(newPartyStatus);
    }

    function stakeAmount() public view returns (uint stakeAmount_) {
        stakeAmount_ = stakePrice;
    }

    function alcoholAmount() public view returns (uint alcoholAmount_) {
        alcoholAmount_ = alcoholPrice;
    }

    function getAlcoholCollector() public view returns (address collector) {
        collector = alcoholCollector;
    }

    function getRefunder() public view returns (address refunder_) {
        refunder_ = refunder;
    }

    function getPartyStatus() public view returns (uint8 partyStatus_) {
        partyStatus_ = partyStatus;
    }

    // don't allow accidental receipt of ether
    receive() external payable {
        revert();
    }

    // don't allow accidental function calls
    fallback() external payable {
        revert();
    }
}