// SPDX-License-Identifier: BSD-3-Clause

import {Comptroller} from "src/Comptroller.sol";
import {PriceOracle} from "src/PriceOracle.sol";
import {IBaseV1Pair} from "src/Swap/BaseV1-periphery.sol";
import {erc20, Math} from "src/Swap/BaseV1-libs.sol";
import {CToken} from "src/CToken.sol";

pragma solidity 0.8.11;

interface IBaseV1Router {
    function pairFor(address, address, bool) external view returns(address);
    function isPair(address) external view returns(bool);
    function isStable(address) external view returns(bool);
}

interface ICErc20 { 
    function underlying() external view returns(address);
}

contract CLMPriceOracle is PriceOracle {
    // address of cUsdc (underlying asset will be statically priced)
    address public immutable usdc;
    // address of cUsdt (underlying asset will be statically priced)
    address public immutable usdt;
    // address of cCanto (so we can set the underlying to wcanto)
    address public immutable cCanto;
    // address of note 
    address public immutable note;
    // address of wcanto
    address public immutable wcanto;

    // address of comptroller
    address public immutable comptroller;
    // address of router contract
    address public immutable router;

    // modifier to prevent other contracts from using the data from this oracle
    modifier onlyComptroller(address sender) {
        if (sender != comptroller) {
            // function returns default value (0)
            return;
        }
        _;
    }

    /// @dev Initializes PriceOracle, by setting immutable addresses 
    /// @param _comptroller, address of protocol comptroller 
    /// @param _router, address of protocol router
    /// @param _cCanto, address of CCanto lm
    /// @param _usdt, address of usdt
    /// @param _usdc, address of usdc
    /// @param _wcanto, address of wcanto
    /// @param _note, address of note
    constructor(
        address _comptroller, 
        address _router, 
        address _cCanto, 
        address _usdt,
        address _usdc,
        address _wcanto,
        address _note
    ) {
        comptroller = _comptroller;
        router = _router;
        usdc = _usdc;
        usdt = _usdt;
        note = _note;
        wcanto = _wcanto;
        cCanto = _cCanto;
    }

    /// @param cToken, the cToken (treated as CErc20) that is being priced, in the case of cCanto, although it is not a cErc20 it is treated as such.
    /// @return price, the price of the asset in Note, scaled by 1e18
    function getUnderlyingPrice(CToken cToken) external override view onlyComptroller(msg.sender) returns(uint) {
        address underlying;
        IBaseV1Router router_ = IBaseV1Router(router);
        // first check whether the cToken is cCanto
        if (address(cToken) == cCanto) {
            // return price from wcanto/note pool
            return getPriceNote(wcanto, false); 
        } else {
            // this is a CErc20, get the underlying address
            underlying = address(ICErc20(address(cToken)).underlying());
        }

        // if the underlying is note
        if (underlying == note) {
            return 1e18;
        }
        // if the underlying is usdc or usdt
        if ((underlying == usdc) || (underlying == usdt)) {
            uint decimals = 10 ** erc20(underlying).decimals();
            return 1e18 * 1e18 / (decimals);
        }
        // if the underlying is a pair
        if (router_.isPair(underlying)) {
            return getPriceLp(IBaseV1Pair(underlying));
        } else {
            // treat this as a stable asset
            if (router_.isStable(underlying)) {
                return getPriceNote(underlying, true);
            } else {
                return getPriceCanto(underlying) * getPriceNote(wcanto, false) / 1e18;
            }  
        }
    }

    /// @param pair, the address of the pair that the lpToken was minted from
    /// @return price, the price of the lpToken 
    function getPriceLp(IBaseV1Pair pair) internal view returns(uint) {
        uint[] memory supply = pair.sampleSupply(12, 1);
        uint[] memory prices;
        uint[] memory unitReserves;
        uint[] memory assetReserves;
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint decimals;

        // stables will be traded between note (unit asset is note)
        if (pair.stable()) {
           if (token0 == note) { //token0 is the unit, token1 will be priced with respect to this asset initially
                decimals = 10 ** (erc20(token1).decimals()); // we must normalize the price of token1 to 18 decimals
                prices = pair.sample(token1, decimals, 12, 1);
                (unitReserves, assetReserves) = pair.sampleReserves(12, 1);
            } else {
                decimals = 10 ** (erc20(token0).decimals());
                prices = pair.sample(token0, decimals, 12, 1);
                (assetReserves, unitReserves) = pair.sampleReserves(12, 1);
            }
        } else { 
            // the unit reserve will be Canto
            if (token0 == address(wcanto)) { // token0 is Canto, and the unit asset of this pair is Canto
                decimals = 10 ** (erc20(token1).decimals());
                prices = pair.sample(token1, decimals, 12, 1);
                (unitReserves, assetReserves) = pair.sampleReserves(12, 1);
            } else {
                decimals = 10 ** (erc20(token0)).decimals();
                prices = pair.sample(token0, decimals, 12, 1);
                (assetReserves, unitReserves) = pair.sampleReserves(12, 1);
            }
        }
        // now calcuate TVL from twaps and average
        uint LpPricesCumulative;
        
        // average over most recent 12 TWAPS
        for(uint i; i < 12; ++i) {
            uint token0TVL = (assetReserves[i] * prices[i]) / decimals;
             uint token1TVL = unitReserves[i]; // price of the unit asset is always 1
            LpPricesCumulative += (token0TVL + token1TVL) * 1e18 / supply[i];
        }
        uint LpPrice = LpPricesCumulative / 12; // take the average of the cumulative prices 
        
        if (pair.stable()) { // this asset has been priced in terms of Note
            return LpPrice;
        }
        // this asset has been priced in terms of Canto
        return LpPrice * getPriceNote(address(wcanto), false) / 1e18; // return the price in terms of Note
    }

    /// @param token_, the asset to be priced in terms of Canto
    /// @return price, the price of the asset in terms of canto, in the case of failure, return 0
    function getPriceCanto(address token_) internal view returns(uint) {
        erc20 token = erc20(token_);
        address pair = getVolatilePair(token_);
        // this pair does not exist, return 0
        uint price;
        if (pair == address(0)) {
            // price has already been initialized to zero
            return price;
        }
        // pair exists, now return the quoted amount of Canto for 10**token_decimals
        uint decimals = 10 ** token.decimals(); 
        // return 0 if there aren't enough observations
        if (IBaseV1Pair(pair).observationLength() < 8) {
            return 0;
        }

        price = IBaseV1Pair(pair).quote(token_, decimals, 8);
        // we now have the returned value, in the case of failed require return 0
        // return the price scaled by 1e18, and divided by the amtIn, (this is a vol-pair so operations are roughly linear)
        return price * 1e18 / decimals;
    }

    /// @param token_, the asset to be priced in terms of Canto
    /// @return price, the price of the asset in terms of canto, in the case of failure, return 0
    function getPriceNote(address token_, bool stable) internal view returns(uint) {
        erc20 token = erc20(token_);
        address pair;
        if (stable) {
            pair = getStablePair(token_);
        } else {
            // this pair is between wcanto / note (the only pair of this form)
            pair = getVolatilePair(note);
        }
        // this pair does not exist, return 0
        uint price;
        if (pair == address(0)) {
            // price has already been initialized to zero
            return price;
        }
        // pair exists, now return the quoted amount of Canto for 10**token_decimals
        uint decimals = 10 ** token.decimals(); 
        // return 0 if there aren't enough observations
        if (IBaseV1Pair(pair).observationLength() < 8) {
            return 0;
        }
        price = IBaseV1Pair(pair).quote(token_, decimals, 8);

        // we now have the returned value, in the case of failed require return 0
        // return the price scaled by 1e18, and divided by the amtIn, (this is a vol-pair so operations are roughly linear)
        return price * 1e18 / decimals;
    }

    /// @param token_, asset token in stable pair
    /// @return pair, address of pair if it is to exist, otherwise return address(0)
    function getStablePair(address token_) internal view returns(address) {
        IBaseV1Router router_ = IBaseV1Router(router);
        // return address of pair if it was to be deployed through the router's CREATE2 method
        address pair  = router_.pairFor(note, token_, true);
        // if the pair does not exist, return address(0)
        if (!router_.isPair(pair)) {
            pair = address(0);
        }
        return pair;
    }

    /// @param token_, asset token in non-stable pair
    /// @return pair, address of pair if it is to exist
    function getVolatilePair(address token_) internal view returns(address) {
        IBaseV1Router router_ = IBaseV1Router(router);
        address pair = router_.pairFor(wcanto, token_, false);
        // if the pair does not exist return address(0)
        if (!router_.isPair(pair)) {
            pair = address(0);
        }
        return pair;
    }
}