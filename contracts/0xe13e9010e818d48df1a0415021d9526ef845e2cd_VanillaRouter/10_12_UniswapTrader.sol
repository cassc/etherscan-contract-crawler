// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.8;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
    @title The Uniswap-enabled base contract for Vanilla.
*/
contract UniswapTrader {
    using SafeMath for uint256;

    string private constant _ERROR_SLIPPAGE_LIMIT_EXCEEDED = "a1";
    string private constant _INVALID_UNISWAP_PAIR = "a2";

    address internal immutable _uniswapFactoryAddr;
    address internal immutable _wethAddr;

    // internally tracked reserves for price manipulation protection for each token (Uniswap uses uint112 so uint128 is plenty)
    mapping(address => uint128) public wethReserves;

    /**
        @notice Deploys the contract and initializes Uniswap contract references and internal WETH-reserve for safe tokens.
        @dev using UniswapRouter to ensure that Vanilla uses the same WETH contract
        @param routerAddress The address of UniswapRouter contract
        @param limit The initial reserve value for tokens in the safelist
        @param safeList The list of "safe" tokens to trade
     */
    constructor(
        address routerAddress,
        uint128 limit,
        address[] memory safeList
    ) public {
        // fetch addresses via router to guarantee correctness
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address wethAddr = router.WETH();
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        for (uint256 i = 0; i < safeList.length; i++) {
            address token = safeList[i];
            // verify that WETH-token pair exists in Uniswap
            // (order isn't significant, UniswapV2Factory.createPair populates the mapping in reverse direction too)
            address pair = factory.getPair(token, wethAddr);
            require(pair != address(0), _INVALID_UNISWAP_PAIR);

            // we initialize the fixed list of rewardedTokens with the reserveLimit-value that they'll match the invariant
            // "every rewardedToken will have wethReserves[rewardedToken] > 0"
            // (this way we don't need to store separate lists for both wethReserve-tracking and tokens eligible for the rewards)
            wethReserves[token] = limit;
        }
        _wethAddr = wethAddr;
        _uniswapFactoryAddr = address(factory);
    }

    /**
        @notice Checks if the given ERC-20 token will be eligible for rewards (i.e. a safelisted token)
        @param token The ERC-20 token address
     */
    function isTokenRewarded(address token) public view returns (bool) {
        return wethReserves[token] > 0;
    }

    function _pairInfo(
        address factory,
        address token,
        address weth
    ) internal pure returns (address pair, bool tokenFirst) {
        // as order of tokens is important in Uniswap pairs, we record this information here and pass it on to caller
        // for gas optimization
        tokenFirst = token < weth;

        // adapted from UniswapV2Library.sol, calculates the CREATE2 address for a pair without making any external calls to factory contract
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(
                            tokenFirst
                                ? abi.encodePacked(token, weth)
                                : abi.encodePacked(weth, token)
                        ),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
                    )
                )
            )
        );
    }

    function _amountToSwap(
        uint256 tokensIn,
        uint256 reservesIn,
        uint256 reservesOut
    ) internal pure returns (uint256 tokensOut) {
        uint256 inMinusFee = tokensIn.mul(997); // in * (100% - 0.3%)
        tokensOut = reservesOut.mul(inMinusFee).div(
            reservesIn.mul(1000).add(inMinusFee)
        );
    }

    function _updateReservesOnBuy(address token, uint112 wethReserve)
        private
        returns (uint128 reserve)
    {
        // when buying, update internal reserve only if Uniswap reserve is greater
        reserve = wethReserves[token];
        if (reserve == 0) {
            // trading a non-safelisted token, so do not update internal reserves
            return reserve;
        }
        if (wethReserve > reserve) {
            wethReserves[token] = wethReserve;
            reserve = wethReserve;
        }
    }

    function _buyInUniswap(
        address token_,
        uint256 eth,
        uint256 amount_,
        address tokenOwner_
    ) internal returns (uint256 numToken, uint128 reserve) {
        (address pairAddress, bool tokenFirst) =
            _pairInfo(_uniswapFactoryAddr, token_, _wethAddr);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        address tokenCustody = address(this);
        uint256 balance = IERC20(token_).balanceOf(tokenCustody);
        IERC20(_wethAddr).transferFrom(tokenOwner_, pairAddress, eth);
        if (tokenFirst) {
            (uint112 tokenReserve, uint112 wethReserve, ) = pair.getReserves();
            pair.swap(
                _amountToSwap(eth, wethReserve, tokenReserve),
                uint256(0),
                tokenCustody,
                new bytes(0)
            );
            reserve = _updateReservesOnBuy(token_, wethReserve);
        } else {
            (uint112 wethReserve, uint112 tokenReserve, ) = pair.getReserves();
            pair.swap(
                uint256(0),
                _amountToSwap(eth, wethReserve, tokenReserve),
                tokenCustody,
                new bytes(0)
            );
            reserve = _updateReservesOnBuy(token_, wethReserve);
        }
        // finally check how the custody balance has changed after swap
        numToken = IERC20(token_).balanceOf(tokenCustody) - balance;
        // revert if the price diff between trade-time and execution-time was too large
        require(numToken >= amount_, _ERROR_SLIPPAGE_LIMIT_EXCEEDED);
    }

    function _updateReservesOnSell(address token, uint112 wethReserve)
        private
        returns (uint128 reserve)
    {
        // when selling, update internal reserve only if the Uniswap reserve is smaller
        reserve = wethReserves[token];
        if (reserve == 0) {
            // trading a non-safelisted token, so do not update internal reserves
            return reserve;
        }
        if (wethReserve < reserve) {
            wethReserves[token] = wethReserve;
            reserve = wethReserve;
        }
    }

    function _sellInUniswap(
        address token_,
        uint256 amount_,
        uint256 eth_,
        address tokenReceiver_
    ) internal returns (uint256 numEth, uint128 reserve) {
        (address pairAddress, bool tokenFirst) =
            _pairInfo(_uniswapFactoryAddr, token_, _wethAddr);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        uint256 balance = IERC20(_wethAddr).balanceOf(tokenReceiver_);

        // Use TransferHelper because we have no idea here how token.transfer() has been implemented
        TransferHelper.safeTransfer(token_, pairAddress, amount_);
        if (tokenFirst) {
            (uint112 tokenReserve, uint112 wethReserve, ) = pair.getReserves();
            pair.swap(
                uint256(0),
                _amountToSwap(amount_, tokenReserve, wethReserve),
                tokenReceiver_,
                new bytes(0)
            );
            reserve = _updateReservesOnSell(token_, wethReserve);
        } else {
            (uint112 wethReserve, uint112 tokenReserve, ) = pair.getReserves();
            pair.swap(
                _amountToSwap(amount_, tokenReserve, wethReserve),
                uint256(0),
                tokenReceiver_,
                new bytes(0)
            );
            reserve = _updateReservesOnSell(token_, wethReserve);
        }
        // finally check how the receivers balance has changed after swap
        numEth = IERC20(_wethAddr).balanceOf(tokenReceiver_) - balance;
        // revert if the price diff between trade-time and execution-time was too large
        require(numEth >= eth_, _ERROR_SLIPPAGE_LIMIT_EXCEEDED);
    }
}