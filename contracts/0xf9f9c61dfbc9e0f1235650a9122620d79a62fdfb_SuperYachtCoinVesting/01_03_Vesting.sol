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

    address constant public teamWallet = 0x5710BFbBB63Cee635843913172E2f0852268eE82;
    address constant public teamPrivateSaleWallet = 0xBC5a85Fe6cA27d341674791912A079114942A41b;
    address constant public advisorsWallet = 0x1dF531493c70951dd7f6e3b03e3e6321DEF842B0;
    address constant public marketingWallet = 0xC1D18038032527cBee663B6E2d35fA34fe8cb12c;
    address constant public NFTHoldersWallet = 0x453321b7D7B5A6FADD34afB31328a0be676f7F0B;
    address constant public liquidityWallet = 0x3FD884f571512aE8f273992B25Bdf32787cF5b36;
    address constant public treasuryWallet = 0xb95669425A2f9aC4440AD57fFB0a050E8567B903;
    address constant public stakingRewardWallet = 0x0392FA0f3a3d562ac85DFd7674283f00b44cdAf6;

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
    function createVesting() external onlyOwner {
        require(!vestingIsCreated, "vesting is already created");
        vestingIsCreated = true;
        vesting[0] = Vesting(teamWallet, 0, 12, block.timestamp + 360 days, 96_000_000 ether, 8_000_000 ether);
        vesting[1] = Vesting(teamPrivateSaleWallet, 0, 6, block.timestamp + 180 days, 28_000_000 ether, 4_666_666 ether);
        vesting[2] = Vesting(advisorsWallet, 0, 12, block.timestamp + 360 days, 24_000_000 ether, 2_000_000 ether);
        vesting[3] = Vesting(marketingWallet, 0, 48, block.timestamp + ONE_MONTH, 112_000_000 ether, 2_333_333 ether);
        vesting[4] = Vesting(NFTHoldersWallet, 0, 12, block.timestamp + 365 days, 52_250_000 ether, 4_354_166 ether);
        vesting[5] = Vesting(liquidityWallet, 0, 12, block.timestamp + ONE_MONTH, 139_500_000 ether, 11_625_000 ether);
        vesting[6] = Vesting(treasuryWallet, 0, 48, block.timestamp + ONE_MONTH, 228_000_000 ether, 4_750_000 ether);
        vesting[7] = Vesting(stakingRewardWallet, 0, 48, block.timestamp + ONE_MONTH, 300_000_000 ether, 6_250_000 ether);
        token.mint(teamPrivateSaleWallet, 7_000_000 ether);
        token.mint(NFTHoldersWallet, 2_750_000 ether);
        token.mint(liquidityWallet, 10_500_000 ether);
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