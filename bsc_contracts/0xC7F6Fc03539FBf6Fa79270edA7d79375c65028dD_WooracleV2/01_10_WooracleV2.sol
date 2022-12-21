// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import "./interfaces/IWooracleV2.sol";
import "./interfaces/AggregatorV3Interface.sol";

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Wooracle V2 contract
contract WooracleV2 is Ownable, IWooracleV2 {
    /* ----- State variables ----- */

    // 128 + 64 + 64 = 256 bits (slot size)
    struct TokenInfo {
        uint128 price; // as chainlink oracle (e.g. decimal = 8)
        uint64 coeff; // k: decimal = 18.    18.4 * 1e18
        uint64 spread; // s: decimal = 18.   spread <= 2e18   18.4 * 1e18
    }

    struct CLOracle {
        address oracle;
        uint8 decimal;
        bool cloPreferred;
    }

    mapping(address => TokenInfo) public infos;

    mapping(address => CLOracle) public clOracles;

    address public override quoteToken;
    uint256 public override timestamp;

    uint256 public staleDuration;
    uint64 public bound;

    mapping(address => bool) public isAdmin;

    constructor() {
        staleDuration = uint256(300);
        bound = uint64(1e16); // 1%
    }

    modifier onlyAdmin() {
        require(owner() == msg.sender || isAdmin[msg.sender], "Wooracle: !Admin");
        _;
    }

    /* ----- External Functions ----- */

    function setAdmin(address addr, bool flag) external onlyOwner {
        isAdmin[addr] = flag;
    }

    /// @dev Set the quote token address.
    /// @param _oracle the token address
    function setQuoteToken(address _quote, address _oracle) external onlyAdmin {
        quoteToken = _quote;
        CLOracle storage cloRef = clOracles[_quote];
        cloRef.oracle = _oracle;
        cloRef.decimal = AggregatorV3Interface(_oracle).decimals();
    }

    function setBound(uint64 _bound) external onlyOwner {
        bound = _bound;
    }

    function setCLOracle(
        address token,
        address _oracle,
        bool _cloPreferred
    ) external onlyAdmin {
        CLOracle storage cloRef = clOracles[token];
        cloRef.oracle = _oracle;
        cloRef.decimal = AggregatorV3Interface(_oracle).decimals();
        cloRef.cloPreferred = _cloPreferred;
    }

    function setCloPreferred(address token, bool _cloPreferred) external onlyAdmin {
        CLOracle storage cloRef = clOracles[token];
        cloRef.cloPreferred = _cloPreferred;
    }

    /// @dev Set the staleDuration.
    /// @param newStaleDuration the new stale duration
    function setStaleDuration(uint256 newStaleDuration) external onlyAdmin {
        staleDuration = newStaleDuration;
    }

    /// @dev Update the base token prices.
    /// @param base the baseToken address
    /// @param newPrice the new prices for the base token
    function postPrice(address base, uint128 newPrice) external override onlyAdmin {
        infos[base].price = newPrice;
        timestamp = block.timestamp;
    }

    /// @dev batch update baseTokens prices
    /// @param bases list of baseToken address
    /// @param newPrices the updated prices list
    function postPriceList(address[] calldata bases, uint128[] calldata newPrices) external onlyAdmin {
        uint256 length = bases.length;
        require(length == newPrices.length, "Wooracle: length_INVALID");

        // TODO: gas optimization:
        // https://ethereum.stackexchange.com/questions/113221/what-is-the-purpose-of-unchecked-in-solidity
        // https://forum.openzeppelin.com/t/a-collection-of-gas-optimisation-tricks/19966
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                infos[bases[i]].price = newPrices[i];
            }
        }

        timestamp = block.timestamp;
    }

    /// @dev update the spreads info.
    /// @param base baseToken address
    /// @param newSpread the new spreads
    function postSpread(address base, uint64 newSpread) external onlyAdmin {
        infos[base].spread = newSpread;
        timestamp = block.timestamp;
    }

    /// @dev batch update the spreads info.
    /// @param bases list of baseToken address
    /// @param newSpreads list of spreads info
    function postSpreadList(address[] calldata bases, uint64[] calldata newSpreads) external onlyAdmin {
        uint256 length = bases.length;
        require(length == newSpreads.length, "Wooracle: length_INVALID");

        unchecked {
            for (uint256 i = 0; i < length; i++) {
                infos[bases[i]].spread = newSpreads[i];
            }
        }

        timestamp = block.timestamp;
    }

    /// @dev update the state of the given base token.
    /// @param base baseToken address
    /// @param newPrice the new prices
    /// @param newSpread the new spreads
    /// @param newCoeff the new slippage coefficent
    function postState(
        address base,
        uint128 newPrice,
        uint64 newSpread,
        uint64 newCoeff
    ) external onlyAdmin {
        _setState(base, newPrice, newSpread, newCoeff);
        timestamp = block.timestamp;
    }

    /// @dev batch update the prices, spreads and slipagge coeffs info.
    /// @param bases list of baseToken address
    /// @param newPrices the prices list
    /// @param newSpreads the spreads list
    /// @param newCoeffs the slippage coefficent list
    function postStateList(
        address[] calldata bases,
        uint128[] calldata newPrices,
        uint64[] calldata newSpreads,
        uint64[] calldata newCoeffs
    ) external onlyAdmin {
        uint256 length = bases.length;
        unchecked {
            for (uint256 i = 0; i < length; i++) {
                _setState(bases[i], newPrices[i], newSpreads[i], newCoeffs[i]);
            }
        }
        timestamp = block.timestamp;
    }

    /*
        Price logic:
        - woPrice: wooracle price
        - cloPrice: chainlink price

        woFeasible is, price > 0 and price timestamp NOT stale

        when woFeasible && priceWithinBound     -> woPrice, feasible
        when woFeasible && !priceWithinBound    -> woPrice, infeasible
        when !woFeasible && clo_preferred       -> cloPrice, feasible
        when !woFeasible && !clo_preferred      -> cloPrice, infeasible
    */
    function price(address base) public view override returns (uint256 priceOut, bool feasible) {
        uint256 woPrice_ = uint256(infos[base].price);
        uint256 woPriceTimestamp = timestamp;

        (uint256 cloPrice_, ) = _cloPriceInQuote(base, quoteToken);

        bool woFeasible = woPrice_ != 0 && block.timestamp <= (woPriceTimestamp + staleDuration);
        bool woPriceInBound = cloPrice_ == 0 ||
            ((cloPrice_ * (1e18 - bound)) / 1e18 <= woPrice_ && woPrice_ <= (cloPrice_ * (1e18 + bound)) / 1e18);

        if (woFeasible) {
            priceOut = woPrice_;
            feasible = woPriceInBound;
        } else {
            priceOut = clOracles[base].cloPreferred ? cloPrice_ : 0;
            feasible = priceOut != 0;
        }
    }

    /// @notice the price decimal for the specified base token
    function decimals(address base) external view override returns (uint8) {
        uint8 d = clOracles[base].decimal;
        return d != 0 ? d : 8;
    }

    function cloPrice(address base) external view override returns (uint256 refPrice, uint256 refTimestamp) {
        return _cloPriceInQuote(base, quoteToken);
    }

    function isWoFeasible(address base) external view override returns (bool) {
        return infos[base].price != 0 && block.timestamp <= (timestamp + staleDuration);
    }

    function woSpread(address base) external view override returns (uint64) {
        return infos[base].spread;
    }

    function woCoeff(address base) external view override returns (uint64) {
        return infos[base].coeff;
    }

    // Wooracle price of the base token
    function woPrice(address base) external view override returns (uint128 priceOut, uint256 priceTimestampOut) {
        priceOut = infos[base].price;
        priceTimestampOut = timestamp;
    }

    function woState(address base) external view override returns (State memory) {
        TokenInfo memory info = infos[base];
        return
            State({
                price: info.price,
                spread: info.spread,
                coeff: info.coeff,
                woFeasible: (info.price != 0 && block.timestamp <= (timestamp + staleDuration))
            });
    }

    function state(address base) external view override returns (State memory) {
        TokenInfo memory info = infos[base];
        (uint256 basePrice, bool feasible) = price(base);
        return State({price: uint128(basePrice), spread: info.spread, coeff: info.coeff, woFeasible: feasible});
    }

    function cloAddress(address base) external view override returns (address clo) {
        clo = clOracles[base].oracle;
    }

    /* ----- Private Functions ----- */
    function _setState(
        address base,
        uint128 newPrice,
        uint64 newSpread,
        uint64 newCoeff
    ) private {
        TokenInfo storage info = infos[base];
        info.price = newPrice;
        info.spread = newSpread;
        info.coeff = newCoeff;
    }

    function _cloPriceInQuote(address fromToken, address toToken)
        private
        view
        returns (uint256 refPrice, uint256 refTimestamp)
    {
        address baseOracle = clOracles[fromToken].oracle;
        if (baseOracle == address(0)) {
            return (0, 0);
        }
        address quoteOracle = clOracles[toToken].oracle;
        uint8 quoteDecimal = clOracles[toToken].decimal;

        (, int256 rawBaseRefPrice, , uint256 baseUpdatedAt, ) = AggregatorV3Interface(baseOracle).latestRoundData();
        (, int256 rawQuoteRefPrice, , uint256 quoteUpdatedAt, ) = AggregatorV3Interface(quoteOracle).latestRoundData();
        uint256 baseRefPrice = uint256(rawBaseRefPrice);
        uint256 quoteRefPrice = uint256(rawQuoteRefPrice);

        // NOTE: Assume wooracle token decimal is same as chainlink token decimal.
        uint256 ceoff = uint256(10)**quoteDecimal;
        refPrice = (baseRefPrice * ceoff) / quoteRefPrice;
        refTimestamp = baseUpdatedAt >= quoteUpdatedAt ? quoteUpdatedAt : baseUpdatedAt;
    }
}