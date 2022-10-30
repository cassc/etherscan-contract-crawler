// SPDX-License-Identifier: MIT
//
//
// UI:
//
// - function "createVesting" ===================================> [address] Create Vesting. Can be called only one by contract deployer
// - function "claim" ===========================================> [uint] Provide vesting index from 0 to 7. Can be called only owner of exact vesting.
// - struct "vesting" ===========================================> [index] Provide vesting index from 0 to 7. Show full information about exact vesting.
//
//
// DEPLOYMENT:
//
// - Depoloy contract with no arguments
// - Use function createVesting for create vesting and begin vesting timer and provide those addresses:
//      address team, teamPrivateSale, advisors, marketing, NFTHolders, liquidity, treasury, stakingReward
//
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function mint(address _to, uint _amount) external;
}

contract SuperYachtCoinVesting is Ownable {

  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- VESTING PARAMETERS
  // -------------------------------------------------------------------------------------------------------

    uint constant ONE_MONTH = 30 days;

    bool public vestingIsCreated;

    mapping(uint => Vesting) public vesting;

    IERC20 public token;

    // @notice                              provide full information of exact vesting
    struct Vesting {
        address owner;                      //The only owner can call vesting claim function
        uint claimCounter;                  //Currect claim number
        uint totalClaimNum;                 //Maximum amount of claims for this vesting
        uint nextUnlockDate;                //Next date of tokens unlock
        uint tokensRemaining;               //Remain amount of token
        uint tokenToUnclockPerMonth;        //Amount of token can be uncloked each month
    }

    constructor(IERC20 _token) {
        token = _token;
    }

    // @notice                             only contract deployer can call this method and only once
    function createVesting(
        address _teamWallet,
        address _teamPrivateSaleWallet,
        address _advisorsWallet,
        address _marketingWallet,
        address _NFTHoldersWallet,
        address _liquidityWallet,
        address _treasuryWallet,
        address _stakingRewardWallet
        ) public onlyOwner
        {
        require(!vestingIsCreated, "vesting is already created");
        vestingIsCreated = true;
        vesting[0] = Vesting(_teamWallet, 0, 12, block.timestamp + 360 days, 96_000_000 ether, 4_000_000 ether);
        vesting[1] = Vesting(_teamPrivateSaleWallet, 0, 6, block.timestamp + 180 days, 28_000_000 ether, 4_666_667 ether);
        vesting[2] = Vesting(_advisorsWallet, 0, 12, block.timestamp + 360 days, 24_000_000 ether, 2_000_000 ether);
        vesting[3] = Vesting(_marketingWallet, 0, 48, block.timestamp + ONE_MONTH, 112_000_000 ether, 2_333_333 ether);
        vesting[4] = Vesting(_NFTHoldersWallet, 0, 6, block.timestamp + ONE_MONTH, 44_000_000 ether, 7_333_333 ether);
        vesting[5] = Vesting(_liquidityWallet, 0, 12, block.timestamp + ONE_MONTH, 135_000_000 ether, 11_250_000 ether);
        vesting[6] = Vesting(_treasuryWallet, 0, 48, block.timestamp + ONE_MONTH, 193_800_000 ether, 4_037_500 ether);
        vesting[7] = Vesting(_stakingRewardWallet, 0, 48, block.timestamp + ONE_MONTH, 300_000_000 ether, 6_250_000 ether);
        token.mint(_teamPrivateSaleWallet, 7_000_000 ether);
        token.mint(_NFTHoldersWallet, 11_000_000 ether);
        token.mint(_liquidityWallet, 15_000_000 ether);
        token.mint(_treasuryWallet, 34_200_000 ether);
    }

    modifier checkLock(uint _index) {
        require(vesting[_index].owner == msg.sender, "Not an owner of this vesting");
        require(block.timestamp > vesting[_index].nextUnlockDate, "Tokens are still locked");
        require(vesting[_index].tokensRemaining > 0, "Nothing to claim");
        _;
    }

    // @notice                             please use _index from table below
    //
    // 0 - Team
    // 1 - Team Private Sale
    // 2 - Advisors
    // 3 - Marketing
    // 4 - NFT Holders
    // 5 - Liquidity
    // 6 - Treasury
    // 7 - Staking Reward
    //
    function claim(uint256 _index) public checkLock(_index) {
        if(vesting[_index].claimCounter + 1 < vesting[_index].totalClaimNum) {
            uint toMint = vesting[_index].tokenToUnclockPerMonth;
            token.mint(msg.sender, toMint);
            vesting[_index].tokensRemaining -= toMint;
            vesting[_index].nextUnlockDate += ONE_MONTH;
            vesting[_index].claimCounter++;
        } else {
            token.mint(msg.sender, vesting[_index].tokensRemaining);
            vesting[_index].tokensRemaining = 0;
        }
    }
}