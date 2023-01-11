pragma solidity =0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./PoolToken.sol";
import "./interfaces/IOptiSwap.sol";
import "./interfaces/IVeloVoter.sol";
import "./interfaces/IVeloPairFactory.sol";
import "./interfaces/IVeloGauge.sol";
import "./interfaces/IVeloRouter.sol";
import "./interfaces/IBaseV1Pair.sol";
import "./interfaces/IVeloVaultToken.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";
import "./libraries/SafeToken.sol";
import "./libraries/Math.sol";

interface OptiSwapPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract VeloVaultToken is IVeloVaultToken, PoolToken {
    using SafeToken for address;

    bool public constant isVaultToken = true;
    bool public constant stable = false;

    address public optiSwap;
    address public router;
    address public voter;
    address public gauge;
    address public pairFactory;
    address public rewardsToken;
    address public WETH;
    address public reinvestFeeTo;
    address public token0;
    address public token1;

    uint256 public constant MIN_REINVEST_BOUNTY = 0;
    uint256 public constant MAX_REINVEST_BOUNTY = 0.05e18;
    uint256 public REINVEST_BOUNTY = 0.02e18;
    uint256 public constant MIN_REINVEST_FEE = 0;
    uint256 public constant MAX_REINVEST_FEE = 0.05e18;
    uint256 public REINVEST_FEE = 0.02e18;

    address[] reinvestorList;
    mapping(address => bool) reinvestorEnabled;

    event Reinvest(address indexed caller, uint256 reward, uint256 bounty, uint256 fee);
    event UpdateReinvestBounty(uint256 _newReinvestBounty);
    event UpdateReinvestFee(uint256 _newReinvestFee);
    event UpdateReinvestFeeTo(address _newReinvestFeeTo);

    function _initialize(
        address _underlying,
        address _optiSwap,
        address _router,
        address _voter,
        address _pairFactory,
        address _rewardsToken,
        address _reinvestFeeTo
    ) external {
        require(factory == address(0), "VaultToken: FACTORY_ALREADY_SET"); // sufficient check
        factory = msg.sender;
        _setName("Tarot Vault Token", "vTAROT");
        underlying = _underlying;
        optiSwap = _optiSwap;
        voter = _voter;
        gauge = IVeloVoter(voter).gauges(underlying);
        require(gauge != address(0), "VaultToken: NO_GAUGE");
        router = _router;
        pairFactory = _pairFactory;
        WETH = IVeloRouter(_router).weth();
        (token0, token1) = IBaseV1Pair(_underlying).tokens();
        rewardsToken = _rewardsToken;
        reinvestFeeTo = _reinvestFeeTo;
        rewardsToken.safeApprove(address(router), uint256(-1));
        WETH.safeApprove(address(router), uint256(-1));
        underlying.safeApprove(address(gauge), uint256(-1));
    }

    function reinvestorListLength() external view returns (uint256) {
        return reinvestorList.length;
    }

    function reinvestorListItem(uint256 index) external view returns (address) {
        return reinvestorList[index];
    }

    function isReinvestorEnabled(address reinvestor) external view returns (bool) {
        return reinvestorEnabled[reinvestor];
    }

    function _addReinvestor(address reinvestor) private {
        require(!reinvestorEnabled[reinvestor], "VaultToken: REINVESTOR_ENABLED");

        reinvestorEnabled[reinvestor] = true;
        reinvestorList.push(reinvestor);
    }

    function addReinvestor(address reinvestor) external onlyFactoryOwner {
        _addReinvestor(reinvestor);
    }

    function _indexOfReinvestor(address reinvestor) private view returns (uint256 index) {
        uint256 count = reinvestorList.length;
        for (uint256 i = 0; i < count; i++) {
            if (reinvestorList[i] == reinvestor) {
                return i;
            }
        }
        require(false, "VaultToken: REINVESTOR_NOT_FOUND");
    }

