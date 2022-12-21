// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {IERC20} from "./interfaces/IERC20.sol";
import {SafeERC20} from "./library/SafeERC20.sol";
import {SafeMath} from "./library/SafeMath.sol";

import "./interfaces/ICurve.sol";
import "./dependencies/Governable.sol";

import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

interface IUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface IOracle {
    function latestAnswer() external view returns (uint256);
}

interface IBurnContract {
    function totalGHNYBurnt() external view returns (uint256 _totalGHNYBurnt);
}

// In order to implement a staking contract in the future
interface IStaking {
    function receivedWETH(uint256 amountWETH) external;

    function receivedGHNY(uint256 amountGHNY) external;
}

// Standard Curve interface with int128 (i) is problematic for TriCrypto
interface ITriCryptoPool {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 amount, uint256 i) external view returns (uint256);
}

interface IVault is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function deposit(uint256 amount) external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);
}

/**
@notice An IStaking interface has been implemented in order to enable a future Staking Contract:
- For the Staking Contract to know the fees received, two functions are called after a transfer.
- This means that the Staking Contract must implement both functions receivedWETH & receivedGHNY.
- Staking Fees must be zero until a proper Staking Contract is set up, otherwise tx will revert.
*/

contract FeeContract is Governable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 internal constant GHNY = IERC20(0xfB4d8bEe1840F3897d2344035F68eD594359c939);

    address internal constant uniRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant uniPool = 0x38Eb565EB30cdEFF04aEeb9700503ea820Ac5347;
    address internal constant triCryptoPool = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address internal constant stETHPool = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;

    ICurveFi internal constant zapContract = ICurveFi(0xA79828DF1850E8a3A3064576f380D90aECDD3359);

    address internal constant hsLUSD = 0x6B5020a88669B0320fAB5f2771bc35401b0dA6CC;
    address internal constant hsFRAX = 0xF437C8cEa5Bb0d8C10Bb9c012fb4a765663942f1;
    address internal constant hsTriCrypto = 0xd6EFCDc97452Ab05B7b4cA61725F48539a5844A3;
    address internal constant hsStETH = 0x042815d6fe33152C123059c0e2be77404769b9c8;

    address internal constant ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IERC20 internal constant usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 internal constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 internal constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 internal constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public targetStable;

    address public burnContract = 0x07945d5D10d2e47a59c4A5f470352ae85F2E5C45;
    address public stakingContract;
    address public treasuryAddress = 0xcE88F73FAA2C8de5fdE0951A6b80583af4C14265;
    address public keeperAddress;

    // Different variables packed into a single slot
    struct Variables {
        uint64 stakingFee;
        uint64 treasuryFee;
        uint40 GHNYPercent;
        uint24 uniStableFee;
        uint24 uniGHNYFee;
        uint24 slippageMax;
        uint16 optimal;
    }

    Variables public vars;

    uint256 internal constant DENOMINATOR = 10000;

    event BuybackGHNY(uint256 timestamp, uint256 amount);
    event FeesUpdated(uint256 stakingFee, uint256 treasuryFee);
    event GHNYPercentUpdated(uint256 newPercent, uint256 oldPercent);
    event Sweep(address indexed token, uint256 amount);

    constructor(address _governor) Governable(_governor) {
        targetStable = address(usdc);

        vars.stakingFee = 0;
        vars.treasuryFee = 2000; // Team fee
        vars.GHNYPercent = 0;
        vars.uniStableFee = 500; // 0.05% WETH-USD Pool
        vars.uniGHNYFee = 10000; // 1% WETH-GHNY Pool
        vars.slippageMax = 9700; // 3% diff from Oracle price
        vars.optimal = 2; // USDC

        _approveToken(address(weth), uniRouter);
        _approveToken(address(usdc), uniRouter);
    }

    modifier onlyAuthorized() {
        require(msg.sender == governor || msg.sender == keeperAddress, "FeeContract: Not authorized");
        _;
    }

    // --- Public View Functions --- //

    /// @notice Getter to track the amount of GHNY burnt to date
    function totalGHNYBurnt() external view returns (uint256 _totalGHNYBurnt) {
        _totalGHNYBurnt = IBurnContract(burnContract).totalGHNYBurnt();
    }

    /// @notice See how much USDC we would get for all of our hsTokens
    function valueOfTokens() external view returns (uint256 _totalUSDC) {
        _totalUSDC = valueOfMeta(hsFRAX).add(valueOfMeta(hsLUSD)).add(valueOfTriCrypto()).add(valueOfStETH());
    }

    function valueOfMeta(address _vaultAddress) public view returns (uint256) {
        if (_tokenBalance(_vaultAddress) == 0) return 0;

        address lpToken = IVault(_vaultAddress).token();
        uint256 amountLp = _tokenBalance(_vaultAddress).mul(IVault(_vaultAddress).pricePerShare()).div(1e18);

        return zapContract.calc_withdraw_one_coin(lpToken, amountLp, 2);
    }

    function valueOfTriCrypto() public view returns (uint256) {
        if (_tokenBalance(hsTriCrypto) == 0) return 0;

        uint256 amountLpTriCrypto = _tokenBalance(hsTriCrypto).mul(IVault(hsTriCrypto).pricePerShare()).div(
            1e18
        );

        return ITriCryptoPool(triCryptoPool).calc_withdraw_one_coin(amountLpTriCrypto, 0);
    }

    function valueOfStETH() public view returns (uint256) {
        if (_tokenBalance(hsStETH) == 0) return 0;

        IOracle ethOracle = IOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        uint256 ethPrice = ethOracle.latestAnswer(); // 1e8 precision

        uint256 amountLpStETH = _tokenBalance(hsStETH).mul(IVault(hsStETH).pricePerShare()).div(1e18);
        uint256 ETHInStETH = ICurveFi(stETHPool).calc_withdraw_one_coin(amountLpStETH, 0);

        return ETHInStETH.mul(ethPrice).div(1e20);
    }

    /// @notice Get actual price from UniV3 Pool in USD with 18 decimals
    function getCurrentUniV3Price() external view returns (uint256 _price) {
        IOracle ethOracle = IOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        uint256 ethPrice = ethOracle.latestAnswer(); // 1e8 precision

        (uint160 sqrtRatioX96, , , , , , ) = IUniV3(uniPool).slot0();
        uint256 GHNYPerETH = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, uint256(2**192) / 1e18);

        _price = ethPrice.mul(1e28).div(GHNYPerETH);
    }

    // --- External Core Functions --- //

    function executeAll() external onlyAuthorized {
        _executeMain(true, true, true, true);
    }

    function executeMain(
        bool _lusd,
        bool _frax,
        bool _triCrypto,
        bool _stETH
    ) external onlyAuthorized {
        _executeMain(_lusd, _frax, _triCrypto, _stETH);
    }

    // --- Internal Functions --- //

    function _executeMain(
        bool _lusd,
        bool _frax,
        bool _triCrypto,
        bool _stETH
    ) internal {
        _swapToWeth(_lusd, _frax, _triCrypto, _stETH);
        _distributeFees();
        _uniV3SwapToGHNY();
        _distributeGHNY();
    }

    function _swapToWeth(
        bool _lusd,
        bool _frax,
        bool _triCrypto,
        bool _stETH
    ) internal {
        if (_lusd) _swapMetaToWeth(hsLUSD);
        if (_frax) _swapMetaToWeth(hsFRAX);
        if (_triCrypto) _swapTriCryptoToWeth(hsTriCrypto);
        if (_stETH) _swapStETHToWeth(hsStETH);
    }

    function _swapMetaToWeth(address _vaultAddress) internal {
        _removeLiquidity(_vaultAddress);
        _swapOptimalToWeth();
    }

    function _removeLiquidity(address _vaultAddress) internal {
        (address lpToken, uint256 lpTokenBal) = _withdrawFromVault(_vaultAddress);

        _approveToken(lpToken, address(zapContract));

        // Remove liquidity in the optimal token (DAI is 1, USDC is 2, USDT is 3)
        zapContract.remove_liquidity_one_coin(lpToken, lpTokenBal, vars.optimal, 0);
    }

    function _swapTriCryptoToWeth(address _vaultAddress) internal {
        (address lpToken, uint256 lpTokenBal) = _withdrawFromVault(_vaultAddress);

        _approveToken(lpToken, triCryptoPool);

        // Remove liquidity in TriCrypto (USDT is 0, WBTC is 1, WETH is 2)
        ITriCryptoPool(triCryptoPool).remove_liquidity_one_coin(lpTokenBal, 2, 0);
    }

    function _swapStETHToWeth(address _vaultAddress) internal {
        (address lpToken, uint256 lpTokenBal) = _withdrawFromVault(_vaultAddress);

        _approveToken(lpToken, stETHPool);

        // Remove liquidity in stETH Pool (ETH is 0, stETH is 1)
        ICurveFi(stETHPool).remove_liquidity_one_coin(lpTokenBal, 0, 0);

        // Convert all the ETH to WETH
        IWETH(address(weth)).deposit{value: address(this).balance}();
    }

    function _withdrawFromVault(address _vaultAddress)
        internal
        returns (address lpToken, uint256 lpTokenBal)
    {
        // Withdraw the underlying lpToken from the Grizzly Vault
        IVault(_vaultAddress).withdraw(_tokenBalance(_vaultAddress));

        lpToken = IVault(_vaultAddress).token();
        lpTokenBal = _tokenBalance(lpToken);
    }

    function _swapOptimalToWeth() internal {
        address _targetStable = targetStable;

        IOracle ethOracle = IOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        uint256 ethPrice = ethOracle.latestAnswer(); // 1e8 precision

        uint256 targetStableBalance = _tokenBalance(_targetStable);

        Variables memory _vars = vars;

        uint256 ethExpected;

        if (_vars.optimal == 2 || _vars.optimal == 3) {
            // Use our slippage tolerance, convert between USDC / USDT (1e6) -> ETH (1e18)
            ethExpected = (((targetStableBalance.mul(1e20)).div(ethPrice)).mul(_vars.slippageMax)).div(
                DENOMINATOR
            );
        } else {
            // Use our slippage tolerance, convert between DAI (1e18) -> ETH (1e18)
            ethExpected = (((targetStableBalance.mul(1e8)).div(ethPrice)).mul(_vars.slippageMax)).div(
                DENOMINATOR
            );
        }

        IUniV3(uniRouter).exactInput(
            IUniV3.ExactInputParams({
                path: abi.encodePacked(_targetStable, _vars.uniStableFee, address(weth)),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: targetStableBalance,
                amountOutMinimum: ethExpected
            })
        );
    }

    function _uniV3SwapToGHNY() internal {
        uint256 wethBal = _tokenBalance(address(weth));

        Variables memory _vars = vars;

        uint256 amountOutGHNY = _getUniswapTwapAmount(address(weth), address(GHNY), uint128(wethBal), 120);
        amountOutGHNY = amountOutGHNY.mul(_vars.slippageMax).div(DENOMINATOR);

        IUniV3(uniRouter).exactInput(
            IUniV3.ExactInputParams({
                path: abi.encodePacked(address(weth), _vars.uniGHNYFee, address(GHNY)),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: wethBal,
                amountOutMinimum: amountOutGHNY
            })
        );
    }

    function _getUniswapTwapAmount(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint32 interval
    ) internal view returns (uint256 amountOut) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = interval; // 300 -> 5 min;
        secondsAgo[1] = 0;

        // Returns the cumulative tick values and liquidity as of each timestamp secondsAgo from current block timestamp
        (int56[] memory tickCumulatives, ) = IUniV3(uniPool).observe(secondsAgo);

        int24 avgTick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(interval)));

        amountOut = OracleLibrary.getQuoteAtTick(avgTick, amountIn, tokenIn, tokenOut);
    }

    function _distributeFees() internal {
        uint256 wethBal = _tokenBalance(address(weth));

        Variables memory _vars = vars;

        if (wethBal != 0) {
            uint256 stakingFee = wethBal.mul(_vars.stakingFee).div(DENOMINATOR);
            uint256 treasuryFee = wethBal.mul(_vars.treasuryFee).div(DENOMINATOR);

            if (stakingFee != 0) {
                weth.safeTransfer(stakingContract, stakingFee);
                IStaking(stakingContract).receivedWETH(stakingFee);
            }

            weth.safeTransfer(treasuryAddress, treasuryFee);
        }
    }

    function _distributeGHNY() internal {
        uint256 GHNYBal = _tokenBalance(address(GHNY));

        if (GHNYBal != 0) {
            uint256 stakingGHNY = GHNYBal.mul(vars.GHNYPercent).div(DENOMINATOR);

            if (stakingGHNY != 0) {
                GHNY.safeTransfer(stakingContract, stakingGHNY);
                IStaking(stakingContract).receivedGHNY(stakingGHNY);
            }

            _burnGHNY();
        }
    }

    /// @notice Burn GHNY by transferring to the Burn Contract as the supply is fixed and is not "burnable"
    function _burnGHNY() internal {
        uint256 GHNYBal = _tokenBalance(address(GHNY));
        GHNY.safeTransfer(burnContract, GHNYBal);
        emit BuybackGHNY(block.timestamp, GHNYBal);
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _tokenBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // --- External Protected Functions --- //

    /// @notice Set the optimal token to sell the Meta token on Curve
    function setOptimal(uint16 _optimal) external onlyGovernor {
        if (_optimal == 1) {
            targetStable = address(dai);
        } else if (_optimal == 2) {
            targetStable = address(usdc);
        } else if (_optimal == 3) {
            targetStable = address(usdt);
        } else {
            revert("Incorrect token");
        }

        vars.optimal = _optimal;

        _approveToken(address(targetStable), uniRouter);
    }

    /// @notice Set the fee pool we'd like to swap through on UniV3 (1% = 10_000)
    function setUniFees(uint24 _stableFee) external onlyGovernor {
        require(_stableFee == 100 || _stableFee == 500 || _stableFee == 3000, "FeeContract: Not valid fee");
        vars.uniStableFee = _stableFee;
    }

    /// @notice Set the fee pool we'd like to swap GHNY on UniV3 (1% = 10_000)
    function setUniGHNYFee(uint24 _uniGHNYFee) external onlyGovernor {
        require(_uniGHNYFee == 3000 || _uniGHNYFee == 10000, "FeeContract: Not valid fee");
        vars.uniGHNYFee = _uniGHNYFee;
    }

    /// @notice Set the slippage parameter for making swaps
    function setSlippage(uint24 _slippageMax) external onlyGovernor {
        require(_slippageMax <= 10000, "FeeContract: Not valid slippage");
        vars.slippageMax = _slippageMax;
    }

    function setFeePercentages(uint64 _stakingFee, uint64 _treasuryFee) external onlyGovernor {
        require(_stakingFee <= 10000 && _treasuryFee <= 10000, "FeeContract: Not valid values");

        vars.stakingFee = _stakingFee;
        vars.treasuryFee = _treasuryFee;

        emit FeesUpdated(_stakingFee, _treasuryFee);
    }

    function setGHNYPercentage(uint40 _GHNYPercent) external onlyGovernor {
        require(_GHNYPercent <= 10000, "FeeContract: Not valid values");

        uint40 oldPercent = vars.GHNYPercent;
        vars.GHNYPercent = _GHNYPercent;

        emit GHNYPercentUpdated(_GHNYPercent, oldPercent);
    }

    /// @notice Sweep tokens or ETH in case they get stuck in the contract
    function sweep(address[] memory _tokens, bool _ETH) external onlyGovernor {
        if (_ETH) {
            uint256 balance = address(this).balance;
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success, "FeeContract: Sending ETH failed");
            emit Sweep(ETHAddress, balance);
        }
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 amount = _tokenBalance(_tokens[i]);
            IERC20(_tokens[i]).safeTransfer(msg.sender, amount);
            emit Sweep(_tokens[i], amount);
        }
    }

    /// @notice BurnContract is just a contract with no functionality
    function setBurnContractAddress(address _burnContract) external onlyGovernor {
        require(_burnContract != address(0), "FeeContract: Not valid address");
        burnContract = _burnContract;
    }

    function setStakingContractAddress(address _stakingContract) external onlyGovernor {
        require(_stakingContract != address(0), "FeeContract: Not valid address");
        stakingContract = _stakingContract;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyGovernor {
        require(_treasuryAddress != address(0), "FeeContract: Not valid address");
        treasuryAddress = _treasuryAddress;
    }

    function setKeeperAddress(address _keeperAddress) external onlyGovernor {
        require(_keeperAddress != address(0), "FeeContract: Not valid address");
        keeperAddress = _keeperAddress;
    }

    receive() external payable {
        require(msg.sender != tx.origin, "FeeContract: Do not send ETH directly");
    }
}