// SPDX-License-Identifier: MIT

/*

Coded for The Keep3r Network with ♥ by

██████╗░███████╗███████╗██╗  ░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
██╔══██╗██╔════╝██╔════╝██║  ░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
██║░░██║█████╗░░█████╗░░██║  ░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
██║░░██║██╔══╝░░██╔══╝░░██║  ░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
██████╔╝███████╗██║░░░░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
╚═════╝░╚══════╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://defi.sucks

*/

pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "./libraries/LiquidityAmounts.sol";
import "./libraries/PoolAddress.sol";
import "./libraries/FixedPoint96.sol";
import "./libraries/FullMath.sol";
import "./libraries/TickMath.sol";

import "../interfaces/external/IWeth9.sol";
import "../interfaces/IUniV3PairManager.sol";

import "./peripherals/Governable.sol";

contract UniV3PairManager is IUniV3PairManager, Governable {
    /// @inheritdoc IERC20Metadata
    string public override name;

    /// @inheritdoc IERC20Metadata
    string public override symbol;

    /// @inheritdoc IERC20
    uint256 public override totalSupply = 0;

    /// @inheritdoc IPairManager
    address public immutable override token0;

    /// @inheritdoc IPairManager
    address public immutable override token1;

    /// @inheritdoc IPairManager
    address public immutable override pool;

    /// @inheritdoc IUniV3PairManager
    uint24 public immutable override fee;

    /// @inheritdoc IUniV3PairManager
    uint160 public immutable override sqrtRatioAX96;

    /// @inheritdoc IUniV3PairManager
    uint160 public immutable override sqrtRatioBX96;

    /// @notice Lowest possible tick in the Uniswap's curve
    int24 private constant _TICK_LOWER = -887200;

    /// @notice Highest possible tick in the Uniswap's curve
    int24 private constant _TICK_UPPER = 887200;

    /// @inheritdoc IERC20Metadata
    //solhint-disable-next-line const-name-snakecase
    uint8 public constant override decimals = 18;

    /// @inheritdoc IERC20
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @inheritdoc IERC20
    mapping(address => uint256) public override balanceOf;

    /// @notice Struct that contains token0, token1, and fee of the Uniswap pool
    PoolAddress.PoolKey private _poolKey;

    constructor(address _pool, address _governance) Governable(_governance) {
        pool = _pool;
        uint24 _fee = IUniswapV3Pool(_pool).fee();
        fee = _fee;
        address _token0 = IUniswapV3Pool(_pool).token0();
        address _token1 = IUniswapV3Pool(_pool).token1();
        token0 = _token0;
        token1 = _token1;
        name = string(abi.encodePacked("Keep3rLP - ", ERC20(_token0).symbol(), "/", ERC20(_token1).symbol()));
        symbol = string(abi.encodePacked("kLP-", ERC20(_token0).symbol(), "/", ERC20(_token1).symbol()));
        sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(_TICK_LOWER);
        sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(_TICK_UPPER);
        _poolKey = PoolAddress.PoolKey({ token0: _token0, token1: _token1, fee: _fee });
    }

    // This low-level function should be called from a contract which performs important safety checks
    /// @inheritdoc IUniV3PairManager
    function mint(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external override returns (uint128 liquidity) {
        (liquidity, , ) = _addLiquidity(amount0Desired, amount1Desired, amount0Min, amount1Min);
        _mint(to, liquidity);
    }

    /// @inheritdoc IUniV3PairManager
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        if (msg.sender != pool) revert OnlyPool();
        if (amount0Owed > 0) _pay(decoded._poolKey.token0, decoded.payer, pool, amount0Owed);
        if (amount1Owed > 0) _pay(decoded._poolKey.token1, decoded.payer, pool, amount1Owed);
    }

    /// @inheritdoc IUniV3PairManager
    function burn(
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = IUniswapV3Pool(pool).burn(_TICK_LOWER, _TICK_UPPER, liquidity);

        if (amount0 < amount0Min || amount1 < amount1Min) revert ExcessiveSlippage();

        IUniswapV3Pool(pool).collect(to, _TICK_LOWER, _TICK_UPPER, uint128(amount0), uint128(amount1));
        _burn(msg.sender, liquidity);
    }

    /// @inheritdoc IUniV3PairManager
    function collect() external override onlyGovernance returns (uint256 amount0, uint256 amount1) {
        (, , , uint128 tokensOwed0, uint128 tokensOwed1) = IUniswapV3Pool(pool).positions(
            keccak256(abi.encodePacked(address(this), _TICK_LOWER, _TICK_UPPER))
        );
        (amount0, amount1) = IUniswapV3Pool(pool).collect(
            governance,
            _TICK_LOWER,
            _TICK_UPPER,
            tokensOwed0,
            tokensOwed1
        );
    }

    /// @inheritdoc IUniV3PairManager
    function position()
        external
        view
        override
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        (liquidity, feeGrowthInside0LastX128, feeGrowthInside1LastX128, tokensOwed0, tokensOwed1) = IUniswapV3Pool(pool)
            .positions(keccak256(abi.encodePacked(address(this), _TICK_LOWER, _TICK_UPPER)));
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) external override returns (bool) {
        _transferTokens(msg.sender, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowance[from][spender] = newAllowance;

            emit Approval(from, spender, newAllowance);
        }

        _transferTokens(from, to, amount);
        return true;
    }

    /// @notice Adds liquidity to an initialized pool
    /// @dev Reverts if the returned amount0 is less than amount0Min or if amount1 is less than amount1Min
    /// @dev This function calls the mint function of the corresponding Uniswap pool, which in turn calls UniswapV3Callback
    /// @param amount0Desired The amount of token0 we would like to provide
    /// @param amount1Desired The amount of token1 we would like to provide
    /// @param amount0Min The minimum amount of token0 we want to provide
    /// @param amount1Min The minimum amount of token1 we want to provide
    /// @return liquidity The calculated liquidity we get for the token amounts we provided
    /// @return amount0 The amount of token0 we ended up providing
    /// @return amount1 The amount of token1 we ended up providing
    function _addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    )
        internal
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            amount0Desired,
            amount1Desired
        );

        (amount0, amount1) = IUniswapV3Pool(pool).mint(
            address(this),
            _TICK_LOWER,
            _TICK_UPPER,
            liquidity,
            abi.encode(MintCallbackData({ _poolKey: _poolKey, payer: msg.sender }))
        );

        if (amount0 < amount0Min || amount1 < amount1Min) revert ExcessiveSlippage();
    }

    /// @notice Transfers the passed-in token from the payer to the recipient for the corresponding value
    /// @param token The token to be transferred to the recipient
    /// @param from The address of the payer
    /// @param to The address of the passed-in tokens recipient
    /// @param value How much of that token to be transferred from payer to the recipient
    function _pay(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        _safeTransferFrom(token, from, to, value);
    }

    /// @notice Mints Keep3r credits to the passed-in address of recipient and increases total supply of Keep3r credits by the corresponding amount
    /// @param to The recipient of the Keep3r credits
    /// @param amount The amount Keep3r credits to be minted to the recipient
    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @notice Burns Keep3r credits to the passed-in address of recipient and reduces total supply of Keep3r credits by the corresponding amount
    /// @param to The address that will get its Keep3r credits burned
    /// @param amount The amount Keep3r credits to be burned from the recipient/recipient
    function _burn(address to, uint256 amount) internal {
        totalSupply -= amount;
        balanceOf[to] -= amount;
        emit Transfer(to, address(0), amount);
    }

    /// @notice Transfers amount of Keep3r credits between two addresses
    /// @param from The user that transfers the Keep3r credits
    /// @param to The user that receives the Keep3r credits
    /// @param amount The amount of Keep3r credits to be transferred
    function _transferTokens(
        address from,
        address to,
        uint256 amount
    ) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }

    /// @notice Transfers the passed-in token from the specified "from" to the specified "to" for the corresponding value
    /// @dev Reverts with IUniV3PairManager#UnsuccessfulTransfer if the transfer was not successful,
    ///      or if the passed data length is different than 0 and the decoded data is not a boolean
    /// @param token The token to be transferred to the specified "to"
    /// @param from  The address which is going to transfer the tokens
    /// @param value How much of that token to be transferred from "from" to "to"
    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert UnsuccessfulTransfer();
    }
}