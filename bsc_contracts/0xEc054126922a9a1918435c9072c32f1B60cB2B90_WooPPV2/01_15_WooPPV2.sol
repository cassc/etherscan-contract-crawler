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
import "./interfaces/IWooPPV2.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/IWooLendingManager.sol";

import "./libraries/TransferHelper.sol";

// OpenZeppelin contracts
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// REMOVE IT IN PROD
// import "hardhat/console.sol";

/// @title Woo pool for token swap, version 2.
/// @notice the implementation class for interface IWooPPV2, mainly for query and swap tokens.
contract WooPPV2 is Ownable, ReentrancyGuard, Pausable, IWooPPV2 {
    /* ----- Type declarations ----- */
    struct DecimalInfo {
        uint64 priceDec; // 10**(price_decimal)
        uint64 quoteDec; // 10**(quote_decimal)
        uint64 baseDec; // 10**(base_decimal)
    }

    struct TokenInfo {
        uint192 reserve; // balance reserve
        uint16 feeRate; // 1 in 100000; 10 = 1bp = 0.01%; max = 65535
    }

    /* ----- State variables ----- */
    address constant ETH_PLACEHOLDER_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public unclaimedFee; // NOTE: in quote token

    // wallet address --> is admin
    mapping(address => bool) public isAdmin;

    // token address --> fee rate
    mapping(address => TokenInfo) public tokenInfos;

    /// @inheritdoc IWooPPV2
    address public immutable override quoteToken;

    IWooracleV2 public wooracle;

    address public feeAddr;

    mapping(address => IWooLendingManager) public lendManagers;

    /* ----- Modifiers ----- */

    modifier onlyAdmin() {
        require(msg.sender == owner() || isAdmin[msg.sender], "WooPPV2: !admin");
        _;
    }

    constructor(address _quoteToken) {
        quoteToken = _quoteToken;
    }

    function init(address _wooracle, address _feeAddr) external onlyOwner {
        require(address(wooracle) == address(0), "WooPPV2: INIT_INVALID");
        wooracle = IWooracleV2(_wooracle);
        feeAddr = _feeAddr;
    }

    /* ----- External Functions ----- */

    /// @inheritdoc IWooPPV2
    function tryQuery(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view override returns (uint256 toAmount) {
        if (fromToken == quoteToken) {
            toAmount = _tryQuerySellQuote(toToken, fromAmount);
        } else if (toToken == quoteToken) {
            toAmount = _tryQuerySellBase(fromToken, fromAmount);
        } else {
            (toAmount, ) = _tryQueryBaseToBase(fromToken, toToken, fromAmount);
        }
    }

    /// @inheritdoc IWooPPV2
    function query(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view override returns (uint256 toAmount) {
        if (fromToken == quoteToken) {
            toAmount = _tryQuerySellQuote(toToken, fromAmount);
        } else if (toToken == quoteToken) {
            toAmount = _tryQuerySellBase(fromToken, fromAmount);
        } else {
            uint256 swapFee;
            (toAmount, swapFee) = _tryQueryBaseToBase(fromToken, toToken, fromAmount);
            require(swapFee <= tokenInfos[quoteToken].reserve, "WooPPV2: INSUFF_QUOTE_FOR_SWAPFEE");
        }
        require(toAmount <= tokenInfos[toToken].reserve, "WooPPV2: INSUFF_BALANCE");
    }

    /// @inheritdoc IWooPPV2
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external override returns (uint256 realToAmount) {
        if (fromToken == quoteToken) {
            // case 1: quoteToken --> baseToken
            realToAmount = _sellQuote(toToken, fromAmount, minToAmount, to, rebateTo);
        } else if (toToken == quoteToken) {
            // case 2: fromToken --> quoteToken
            realToAmount = _sellBase(fromToken, fromAmount, minToAmount, to, rebateTo);
        } else {
            // case 3: fromToken --> toToken (base to base)
            realToAmount = _swapBaseToBase(fromToken, toToken, fromAmount, minToAmount, to, rebateTo);
        }
    }

    /// @dev OKAY to be public method
    function claimFee() external nonReentrant {
        require(feeAddr != address(0), "WooPPV2: !feeAddr");
        uint256 amountToTransfer = unclaimedFee;
        unclaimedFee = 0;
        TransferHelper.safeTransfer(quoteToken, feeAddr, amountToTransfer);
    }

    /// @inheritdoc IWooPPV2
    /// @dev pool size = tokenInfo.reserve
    function poolSize(address token) public view override returns (uint256) {
        return tokenInfos[token].reserve;
    }

    /// @dev User pool balance (substracted unclaimed fee)
    function balance(address token) public view returns (uint256) {
        return token == quoteToken ? _rawBalance(token) - unclaimedFee : _rawBalance(token);
    }

    function decimalInfo(address baseToken) public view returns (DecimalInfo memory) {
        return
            DecimalInfo({
                priceDec: uint64(10)**(IWooracleV2(wooracle).decimals(baseToken)), // 8
                quoteDec: uint64(10)**(IERC20Metadata(quoteToken).decimals()), // 18 or 6
                baseDec: uint64(10)**(IERC20Metadata(baseToken).decimals()) // 18 or 8
            });
    }

    /* ----- Admin Functions ----- */

    function setWooracle(address _wooracle) external onlyAdmin {
        wooracle = IWooracleV2(_wooracle);
        emit WooracleUpdated(_wooracle);
    }

    function setFeeAddr(address _feeAddr) external onlyAdmin {
        feeAddr = _feeAddr;
        emit FeeAddrUpdated(_feeAddr);
    }

    function setFeeRate(address token, uint16 rate) external onlyAdmin {
        require(rate <= 1e5, "!rate");
        tokenInfos[token].feeRate = rate;
    }

    function pause() external onlyAdmin {
        super._pause();
    }

    function unpause() external onlyAdmin {
        super._unpause();
    }

    function setAdmin(address addr, bool flag) external onlyAdmin {
        require(addr != address(0), "WooPPV2: !admin");
        isAdmin[addr] = flag;
        emit AdminUpdated(addr, flag);
    }

    function deposit(address token, uint256 amount) public override nonReentrant onlyAdmin {
        uint256 balanceBefore = balance(token);
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        uint256 amountReceived = balance(token) - balanceBefore;
        require(amountReceived >= amount, "AMOUNT_INSUFF");

        tokenInfos[token].reserve = uint192(tokenInfos[token].reserve + amount);

        emit Deposit(token, msg.sender, amount);
    }

    function depositAll(address token) external onlyAdmin {
        deposit(token, IERC20(token).balanceOf(msg.sender));
    }

    function repayWeeklyLending(address wantToken) external nonReentrant onlyAdmin {
        IWooLendingManager lendManager = lendManagers[wantToken];
        lendManager.accureInterest();
        uint256 amount = lendManager.weeklyRepayment();
        address repaidToken = lendManager.want();
        if (amount > 0) {
            tokenInfos[repaidToken].reserve = uint192(tokenInfos[repaidToken].reserve - amount);
            TransferHelper.safeApprove(repaidToken, address(lendManager), amount);
            lendManager.repayWeekly();
        }
        emit Withdraw(repaidToken, address(lendManager), amount);
    }

    function withdraw(address token, uint256 amount) public nonReentrant onlyAdmin {
        require(tokenInfos[token].reserve >= amount, "WooPPV2: !amount");
        tokenInfos[token].reserve = uint192(tokenInfos[token].reserve - amount);
        TransferHelper.safeTransfer(token, owner(), amount);
        emit Withdraw(token, owner(), amount);
    }

    function withdrawAll(address token) external onlyAdmin {
        withdraw(token, poolSize(token));
    }

    function skim(address token) public nonReentrant onlyAdmin {
        TransferHelper.safeTransfer(token, owner(), balance(token) - tokenInfos[token].reserve);
    }

    function skimMulTokens(address[] memory tokens) external nonReentrant onlyAdmin {
        unchecked {
            uint256 len = tokens.length;
            for (uint256 i = 0; i < len; i++) {
                skim(tokens[i]);
            }
        }
    }

    function sync(address token) external nonReentrant onlyAdmin {
        tokenInfos[token].reserve = uint192(balance(token));
    }

    /* ----- Owner Functions ----- */

    function setLendManager(IWooLendingManager _lendManager) external onlyOwner {
        lendManagers[_lendManager.want()] = _lendManager;
        isAdmin[address(_lendManager)] = true;
        emit AdminUpdated(address(_lendManager), true);
    }

    function migrateToNewPool(address token, address newPool) external onlyOwner {
        require(token != address(0), "WooPPV2: !token");
        require(newPool != address(0), "WooPPV2: !newPool");

        tokenInfos[token].reserve = 0;

        uint256 bal = balance(token);
        TransferHelper.safeApprove(token, newPool, bal);
        WooPPV2(newPool).depositAll(token);

        emit Migrate(token, newPool, bal);
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyOwner {
        if (stuckToken == ETH_PLACEHOLDER_ADDR) {
            TransferHelper.safeTransferETH(msg.sender, address(this).balance);
        } else {
            uint256 amount = IERC20(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, msg.sender, amount);
        }
    }

    /* ----- Private Functions ----- */

    function _tryQuerySellBase(address baseToken, uint256 baseAmount)
        private
        view
        whenNotPaused
        returns (uint256 quoteAmount)
    {
        IWooracleV2.State memory state = IWooracleV2(wooracle).state(baseToken);
        (quoteAmount, ) = _calcQuoteAmountSellBase(baseToken, baseAmount, state);
        uint256 fee = (quoteAmount * tokenInfos[baseToken].feeRate) / 1e5;
        quoteAmount = quoteAmount - fee;
    }

    function _tryQuerySellQuote(address baseToken, uint256 quoteAmount)
        private
        view
        whenNotPaused
        returns (uint256 baseAmount)
    {
        uint256 swapFee = (quoteAmount * tokenInfos[baseToken].feeRate) / 1e5;
        quoteAmount = quoteAmount - swapFee;
        IWooracleV2.State memory state = IWooracleV2(wooracle).state(baseToken);
        (baseAmount, ) = _calcBaseAmountSellQuote(baseToken, quoteAmount, state);
    }

    function _tryQueryBaseToBase(
        address baseToken1,
        address baseToken2,
        uint256 base1Amount
    ) private view whenNotPaused returns (uint256 base2Amount, uint256 swapFee) {
        if (
            baseToken1 == address(0) || baseToken2 == address(0) || baseToken1 == quoteToken || baseToken2 == quoteToken
        ) {
            return (0, 0);
        }

        IWooracleV2.State memory state1 = IWooracleV2(wooracle).state(baseToken1);
        IWooracleV2.State memory state2 = IWooracleV2(wooracle).state(baseToken2);

        uint64 spread = _maxUInt64(state1.spread, state2.spread) / 2;
        uint16 feeRate = _maxUInt16(tokenInfos[baseToken1].feeRate, tokenInfos[baseToken2].feeRate);

        state1.spread = spread;
        state2.spread = spread;

        (uint256 quoteAmount, ) = _calcQuoteAmountSellBase(baseToken1, base1Amount, state1);

        swapFee = (quoteAmount * feeRate) / 1e5;
        quoteAmount = quoteAmount - swapFee;

        (base2Amount, ) = _calcBaseAmountSellQuote(baseToken2, quoteAmount, state2);
    }

    function _sellBase(
        address baseToken,
        uint256 baseAmount,
        uint256 minQuoteAmount,
        address to,
        address rebateTo
    ) private nonReentrant whenNotPaused returns (uint256 quoteAmount) {
        require(baseToken != address(0), "WooPPV2: !baseToken");
        require(to != address(0), "WooPPV2: !to");
        require(baseToken != quoteToken, "WooPPV2: baseToken==quoteToken");

        require(balance(baseToken) - tokenInfos[baseToken].reserve >= baseAmount, "WooPPV2: BASE_BALANCE_NOT_ENOUGH");

        {
            uint256 newPrice;
            IWooracleV2.State memory state = IWooracleV2(wooracle).state(baseToken);
            (quoteAmount, newPrice) = _calcQuoteAmountSellBase(baseToken, baseAmount, state);
            IWooracleV2(wooracle).postPrice(baseToken, uint128(newPrice));
            // console.log('Post new price:', newPrice, newPrice/1e8);
        }

        uint256 swapFee = (quoteAmount * tokenInfos[baseToken].feeRate) / 1e5;
        quoteAmount = quoteAmount - swapFee;
        require(quoteAmount >= minQuoteAmount, "WooPPV2: quoteAmount_LT_minQuoteAmount");

        unclaimedFee = unclaimedFee + swapFee;

        tokenInfos[baseToken].reserve = uint192(tokenInfos[baseToken].reserve + baseAmount);
        tokenInfos[quoteToken].reserve = uint192(tokenInfos[quoteToken].reserve - quoteAmount - swapFee);

        if (to != address(this)) {
            TransferHelper.safeTransfer(quoteToken, to, quoteAmount);
        }

        emit WooSwap(
            baseToken,
            quoteToken,
            baseAmount,
            quoteAmount,
            msg.sender,
            to,
            rebateTo,
            quoteAmount + swapFee,
            swapFee
        );
    }

    function _sellQuote(
        address baseToken,
        uint256 quoteAmount,
        uint256 minBaseAmount,
        address to,
        address rebateTo
    ) private nonReentrant whenNotPaused returns (uint256 baseAmount) {
        require(baseToken != address(0), "WooPPV2: !baseToken");
        require(to != address(0), "WooPPV2: !to");
        require(baseToken != quoteToken, "WooPPV2: baseToken==quoteToken");

        require(
            balance(quoteToken) - tokenInfos[quoteToken].reserve >= quoteAmount,
            "WooPPV2: QUOTE_BALANCE_NOT_ENOUGH"
        );

        uint256 swapFee = (quoteAmount * tokenInfos[baseToken].feeRate) / 1e5;
        quoteAmount = quoteAmount - swapFee;
        unclaimedFee = unclaimedFee + swapFee;

        {
            uint256 newPrice;
            IWooracleV2.State memory state = IWooracleV2(wooracle).state(baseToken);
            (baseAmount, newPrice) = _calcBaseAmountSellQuote(baseToken, quoteAmount, state);
            IWooracleV2(wooracle).postPrice(baseToken, uint128(newPrice));
            // console.log('Post new price:', newPrice, newPrice/1e8);
            require(baseAmount >= minBaseAmount, "WooPPV2: baseAmount_LT_minBaseAmount");
        }

        tokenInfos[baseToken].reserve = uint192(tokenInfos[baseToken].reserve - baseAmount);
        tokenInfos[quoteToken].reserve = uint192(tokenInfos[quoteToken].reserve + quoteAmount);

        if (to != address(this)) {
            TransferHelper.safeTransfer(baseToken, to, baseAmount);
        }

        emit WooSwap(
            quoteToken,
            baseToken,
            quoteAmount + swapFee,
            baseAmount,
            msg.sender,
            to,
            rebateTo,
            quoteAmount + swapFee,
            swapFee
        );
    }

    function _swapBaseToBase(
        address baseToken1,
        address baseToken2,
        uint256 base1Amount,
        uint256 minBase2Amount,
        address to,
        address rebateTo
    ) private nonReentrant whenNotPaused returns (uint256 base2Amount) {
        require(baseToken1 != address(0) && baseToken1 != quoteToken, "WooPPV2: !baseToken1");
        require(baseToken2 != address(0) && baseToken2 != quoteToken, "WooPPV2: !baseToken2");
        require(to != address(0), "WooPPV2: !to");

        require(balance(baseToken1) - tokenInfos[baseToken1].reserve >= base1Amount, "WooPPV2: !BASE1_BALANCE");

        IWooracleV2.State memory state1 = IWooracleV2(wooracle).state(baseToken1);
        IWooracleV2.State memory state2 = IWooracleV2(wooracle).state(baseToken2);

        uint256 swapFee;
        uint256 quoteAmount;
        {
            uint64 spread = _maxUInt64(state1.spread, state2.spread) / 2;
            uint16 feeRate = _maxUInt16(tokenInfos[baseToken1].feeRate, tokenInfos[baseToken2].feeRate);

            state1.spread = spread;
            state2.spread = spread;

            uint256 newBase1Price;
            (quoteAmount, newBase1Price) = _calcQuoteAmountSellBase(baseToken1, base1Amount, state1);
            IWooracleV2(wooracle).postPrice(baseToken1, uint128(newBase1Price));
            // console.log('Post new base1 price:', newBase1Price, newBase1Price/1e8);

            swapFee = (quoteAmount * feeRate) / 1e5;
        }

        quoteAmount = quoteAmount - swapFee;
        unclaimedFee = unclaimedFee + swapFee;

        tokenInfos[quoteToken].reserve = uint192(tokenInfos[quoteToken].reserve - swapFee);
        tokenInfos[baseToken1].reserve = uint192(tokenInfos[baseToken1].reserve + base1Amount);

        {
            uint256 newBase2Price;
            (base2Amount, newBase2Price) = _calcBaseAmountSellQuote(baseToken2, quoteAmount, state2);
            IWooracleV2(wooracle).postPrice(baseToken2, uint128(newBase2Price));
            // console.log('Post new base2 price:', newBase2Price, newBase2Price/1e8);
            require(base2Amount >= minBase2Amount, "WooPPV2: base2Amount_LT_minBase2Amount");
        }

        tokenInfos[baseToken2].reserve = uint192(tokenInfos[baseToken2].reserve - base2Amount);

        if (to != address(this)) {
            TransferHelper.safeTransfer(baseToken2, to, base2Amount);
        }

        emit WooSwap(
            baseToken1,
            baseToken2,
            base1Amount,
            base2Amount,
            msg.sender,
            to,
            rebateTo,
            quoteAmount + swapFee,
            swapFee
        );
    }

    /// @dev Get the pool's balance of the specified token
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// @dev forked and curtesy by Uniswap v3 core
    function _rawBalance(address token) private view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32, "WooPPV2: !BALANCE");
        return abi.decode(data, (uint256));
    }

    function _calcQuoteAmountSellBase(
        address baseToken,
        uint256 baseAmount,
        IWooracleV2.State memory state
    ) private view returns (uint256 quoteAmount, uint256 newPrice) {
        require(state.woFeasible, "WooPPV2: !ORACLE_FEASIBLE");

        DecimalInfo memory decs = decimalInfo(baseToken);

        // quoteAmount = baseAmount * oracle.price * (1 - oracle.k * baseAmount * oracle.price - oracle.spread)
        {
            uint256 coef = uint256(1e18) -
                ((uint256(state.coeff) * baseAmount * state.price) / decs.baseDec / decs.priceDec) -
                state.spread;
            quoteAmount = (((baseAmount * decs.quoteDec * state.price) / decs.priceDec) * coef) / 1e18 / decs.baseDec;
        }

        // newPrice = oracle.price * (1 - 2 * k * oracle.price * baseAmount)
        newPrice =
            ((uint256(1e18) - (uint256(2) * state.coeff * state.price * baseAmount) / decs.priceDec / decs.baseDec) *
                state.price) /
            1e18;
    }

    function _calcBaseAmountSellQuote(
        address baseToken,
        uint256 quoteAmount,
        IWooracleV2.State memory state
    ) private view returns (uint256 baseAmount, uint256 newPrice) {
        require(state.woFeasible, "WooPPV2: !ORACLE_FEASIBLE");

        DecimalInfo memory decs = decimalInfo(baseToken);

        // baseAmount = quoteAmount / oracle.price * (1 - oracle.k * quoteAmount - oracle.spread)
        {
            uint256 coef = uint256(1e18) - (quoteAmount * state.coeff) / decs.quoteDec - state.spread;
            baseAmount = (((quoteAmount * decs.baseDec * decs.priceDec) / state.price) * coef) / 1e18 / decs.quoteDec;
        }

        // new_price = oracle.price * (1 + 2 * k * quoteAmount)
        newPrice =
            ((uint256(1e18) * decs.quoteDec + uint256(2) * state.coeff * quoteAmount) * state.price) /
            decs.quoteDec /
            1e18;
    }

    function _maxUInt16(uint16 a, uint16 b) private pure returns (uint16) {
        return a > b ? a : b;
    }

    function _maxUInt64(uint64 a, uint64 b) private pure returns (uint64) {
        return a > b ? a : b;
    }
}