    function removeReinvestor(address reinvestor) external onlyFactoryOwner {
        require(reinvestorEnabled[reinvestor], "VaultToken: REINVESTOR_ENABLED");

        uint256 index = _indexOfReinvestor(reinvestor);
        address last = reinvestorList[reinvestorList.length - 1];
        reinvestorList[index] = last;
        reinvestorList.pop();
        delete reinvestorEnabled[reinvestor];
    }

    function updateReinvestBounty(uint256 _newReinvestBounty) external onlyFactoryOwner {
        require(_newReinvestBounty >= MIN_REINVEST_BOUNTY && _newReinvestBounty <= MAX_REINVEST_BOUNTY, "VaultToken: INVLD_REINVEST_BOUNTY");
        REINVEST_BOUNTY = _newReinvestBounty;

        emit UpdateReinvestBounty(_newReinvestBounty);
    }

    function updateReinvestFee(uint256 _newReinvestFee) external onlyFactoryOwner {
        require(_newReinvestFee >= MIN_REINVEST_FEE && _newReinvestFee <= MAX_REINVEST_FEE, "VaultToken: INVLD_REINVEST_FEE");
        REINVEST_FEE = _newReinvestFee;

        emit UpdateReinvestFee(_newReinvestFee);
    }

    function updateReinvestFeeTo(address _newReinvestFeeTo) external onlyFactoryOwner {
        reinvestFeeTo = _newReinvestFeeTo;

        emit UpdateReinvestFeeTo(_newReinvestFeeTo);
    }

    /*** PoolToken Overrides ***/

    function _update() internal {
        uint256 _totalBalance = IVeloGauge(gauge).balanceOf(address(this));
        totalBalance = _totalBalance;
        emit Sync(_totalBalance);
    }

    // this low-level function should be called from another contract
    function mint(address minter) external nonReentrant update returns (uint256 mintTokens) {
        uint256 mintAmount = underlying.myBalance();
        // handle pools with deposit fees by checking balance before and after deposit
        uint256 _totalBalanceBefore = IVeloGauge(gauge).balanceOf(address(this));
        IVeloGauge(gauge).deposit(mintAmount, 0);
        uint256 _totalBalanceAfter = IVeloGauge(gauge).balanceOf(address(this));
        mintTokens = _totalBalanceAfter.sub(_totalBalanceBefore).mul(1e18).div(exchangeRate());

        if (totalSupply == 0) {
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            mintTokens = mintTokens.sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        }
        require(mintTokens > 0, "VaultToken: MINT_AMOUNT_ZERO");
        _mint(minter, mintTokens);
        emit Mint(msg.sender, minter, mintAmount, mintTokens);
    }

