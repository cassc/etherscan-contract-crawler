/**
 *Submitted for verification at BscScan.com on 2023-01-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-04
*/

pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function AddRewards(uint _amount) external;
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract LockupVault {

    IBEP20 public kinectAddress;
    IBEP20 public dividendVaultAddress;

    uint256 public lastPayout;
    uint256 public payoutRate = 5; //5% a day
    uint256 public distributionInterval = 1;

    // Events
    event RewardsDistributed(uint256 rewardAmount);
    event UpdatePayoutRate(uint256 payout);
    event UpdateDistributionInterval(uint256 interval);

    constructor(IBEP20 _kinectAddress, IBEP20 _dividendVaultAddress){
        kinectAddress = _kinectAddress;
        dividendVaultAddress = _dividendVaultAddress;
        kinectAddress.approve(address(dividendVaultAddress), 2**256 - 1);
        lastPayout = block.timestamp;
    }

    function claimableRewards() public view returns(uint) {
        uint256 dividendBalance = IBEP20(kinectAddress).balanceOf(address(this));
        uint256 share = dividendBalance * payoutRate / 100 / 24 hours;
        uint256 profit = share * (block.timestamp - lastPayout);
        return profit;
    }

    function payoutDivs() public {
        uint256 dividendBalance = IBEP20(kinectAddress).balanceOf(address(this));

        if (block.timestamp - lastPayout > distributionInterval && dividendBalance > 0) {

            //A portion of the dividend is paid out according to the rate
            uint256 share = dividendBalance * payoutRate / 100 / 24 hours;
            //divide the profit by seconds in the day
            uint256 profit = share * (block.timestamp - lastPayout);

            if (profit > dividendBalance){
                profit = dividendBalance;
            }

            lastPayout = block.timestamp;

            dividendVaultAddress.AddRewards(profit);

            emit RewardsDistributed(profit);
        }
    }

}