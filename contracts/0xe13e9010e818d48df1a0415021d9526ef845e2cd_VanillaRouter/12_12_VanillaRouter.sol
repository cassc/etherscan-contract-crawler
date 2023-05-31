// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./VanillaGovernanceToken.sol";
import "./UniswapTrader.sol";

/// @dev Needed functions from the WETH contract originally deployed in https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

/**
    @title The main entrypoint for Vanilla
*/
contract VanillaRouter is UniswapTrader {
    string private constant _ERROR_TRADE_EXPIRED = "b1";
    string private constant _ERROR_TRANSFER_FAILED = "b2";
    string private constant _ERROR_TOO_MANY_TRADES_PER_BLOCK = "b3";
    string private constant _ERROR_NO_TOKEN_OWNERSHIP = "b4";
    string private constant _ERROR_RESERVELIMIT_TOO_LOW = "b5";
    string private constant _ERROR_NO_SAFE_TOKENS = "b6";

    uint256 public immutable epoch;
    VanillaGovernanceToken public immutable vnlContract;
    uint128 public immutable reserveLimit;

    using SafeMath for uint256;

    // data for calculating volume-weighted average prices, average purchasing block, and limiting trades per block
    struct PriceData {
        uint256 ethSum;
        uint256 tokenSum;
        uint256 weightedBlockSum;
        uint256 latestBlock;
    }

    // Price data, indexed as [owner][token]
    mapping(address => mapping(address => PriceData)) public tokenPriceData;

    /**
       @dev Emitted when tokens are sold.
       @param seller The owner of tokens.
       @param token The address of the sold token.
       @param amount Number of sold tokens.
       @param eth The received ether from the trade.
       @param profit The calculated profit from the trade.
       @param reward The amount of VanillaGovernanceToken reward tokens transferred to seller.
       @param reserve The internally tracker Uniswap WETH reserve before trade.
     */
    event TokensSold(
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 eth,
        uint256 profit,
        uint256 reward,
        uint256 reserve
    );

    /**
       @dev Emitted when tokens are bought.
       @param buyer The new owner of tokens.
       @param token The address of the purchased token.
       @param eth The amount of ether spent in the trade.
       @param amount Number of purchased tokens.
       @param reserve The internally tracker Uniswap WETH reserve before trade.
     */
    event TokensPurchased(
        address indexed buyer,
        address indexed token,
        uint256 eth,
        uint256 amount,
        uint256 reserve
    );

    /**
        @notice Deploys the contract and the VanillaGovernanceToken contract.
        @dev initializes the token contract for safe reference and sets the epoch for reward calculations
        @param uniswapRouter The address of UniswapRouter contract
        @param limit The minimum WETH reserve for a token to be eligible in profit mining
        @param safeList The list of ERC-20 addresses that are considered "safe", and will be eligible for rewards
    */
    constructor(
        address uniswapRouter,
        uint128 limit,
        address[] memory safeList
    ) public UniswapTrader(uniswapRouter, limit, safeList) {
        vnlContract = new VanillaGovernanceToken();
        epoch = block.number;
        require(limit > 0, _ERROR_RESERVELIMIT_TOO_LOW);
        require(safeList.length > 0, _ERROR_NO_SAFE_TOKENS);
        reserveLimit = limit;
    }

    modifier beforeDeadline(uint256 deadline) {
        require(deadline >= block.timestamp, _ERROR_TRADE_EXPIRED);
        _;
    }

    /**
        @notice Buys the tokens with Ether. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function depositAndBuy(
        address token,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external payable beforeDeadline(blockTimeDeadline) {
        IWETH weth = IWETH(_wethAddr);
        uint256 numEth = msg.value;
        weth.deposit{value: numEth}();

        // execute swap using WETH-balance of this contract
        _executeBuy(msg.sender, address(this), token, numEth, numToken);
    }

    /**
        @notice Buys the tokens with WETH. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numEth The amount of WETH to spend. Needs to be pre-approved for the VanillaRouter.
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function buy(
        address token,
        uint256 numEth,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external beforeDeadline(blockTimeDeadline) {
        // execute swap using WETH-balance of the caller
        _executeBuy(msg.sender, msg.sender, token, numEth, numToken);
    }

    function _executeBuy(
        address owner,
        address currentWETHHolder,
        address token,
        uint256 numEthSold,
        uint256 numToken
    ) internal {
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        PriceData storage prices = tokenPriceData[owner][token];
        require(
            block.number > prices.latestBlock,
            _ERROR_TOO_MANY_TRADES_PER_BLOCK
        );
        prices.latestBlock = block.number;

        // do the swap and update price data
        (uint256 tokens, uint256 newReserve) =
            _buyInUniswap(token, numEthSold, numToken, currentWETHHolder);
        prices.ethSum = prices.ethSum.add(numEthSold);
        prices.tokenSum = prices.tokenSum.add(tokens);
        prices.weightedBlockSum = prices.weightedBlockSum.add(
            block.number.mul(tokens)
        );
        emit TokensPurchased(msg.sender, token, numEthSold, tokens, newReserve);
    }

    /**
        @dev Receives the ether only from WETH contract during withdraw()
     */
    receive() external payable {
        // make sure that router accepts ETH only from WETH contract
        assert(msg.sender == _wethAddr);
    }

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sell(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external beforeDeadline(blockTimeDeadline) {
        // execute the swap by transferring WETH directly to caller
        _executeSell(msg.sender, msg.sender, token, numToken, numEthLimit);
    }

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sellAndWithdraw(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external beforeDeadline(blockTimeDeadline) {
        // execute the swap by transferring WETH to this contract first
        uint256 numEth =
            _executeSell(
                msg.sender,
                address(this),
                token,
                numToken,
                numEthLimit
            );

        IWETH iweth = IWETH(_wethAddr);
        iweth.withdraw(numEth);

        (bool etherTransferSuccessful, ) =
            msg.sender.call{value: numEth}(new bytes(0));
        require(etherTransferSuccessful, _ERROR_TRANSFER_FAILED);
    }

    function _executeSell(
        address owner,
        address recipient,
        address token,
        uint256 numTokensSold,
        uint256 numEthLimit
    ) internal returns (uint256) {
        // verify the one-trade-per-block-per-token rule and protect against reentrancy
        PriceData storage prices = tokenPriceData[owner][token];
        require(
            block.number > prices.latestBlock,
            _ERROR_TOO_MANY_TRADES_PER_BLOCK
        );
        prices.latestBlock = block.number;

        // do the swap, calculate the profit and update price data
        (uint256 numEth, uint128 reserve) =
            _sellInUniswap(token, numTokensSold, numEthLimit, recipient);

        uint256 profitablePrice =
            numTokensSold.mul(prices.ethSum).div(prices.tokenSum);
        uint256 avgBlock = prices.weightedBlockSum.div(prices.tokenSum);
        uint256 newTokenSum = prices.tokenSum.sub(numTokensSold);
        uint256 profit =
            numEth > profitablePrice ? numEth.sub(profitablePrice) : 0;

        prices.ethSum = _proportionOf(
            prices.ethSum,
            newTokenSum,
            prices.tokenSum
        );
        prices.weightedBlockSum = _proportionOf(
            prices.weightedBlockSum,
            newTokenSum,
            prices.tokenSum
        );
        prices.tokenSum = newTokenSum;

        uint256 reward = 0;
        if (isTokenRewarded(token)) {
            // calculate the reward, and mint tokens
            reward = _calculateReward(
                epoch,
                avgBlock,
                block.number,
                profit,
                reserve,
                reserveLimit
            );
            if (reward > 0) {
                vnlContract.mint(msg.sender, reward);
            }
        }

        emit TokensSold(
            msg.sender,
            token,
            numTokensSold,
            numEth,
            profit,
            reward,
            reserve
        );
        return numEth;
    }

    /**
        @notice Estimates the reward.
        @dev Estimates the reward for given `owner` when selling `numTokensSold``token`s for `numEth` Ether. Also returns the individual components of the reward formula.
        @return profitablePrice The expected amount of Ether for this trade. Profit of this trade can be calculated with `numEth`-`profitablePrice`.
        @return avgBlock The volume-weighted average block for the `owner` and `token`
        @return htrs The Holding/Trading Ratio, Squared- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return vpc The Value-Protection Coefficient- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return reward The token reward estimate for this trade.
     */
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    )
        external
        view
        returns (
            uint256 profitablePrice,
            uint256 avgBlock,
            uint256 htrs,
            uint256 vpc,
            uint256 reward
        )
    {
        PriceData storage prices = tokenPriceData[owner][token];
        require(prices.tokenSum > 0, _ERROR_NO_TOKEN_OWNERSHIP);
        profitablePrice = numTokensSold.mul(prices.ethSum).div(prices.tokenSum);
        avgBlock = prices.weightedBlockSum.div(prices.tokenSum);
        if (numEth > profitablePrice) {
            uint256 profit = numEth.sub(profitablePrice);
            uint128 wethReserve = wethReserves[token];
            htrs = _estimateHTRS(avgBlock);
            vpc = _estimateVPC(profit, wethReserve);
            reward = _calculateReward(
                epoch,
                avgBlock,
                block.number,
                profit,
                wethReserve,
                reserveLimit
            );
        } else {
            htrs = 0;
            vpc = 0;
            reward = 0;
        }
    }

    function _estimateHTRS(uint256 avgBlock) internal view returns (uint256) {
        // H     = "Holding/Trading Ratio, Squared" (HTRS)
        //       = ((Bmax-Bavg)/(Bmax-Bmin))²
        //       = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
        //       = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
        if (avgBlock == block.number || block.number == epoch) return 0;

        uint256 bhold = block.number - avgBlock;
        uint256 btrade = block.number - epoch;

        return bhold.mul(bhold).mul(1_000_000).div(btrade.mul(btrade));
    }

    function _estimateVPC(uint256 profit, uint256 reserve)
        internal
        view
        returns (uint256)
    {
        // VPC = 1-max((P + L)/W, 1) (= 0 if P+L > W)
        //     = (W - P - L ) / W
        if (profit + reserveLimit > reserve) return 0;

        return (reserve - profit - reserveLimit).mul(1_000_000).div(reserve);
    }

    function _calculateReward(
        uint256 epoch_,
        uint256 avgBlock,
        uint256 currentBlock,
        uint256 profit,
        uint128 wethReserve,
        uint128 reserveLimit_
    ) internal pure returns (uint256) {
        /*
        Reward formula:
            P     = absolute profit in Ether = `profit`
            Bmax  = block.number when trade is happening = `block.number`
            Bavg  = volume-weighted average block.number of purchase = `avgBlock`
            Bmin  = "epoch", the block.number when contract was deployed = `epoch_`
            Bhold = Bmax-Bavg = number of blocks the trade has been held (instead of traded)
            Btrade= Bmax-Bmin = max possible trading time in blocks
            H     = "Holding/Trading Ratio, Squared" (HTRS)
                  = ((Bmax-Bavg)/(Bmax-Bmin))²
                  = (((Bmax-Bmin)-(Bavg-Bmin))/(Bmax-Bmin))²
                  = (Bhold/Btrade)² (= 0 if Bmax = Bavg, NaN if Bmax = Bmin)
            L     = WETH reserve limit for any traded token = `_reserveLimit`
            W     = internally tracked WETH reserve size for when selling a token = `wethReserve`
            V     = value protection coefficient
                  = 1-min((P + L)/W, 1) (= 0 if P+L > W)
            R     = minted rewards
                  = P*V*H
                  = if   (P = 0 || P + L > W || Bmax = Bavg || BMax = Bmin)
                         0
                    else P * (1-(P + L)/W) * (Bhold/Btrade)²
                       = (P * (W - P - L) * Bhold²) / W / Btrade²
        */

        if (profit == 0) return 0;
        if (profit + reserveLimit_ > wethReserve) return 0;
        if (currentBlock == avgBlock) return 0;
        if (currentBlock == epoch_) return 0;

        // these cannot underflow thanks to previous checks
        uint256 rpl = wethReserve - profit - reserveLimit_;
        uint256 bhold = currentBlock - avgBlock;
        uint256 btrade = currentBlock - epoch_;

        uint256 nominator = profit.mul(rpl).mul(bhold.mul(bhold));
        // no division by zero possible, both wethReserve and btrade² are always > 0
        return nominator / wethReserve / (btrade.mul(btrade));
    }

    function _proportionOf(
        uint256 total,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        // percentage = (numerator/denominator)
        // proportion = total * percentage
        return total.mul(numerator).div(denominator);
    }
}