// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol";

import "./interfaces/ICommunityStakingPool.sol";
import "./interfaces/ICommunityCoin.sol";

import "./CommunityStakingPoolBase.sol";

// import "hardhat/console.sol";

contract CommunityStakingPool is CommunityStakingPoolBase, ICommunityStakingPool {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @custom:shortd address of traded token. ie investor token - ITR
     * @notice address of traded token. ie investor token - ITR
     */
    address public tradedToken;

    /**
     * @custom:shortd address of reserve token. ie WETH,USDC,USDT,etc
     * @notice address of reserve token. ie WETH,USDC,USDT,etc
     */
    address public reserveToken;

    address private _token0;
    address private _token1;

    //bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    //bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    address internal WETH;

    /**
     * @custom:shortd uniswap v2 pair
     * @notice uniswap v2 pair
     */
    IUniswapV2Pair public uniswapV2Pair;

    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice Special function receive ether
     */
    receive() external payable {}

    /**
     * @notice initialize method. Called once by the factory at time of deployment
     * @param stakingProducedBy_ address of Community Coin token.
     * @param reserveToken_ address of reserve token. ie WETH,USDC,USDT,etc
     * @param tradedToken_ address of traded token. ie investor token - ITR
     * @param donations_ array of tuples donations. address,uint256. if array empty when coins will obtain sender, overwise donation[i].account  will obtain proportionally by ration donation[i].amount
     * @param lpFraction_ fraction of LP token multiplied by `FRACTION`.
     * @param lpFractionBeneficiary_ beneficiary's address which obtain lpFraction of LP tokens. if address(0) then it would be owner()
     * @custom:shortd initialize method. Called once by the factory at time of deployment
     */
    function initialize(
        address stakingProducedBy_,
        address reserveToken_,
        address tradedToken_,
        IStructs.StructAddrUint256[] memory donations_,
        uint64 lpFraction_,
        address lpFractionBeneficiary_,
        uint64 rewardsRateFraction_
    ) external override initializer {
        CommunityStakingPoolBase_init(
            stakingProducedBy_,
            donations_,
            lpFraction_,
            lpFractionBeneficiary_,
            rewardsRateFraction_
        );

        (tradedToken, reserveToken) = (tradedToken_, reserveToken_);

        address pair = IUniswapV2Factory(uniswapRouterFactory).getPair(tradedToken, reserveToken);
        require(pair != address(0), "NO_UNISWAP_V2_PAIR");
        uniswapV2Pair = IUniswapV2Pair(pair);
        _token0 = uniswapV2Pair.token0();
        _token1 = uniswapV2Pair.token1();

        WETH = UniswapV2Router02.WETH();
    }

    /**
     * @notice way to unstake via approve/transferFrom. Another way is send directly to contract. User will obtain uniswap-LP tokens
     * @param account account address will unstaked from
     * @param amount The number of shares that will be unstaked.
     * @custom:calledby staking contract
     * @custom:shortd redeem lp tokens
     */
    function unstake(address account, uint256 amount)
        external
        override
        onlyStaking
        returns (uint256 affectedLPAmount, uint64 rewardsFraction)
    {
        affectedLPAmount = __redeem(account, amount);
        uniswapV2Pair.transfer(account, affectedLPAmount);
        rewardsRateFraction = rewardsFraction;
    }

    /**
     * @notice way to unstake and remove liquidity via approve/transferFrom shares. User will obtain reserve and traded tokens back
     * @param account account address will unstaked from
     * @param amount The number of shares that will be unstaked.
     * @custom:calledby staking contract
     * @custom:shortd unstake and remove liquidity
     */
    function unstakeAndRemoveLiquidity(address account, uint256 amount)
        external
        override
        onlyStaking
        returns (
            uint256 affectedReservedAmount,
            uint256 affectedTradedAmount,
            uint64 rewardsFraction
        )
    {
        (affectedReservedAmount, affectedTradedAmount) = __redeemAndRemoveLiquidity(account, amount);
        rewardsRateFraction = rewardsFraction;
    }

    /**
     * @notice way to redeem via approve/transferFrom. Another way is send directly to contract. User will obtain uniswap-LP tokens
     * @param account account address will redeemed from
     * @param amount The number of shares that will be redeemed.
     * @custom:calledby staking contract
     * @custom:shortd redeem lp tokens
     */
    function redeem(address account, uint256 amount)
        external
        override
        onlyStaking
        returns (uint256 affectedLPAmount, uint64 rewardsFraction)
    {
        affectedLPAmount = __redeem(account, amount);
        uniswapV2Pair.transfer(account, affectedLPAmount);
        rewardsRateFraction = rewardsFraction;
    }

    /**
     * @notice way to redeem and remove liquidity via approve/transferFrom shares. User will obtain reserve and traded tokens back
     * @param account account address will redeemed from
     * @param amount The number of shares that will be redeemed.
     * @custom:calledby staking contract
     * @custom:shortd redeem and remove liquidity
     */
    function redeemAndRemoveLiquidity(address account, uint256 amount)
        external
        override
        onlyStaking
        returns (
            uint256 affectedReservedAmount,
            uint256 affectedTradedAmount,
            uint64 rewardsFraction
        )
    {
        (affectedReservedAmount, affectedTradedAmount) = __redeemAndRemoveLiquidity(account, amount);
        rewardsRateFraction = rewardsFraction;
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice method will receive Traded token, exchange to reserve token via uniswap.
     * Finally will add to liquidity pool and stake it.
     * @custom:shortd  the way to sell traded token and stake liquidity.
     */
    function sellAndStakeLiquidity(uint256 amountTradedToken) public nonReentrant {
        address account = _msgSender();
        IERC20Upgradeable(tradedToken).transferFrom(account, address(this), amountTradedToken);

        _sellTradedAndStake(account, amountTradedToken);
    }

    /**
     * @notice method will receive Traded token, exchange to reserve token via uniswap.
     * Finally will add to liquidity pool and stake it. Beneficiary will obtain shares
     * @custom:shortd  the way to sell traded token and stake liquidity. Beneficiary will obtain shares
     */
    function sellAndStakeLiquidity(uint256 amountTradedToken, address beneficiary) public nonReentrant {
        IERC20Upgradeable(tradedToken).transferFrom(_msgSender(), address(this), amountTradedToken);
        _sellTradedAndStake(beneficiary, amountTradedToken);
    }

    /**
     * @notice payble method will receive ETH, convert it to WETH, exchange to reserve token via uniswap.
     * Finally will add to liquidity pool and stake it. Sender will obtain shares
     * @custom:shortd  the way to buy liquidity and stake via ETH
     */
    function buyAndStakeLiquidity() public payable nonReentrant {
        address account = _msgSender();
        require(msg.value > 0, "INSUFFICIENT_BALANCE");
        uint256 amountETH = msg.value;
        IWETH(WETH).deposit{value: amountETH}();
        uint256 amountReserveToken = doSwapOnUniswap(WETH, reserveToken, amountETH);
        _buyAndStakeLiquidity(account, amountReserveToken);
    }

    /**
     * @notice method will receive payingToken token, exchange to reserve token via uniswap.
     * Finally will add to liquidity pool and stake it. Sender will obtain shares
     * @custom:shortd  the way to buy liquidity and stake via paying token
     */
    function buyAndStakeLiquidity(address payingToken, uint256 amount) public nonReentrant {
        address account = _msgSender();
        IERC20Upgradeable(payingToken).transferFrom(account, address(this), amount);
        uint256 amountReserveToken = doSwapOnUniswap(payingToken, reserveToken, amount);
        _buyAndStakeLiquidity(account, amountReserveToken);
    }

    /**
     * @notice method will receive reserveToken token then will add to liquidity pool and stake it. Sender will obtain shares
     * @custom:shortd  the way to buy liquidity and stake via reserveToken
     */
    function buyAndStakeLiquidity(uint256 tokenBAmount) public nonReentrant {
        address account = _msgSender();
        IERC20Upgradeable(reserveToken).transferFrom(account, address(this), tokenBAmount);
        _buyAndStakeLiquidity(account, tokenBAmount);
    }

    /**
     * @notice payble method will receive ETH, convert it to WETH, exchange to reserve token via uniswap.
     * Finally will add to liquidity pool and stake it. Beneficiary will obtain shares
     * @custom:shortd  the way to buy liquidity and stake via ETH. Beneficiary will obtain shares
     */
    function buyAndStakeLiquidity(address beneficiary) public payable nonReentrant {
        require(msg.value > 0, "INSUFFICIENT_BALANCE");
        uint256 amountETH = msg.value;
        IWETH(WETH).deposit{value: amountETH}();
        uint256 amountReserveToken = doSwapOnUniswap(WETH, reserveToken, amountETH);
        _buyAndStakeLiquidity(beneficiary, amountReserveToken);
    }

    /**
     * @notice method will receive payingToken token, exchange to reserve token via uniswap.
     * Finally will add to liquidity pool and stake it. Beneficiary will obtain shares
     * @custom:shortd  the way to buy liquidity and stake via paying token. Beneficiary will obtain shares
     */
    function buyAndStakeLiquidity(
        address payingToken,
        uint256 amount,
        address beneficiary
    ) public nonReentrant {
        // note that here can be magic trick
        // trusted forwarder can be call tx as a Bob that wanted to specify alice as a beneficiary
        address account = _msgSender();
        IERC20Upgradeable(payingToken).transferFrom(account, address(this), amount);
        uint256 amountReserveToken = doSwapOnUniswap(payingToken, reserveToken, amount);
        _buyAndStakeLiquidity(beneficiary, amountReserveToken);
    }

    /**
     * @notice method will receive reserveToken token then will add to liquidity pool and stake it. Beneficiary will obtain shares
     * @custom:shortd  the way to buy liquidity and stake via reserveToken. Beneficiary will obtain shares
     */
    function buyAndStakeLiquidity(uint256 tokenBAmount, address beneficiary) public nonReentrant {
        IERC20Upgradeable(reserveToken).transferFrom(_msgSender(), address(this), tokenBAmount);
        _buyAndStakeLiquidity(beneficiary, tokenBAmount);
    }

    /**
     * @notice way to stake LP tokens of current pool(traded/reserve tokens)
     * @dev keep in mind that user can redeem lp token from other staking contract with same pool but different duration and use here.
     * @param lpAmount liquidity tokens's amount
     * @custom:shortd way to stake LP tokens
     */
    function stakeLiquidity(uint256 lpAmount) public nonReentrant {
        require(lpAmount > 0, "AMOUNT_EMPTY");
        IERC20Upgradeable(address(uniswapV2Pair)).transferFrom(_msgSender(), address(this), lpAmount);
        (uint256 reserve0, uint256 reserve1, ) = uniswapV2Pair.getReserves();
        uint256 priceBeforeStake = (
            _token0 == reserveToken ? (FRACTION * reserve0) / reserve1 : (FRACTION * reserve1) / reserve0
        );
        _stake(_msgSender(), lpAmount, priceBeforeStake);
    }

    function addAndStakeLiquidity(uint256 amountTradedToken, uint256 amountReserveToken) public nonReentrant {
        (
            ,
            ,
            /*uint256 rTraded*/
            /*uint256 rReserved*/
            uint256 priceTraded, /*uint256 priceReserved*/

        ) = uniswapPrices();

        require(amountTradedToken > 0 && amountReserveToken > 0, "AMOUNT_EMPTY");

        IERC20Upgradeable(tradedToken).transferFrom(_msgSender(), address(this), amountTradedToken);
        IERC20Upgradeable(reserveToken).transferFrom(_msgSender(), address(this), amountReserveToken);

        require(
            IERC20Upgradeable(tradedToken).approve(uniswapRouter, amountTradedToken) &&
                IERC20Upgradeable(reserveToken).approve(uniswapRouter, amountReserveToken),
            "APPROVE_FAILED"
        );

        (uint256 A, uint256 B, uint256 lpTokens) = UniswapV2Router02.addLiquidity(
            tradedToken,
            reserveToken,
            amountTradedToken,
            amountReserveToken,
            0, // there may be some slippage
            0, // there may be some slippage
            address(this),
            block.timestamp
        );
        require(lpTokens > 0, "NO_LIQUIDITY");

        _stake(_msgSender(), lpTokens, priceTraded);
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function uniswapPrices()
        internal
        view
        returns (
            // reserveTraded, reserveReserved, priceTraded, priceReserved
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 reserve0, uint256 reserve1, ) = uniswapV2Pair.getReserves();

        require(reserve0 != 0 && reserve1 != 0, "RESERVES_EMPTY");
        if (_token0 == tradedToken) {
            return (reserve0, reserve1, (FRACTION * reserve0) / reserve1, (FRACTION * reserve1) / reserve0);
        } else {
            return (reserve1, reserve0, (FRACTION * reserve1) / reserve0, (FRACTION * reserve0) / reserve1);
        }
    }

    function _sellTradedAndStake(address from, uint256 incomingTradedToken) internal {
        (
            uint256 rTraded, /*uint256 rReserved*/
            ,
            uint256 priceTraded, /*uint256 priceReserved*/

        ) = uniswapPrices();

        uint256 r3 = sqrt((rTraded + incomingTradedToken) * (rTraded)) - rTraded; //
        require(r3 > 0 && incomingTradedToken > r3, "BAD_AMOUNT");
        // remaining (r2-r3) we will exchange at uniswap to traded token
        uint256 amountReserveToken = doSwapOnUniswap(tradedToken, reserveToken, r3);
        uint256 amountTradedToken = incomingTradedToken - r3;

        require(
            IERC20Upgradeable(tradedToken).approve(uniswapRouter, amountTradedToken) &&
                IERC20Upgradeable(reserveToken).approve(uniswapRouter, amountReserveToken),
            "APPROVE_FAILED"
        );

        (uint256 A, uint256 B, uint256 lpTokens) = UniswapV2Router02.addLiquidity(
            tradedToken,
            reserveToken,
            amountTradedToken,
            amountReserveToken,
            0, // there may be some slippage
            0, // there may be some slippage
            address(this),
            block.timestamp
        );
        require(lpTokens > 0, "NO_LIQUIDITY");

        _stake(from, lpTokens, priceTraded);
    }

    function _buyAndStakeLiquidity(address from, uint256 incomingReserveToken) internal {
        (
            ,
            /*uint256 rTraded*/
            uint256 rReserved, /*uint256 priceTraded*/
            ,
            uint256 priceReserved
        ) = uniswapPrices();

        //Then the amount they would want to swap is
        // r3 = sqrt( (r1 + r2) * r1 ) - r1
        // where
        //  r1 - reserve at uniswap(reserve1)
        //  r2 - incoming amount of reserve token
        uint256 r3 = sqrt((rReserved + incomingReserveToken) * (rReserved)) - rReserved; //
        require(r3 > 0 && incomingReserveToken > r3, "BAD_AMOUNT");
        // remaining (r2-r3) we will exchange at uniswap to traded token
        uint256 amountTradedToken = doSwapOnUniswap(reserveToken, tradedToken, r3);
        uint256 amountReserveToken = incomingReserveToken - r3;
        require(
            IERC20Upgradeable(tradedToken).approve(uniswapRouter, amountTradedToken) &&
                IERC20Upgradeable(reserveToken).approve(uniswapRouter, amountReserveToken),
            "APPROVE_FAILED"
        );
        (, , uint256 lpTokens) = UniswapV2Router02.addLiquidity(
            tradedToken,
            reserveToken,
            amountTradedToken,
            amountReserveToken,
            0, // there may be some slippage
            0, // there may be some slippage
            address(this),
            block.timestamp
        );
        require(lpTokens > 0, "NO_LIQUIDITY");

        _stake(from, lpTokens, priceReserved);
    }

    ////////////////////////////////////////////////////////////////////////
    // private section /////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function __redeemAndRemoveLiquidity(address sender, uint256 amount)
        private
        returns (uint256 affectedReservedAmount, uint256 affectedTradedAmount)
    {
        uint256 amount2Redeem = __redeem(sender, amount);

        require(uniswapV2Pair.approve(uniswapRouter, amount2Redeem), "APPROVE_FAILED");
        (affectedTradedAmount, affectedReservedAmount) = UniswapV2Router02.removeLiquidity(
            tradedToken, //address tokenA,
            reserveToken, //address tokenB,
            amount2Redeem, //uint liquidity,
            0, //uint amountAMin,
            0, //uint amountBMin,
            address(this), //address to,
            block.timestamp //uint deadline
        );
        // _fractionAmountSend(tradedToken, amountA, tradedTokenClaimFraction, stakingProducedBy, sender);
        // _fractionAmountSend(reserveToken, amountB, reserveTokenClaimFraction, stakingProducedBy, sender);
        _fractionAmountSend(tradedToken, affectedTradedAmount, 0, stakingProducedBy, sender);
        _fractionAmountSend(reserveToken, affectedReservedAmount, 0, stakingProducedBy, sender);
    }

    function __redeem(address sender, uint256 amount) private returns (uint256 amount2Redeem) {
        emit Redeemed(sender, amount);

        // validate free amount to redeem was moved to method _beforeTokenTransfer
        // transfer and burn moved to upper level
        amount2Redeem = _fractionAmountSend(
            address(uniswapV2Pair),
            amount,
            lpFraction,
            lpFractionBeneficiary == address(0) ? stakingProducedBy : lpFractionBeneficiary,
            address(0)
        );
    }

    /**
     * @dev implemented EIP-2771
     */
    function _msgSender() internal view virtual override returns (address signer) {
        signer = msg.sender;
        if (msg.data.length >= 20 && ITrustedForwarder(stakingProducedBy).isTrustedForwarder(signer)) {
            assembly {
                signer := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }
        // Calculate the square root of the perfect square of a
        // power of two that is the closest to x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }
        // The operations can never overflow because the result is
        // max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}