    // this low-level function should be called from another contract
    function redeem(address redeemer) external nonReentrant update returns (uint256 redeemAmount) {
        uint256 redeemTokens = balanceOf[address(this)];
        redeemAmount = redeemTokens.mul(exchangeRate()).div(1e18);

        require(redeemAmount > 0, "VaultToken: REDEEM_AMOUNT_ZERO");
        require(redeemAmount <= totalBalance, "VaultToken: INSUFFICIENT_CASH");
        _burn(address(this), redeemTokens);
        IVeloGauge(gauge).withdraw(redeemAmount);
        _safeTransfer(redeemer, redeemAmount);
        emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);
    }

    /*** Reinvest ***/

    function _optimalDepositA(
        uint256 _amountA,
        uint256 _reserveA
    ) internal view returns (uint256) {
        uint256 swapFee = IVeloPairFactory(pairFactory).getFee(false);
        uint256 swapFeeFactor = uint256(10000).sub(swapFee);
        uint256 a = uint256(10000).add(swapFeeFactor).mul(_reserveA);
        uint256 b = _amountA.mul(10000).mul(_reserveA).mul(4).mul(swapFeeFactor);
        uint256 c = Math.sqrt(a.mul(a).add(b));
        uint256 d = uint256(2).mul(swapFeeFactor);
        return c.sub(a).div(d);
    }

    function approveRouter(address token, uint256 amount) internal {
        if (IERC20(token).allowance(address(this), router) >= amount) return;
        token.safeApprove(address(router), uint256(-1));
    }

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) internal {
        approveRouter(tokenIn, amount);
        IVeloRouter(router).swapExactTokensForTokensSimple(amount, 0, tokenIn, tokenOut, false, address(this), block.timestamp);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal returns (uint256 liquidity) {
        approveRouter(tokenA, amountA);
        approveRouter(tokenB, amountB);
        (, , liquidity) = IVeloRouter(router).addLiquidity(tokenA, tokenB, false, amountA, amountB, 0, 0, address(this), block.timestamp);
    }

    function swapTokensForBestAmountOut(
        IOptiSwap _optiSwap,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }
        address pair;
        (pair, amountOut) = _optiSwap.getBestAmountOut(amountIn, tokenIn, tokenOut);
        require(pair != address(0), "NO_PAIR");
        tokenIn.safeTransfer(pair, amountIn);
        if (tokenIn < tokenOut) {
            OptiSwapPair(pair).swap(0, amountOut, address(this), new bytes(0));
        } else {
            OptiSwapPair(pair).swap(amountOut, 0, address(this), new bytes(0));
        }
    }

    function optiSwapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }
        IOptiSwap _optiSwap = IOptiSwap(optiSwap);
        address nextHop = _optiSwap.getBridgeToken(tokenIn);
        if (nextHop == tokenOut) {
            return swapTokensForBestAmountOut(_optiSwap, tokenIn, tokenOut, amountIn);
        }
        address waypoint = _optiSwap.getBridgeToken(tokenOut);
        if (tokenIn == waypoint) {
            return swapTokensForBestAmountOut(_optiSwap, tokenIn, tokenOut, amountIn);
        }
        uint256 hopAmountOut;
        if (nextHop != tokenIn) {
            hopAmountOut = swapTokensForBestAmountOut(_optiSwap, tokenIn, nextHop, amountIn);
        } else {
            hopAmountOut = amountIn;
        }
        if (nextHop == waypoint) {
            return swapTokensForBestAmountOut(_optiSwap, nextHop, tokenOut, hopAmountOut);
        } else if (waypoint == tokenOut) {
            return optiSwapExactTokensForTokens(nextHop, tokenOut, hopAmountOut);
        } else {
            uint256 waypointAmountOut = optiSwapExactTokensForTokens(nextHop, waypoint, hopAmountOut);
            return swapTokensForBestAmountOut(_optiSwap, waypoint, tokenOut, waypointAmountOut);
        }
    }

    function _getReward() internal returns (uint256 amount) {
        address[] memory tokens = new address[](1);
        tokens[0] = rewardsToken;
        IVeloGauge(gauge).getReward(address(this), tokens);

        return rewardsToken.myBalance();
    }

    function getReward() external nonReentrant returns (uint256) {
        require(msg.sender == tx.origin || reinvestorEnabled[msg.sender]);
        return _getReward();
    }

    function reinvest() external nonReentrant update {
        require(msg.sender == tx.origin || reinvestorEnabled[msg.sender]);
        // 1. Withdraw all the rewards.
        uint256 reward = _getReward();
        if (reward == 0) return;
        // 2. Send the reward bounty to the caller.
        uint256 bounty = reward.mul(REINVEST_BOUNTY) / 1e18;
        if (bounty > 0) {
            rewardsToken.safeTransfer(msg.sender, bounty);
        }
        uint256 fee = reward.mul(REINVEST_FEE) / 1e18;
        if (fee > 0) {
            rewardsToken.safeTransfer(reinvestFeeTo, fee);
        }
        // 3. Convert all the remaining rewards to token0 or token1.
        address tokenA;
        address tokenB;
        if (token0 == rewardsToken || token1 == rewardsToken) {
            (tokenA, tokenB) = token0 == rewardsToken ? (token0, token1) : (token1, token0);
        } else {
            if (token1 == WETH) {
                (tokenA, tokenB) = (token1, token0);
            } else {
                (tokenA, tokenB) = (token0, token1);
            }
            optiSwapExactTokensForTokens(rewardsToken, tokenA, reward.sub(bounty.add(fee)));
        }
        // 4. Convert tokenA to LP Token underlyings.
        uint256 totalAmountA = tokenA.myBalance();
        assert(totalAmountA > 0);
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(underlying).getReserves();
        uint256 reserveA = tokenA == token0 ? r0 : r1;
        uint256 swapAmount = _optimalDepositA(totalAmountA, reserveA);
        swapExactTokensForTokens(tokenA, tokenB, swapAmount);
        uint256 liquidity = addLiquidity(tokenA, tokenB, totalAmountA.sub(swapAmount), tokenB.myBalance());
        // 5. Stake the LP Tokens.
        IVeloGauge(gauge).deposit(liquidity, 0);
        emit Reinvest(msg.sender, reward, bounty, fee);
    }

    function adminClaimRewards(address[] calldata _tokens) external onlyFactoryOwner nonReentrant {
        IVeloGauge(gauge).getReward(address(this), _tokens);
    }

    function adminRescueTokens(address _to, address[] calldata _tokens) external onlyFactoryOwner nonReentrant {
        require(_to != address(0), "VaultToken: INVLD_TO");

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(token != underlying, "VaultToken: IS_UNDERLYING");
            require(token != rewardsToken, "VaultToken: IS_REWARDS_TOKEN");
            require(token != token0, "VaultToken: IS_TOKEN_0");
            require(token != token1, "VaultToken: IS_TOKEN_1");

            uint256 tokenBalance = token.myBalance();
            if (tokenBalance > 0) {
                token.safeTransfer(_to, tokenBalance);
            }
        }
    }

    /*** Mirrored From uniswapV2Pair ***/

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        )
    {
        (uint _reserve0, uint _reserve1, uint _blockTimestampLast) = IUniswapV2Pair(underlying).getReserves();
        reserve0 = safe112(_reserve0);
        reserve1 = safe112(_reserve1);
        blockTimestampLast = uint32(_blockTimestampLast % 2**32);
        // if no token has been minted yet mirror uniswap getReserves
        if (totalSupply == 0) return (reserve0, reserve1, blockTimestampLast);
        // else, return the underlying reserves of this contract
        uint256 _totalBalance = totalBalance;
        uint256 _totalSupply = IUniswapV2Pair(underlying).totalSupply();
        reserve0 = safe112(_totalBalance.mul(reserve0).div(_totalSupply));
        reserve1 = safe112(_totalBalance.mul(reserve1).div(_totalSupply));
        require(reserve0 > 100 && reserve1 > 100, "VaultToken: INSUFFICIENT_RESERVES");
    }

    /*** Mirrored from BaseV1Pair ***/

    function observationLength() external view returns (uint) {
        return IBaseV1Pair(underlying).observationLength();
    }

    function observations(uint index)
        external
        view
        returns (
            uint timestamp,
            uint reserve0Cumulative,
            uint reserve1Cumulative
        )
    {
        return IBaseV1Pair(underlying).observations(index);
    }

    function currentCumulativePrices()
        external
        view
        returns (
            uint reserve0Cumulative,
            uint reserve1Cumulative,
            uint timestamp
        )
    {
        return IBaseV1Pair(underlying).currentCumulativePrices();
    }

    /*** Utilities ***/

    function safe112(uint256 n) internal pure returns (uint112) {
        require(n < 2**112, "VaultToken: SAFE112");
        return uint112(n);
    }

    function getBlockTimestamp() public view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    /*** Modifiers ***/

    modifier onlyFactoryOwner() {
        require(Ownable(factory).owner() == msg.sender, "NOT_AUTHORIZED");
        _;
    }
}