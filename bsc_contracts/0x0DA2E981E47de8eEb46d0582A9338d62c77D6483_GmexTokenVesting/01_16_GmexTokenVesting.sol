/*
 * Global Market Exchange 
 * Official Site  : https://globalmarket.host
 * Private Sale   : https://globalmarketinc.io
 * Email          : [email protected]
 * Telegram       : https://t.me/gmekcommunity
 * Development    : Digichain Development Technology
 * Dev Is         : Tommy Chain & Team
 * Powering new equity blockchain on decentralized real and virtual projects
 * It is a revolutionary blockchain, DeFi and crypto architecture technology project
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/Pausable.sol";

import "./GmexToken.sol";

/**
 * @title GmexTokenVesting
 * @notice This contract is used for distributing certain
 * amount of Global Market Exchange tokens within each time period.
 */

contract GmexTokenVesting is Initializable, OwnableUpgradeable, Pausable {
    using SafeMathUpgradeable for uint256;

    GmexToken public gmexToken;

    event AddedToVesting(
        address _vestedAddress,
        uint256 _amount,
        uint256 _start,
        uint256 _duration
    );
    event TokensReleased(address _vestedAddress, uint256 amount);
    event VestIgnored(address _vestedAddress, uint256 timestamp);

    struct TokenGrant {
        uint256 _amount;
        uint256 _start;
        uint256 _duration; // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
        bool _vested;
        bool _ignore;
    }

    mapping(address => TokenGrant[]) public grants;

    uint256 public _totalGmexTokenVestedAmount;

    address public initialLiquidity;
    address public privateSale;
    address public publicSale;
    address public marketing;
    address public stakingIncentiveDiscount;
    address public advisor;
    address public team;
    address public treasury;

    uint256 private vestingTimestamp;

    function initialize(
        GmexToken _gmexToken,
        address _initialLiquidity,
        address _privateSale,
        address _publicSale,
        address _marketing,
        address _stakingIncentiveDiscount,
        address _advisor,
        address _team,
        address _treasury
    ) public initializer {
        __Ownable_init();
        __PausableUpgradeable_init();
        gmexToken = _gmexToken;
        initialLiquidity = _initialLiquidity;
        privateSale = _privateSale;
        publicSale = _publicSale;
        marketing = _marketing;
        stakingIncentiveDiscount = _stakingIncentiveDiscount;
        advisor = _advisor;
        team = _team;
        treasury = _treasury;

        // Thursday, June 16, 2022 12:00:00 AM (GMT)
        vestingTimestamp = 1655337600;
    }

    // update initialLiquidity address
    function updateInitialLiquidityAddress(address _initialLiquidity)
        public
        onlyOwner
    {
        require(
            grants[initialLiquidity].length <= 0,
            "Cannot update initial liquidity address !"
        );
        require(
            grants[_initialLiquidity].length <= 0,
            "Cannot update initial liquidity address !"
        );
        require(_initialLiquidity != privateSale, "Already assigned !");
        require(_initialLiquidity != publicSale, "Already assigned !");
        require(_initialLiquidity != marketing, "Already assigned !");
        require(
            _initialLiquidity != stakingIncentiveDiscount,
            "Already assigned !"
        );
        require(_initialLiquidity != advisor, "Already assigned !");
        require(_initialLiquidity != team, "Already assigned !");
        require(_initialLiquidity != treasury, "Already assigned !");
        initialLiquidity = _initialLiquidity;
    }

    // update privatesale address
    function updatePrivateSaleAddress(address _privateSale) public onlyOwner {
        require(
            grants[privateSale].length <= 0,
            "Cannot update private sale address !"
        );
        require(
            grants[_privateSale].length <= 0,
            "Cannot update private sale address !"
        );
        require(_privateSale != initialLiquidity, "Already assigned !");
        require(_privateSale != publicSale, "Already assigned !");
        require(_privateSale != marketing, "Already assigned !");
        require(_privateSale != stakingIncentiveDiscount, "Already assigned !");
        require(_privateSale != advisor, "Already assigned !");
        require(_privateSale != team, "Already assigned !");
        require(_privateSale != treasury, "Already assigned !");
        privateSale = _privateSale;
    }

    // update publicsale address
    function updatePublicSaleAddress(address _publicSale) public onlyOwner {
        require(
            grants[publicSale].length <= 0,
            "Cannot update public sale address !"
        );
        require(
            grants[_publicSale].length <= 0,
            "Cannot update public sale address !"
        );
        require(_publicSale != initialLiquidity, "Already assigned !");
        require(_publicSale != privateSale, "Already assigned !");
        require(_publicSale != marketing, "Already assigned !");
        require(_publicSale != stakingIncentiveDiscount, "Already assigned !");
        require(_publicSale != advisor, "Already assigned !");
        require(_publicSale != team, "Already assigned !");
        require(_publicSale != treasury, "Already assigned !");
        publicSale = _publicSale;
    }

    // update marketing address
    function updateMarketingAddress(address _marketing) public onlyOwner {
        require(
            grants[marketing].length <= 0,
            "Cannot update marketing address !"
        );
        require(
            grants[_marketing].length <= 0,
            "Cannot update marketing address !"
        );
        require(_marketing != initialLiquidity, "Already assigned !");
        require(_marketing != privateSale, "Already assigned !");
        require(_marketing != publicSale, "Already assigned !");
        require(_marketing != stakingIncentiveDiscount, "Already assigned !");
        require(_marketing != advisor, "Already assigned !");
        require(_marketing != team, "Already assigned !");
        require(_marketing != treasury, "Already assigned !");
        marketing = _marketing;
    }

    // update stakingIncentiveDiscount address
    function updateStakingIncentiveDiscountAddress(
        address _stakingIncentiveDiscount
    ) public onlyOwner {
        require(
            grants[stakingIncentiveDiscount].length <= 0,
            "Cannot update stakingIncentiveDiscount address !"
        );
        require(
            grants[_stakingIncentiveDiscount].length <= 0,
            "Cannot update stakingIncentiveDiscount address !"
        );
        require(
            _stakingIncentiveDiscount != initialLiquidity,
            "Already assigned !"
        );
        require(_stakingIncentiveDiscount != privateSale, "Already assigned !");
        require(_stakingIncentiveDiscount != publicSale, "Already assigned !");
        require(_stakingIncentiveDiscount != marketing, "Already assigned !");
        require(_stakingIncentiveDiscount != advisor, "Already assigned !");
        require(_stakingIncentiveDiscount != team, "Already assigned !");
        require(_stakingIncentiveDiscount != treasury, "Already assigned !");
        stakingIncentiveDiscount = _stakingIncentiveDiscount;
    }

    // update advisor address
    function updateAdvisorAddress(address _advisor) public onlyOwner {
        require(grants[advisor].length <= 0, "Cannot update advisor address !");
        require(
            grants[_advisor].length <= 0,
            "Cannot update advisor address !"
        );
        require(_advisor != initialLiquidity, "Already assigned !");
        require(_advisor != privateSale, "Already assigned !");
        require(_advisor != publicSale, "Already assigned !");
        require(_advisor != marketing, "Already assigned !");
        require(_advisor != stakingIncentiveDiscount, "Already assigned !");
        require(_advisor != team, "Already assigned !");
        require(_advisor != treasury, "Already assigned !");
        advisor = _advisor;
    }

    // update team address
    function updateTeamAddress(address _team) public onlyOwner {
        require(grants[team].length <= 0, "Cannot update team address !");
        require(grants[_team].length <= 0, "Cannot update team address !");
        require(_team != initialLiquidity, "Already assigned !");
        require(_team != privateSale, "Already assigned !");
        require(_team != publicSale, "Already assigned !");
        require(_team != marketing, "Already assigned !");
        require(_team != stakingIncentiveDiscount, "Already assigned !");
        require(_team != advisor, "Already assigned !");
        require(_team != treasury, "Already assigned !");
        team = _team;
    }

    // update treasury address
    function updateTreasuryAddress(address _treasury) public onlyOwner {
        require(
            grants[treasury].length <= 0,
            "Cannot update treasury address !"
        );
        require(
            grants[_treasury].length <= 0,
            "Cannot update treasury address !"
        );
        require(_treasury != initialLiquidity, "Already assigned !");
        require(_treasury != privateSale, "Already assigned !");
        require(_treasury != publicSale, "Already assigned !");
        require(_treasury != marketing, "Already assigned !");
        require(_treasury != stakingIncentiveDiscount, "Already assigned !");
        require(_treasury != advisor, "Already assigned !");
        require(_treasury != team, "Already assigned !");
        treasury = _treasury;
    }

    // update vestingTimestamp
    function updateVestingTimestamp(uint256 _vestingTimestamp)
        public
        onlyOwner
    {
        require(
            grants[initialLiquidity].length <= 0,
            "Cannot update vestingTimestamp: initialliquidity !"
        );
        require(
            grants[privateSale].length <= 0,
            "Cannot update vestingTimestamp: privateSale !"
        );
        require(
            grants[publicSale].length <= 0,
            "Cannot update vestingTimestamp: publicSale !"
        );
        require(
            grants[marketing].length <= 0,
            "Cannot update vestingTimestamp: marketing !"
        );
        require(
            grants[stakingIncentiveDiscount].length <= 0,
            "Cannot update vestingTimestamp: stakingIncentiveDiscount !"
        );
        require(
            grants[advisor].length <= 0,
            "Cannot update vestingTimestamp: advisor !"
        );
        require(
            grants[team].length <= 0,
            "Cannot update vestingTimestamp: team !"
        );
        require(
            grants[treasury].length <= 0,
            "Cannot update vestingTimestamp: treasury !"
        );
        vestingTimestamp = _vestingTimestamp;
    }

    /**
     * @notice Add to token vesting
     */
    function addToTokenVesting(
        address _vestingAddress,
        uint256 _amount,
        uint256 _start,
        uint256 _duration
    ) public onlyOwner {
        emit AddedToVesting(_vestingAddress, _amount, _start, _duration);
        grants[_vestingAddress].push(
            TokenGrant(_amount, _start, _duration, false, false)
        );
    }

    function createInitialLiquidityVesting() public onlyOwner {
        require(
            initialLiquidity != address(0),
            "Initial liquidity address is invalid !"
        );
        require(grants[initialLiquidity].length <= 0, "Already Created !");
        addToTokenVesting(
            initialLiquidity,
            500000000000000000000000000,
            vestingTimestamp,
            12 weeks
        );
    }

    function createPrivateSaleVesting() public onlyOwner {
        require(privateSale != address(0), "Private sale address is invalid !");
        require(grants[privateSale].length <= 0, "Already Created !");
        addToTokenVesting(
            privateSale,
            100000000000000000000000000,
            vestingTimestamp + 12 weeks,
            12 weeks
        );
        addToTokenVesting(
            privateSale,
            100000000000000000000000000,
            vestingTimestamp + 24 weeks,
            12 weeks
        );
        addToTokenVesting(
            privateSale,
            100000000000000000000000000,
            vestingTimestamp + 36 weeks,
            12 weeks
        );
        addToTokenVesting(
            privateSale,
            100000000000000000000000000,
            vestingTimestamp + 48 weeks,
            12 weeks
        );
        addToTokenVesting(
            privateSale,
            100000000000000000000000000,
            vestingTimestamp + 60 weeks,
            12 weeks
        );
    }

    function createPublicVesting() public onlyOwner {
        require(publicSale != address(0), "Public sale address is invalid !");
        require(grants[publicSale].length <= 0, "Already Created !");
        addToTokenVesting(
            publicSale,
            100000000000000000000000000,
            vestingTimestamp,
            12 weeks
        );
        addToTokenVesting(
            publicSale,
            100000000000000000000000000,
            vestingTimestamp + 12 weeks,
            12 weeks
        );
        addToTokenVesting(
            publicSale,
            100000000000000000000000000,
            vestingTimestamp + 24 weeks,
            12 weeks
        );
        addToTokenVesting(
            publicSale,
            100000000000000000000000000,
            vestingTimestamp + 36 weeks,
            12 weeks
        );
        addToTokenVesting(
            publicSale,
            100000000000000000000000000,
            vestingTimestamp + 48 weeks,
            12 weeks
        );
    }

    function createMarketingVesting() public onlyOwner {
        require(marketing != address(0), "Marketing address is invalid !");
        require(grants[marketing].length <= 0, "Already Created !");
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 36 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 60 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 84 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 108 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 132 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 156 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 180 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 204 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 228 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 252 weeks,
            12 weeks
        );
        addToTokenVesting(
            marketing,
            125000000000000000000000000,
            vestingTimestamp + 276 weeks,
            12 weeks
        );
    }

    function createStakingIncentiveDiscountVesting() public onlyOwner {
        require(
            stakingIncentiveDiscount != address(0),
            "Staking Incentive Discount address is invalid !"
        );
        require(
            grants[stakingIncentiveDiscount].length <= 0,
            "Already Created !"
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            100000000000000000000000000,
            vestingTimestamp,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            100000000000000000000000000,
            vestingTimestamp + 12 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            100000000000000000000000000,
            vestingTimestamp + 24 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            100000000000000000000000000,
            vestingTimestamp + 36 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            87500000000000000000000000,
            vestingTimestamp + 48 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            87500000000000000000000000,
            vestingTimestamp + 60 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            87500000000000000000000000,
            vestingTimestamp + 72 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            87500000000000000000000000,
            vestingTimestamp + 84 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            75000000000000000000000000,
            vestingTimestamp + 96 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            75000000000000000000000000,
            vestingTimestamp + 108 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            75000000000000000000000000,
            vestingTimestamp + 120 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            75000000000000000000000000,
            vestingTimestamp + 132 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            62500000000000000000000000,
            vestingTimestamp + 144 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            62500000000000000000000000,
            vestingTimestamp + 156 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            62500000000000000000000000,
            vestingTimestamp + 168 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            62500000000000000000000000,
            vestingTimestamp + 180 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            50000000000000000000000000,
            vestingTimestamp + 192 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            50000000000000000000000000,
            vestingTimestamp + 204 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            50000000000000000000000000,
            vestingTimestamp + 216 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            50000000000000000000000000,
            vestingTimestamp + 228 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            37500000000000000000000000,
            vestingTimestamp + 240 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            37500000000000000000000000,
            vestingTimestamp + 252 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            37500000000000000000000000,
            vestingTimestamp + 264 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            37500000000000000000000000,
            vestingTimestamp + 276 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 288 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 300 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 312 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 324 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 336 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 348 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 360 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 372 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 384 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 396 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            25000000000000000000000000,
            vestingTimestamp + 408 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            12500000000000000000000000,
            vestingTimestamp + 420 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            12500000000000000000000000,
            vestingTimestamp + 432 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            12500000000000000000000000,
            vestingTimestamp + 444 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            12500000000000000000000000,
            vestingTimestamp + 456 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            12500000000000000000000000,
            vestingTimestamp + 468 weeks,
            12 weeks
        );
        addToTokenVesting(
            stakingIncentiveDiscount,
            12500000000000000000000000,
            vestingTimestamp + 480 weeks,
            12 weeks
        );
    }

    function createAdvisorVesting() public onlyOwner {
        require(advisor != address(0), "Advisor address is invalid !");
        require(grants[advisor].length <= 0, "Already Created !");
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 72 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 96 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 120 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 144 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 168 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 192 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 216 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 240 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 264 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 288 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 312 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 336 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 360 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 384 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 408 weeks,
            12 weeks
        );
        addToTokenVesting(
            advisor,
            31250000000000000000000000,
            vestingTimestamp + 432 weeks,
            12 weeks
        );
    }

    function createTeamVesting() public onlyOwner {
        require(team != address(0), "Team address is invalid !");
        require(grants[team].length <= 0, "Already Created !");
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 72 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 96 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 120 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 144 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 168 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 192 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 216 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 240 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 264 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 288 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 312 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 336 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 360 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 384 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 408 weeks,
            12 weeks
        );
        addToTokenVesting(
            team,
            125000000000000000000000000,
            vestingTimestamp + 432 weeks,
            12 weeks
        );
    }

    function createTreasuryVesting() public onlyOwner {
        require(treasury != address(0), "Treasury address is invalid !");
        require(grants[treasury].length <= 0, "Already Created !");
        addToTokenVesting(
            treasury,
            250000000000000000000000000,
            vestingTimestamp,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 12 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 24 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 36 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 48 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 60 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 72 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 84 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 96 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 108 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 120 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 132 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 144 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 156 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 168 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 180 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 192 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 204 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 216 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 228 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 240 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 252 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 264 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 276 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 288 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 300 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 312 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 324 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 336 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 348 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 360 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 372 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 384 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 396 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 408 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 420 weeks,
            12 weeks
        );
        addToTokenVesting(
            treasury,
            62500000000000000000000000,
            vestingTimestamp + 432 weeks,
            12 weeks
        );
    }

    // Get number of gmex token vested
    function getTotalGmexTokenVestedAmount() public view returns (uint256) {
        return _totalGmexTokenVestedAmount;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release(address _vestingAddress) public whenNotPaused {
        require(_vestingAddress != address(0), "Vesting address is invalid !");
        TokenGrant[] storage vestingGrants = grants[_vestingAddress];

        require(vestingGrants.length > 0, "Vesting address not found !");

        uint256 currentTimestamp = block.timestamp;
        for (uint256 i = 0; i < vestingGrants.length; i++) {
            TokenGrant storage grant = vestingGrants[i];
            if (
                currentTimestamp >= grant._start &&
                currentTimestamp <= grant._start.add(grant._duration) &&
                !grant._vested &&
                !grant._ignore
            ) {
                _totalGmexTokenVestedAmount += grant._amount;
                grant._vested = true;
                gmexToken.transfer(_vestingAddress, grant._amount);
                emit TokensReleased(_vestingAddress, grant._amount);
            }
        }
    }

    /**
     * @notice Ignore vesting that falls under given timestamp
     */
    function ignoreParticularTimestampVesting(
        address _vestingAddress,
        uint256 timestamp
    ) public onlyOwner {
        require(_vestingAddress != address(0), "Vesting address is invalid !");
        TokenGrant[] storage vestingGrants = grants[_vestingAddress];

        require(vestingGrants.length > 0, "Vesting address not found !");

        for (uint256 i = 0; i < vestingGrants.length; i++) {
            TokenGrant storage grant = vestingGrants[i];
            if (
                timestamp >= grant._start &&
                timestamp <= grant._start.add(grant._duration) &&
                !grant._vested &&
                !grant._ignore
            ) {
                grant._ignore = true;
                emit VestIgnored(_vestingAddress, timestamp);
            }
        }
    }

    /**
     * @notice Get Latest Vest Information for given vesting address.
     */
    function getLatestVestInformation(address _vestingAddress)
        public
        view
        returns (
            uint256 amount,
            uint256 start,
            uint256 duration,
            bool vested,
            bool ignore
        )
    {
        require(_vestingAddress != address(0), "Vesting address is invalid !");
        TokenGrant[] memory vestingGrants = grants[_vestingAddress];

        require(vestingGrants.length > 0, "Vesting address not found !");

        uint256 currentTimestamp = block.timestamp;
        for (uint256 i = 0; i < vestingGrants.length; i++) {
            TokenGrant memory grant = vestingGrants[i];
            if (
                currentTimestamp >= grant._start &&
                currentTimestamp <= grant._start.add(grant._duration)
            ) {
                return (
                    grant._amount,
                    grant._start,
                    grant._duration,
                    grant._vested,
                    grant._ignore
                );
            }
        }
    }

    /**
     * @notice Get Vest Information for given vesting address and timestamp.
     */
    function getVestInformationForTimestamp(
        address _vestingAddress,
        uint256 timestamp
    )
        public
        view
        returns (
            uint256 amount,
            uint256 start,
            uint256 duration,
            bool vested,
            bool ignore
        )
    {
        require(_vestingAddress != address(0), "Vesting address is invalid !");
        TokenGrant[] memory vestingGrants = grants[_vestingAddress];

        require(vestingGrants.length > 0, "Vesting address not found !");

        for (uint256 i = 0; i < vestingGrants.length; i++) {
            TokenGrant memory grant = vestingGrants[i];
            if (
                timestamp >= grant._start &&
                timestamp <= grant._start.add(grant._duration)
            ) {
                return (
                    grant._amount,
                    grant._start,
                    grant._duration,
                    grant._vested,
                    grant._ignore
                );
            }
        }
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param amount the amount to withdraw
     */
    function withdraw(uint256 amount) public onlyOwner {
        uint256 availableBalance = gmexToken.balanceOf(address(this));
        require(amount <= availableBalance, "Requested amount exceeded !");
        gmexToken.transfer(owner(), amount);
    }

    function vestTokens() public onlyOwner {
        release(initialLiquidity);
        release(privateSale);
        release(publicSale);
        release(marketing);
        release(stakingIncentiveDiscount);
        release(advisor);
        release(team);
        release(treasury);
    }
}