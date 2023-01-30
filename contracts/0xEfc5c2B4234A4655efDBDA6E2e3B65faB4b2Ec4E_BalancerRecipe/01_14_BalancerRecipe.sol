// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./OpenZeppelin/SafeERC20.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/Ownable.sol";
import "./Interfaces/IWETH.sol";
import "./Interfaces/ILendingRegistry.sol";
import "./Interfaces/ILendingLogic.sol";
import "./Interfaces/IPieRegistry.sol";
import "./Interfaces/IPie.sol";
import "./Interfaces/IUniV3Router.sol";
import "./Interfaces/IBalancer.sol";

pragma experimental ABIEncoderV2;

/**
 * @title BalancerRecipe contract for BaoFinance's Baskets Protocol (vexs SimpleUniRecipe fork)
 *
 * @author fabiaz84
 */
contract BalancerRecipe is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // -------------------------------
    // CONSTANTS
    // -------------------------------

    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ILendingRegistry public immutable lendingRegistry;
    IPieRegistry public immutable basketRegistry;
    IBalancer public balancer = IBalancer(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    // -------------------------------
    // VARIABLES
    // -------------------------------

    uniV3Router public uniRouter;
    uniOracle public oracle;

    mapping(address => bytes32) balancerViable;

    /**
     * Create a new Recipe.
     *
     * @param _lendingRegistry LendingRegistry address
     * @param _pieRegistry PieRegistry address
     * @param _uniV3Router Uniswap V3 Router address
     * @param _uniOracle Uniswap Oracke address
     */
    constructor(
        address _lendingRegistry,
        address _pieRegistry,
        address _uniV3Router,
        address _uniOracle
    ) {
        require(_lendingRegistry != address(0), "LENDING_MANAGER_ZERO");
        require(_pieRegistry != address(0), "PIE_REGISTRY_ZERO");

        lendingRegistry = ILendingRegistry(_lendingRegistry);
        basketRegistry = IPieRegistry(_pieRegistry);

        uniRouter = uniV3Router(_uniV3Router);
        oracle = uniOracle(_uniOracle);

        // Approve max WETH spending on Balancer
        WETH.approve(address(balancer), type(uint256).max);
    }

    // -------------------------------
    // PUBLIC FUNCTIONS
    // -------------------------------

    /**
     * External bake function.
     * Mints `_mintAmount` basket tokens with as little of `_maxInput` as possible.
     *
     * @param _basket Address of basket token to mint
     * @param _maxInput Max WETH to use to mint _mintAmount basket tokens
     * @param _mintAmount Target amount of basket tokens to mint
     * @return inputAmountUsed Amount of WETH used to mint the basket token
     * @return outputAmount Amount of basket tokens minted
     */
    function bake(
        address _basket,
        uint256 _maxInput,
        uint256 _mintAmount
    ) external returns(uint256 inputAmountUsed, uint256 outputAmount) {
        IERC20 outputToken = IERC20(_basket);

        IERC20(address(WETH)).safeTransferFrom(_msgSender(), address(this), _maxInput);

        outputAmount = _bake(_basket, _mintAmount);

        uint256 remainingInputBalance = WETH.balanceOf(address(this));
        
        if(remainingInputBalance > 0) {
            WETH.transfer(_msgSender(), remainingInputBalance);
        }
        inputAmountUsed = _maxInput - remainingInputBalance;

        outputToken.safeTransfer(_msgSender(), outputAmount);  
    }

    /**
     * Bake a basket with ETH.
     *
     * Wraps the ETH that was sent, and continues the baking
     * process as normal.
     *
     * @param _basket Basket token to mint
     * @param _mintAmount Target amount of basket tokens to mint
     */
    function toBasket(
        address _basket,
        uint256 _mintAmount
    ) external payable returns (uint256 outputAmount) {
        // Wrap ETH
        address(WETH).call{value: msg.value}("");

        // Bake basket
        outputAmount = _bake(_basket, _mintAmount);

        // Transfer minted baskets to msg.sender
        IERC20(_basket).safeTransfer(msg.sender, outputAmount);

        // if any WETH left convert it into ETH and send it back
        uint256 wethBalance = WETH.balanceOf(address(this));
        if(wethBalance != 0) {
            // console.log("returning WETH");
            // console.log(wethBalance);
            WETH.withdraw(wethBalance);
            payable(msg.sender).transfer(wethBalance);
        }
    }

    /**
     * Get the price of `_amount` basket tokens in WETH
     *
     * @param _basket Basket token to get the price of
     * @param _amount Amount of basket tokens to get price of
     * @return _price Price of `_amount` basket tokens in WETH
     */
    function getPrice(address _basket, uint256 _amount) public returns (uint256 _price) {
        // Check that _basket is a valid basket
        require(basketRegistry.inRegistry(_basket));

        // Loop through all the tokens in the basket and get their prices on UniSwap V3
        (address[] memory tokens, uint256[] memory amounts) = IPie(_basket).calcTokensForAmount(_amount);
        address _token;
        address _underlying;
        uint256 _amount;
        for (uint256 i; i < tokens.length; ++i) {
            _token = tokens[i];
            _amount = amounts[i].add(1);

            // If the amount equals zero, revert.
            assembly {
                if iszero(_amount) {
                    revert(0, 0)
                }
            }

            _underlying = lendingRegistry.wrappedToUnderlying(_token);
            if (_underlying != address(0)) {
                _amount = mulDivDown(
                    _amount,
                    getLendingLogicFromWrapped(_token).exchangeRateView(_token),
                    1e18
                );
                _token = _underlying;
            }

            // If the token is DAI, we don't need to perform a swap before calculating.
            _price += _token == address(DAI) ? _amount : _quoteExactOutput(address(DAI), _token, _amount, 500);
        }
    }

    /**
     * Get the price of `_amount` basket tokens in ETH
     *
     * @param _basket Basket token to get the price of
     * @param _amount Amount of basket tokens to get price of
     * @return _price Price of `_amount` basket tokens in ETH
     */
    function getPriceEth(address _basket, uint256 _amount) external returns (uint256 _price) {
        _price = _quoteExactOutput(
            address(WETH),
            address(DAI),
            getPrice(_basket, _amount),
            500
        );
    }

    // -------------------------------
    // INTERNAL FUNCTIONS
    // -------------------------------

    /**
     * Internal bake function.
     * Checks if _basket is a valid basket, mints _mintAmount basketTokens, and returns the real
     * amount minted.
     *
     * @param _basket Address of basket token to mint
     * @param _mintAmount Target amount of basket tokens to mint
     * @return outputAmount Amount of basket tokens minted
     */
    function _bake(address _basket, uint256 _mintAmount) internal returns (uint256 outputAmount) {
        require(basketRegistry.inRegistry(_basket));

        swapAndJoin(_basket, _mintAmount);

        outputAmount = IERC20(_basket).balanceOf(address(this));
    }

    /**
     * Swap for the underlying assets of a basket using only Balancer and mint _outputAmount basket tokens.
     *
     * @param _basket Basket to pull underlying assets from
     * @param _mintAmount Target amount of basket tokens to mint
     */
    function swapAndJoin(address _basket, uint256 _mintAmount) internal {
        IPie basket = IPie(_basket);
        (address[] memory tokens, uint256[] memory amounts) = basket.calcTokensForAmount(_mintAmount);

        // Instantiate empty variables that will be assigned multiple times in the loop, less memory allocation
        address _token;
        address underlying;
        uint256 _amount;
        uint256 underlyingAmount;
        ILendingLogic lendingLogic;

        for (uint256 i; i < tokens.length; ++i) {
            _token = tokens[i];
            _amount = amounts[i].add(1);

            // If the token is registered in the lending registry, swap to
            // its underlying token and lend it.
            underlying = lendingRegistry.wrappedToUnderlying(_token);

            if (underlying == address(0) && _token != address(WETH)) {
                _swap_out_amount(
                    address(WETH),
                    _token,
                    _amount
                );
            } else {
                // Get underlying amount according to the exchange rate
                lendingLogic = getLendingLogicFromWrapped(_token);
                underlyingAmount = mulDivDown(_amount, lendingLogic.exchangeRate(_token), 1e18);

                // Swap for the underlying asset on Balancer
                // If the token is WETH, no need to swap
                if (underlying != address(WETH)) {
                    _swap_out_amount(
                        address(WETH),
                        underlying,
                        underlyingAmount
                    );
                }

                // Execute lending transactions
                (address[] memory targets, bytes[] memory data) = lendingLogic.lend(underlying, underlyingAmount, address(this));
                for (uint256 j; j < targets.length; ++j) {
                    (bool success,) = targets[j].call{value : 0}(data[j]);
                    require(success, "CALL_FAILED");
                }
            }
            IERC20(_token).approve(_basket, _amount);
        }
        basket.joinPool(_mintAmount);
    }

    /**
     * Swap `_from` -> `_to` and receive exactly `_amountOut` of `_to` on Balancer
     *
     * @param _assetIn Address of token to swap from
     * @param _assetOut Address of token to swap to
     * @param _amountOut Exact amount of `_to` to receive
     */
    function _swap_out_amount(
        address _assetIn,
        address _assetOut,
        uint256 _amountOut
    ) internal {
            IBalancer.SwapKind kind = IBalancer.SwapKind.GIVEN_OUT;
            IBalancer.SingleSwap memory singleSwap = IBalancer.SingleSwap(
                balancerViable[_assetOut],
                kind,
                _assetIn,
                _assetOut,
                _amountOut,
                "0x00"
            );
            
            IBalancer.FundManagement memory funds =  IBalancer.FundManagement(
                address(this),
                false,
                payable(address(this)),
                false
            );

            IERC20(_assetIn).approve(address(balancer), 0);
            IERC20(_assetIn).approve(address(balancer), type(uint256).max);
            balancer.swap(
                singleSwap,
                funds,
                type(uint256).max,
                block.timestamp + 1
            );
    }

    /**
     * Quote an exact input swap on UniV3
     *
     * @param _from Token to swap from
     * @param _to Token to swap to
     * @param _amountOut Exact amount of `_to` tokens to be received for `_amountIn` `_from` tokens
     * @return _amountIn Amount to send in order to receive `_amountOut` `to` tokens
     */
    function _quoteExactOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint24 _fee
    ) internal returns (uint256 _amountIn) {
        try oracle.quoteExactOutputSingle(_from, _to, _fee, _amountOut, 0) returns (uint256 _p) {
            _amountIn = _p;
        } catch {
            _amountIn = type(uint256).max;
        }
    }

    /**
     * Get the lending logic of a wrapped token
     *
     * @param _wrapped Address of wrapped token
     * @return ILendingLogic - Lending logic associated with `_wrapped`
     */
    function getLendingLogicFromWrapped(address _wrapped) internal view returns (ILendingLogic) {
        return ILendingLogic(
            lendingRegistry.protocolToLogic(
                lendingRegistry.wrappedToProtocol(
                    _wrapped
                )
            )
        );
    }

    /**
     * Yoinked from the geniuses behind solmate
     * https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
     *
     * (x*y)/z
     */
    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    // -------------------------------
    // ADMIN FUNCTIONS
    // -------------------------------

    /**
     * Update the Uni V3 Router
     *
     * @param _newRouter New Uni V3 Router address
     */
    function updateUniRouter(address _newRouter) external onlyOwner {
        // Update stored Uni V3 exchange
        uniRouter = uniV3Router(_newRouter);
    }

    function setBalancerPoolMapping(address _inputAsset, bytes32 _pool) external onlyOwner {
        balancerViable[_inputAsset] = _pool;
    }

    /**
     * Update the Uni V3 Oracle
     *
     * @param _newOracle New Uni V3 Oracle address
     */
    function updateUniOracle(address _newOracle) external onlyOwner {
        oracle = uniOracle(_newOracle);
    }

    receive() external payable {}
}