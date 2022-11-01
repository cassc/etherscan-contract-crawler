pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IDogPoundActions.sol";
import "./interfaces/IDogPoundManager.sol";

contract RewardsVaultBNB is Ownable {

    address public loyalityPoolAddress1;
    address public loyalityPoolAddress2;

    uint256 public lastPayout;
    uint256 public payoutRate = 3; //3% a day
    uint256 public distributionInterval = 3600;
    bool public poolsLocked = false;
    IDogPoundManager public DogPoundManager;

    // Events
    event RewardsDistributed(uint256 rewardAmount);
    event UpdatePayoutRate(uint256 payout);
    event UpdateDistributionInterval(uint256 interval);

    constructor(address _dogPoundManager){
        lastPayout = block.timestamp;
        DogPoundManager = IDogPoundManager(_dogPoundManager);
    }

    receive() external payable {}

    function payoutDivs() public {

        uint256 dividendBalance = address(this).balance;

        if (block.timestamp - lastPayout > distributionInterval && dividendBalance > 0) {

            //A portion of the dividend is paid out according to the rate
            uint256 share = dividendBalance * payoutRate / 100 / 24 hours;
            //divide the profit by seconds in the day
            uint256 profit = share * (block.timestamp - lastPayout);

            if (profit > dividendBalance){
                profit = dividendBalance;
            }

            lastPayout = block.timestamp;
            uint256 poolSize;
            poolSize = DogPoundManager.getAutoPoolSize();
            if(poolSize == 0){
                return;
            }
            uint256 transfer1Size = (profit * poolSize)/10000;
            uint256 transfer2Size = profit - transfer1Size;
            payable (loyalityPoolAddress1).transfer(transfer1Size);
            payable (loyalityPoolAddress2).transfer(transfer2Size);
            emit RewardsDistributed(profit);

        }
    }

    function updateLoyalityPoolAddress(address _loyalityPoolAddress1, address _loyalityPoolAddress2) external onlyOwner {
        require(!poolsLocked);
        loyalityPoolAddress1 = _loyalityPoolAddress1;
        loyalityPoolAddress2 = _loyalityPoolAddress2;
    }

    function updatePayoutRate(uint256 _newPayout) external onlyOwner {
        require(_newPayout <= 100, 'invalid payout rate');
        payoutRate = _newPayout;
        emit UpdatePayoutRate(payoutRate);
    }

    function setDogPoundManager(IDogPoundManager _dogPoundManager) external onlyOwner {
        DogPoundManager = _dogPoundManager;
    }   

    function fixPoolAddresses() external onlyOwner{
        poolsLocked = true;
    }

    function payOutAllRewards() external onlyOwner {
        uint256 rewardBalance = address(this).balance;
        uint256 poolSize;
        poolSize = DogPoundManager.getAutoPoolSize();
        if(poolSize == 0){
            return;
        }
        uint256 transfer1Size = (rewardBalance * poolSize)/10000;
        uint256 transfer2Size = rewardBalance - transfer1Size;
        payable (loyalityPoolAddress1).transfer(transfer1Size);
        payable (loyalityPoolAddress2).transfer(transfer2Size);
    }

    function updateDistributionInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval > 0 && _newInterval < 24 hours, 'invalid interval');
        distributionInterval = _newInterval;
        emit UpdateDistributionInterval(distributionInterval);
    }

}