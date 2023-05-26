// SPDX-License-Identifier: MIT

// Etalon Token https://www.etalontoken.org was created by the World's Engineers https://www.worldsengineers.org 

// Etalon is a wealth accumulating token, your personal free pocket bank. 
pragma solidity >=0.4.22 <=0.8.7;

//import "hardhat/console.sol";
//import "./Pricing.sol";
import "./SellLimit.sol";
import "./GlobalLimits.sol";
import "contracts/LimboContract.sol";
import "contracts/TaxContract.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "@uniswap/v2-periphery/contracts/libraries/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; // adding the liquidity pool library
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

//import "@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Pool.sol/IUniswapV3Pool.json";
//import "@uniswap/v3-core/artifacts/contracts/interfaces/IUniswapV3Factory.sol";

// Etalon Token
contract EtalonToken is LimboContract("Etalon", "ETA") {
    using PRBMathUD60x18 for uint256;
    //using Pricing for Pricing.PricingData;
    using SellLimit for SellLimit.SellLimitData;
    using GlobalLimits for GlobalLimits.GlobalLimitsData;
    using SafeMath for uint256;

    // settings
    uint256 constant INITIAL_EMISSION = 1e30; // emission in constructor
    uint256 constant MAX_PRICE_FALL_PERCENT = 1e16; // 1e18=100% the maximum accepted percentage as a price movement for a single transaction from the account
    uint256 constant MAX_FALL_PERCENT_GLOBAL = 2e16; // (1%)the maximum accepted percentage as a price movement for multiple transactions
    uint256 constant PRICE_CONTROL_TIME_INTERVAL_MINUTES = 60; // time interval for price control (after this interval, a trace price measurement occurs)
    uint256 constant MIN_CELL_INTERVAL_SEC = 60; // minimal interval for a sell transaction
    uint256 constant MAX_ONE_ACCOUNT_AMMOUNT_PERCENT = 1e16; // the maximum percentage of the total supply that could be owned by the account(100%=1e18)

    // events
    event OnIncrementGlobalLimits(uint256 maxFallPercent); // increment global limits
    event OnDecrementGlobalLimits(uint256 maxFallPercent); // decrement global limits
    event OnIncrementSellLimit(uint256 maxFallPercent); // the sell limit while selling is raised up
    event OnDecrementSellLimit(uint256 maxFallPercent); // the sell limit while selling is pulled down

    uint256 public _TotalOnAccounts; // how many tokens are in total on all accounts (except the tax pools)
    mapping(address => uint256) _LastBuyTimes; // when was the last buy on any account (except the router)
    //Pricing.PricingData internal _Pricing; //  the current price
    SellLimit.SellLimitData public _SellLimit; // current limit on token withdraw for single account
    GlobalLimits.GlobalLimitsData public _GlobalLimits; // global limit on token withdraw
    IUniswapV2Router02 public _UniswapRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // the Uniswap router address
    IUniswapV2Pair public _UniswapV2Pair; // the pair
    bool _AddresSort;   // if true, than first address of token than weth

    constructor() {
        // developer's reward mint
        uint256 devCash = PRBMathUD60x18.mul(INITIAL_EMISSION, 3e16); // 3% in total
        uint256 dev1 = PRBMathUD60x18.mul(devCash, 6e17);   // 60% Captain Iceberg
        uint256 dev2 = PRBMathUD60x18.mul(devCash, 3e17);   // 30% Tsar
        uint256 dev3 = PRBMathUD60x18.mul(devCash, 1e17);   // 10% Dismorales
        // 60%
        _mint(0x2aBb515dD8bc2CD707FceDcbD5E780F9d899Ba34, PRBMathUD60x18.div(dev1, 3e18)); // A1
        _mint(0x322aA2aC658BA2Aa3A4D7D680eB2bFcFDbe8D50E, PRBMathUD60x18.div(dev1, 3e18)); // A2
        _mint(0x20572a1C268fBDEe8C3D53980513AB435c5673B0, PRBMathUD60x18.div(dev1, 3e18)); // A3
        // 30%
        _mint(0x1d3d6671a8A6650E60802613a3838865a4c260ef, PRBMathUD60x18.div(dev2, 5e18)); // K1
        _mint(0x623bD33fC62875B25E2bdcd73CaD25911cD034d2, PRBMathUD60x18.div(dev2, 5e18)); // K2
        _mint(0xCa063a5Fa006a0b2349c0F5eb984896b4396de85, PRBMathUD60x18.div(dev2, 5e18)); // K3
        _mint(0x13DaCD602d00B92A6942A0047fBbfE67f980f4A6, PRBMathUD60x18.div(dev2, 5e18)); // K4
        _mint(0x37A47B09454d54dECe30a19B7860975C14FAB83e, PRBMathUD60x18.div(dev2, 5e18)); // K5
        // 10%
        _mint(0xE102c1e0E0DB088ea15f9032b839E9C8cAf92cBC, dev3); // AR

        // create the emission
        _mint(address(this), INITIAL_EMISSION-devCash);

        // initializing the price corrector
        _SellLimit.Initialize(MAX_PRICE_FALL_PERCENT);
        // initializing the library that controls the maximum and the minimum of the sell limits
        _GlobalLimits.Initialize(
            MAX_FALL_PERCENT_GLOBAL,
            PRICE_CONTROL_TIME_INTERVAL_MINUTES,
            1 // minimum possible number
        );
    }

    function GetPoolTokenAndWeth() public view returns (uint256 token, uint256 weth){
        (uint256 Token0, uint256 Token1, ) = _UniswapV2Pair
            .getReserves();
        if(_AddresSort) return (Token0, Token1);
        else return (Token1, Token0);
    }
    // current average price (how much ETH for 1 ETA)
    function GetCurrentMidPrice() public view returns (uint256) {
        (uint256 token, uint256 weth) = GetPoolTokenAndWeth();
        return PRBMathUD60x18.div(weth, token);
    }

    // the amount of tokens with taxes but except Limbo
    function totalSupply() public view override returns (uint256) {
        return _TotalOnAccounts + GetTotalTax();
    }

    // the maximum of totalSupply that could be held on one account (100%=1e18)
    function GetMaxOneAccountPercent() public pure returns (uint256) {
        return MAX_ONE_ACCOUNT_AMMOUNT_PERCENT;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // correctors	
        require(from != to, "Error! Sending tokens to yourself is not permitted");

        // mint and burn proccessing
        if (from == address(0)) {
            _TotalOnAccounts += amount;
            return;
        }
        if (to == address(0)) {
            _TotalOnAccounts = _TotalOnAccounts.sub(amount);
            return;
        }

        // if transfter to router from the current contract then consider it as adding liquidity
        if (from == address(this) && to == address(_UniswapV2Pair)) return;

        // updating the global limits and dependent on them the local limits
        UpdateSellLimits(GetCurrentMidPrice());

        // limiting the quick sell-transaction to prevent the front-running
        QuickSaleLimit(from, to);
        // account limits
        MaxAccountAmmountLimit(from, to, amount);
        // get amount of ETA and ETH on router
        (uint256 RouterToken, uint256 RouterEth) = GetPoolTokenAndWeth();
        // the price corrector (sell limitations)
        if (from != address(0) && to == address(_UniswapV2Pair)) {
            _SellLimit.CheckLimit(RouterEth, RouterToken, amount);
        }

        // we list every account
        if (from != address(_UniswapV2Pair)) TryAddToAccountList(from);
        if (to != address(_UniswapV2Pair)) TryAddToAccountList(to);

        // try the next tax interval
        TryNextTaxInterval(_TotalOnAccounts.sub(RouterToken));

        // try to pay dividends and leave the Limbo
        if (from != address(_UniswapV2Pair))
            TryGetRewardAndLimboOut(from, amount);
        if (to != address(_UniswapV2Pair)) TryGetRewardAndLimboOut(to, amount);

        // get taxes
        uint256 tax = GetTax(amount, balanceOf(from), _TotalOnAccounts);

        // try to "mine" Limbo accounts with half tax
        uint256 minedLimbo = LimboMining(from, tax / 2);
        // decreasing the tax amount when Limbo account was mined
        tax = tax.sub(minedLimbo);
        // burn tax (we don not burn the pool tax)
        if (tax > 0 && from != address(_UniswapV2Pair)) {
            // burn tax
            _burn(from, tax);
            // adding the collected taxes to the Tax Pool
            AddTaxToPool(tax / 2);
        }
    }

    // updating the global limits and dependend on them the local limits
    function UpdateSellLimits(uint256 newPrice) internal {
        //console.log("newPrice: ", newPrice);
        int256 globalLimits = _GlobalLimits.Update(newPrice);
        if (globalLimits > 0) {
            if (globalLimits == 2)
                emit OnIncrementGlobalLimits(_GlobalLimits._MaxFallPercent);
            if (_SellLimit.IncrementLimits())
                emit OnIncrementSellLimit(_SellLimit.MaxFallPercent);
        }
        if (globalLimits < 0) {
            //console.log(2);
            if (globalLimits == -2)
                emit OnDecrementGlobalLimits(_GlobalLimits._MaxFallPercent);
            if (_SellLimit.DecrementLimits())
                emit OnDecrementSellLimit(_SellLimit.MaxFallPercent);
        }
        //console.log(3);
    }

    // preventing the "quick swap-selling right after artificial buy"
    // when a situation occurs then print an exception: "Error! Selling tokens is permitted in a minute after a buy. Try later."
    function QuickSaleLimit(address from, address to) internal {
        // limiters
        if (from == address(0) || to == address(0) || from == to) return;
        // if recieved from router then keep it's timestamp and don't do anything else
        if (from == address(_UniswapV2Pair)) {
            _LastBuyTimes[to] = block.timestamp; // memorize when was the last sell
            return;
        }
        // if tokens are send to router (swap selling)
        if (to == address(_UniswapV2Pair)) {
            uint256 timeInterval = block.timestamp - _LastBuyTimes[from];
            require(
                timeInterval >= MIN_CELL_INTERVAL_SEC * 1 seconds,
                "Error! Selling tokens is permitted in a minute after a buy. Try later."
            );
        }
    }

    // wallet limiters
    // if the account holds more than 1% of the circulating supply then print an exeption.
    function MaxAccountAmmountLimit(
        address from, // from who
        address to, // to whom
        uint256 addamount // amount to be added
    ) internal view {
        if (from == address(0) || to == address(_UniswapV2Pair)) return;
        require(
            balanceOf(to) + addamount <= MaxAccountAmmount(),
            "The recipient is holding 1% or more of the circulating supply. Sending to this address is not permitted"
        );
    }

    // the maximumum amount of tokens that could be held on one account
    function MaxAccountAmmount() public view returns (uint256) {
        return
            PRBMathUD60x18.mul(totalSupply(), MAX_ONE_ACCOUNT_AMMOUNT_PERCENT);
    }

    // gives back the maximum interval in seconds, after sell swaps are permitted
    function GetMinCellIntervalSec() public pure returns (uint256) {
        return MIN_CELL_INTERVAL_SEC;
    }

    // the maximum percenteage that price could be negatively changed 1e18=1%
    function GetMaxFallPercent() public view returns (uint256) {
        return _SellLimit.MaxFallPercent;
    }
}