// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./abstract/ReaperBaseStrategyv3.sol";
import "./interfaces/ITHERouter.sol";
import "./interfaces/ITHEPair.sol";
import "./interfaces/ITHEGauge.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

/// @dev Deposit and stake want in THENA Gauges. Harvests THE rewards and compounds.
///     Designed for BUSD-X pairs
contract ReaperStrategyTHENABUSDStable is ReaperBaseStrategyv3 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// 3rd-party contract addresses
    address public constant THENA_ROUTER = address(0x20a304a7d126758dfe6B243D0fc515F83bCA8431);

    /// @dev Tokens Used:
    /// {BUSD} - Fees are charged in {BUSD}
    /// {THE} - THENA's reward
    /// {gauge} - Gauge where {want} is staked.
    /// {want} - Token staked.
    /// {lpToken0} - {want}'s underlying token.
    /// {lpToken1} - {want}'s underlying token.
    address public constant busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address public constant the = address(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11);
    address public constant wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address public gauge;
    address public want;
    address public lpToken0;
    address public lpToken1;

    /// @dev Arrays
    /// {rewards} - Array need to claim rewards
    /// {THEToBUSDPath} - Path from THE to BUSD
    address[] public rewards;
    address[] public THEToBUSDPath;

    /// @dev tokenA => (tokenB => swapPath config): returns best path to swap
    ///         tokenA to tokenB
    mapping(address => mapping(address => address[])) public swapPath;

    mapping(address => mapping(address => bool)) public stableSwap;

    /// @dev Initializes the strategy. Sets parameters and saves routes.
    /// @notice see documentation for each variable above its respective declaration.
    function initialize(
        address _vault,
        address treasury,
        address[] memory _strategists,
        address[] memory _multisigRoles,
        address[] memory _keepers,
        address _gauge
    ) public initializer {
        __ReaperBaseStrategy_init(_vault, treasury, _strategists, _multisigRoles, _keepers);
        gauge = _gauge;
        want = ITHEGauge(gauge).TOKEN();
        (lpToken0, lpToken1) = ITHEPair(want).tokens();

        // THE, WETH, BUSD
        THEToBUSDPath = [the, wbnb, busd];
        rewards.push(the);
    }

    /// @dev Function that puts the funds to work.
    ///      It gets called whenever someone deposits in the strategy's vault contract.
    function _deposit() internal override {
        uint256 wantBalance = IERC20Upgradeable(want).balanceOf(address(this));
        if (wantBalance != 0) {
            IERC20Upgradeable(want).safeIncreaseAllowance(gauge, wantBalance);
            ITHEGauge(gauge).deposit(wantBalance);
        }
    }

    /// @dev Withdraws funds and sends them back to the vault.
    function _withdraw(uint256 _amount) internal override {
        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        if (wantBal < _amount) {

            // Calculate how much to cWant this is
            uint256 remaining = _amount - wantBal;
            ITHEGauge(gauge).withdraw(remaining);
        }
        IERC20Upgradeable(want).safeTransfer(vault, _amount);
    }

    /// @dev Core function of the strat, in charge of collecting and re-investing rewards.
    ///      1. Claims {THE} from the {gauge}.
    ///      2. Claims fees in {BUSD} for the harvest caller and treasury.
    ///      3. Swaps the remaining rewards for {want} using {THENA_ROUTER}.
    ///      4. Deposits and stakes into {gauge}.
    function _harvestCore() internal override returns (uint256 callerFee) {
        ITHEGauge(gauge).getReward();
        // All {THE} is swapped to {BUSD} here
        // Saves a swap because {BUSD} is one of {want}'s underlying tokens
        callerFee = _chargeFees();
        _addLiquidity();
        deposit();
    }

    /// @dev Helper function to swap {_from} to {_to} given an {_amount}.
    function _swap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to || _amount == 0) {
            return;
        }

        uint256 output;
        bool useStable;
        ITHERouter router = ITHERouter(THENA_ROUTER);
        address[] storage path = swapPath[_from][_to];
        ITHERouter.route[] memory routes = new ITHERouter.route[](path.length - 1);
        uint256 prevRouteOutput = _amount;

        IERC20Upgradeable(_from).safeIncreaseAllowance(THENA_ROUTER, _amount);
        for (uint256 i = 0; i < routes.length; i++) {
            (output, useStable) = router.getAmountOut(prevRouteOutput, path[i], path[i + 1]);
            routes[i] = ITHERouter.route({from: path[i], to: path[i + 1], stable: stableSwap[path[i]][path[i+1]]});
            prevRouteOutput = output;
        }
        router.swapExactTokensForTokens(_amount, 0, routes, address(this), block.timestamp);
    }


    /// @dev Core harvest function.
    ///      Charges fees based on the amount of BUSD gained from reward
    function _chargeFees() internal returns (uint256 BUSDFee){
        IERC20Upgradeable BUSD = IERC20Upgradeable(busd);
        _swap(the,busd,IERC20Upgradeable(the).balanceOf(address(this)));
        uint256 BUSDFee = (BUSD.balanceOf(address(this)) * totalFee) / PERCENT_DIVISOR;

        if (BUSDFee != 0) {
            BUSD.safeTransfer(treasury, BUSDFee);
        }
    }

    /// @dev Core harvest function.
    ///      Converts half of held {BUSD} in {want}
    function _addLiquidity() internal {
        uint256 BUSDBal = IERC20Upgradeable(busd).balanceOf(address(this));
        if (BUSDBal == 0) {
            return;
        }

        ITHEPair pair = ITHEPair(want);
        (uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
        (address token0, address token1) = pair.tokens();
        uint256 toSwap;
        if (busd == token0) {
            toSwap = _getSwapAmount(pair, BUSDBal, reserveA, reserveB, busd);
        } else {
            require(busd == token1, "LP does not have BUSD!");
            toSwap = _getSwapAmount(pair, BUSDBal, reserveB, reserveA, busd);
        }

        if (busd == lpToken0) {
            _swap(busd, lpToken1, toSwap);
        } else {
            _swap(busd, lpToken0, toSwap);
        }

        uint256 lpToken0Bal = IERC20Upgradeable(lpToken0).balanceOf(address(this));
        uint256 lpToken1Bal = IERC20Upgradeable(lpToken1).balanceOf(address(this));
        IERC20Upgradeable(lpToken0).safeIncreaseAllowance(THENA_ROUTER, lpToken0Bal);
        IERC20Upgradeable(lpToken1).safeIncreaseAllowance(THENA_ROUTER, lpToken1Bal);
        ITHERouter(THENA_ROUTER).addLiquidity(
            lpToken0,
            lpToken1,
            ITHEPair(want).stable(),
            lpToken0Bal,
            lpToken1Bal,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @dev Update {SwapPath} for a specified pair of tokens.
    function updateSwapPath(address _tokenIn, address _tokenOut, address[] calldata _path) external {
        _atLeastRole(STRATEGIST);
        require(_tokenIn != _tokenOut && _path.length >= 2 && _path[0] == _tokenIn && _path[_path.length - 1] == _tokenOut);
        swapPath[_tokenIn][_tokenOut] = _path;
    }

    /// @dev Swap whole balance of a token to BUSD
    ///     Should only be used to scrap lost funds.
    function guardianSwap(address _token) external {
        _atLeastRole(GUARDIAN);
        _swap(_token, busd, IERC20Upgradeable(_token).balanceOf(address(this)));
    }

    /// @dev Function to calculate the total {want} held by the strat.
    ///      It takes into account both the funds directly held by the contract and those into the {gauge}
    function balanceOf() public view override returns (uint256) {
        return balanceInGauge() + IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @dev Returns the amount of {want} staked into the {gauge}
    function balanceInGauge() public view returns (uint256) {
        return ITHEGauge(gauge).balanceOf(address(this));
    }


    /// @dev Withdraws all funds leaving rewards behind.
    function _reclaimWant() internal override {
        ITHEGauge(gauge).withdrawAll();
    }

    function setTHEToBUSDPath(address[] memory _path) external {
        _atLeastRole(STRATEGIST);
        require(_path[0] == the && _path[_path.length - 1] == busd, "INVALID INPUT");
        THEToBUSDPath = _path;
    }

    function _getSwapAmount(
        ITHEPair pair,
        uint256 investmentA,
        uint256 reserveA,
        uint256 reserveB,
        address tokenA
    ) private view returns (uint256 swapAmount) {
        uint256 halfInvestment = investmentA / 2;
        uint256 numerator = pair.getAmountOut(halfInvestment, tokenA);
        uint256 denominator = _quoteLiquidity(halfInvestment, reserveA + halfInvestment, reserveB - numerator);
        swapAmount = investmentA - Babylonian.sqrt((halfInvestment * halfInvestment * numerator) / denominator);
    }

    // Copied from THENA's Router since it's an internal function in there
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function _quoteLiquidity(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Router: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "Router: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    function setStableSwap(address _to, address _from, bool _stable) external {
        _atLeastRole(STRATEGIST);
        stableSwap[_to][_from] = _stable;   
    }
}