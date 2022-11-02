// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../access/Governable.sol";
import "../interfaces/swapper/IRoutedSwapper.sol";
import "../interfaces/swapper/IExchange.sol";
import "../libraries/DataTypes.sol";

/**
 * @notice Routed Swapper contract
 * This contract execute swaps and quoted using pre-set swap routes
 */
contract RoutedSwapper is IRoutedSwapper, Governable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice List of the supported exchanges
     */
    EnumerableSet.AddressSet private allExchanges;

    /**
     * @notice Mapping of exchanges' addresses by type
     */
    mapping(DataTypes.ExchangeType => address) public addressOf;

    /**
     * @notice Default swap routings
     * @dev Used to save gas by using a preset routing instead of looking for the best
     */
    mapping(bytes => bytes) public defaultRoutings;

    /// @notice Emitted when an exchange is added
    event ExchangeUpdated(
        DataTypes.ExchangeType indexed exchangeType,
        address indexed oldExchange,
        address indexed newExchange
    );

    /// @notice Emitted when exact-input swap is executed
    event SwapExactInput(
        IExchange indexed exchange,
        bytes path,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Emitted when exact-output swap is executed
    event SwapExactOutput(
        IExchange indexed exchange,
        bytes path,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountInMax,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Emitted when default routing is updated
    event DefaultRoutingUpdated(bytes key, bytes oldRouting, bytes newRouting);

    /// @inheritdoc IRoutedSwapper
    function getAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) public returns (uint256 _amountIn) {
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_OUTPUT, tokenIn_, tokenOut_)
        ];
        require(_defaultRouting.length > 0, "no-routing-found");

        (DataTypes.ExchangeType _exchangeType, bytes memory _path) = abi.decode(
            _defaultRouting,
            (DataTypes.ExchangeType, bytes)
        );

        _amountIn = IExchange(addressOf[_exchangeType]).getAmountsIn(amountOut_, _path);
    }

    /// @inheritdoc IRoutedSwapper
    function getAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) public returns (uint256 _amountOut) {
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_INPUT, tokenIn_, tokenOut_)
        ];
        require(_defaultRouting.length > 0, "no-routing-found");

        (DataTypes.ExchangeType _exchangeType, bytes memory _path) = abi.decode(
            _defaultRouting,
            (DataTypes.ExchangeType, bytes)
        );

        _amountOut = IExchange(addressOf[_exchangeType]).getAmountsOut(amountIn_, _path);
    }

    /// @inheritdoc IRoutedSwapper
    function getAllExchanges() external view override returns (address[] memory) {
        return allExchanges.values();
    }

    /// @inheritdoc IRoutedSwapper
    function swapExactInput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address receiver_
    ) external returns (uint256 _amountOut) {
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_INPUT, tokenIn_, tokenOut_)
        ];
        require(_defaultRouting.length > 0, "no-routing-found");

        (DataTypes.ExchangeType _exchangeType, bytes memory _path) = abi.decode(
            _defaultRouting,
            (DataTypes.ExchangeType, bytes)
        );

        IExchange _exchange = IExchange(addressOf[_exchangeType]);
        uint256 _balanceBefore = IERC20(tokenIn_).balanceOf(address(_exchange));
        IERC20(tokenIn_).safeTransferFrom(msg.sender, address(_exchange), amountIn_);
        _amountOut = _exchange.swapExactInput(
            _path,
            // amountIn will be balanceNow - balanceBefore for fee-on-transfer tokens
            IERC20(tokenIn_).balanceOf(address(_exchange)) - _balanceBefore,
            amountOutMin_,
            receiver_
        );
        emit SwapExactInput(_exchange, _path, tokenIn_, tokenOut_, amountIn_, _amountOut);
    }

    /// @inheritdoc IRoutedSwapper
    function swapExactOutput(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address receiver_
    ) external returns (uint256 _amountIn) {
        bytes memory _defaultRouting = defaultRoutings[
            abi.encodePacked(DataTypes.SwapType.EXACT_OUTPUT, tokenIn_, tokenOut_)
        ];
        require(_defaultRouting.length > 0, "no-routing-found");
        (DataTypes.ExchangeType _exchangeType, bytes memory _path) = abi.decode(
            _defaultRouting,
            (DataTypes.ExchangeType, bytes)
        );

        IExchange _exchange = IExchange(addressOf[_exchangeType]);
        IERC20(tokenIn_).safeTransferFrom(msg.sender, address(_exchange), amountInMax_);
        _amountIn = _exchange.swapExactOutput(_path, amountOut_, amountInMax_, msg.sender, receiver_);
        emit SwapExactOutput(_exchange, _path, tokenIn_, tokenOut_, amountInMax_, _amountIn, amountOut_);
    }

    /**
     * @notice Add or update exchange
     * @dev Use null `exchange_` for removal
     */
    function setExchange(DataTypes.ExchangeType type_, address exchange_) external onlyGovernor {
        address _currentExchange = addressOf[type_];

        if (_currentExchange == address(0)) {
            // Adding
            require(allExchanges.add(exchange_), "exchange-exists");
            addressOf[type_] = exchange_;
        } else if (exchange_ == address(0)) {
            // Removing
            require(allExchanges.remove(_currentExchange), "exchange-does-not-exist");
            delete addressOf[type_];
        } else {
            // Updating
            require(allExchanges.remove(_currentExchange), "exchange-does-not-exist");
            require(allExchanges.add(exchange_), "exchange-exists");
            addressOf[type_] = exchange_;
        }
        emit ExchangeUpdated(type_, _currentExchange, exchange_);
    }

    /**
     * @notice Set default routing
     * @dev Use empty `path_` for removal
     * @param swapType_ If the routing is related to `EXACT_INPUT` or `EXACT_OUTPUT`
     * @param tokenIn_ The swap in token
     * @param tokenOut_ The swap out token
     * @param exchange_ The type (i.e. protocol) of the exchange
     * @param path_ The swap path
     * @dev Use `abi.encodePacked(tokenA, poolFee1, tokenB, poolFee2, tokenC, ...)` for UniswapV3 exchange
     * @dev Use `abi.encode([tokenA, tokenB, tokenC, ...])` for UniswapV2-like exchanges
     */
    function setDefaultRouting(
        DataTypes.SwapType swapType_,
        address tokenIn_,
        address tokenOut_,
        DataTypes.ExchangeType exchange_,
        bytes calldata path_
    ) external onlyGovernor {
        bytes memory _key = abi.encodePacked(swapType_, tokenIn_, tokenOut_);
        bytes memory _currentRouting = defaultRoutings[_key];
        bytes memory _newRouting = abi.encode(exchange_, path_);
        if (path_.length == 0) {
            delete defaultRoutings[_key];
        } else {
            defaultRoutings[_key] = _newRouting;
        }
        emit DefaultRoutingUpdated(_key, _currentRouting, _newRouting);
    }
}