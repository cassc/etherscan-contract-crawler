/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// Copyright (c) 2022 EverRise Pte Ltd. All rights reserved.
// EverRise licenses this file to you under the MIT license.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/*
   ________                              _______   __
  /        |                            /       \ /  |
 $$$$$$$$/__     __  ______    ______  $$$$$$$  |$$/   _______   ______  v3.14159265
 $$ |__  /  \   /  |/      \  /      \ $$ |__$$ |/  | /       | /      \
 $$    | $$  \ /$$//$$$$$$  |/$$$$$$  |$$    $$< $$ |/$$$$$$$/ /$$$$$$  |
 $$$$$/   $$  /$$/ $$    $$ |$$ |  $$/ $$$$$$$  |$$ |$$      \ $$    $$ |
 $$ |_____ $$ $$/  $$$$$$$$/ $$ |      $$ |  $$ |$$ | $$$$$$  |$$$$$$$$/
 $$       | $$$/   $$       |$$ |      $$ |  $$ |$$ |/     $$/ $$       |
 $$$$$$$$/   $/     $$$$$$$/ $$/       $$/   $$/ $$/ $$$$$$$/   $$$$$$$/ Magnum opus
 
Learn more about EverRise and the EverRise Ecosystem of dApps and
how our utilities and partners can help protect your investors
and help your project grow: https://everrise.com
                            ,░░▒▒▒▒▒▒╣╣╣╣╣╣▒▒▒▒▒▒▒░░░
                       ░▒▒▒╢╣╢╣╣╣╣╢╢╢╢╢╢╢╢╣╣╣╣╣╣╣╣╣╣╢▒▒▒▒░.
                   ░▒▒╢╣╢╢╣╣╣╣╣╣╣╣╣╢╢╢╢╢╢╢╣╣╣╣╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒░░
               ,░╥▒╣╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╢╢╢╢╢╢╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒░░
             ╓╥▒╢╢╣▓▓▓▓▓╣╣╣╣╣╣╣╣╣╣╣╢╢╢╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒░.
           ╓╥╢╫╣▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣╣╣╢╢╣╣▒▒▒▒╢╢╣╣╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒░.
         ,▒╢╫▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣╣╣╣╣╣▒░  ░▒╢╣╣╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░.
       ,▒╢╫╫▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣╣╣╣▒░░    `░▒▒╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
      ░▒╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣╣▒▒░        `░▒▒╢╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░.
     ░╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣▒░            `▒▒▒╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
   ,░▒╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╢╣▒░`               "▒▒╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
   ░╢╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣▒▒░                   ░▒▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
 .░▒╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣▒▒░                      `░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
 ░▒╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╢╣▒▒░`      ░░▒░    ░▒░░       ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░,
 ▒▒╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣▒▒░     ,░▒▒╣╣▒░   ░╢▒▒▒░,      ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
 ╣╣╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣▒`    ,╓▒▒╢╫╣╣▒▒    ░▒▒╣╣▒▒▒░.     ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
 ╢╢╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣▒`   ,,▒╢╢╫╣╣╣╣▒▒░    ░▒▒╣╣╣╢╣▒▒░░     ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣▒░`  ,▒▒╢╣╣╣╣╣╣╣╣▒▒░    ░░▒▒╣╣╣╣╣╣╣▒▒░.   "░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ╣╣▓▓▓▓▓▓▓▓▓▓▓▓╣╣▒▒░ ░░▒╢╢╣╣╣╣╣╣╣╣╣▒▒░      ░▒▒╢╣╣╣╣╣╣╣╣▒▒▒░,  ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ╢╢╣▓▓▓▓▓▓▓▓▓▓▓╣▒░░▒▒╢╢╢╫╣╣╣╣╣╣╣╣╣╢▒▒        ░▒╢╣╣╣╣╣╣╣╣▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
 ╣╣╢▓▓▓▓▓▓▓▓▓▓▓╣╣▒╢╢╢╣▓▓╣╣╣╣╣╣╣╣╣╢╣▒░        ░▒╣╣╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
 ▒▒╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣╣▒▒░        .▒▒▒╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
 ▒▒╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╢▒▒░░         ░▒▒╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░
 ░░▒╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣▒▒░          ░░▒╣╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
   ▒╫╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣▒░`           ░▒╢╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
   ░▒╢╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣▒░             ▒╢╣╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░`
    `▒╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣╣╣▒              ░▒▒╣╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
     └▒╢╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣▒▒░              ░▒▒▒╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
      `░▒╢╢▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣▒▒░              ░░▒▒╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
        ░▒╢╢▓▓▓▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣╣▒░                ░▒▒╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░`
          ░▒╢╢╫▓▓▓▓▓▓▓▓▓╣╣╣╣╣╣▒▒                  ░▒╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒░`
            `▒╢╣╢╣▓▓▓▓▓▓╣╣╣╣╣╢▒░                  ░▒╣╣╣╣▒▒▒▒▒▒▒▒▒▒▒▒░`
               ░▒╢╢╢╣▓▓▓╣╣╣╣╣╣▒░                  .▒▒▒╣╣▒▒▒▒▒▒▒▒▒▒░
                 `░▒╢╢▓▓╣╣╣╣╣▒▒░                   ░▒▒▒╣╣╣╣╣▒▒▒░
                    ``╙▒▒╣╢╣▒▒░                    ░░▒╢▒▒▒▒░`
                        ``╙╜``                       ````
*/

error NotZeroAddress();    // 0x66385fa3
error CallerNotApproved(); // 0x4014f1a5
error InvalidAddress();    // 0xe6c4247b

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

error CallerNotOwner();

contract Ownable is IOwnable, Context {
    address public owner;

    function _onlyOwner() private view {
        if (owner != _msgSender()) revert CallerNotOwner();
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    // Allow contract ownership and access to contract onlyOwner functions
    // to be locked using EverOwn with control gated by community vote.
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert NotZeroAddress();

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

error FailedEthSend();
error MaxDistributionsFromAddress();
error NotReadyToDistribute();
error NotAllowedToDistribute();
error NotAllowedToClaim();
error InvalidParameter();

interface IMementoRise {
    function mint(address to, uint256 tokenId, uint256 amount) external;
    function balanceOf(address account, uint256 tokenId) external view returns (uint256);
    function royaltyAddress() external view returns (address payable);
    function getAllTokensHeld(address account) external view returns (uint96[] memory tokenIds, uint256[] memory amounts);
    function setAllowedCreateFrom(uint16 nftType, address contractAddress) external;
}

interface IUniswapV2Pair {
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
}

interface INftRise {
    function createRewards(uint256 amount) external;
    function addAddressToCreate(address account) external;
}

interface IEverRise is IERC20 {
    function owner() external returns (address);
    function uniswapV2Pair() external view returns (IUniswapV2Pair);
}

struct Stats {
    uint256 reservesBalance;
    uint256 liquidityToken;
    uint256 liquidityCoin;
    uint256 staked;
    uint256 aveMultiplier;
    uint256 rewards;
    uint256 volumeBuy;
    uint256 volumeSell;
    uint256 volumeTrade;
    uint256 bridgeVault;
    uint256 tokenPriceCoin;
    uint256 coinPriceStable;
    uint256 tokenPriceStable;
    uint256 marketCap;
    uint128 blockNumber;
    uint64 timestamp;
    uint32 holders;
    uint8 tokenDecimals;
    uint8 coinDecimals;
    uint8 stableDecimals;
    uint8 multiplierDecimals;
}

interface IEverStats {
    function getStats() external view returns (Stats memory stats);
}

struct DistributorDetails {
    uint128 seed;
    uint96 distributedAmount; // Max 79 Bn tokens
    uint16 distributions; // Max 16k distributions
    uint16 claims; // Max 16k claims
} // Total 256 bits, 20000 gwei gas

IERC20 constant veRiseAddress = IERC20(
    0xDbA7b24257fC6e397cB7368B4BC922E944072f1b
);
IEverRise constant everRiseToken = IEverRise(
    0xC17c30e98541188614dF99239cABD40280810cA3
);
IMementoRise constant mementoRise = IMementoRise(
    0x1C57a5eE9C5A90C9a5e31B5265175e0642b943b1
);
INftRise constant nftRise = INftRise(
    0x23cD2E6b283754Fd2340a75732f9DdBb5d11807e
);
IEverStats constant everStats = IEverStats(
    0x889f26f688f0b757F84e5C07bf9FeC6D6c368Af2
);

contract RiseDistributor is Ownable {
    event TransferExternalTokens(address indexed tokenAddress, address indexed to, uint256 count);
    event TransferEthBalance(address indexed to, uint256 count);
    event ExclusionListChanged(address indexed account, bool excluded);
    event RiseFeeAddressChanged(address indexed account);
    event MaxDistributeAllowedChanged(uint256 maxTimesDistributeAllowed);
    event RiseFeeUpdated(uint256 riseFee);
    event RemainingAmountUpdated(uint256 newRemainingAmount);
    event MintFeeUpdated(uint256 mintFee);
    event DistributionVariablesUpdated(uint256 A, uint256 B, uint256 C);
    event BaselineAmountToDistributeUpdated(uint256 amount);
    event DistributedToken(address indexed token, uint256 amount);

    uint256 immutable tokenIdBase;

    uint256 public riseFee = 10_000 * 10**18;
    address public riseFeeAddress = 0x869Cf2253206951D16dB746dDF2212809BA8C8a3;

    uint256 public maxTimesDistributeAllowed = 1;
    uint256 public mintFee;
    uint256 public nextClaim = block.timestamp + 480 days;
    uint256 public launchTime;

    uint256 public distributionVariableA = 15438;
    uint256 public distributionVariableB = 11;
    uint256 public distributionVariableC = 100135;
    uint256 public baselineAmountToDistribute = 1_423_555_575  * 10**18; 

    uint256 public remainingAmount;
    uint256 public lastDistributionAmount;
    uint256 public lastRemainingAmount;
    uint256 public totalDistributedAmount;

    mapping(address => DistributorDetails) public claimedReward;
    mapping(address => bool) public excludedFromDistributeLimit;

    // Start at 1 so first set isn't more expensive
    uint256 private _countClaimed = 1;
    bool private diamondAwarded;

    constructor() {
        mintFee = getDefaultCreateFee();
        tokenIdBase = 4 + (getChain() << 16);
        address deployer = everRiseToken.owner();
        excludedFromDistributeLimit[deployer] = true;
        transferOwnership(deployer);
    }

    function getAccountDetails(address account) public view returns 
        (bool canClaim, 
        bool canDistribute, 
        bool isStaker, 
        bool isNftHolder, 
        uint128 timeToNextDistribution, 
        uint128 _nextClaim, 
        uint128 timeStamp,
        uint256 amountToDistribute)
    {
        DistributorDetails memory details = claimedReward[account];
        canClaim = details.claims < details.distributions;
        canDistribute = details.distributions < maxTimesDistributeAllowed && checkNftHolder(account);
        isStaker = veRiseAddress.balanceOf(account) > 0;
        isNftHolder = checkNftHolder(account);
        timeToNextDistribution = uint128(block.timestamp < nextClaim ? nextClaim - block.timestamp : 0);
        _nextClaim = uint128(nextClaim);
        timeStamp = uint128(block.timestamp);

        amountToDistribute = getAmountToDistribute(remainingAmount, daysSince(_nextClaim));
        if (timeToNextDistribution > 0) {
            if (timeToNextDistribution > 1 days) {
                amountToDistribute = 0;
            } else {
                amountToDistribute = amountToDistribute * (1 days - timeToNextDistribution) / 1 days;
            }
        }
    }

    function activate(uint256 tokensToDistribute) external onlyOwner {
        tokensToDistribute *= 10**18;
        
        require(tokensToDistribute >= baselineAmountToDistribute / 100, "Distribution tokens too low");
        require(tokensToDistribute <= baselineAmountToDistribute, "Distribution tokens too high");

        launchTime = nextClaim = getNextClaim(uint160(address(block.coinbase)));
        lastRemainingAmount = remainingAmount = tokensToDistribute;
        lastDistributionAmount = 0;
    }

    function claimDistributorAchievement() external payable returns (uint256 tokenId) {
        address account = _msgSender();

        DistributorDetails memory details = claimedReward[account];

        if (details.claims >= details.distributions) revert NotAllowedToClaim();

        uint16 claims = details.claims;
        unchecked {
            ++claims;
        }
        details.claims = claims;

        claimedReward[account] = details;

        everRiseToken.transferFrom(account, riseFeeAddress, riseFee);
        distributeMintFee(mementoRise.royaltyAddress());

        ++_countClaimed;
        tokenId = getTokenId(account, details.seed);

        mementoRise.mint(account, tokenId, 1);
    }

    function distributeRiseRewards() external returns (uint256) {
        address account = _msgSender();
        if (block.timestamp < nextClaim) revert NotReadyToDistribute();

        DistributorDetails memory details = claimedReward[account];
        if (!excludedFromDistributeLimit[account]) {
            // Check eligibility
            if (details.distributions >= maxTimesDistributeAllowed)
                revert MaxDistributionsFromAddress();
            if (
                veRiseAddress.balanceOf(account) == 0 &&
                !checkNftHolder(account)
            ) revert NotAllowedToDistribute();
        }

        uint256 remaining = remainingAmount;
        uint256 amount = getAmountToDistribute(remaining, daysSinceStart());

        require(amount < 5 * 10**6 * 10**18, "Daily amount is too high");

        if (amount == 0) revert("No RISE to distribute");

        uint256 seed0 = uint256(blockhash(block.number - 1));

        ++details.distributions;
        details.distributedAmount += uint96(amount);
        details.seed = uint128(seed0);

        claimedReward[account] = details;
        nextClaim = getNextClaim(uint160(address(block.coinbase)));

        lastRemainingAmount = remaining;
        lastDistributionAmount = amount;

        emit DistributedToken(address(everRiseToken), amount);
        
        remainingAmount -= amount;
        totalDistributedAmount += amount;

        // Do transfer
        everRiseToken.transfer(address(nftRise), amount);
        nftRise.createRewards(amount);
        
        return amount;
    }

    function countClaimed() external view returns (uint256) {
        // Subtract one to return real count
        return _countClaimed - 1;
    }

    function changeRiseFeeAddress(address account) external onlyOwner {
        if (account == address(0)) revert NotZeroAddress();

        riseFeeAddress = account;

        emit RiseFeeAddressChanged(account);
    }

    function changeRemainingAmount(uint256 newRemainingAmount) external onlyOwner {
        require(newRemainingAmount <= baselineAmountToDistribute, "Distribution tokens too high");
        remainingAmount = newRemainingAmount;

        emit RemainingAmountUpdated(newRemainingAmount);
    }

    function excludeFromDistributeLimit(address account, bool excluded) external onlyOwner {
        if (account == address(0)) revert NotZeroAddress();

        excludedFromDistributeLimit[account] = excluded;

        emit ExclusionListChanged(account, excluded);
    }

    function changeMaxDistributions(uint256 count) external onlyOwner {
        maxTimesDistributeAllowed = count;

        emit MaxDistributeAllowedChanged(count);
    }

    function changeRiseFee(uint256 value) external onlyOwner {
        if (value < 1 * 10**18) revert InvalidParameter(); // 1

        riseFee = value;

        emit RiseFeeUpdated(value);
    }

    function changeMintFee(uint256 value) external onlyOwner {
        if (value < 1 * 10**14) revert InvalidParameter(); // 0.0001

        mintFee = value;

        emit MintFeeUpdated(value);
    }

    function setDistributionVariables(uint256 A, uint256 B, uint256 C) external onlyOwner {
        distributionVariableA = A;
        distributionVariableB = B;
        distributionVariableC = C;

        emit DistributionVariablesUpdated(A, B, C);
    }

    function setBaselineAmountToDistribute(uint256 amount) external onlyOwner {
        baselineAmountToDistribute = amount;

        emit BaselineAmountToDistributeUpdated(amount);
    }

    function getNextClaim(uint256 seed0) public view returns (uint256) {
        return (block.timestamp - (block.timestamp % 1 days) + 1 days) + 
            (getRandom(_msgSender(), seed0) % 24 hours);
    }

    function getAmountToDistribute(uint256 remaining, uint256 _daysSinceStart) public view returns (uint256) {
        if (launchTime == 0) return 0;

        uint256 amountToDistribute = (
            distributionVariableA * _daysSinceStart -
            distributionVariableB * _daysSinceStart * _daysSinceStart +
            distributionVariableC) * 10**18;

        uint256 theoreticalTotalAmountDistributed = _daysSinceStart == 0
            ? 0
            : theoreticTotalAmount(_daysSinceStart - 1);

        uint256 theoreticalRemaining = baselineAmountToDistribute < theoreticalTotalAmountDistributed
            ? 0 
            : (baselineAmountToDistribute - theoreticalTotalAmountDistributed);

        if (theoreticalRemaining != 0) {
            uint256 factor = (remaining * 10**18) / (theoreticalRemaining);
            amountToDistribute = amountToDistribute * factor / 10**18;
        } else {
            amountToDistribute = lastDistributionAmount;
        }

        uint256 minDailyDelta = lastRemainingAmount == 0
            ? 0
            : (lastDistributionAmount / lastRemainingAmount) * remaining;

        amountToDistribute = amountToDistribute > minDailyDelta
            ? amountToDistribute
            : minDailyDelta;

        amountToDistribute = amountToDistribute > remaining
            ? remaining
            : amountToDistribute;

        uint256 balance = everRiseToken.balanceOf(address(this));
        if (balance < remaining) remaining = balance;

        amountToDistribute = amountToDistribute > remaining
            ? remaining
            : amountToDistribute;

        return amountToDistribute;
    }

    function daysSince(uint256 timestamp) public view returns (uint256) {
        uint256 ts = timestamp - (timestamp % 1 days);
        uint256 startDay = launchTime;
        startDay -= (startDay % 1 days);
        return (ts - startDay) / 1 days;
    }

    function daysSinceStart() public view returns (uint256) {
        return daysSince(block.timestamp);
    }

    function theoreticTotalAmount(uint256 day) public view returns (uint256) {
        uint256 aPart = (day + 1) * (day * distributionVariableA) / 2;
        uint256 k0 = 2;
        uint256 k1 = 3;
        uint256 k2 = 1;
        uint256 k3 = 0;
        uint256 bPart = (k3 +
            k2 * day +
            (day > 1 ? k1 * day * (day - 1) / 2 : 0) +
            (day > 2 ? k0 * day * (day - 1) * (day - 2) / 6 : 0)) * distributionVariableB;
        uint256 cPart = (day + 1) * distributionVariableC;

        return (aPart - bPart + cPart) * 10**18;
    }

    function checkNftHolder(address account) public view returns (bool) {
        (, uint256[] memory amounts) = mementoRise.getAllTokensHeld(account);

        uint256 count = amounts.length;
        if (count == 0) return false;

        for (uint256 i = 0; i < count; ) {
            if (amounts[i] > 0) return true;

            unchecked {
                ++i;
            }
        }

        return false;
    }

    function getRandom(address account, uint256 prevSeed) private view returns (uint256 seed) {
        IUniswapV2Pair pair = everRiseToken.uniswapV2Pair();
        Stats memory stats = everStats.getStats();
        seed = 
            uint256(
                keccak256(
                    abi.encodePacked(
                        pair.price0CumulativeLast(),
                        pair.price1CumulativeLast(),
                        account,
                        stats.coinPriceStable,
                        stats.reservesBalance,
                        stats.staked,
                        stats.volumeBuy,
                        stats.volumeSell,
                        stats.bridgeVault,
                        stats.holders,
                        prevSeed,
                        _countClaimed,
                        block.number,
                        tx.origin
                    )
                )
            );
    }

    function getTokenId(address account, uint256 prevSeed) private returns (uint256 tokenId)
    {
        uint256 seed = 0xfff & getRandom(account, prevSeed);

        tokenId = tokenIdBase;
        // 40% Anodized, 30% bronze, 20% silver, 10% gold, 1 diamond
        bool isDiamond = false;
        if (!diamondAwarded) {
            if (_countClaimed > 470) {
                isDiamond = true;
            } else if (seed == 0xfff) {
                isDiamond = true;
            }
        }

        if (isDiamond) {
            diamondAwarded = true;
            tokenId += 4 << 24;
        } else if (seed > 3686) {
            // Gold
            tokenId += 3 << 24;
        } else if (seed > 2867) {
            // Silver
            tokenId += 2 << 24;
        } else if (seed > 1639) {
            // Bronze
            tokenId += 1 << 24;
        } 
        // Otherwise Anodized
    }

    function distributeMintFee(address payable receiver) private {
        require(msg.value >= mintFee, "Mint fee not covered");

        uint256 _balance = address(this).balance;
        if (_balance > 0) {
            // Transfer everything, easier than transferring extras later
            _sendEthViaCall(receiver, _balance);
        }
    }

    function getChain() private view returns (uint256) {
        uint256 chainId = block.chainid;
        if (
            chainId == 1 ||
            chainId == 3 ||
            chainId == 4 ||
            chainId == 5 ||
            chainId == 42
        )
            // Ethereum
            return 4;
        if (chainId == 56 || chainId == 97)
            // BNB
            return 2;
        if (chainId == 137 || chainId == 80001)
            // Polygon
            return 3;
        if (chainId == 250 || chainId == 4002)
            // Fantom
            return 1;
        if (chainId == 43114 || chainId == 43113)
            // Avalanche
            return 0;

        require(false, "Unknown chain");
        return 0;
    }

    function getDefaultCreateFee() private view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 1)
            // Ethereum
            return 2 * 10**16; // 0.02
        if (chainId == 56)
            // BNB
            return 1 * 10**17; // 0.1
        if (chainId == 137)
            // Polygon
            return 30 * 10**18; // 30
        if (chainId == 250)
            // Fantom
            return 100 * 10**18; // 100
        if (chainId == 43114)
            // Avalanche
            return 1 * 10**18; // 1

        return 300 * 10**18;
    }

    // Token balance management

    function transferBalance(uint256 amount) external onlyOwner {
        _sendEthViaCall(_msgSender(), amount);
    }

    function transferExternalTokens(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (tokenAddress == address(0)) revert NotZeroAddress();
        _transferTokens(tokenAddress, to, amount);
    }

    function _sendEthViaCall(address payable to, uint256 amount) private {
        (bool sent, ) = to.call{value: amount}("");
        if (!sent) revert FailedEthSend();
        emit TransferEthBalance(to, amount);
    }

    function _transferTokens(
        address tokenAddress,
        address to,
        uint256 amount
    ) private {
        IERC20(tokenAddress).transfer(to, amount);
        emit TransferExternalTokens(tokenAddress, to, amount);
    }
}