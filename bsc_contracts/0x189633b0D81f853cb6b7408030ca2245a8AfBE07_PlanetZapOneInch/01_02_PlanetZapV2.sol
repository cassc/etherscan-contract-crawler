pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Dependencies.sol";

/**
@title Planet Zap via OneInch
@author Planet
@notice Use this to Zap and out of any LP on Planet
*/

contract PlanetZapOneInch {
    using SafeERC20 for IERC20;

    address public immutable oneInchRouter; // Router for all the swaps to go through
    address public immutable WBNB; // BNB address
    uint256 public constant minimumAmount = 1000; // minimum number of tokens for the transaction to go through

    enum WantType {
        WANT_TYPE_UNISWAP_V2,
        WANT_TYPE_SOLIDLY_STABLE,
        WANT_TYPE_SOLIDLY_VOLATILE,
        WANT_TYPE_GAMMA_HYPERVISOR
    }

    event TokenReturned(address token, uint256 amount); // emitted when any pending tokens left with the contract after a function call are sent back to the user
    event Swap(address tokenIn, uint256 amountIn); // emitted after every swap transaction
    event ZapIn(address tokenIn, uint256 amountIn); //  emitted after every ZapIn transaction
    event ZapOut(address tokenOut, uint256 amountOut); // emitted after every ZapOut transaction
    // should we also include destination tokens?

    constructor(address _oneInchRouter, address _WBNB) {
        // Safety checks to ensure WBNB token address
        IWBNB(_WBNB).deposit{value: 0}();
        IWBNB(_WBNB).withdraw(0);
        WBNB = _WBNB;

        oneInchRouter = _oneInchRouter;
    }
    // Zap's main functions external and public functions

    /** 
    @notice Swaps BNB for any token via One Inch Router
    @param _token0 One Inch calldata for swapping BNB to the output token
    @param _outputToken Address of output token
    */
    function swapFromBNB (bytes calldata _token0, address _outputToken) external payable {
        require(msg.value >= minimumAmount, 'Planet: Insignificant input amount');

        IWBNB(WBNB).deposit{value: msg.value}();
        _swap(WBNB, _token0, _outputToken);
        emit Swap(WBNB, msg.value);
    }
    
    /** 
    @notice Swaps any token for another token via One Inch Router
    @param _inputToken Address of input token
    @param _tokenInAmount Amount of input token to be swapped
    @param _token0 One Inch calldata for swapping the input token to the output token
    @param _outputToken Address of output token 
    */ 
    function swap (address _inputToken, uint256 _tokenInAmount, bytes calldata _token0, address _outputToken) external {
        require(_tokenInAmount >= minimumAmount, 'Planet: Insignificant input amount');
        IERC20(_inputToken).safeTransferFrom(msg.sender, address(this), _tokenInAmount);
        _swap(_inputToken, _token0, _outputToken);
        emit Swap(_inputToken, _tokenInAmount);
    }

    /** 
    @notice Zaps BNB into any LP Pair (including aggregated pairs) on Planet via One Inch Router
    @param _token0 One Inch calldata for swapping BNB to token0 of the LP Pair
    @param _token1 One Inch calldata for swapping BNB to token1 of the LP Pair
    @param _type LP Pair type, whether uniswapV2, solidly volatile or solidly stable
    @param _router Rourter where "Add Liquidity" is to be called, to create LP Pair
    @param _pair Address of the output LP Pair token
    */ 
    function zapInBNB (bytes calldata _token0, bytes calldata _token1, WantType _type, address _router, address _pair) external payable {
        require(msg.value >= minimumAmount, 'Planet: Insignificant input amount');

        IWBNB(WBNB).deposit{value: msg.value}();
        _zapIn(WBNB, _token0, _token1, _type, _router, _pair);
        emit ZapIn(WBNB, msg.value);
    }

    /** 
    @notice Zaps any token into any LP Pair (including aggregated pairs) on Planet via One Inch Router
    @param _inputToken Address of input token
    @param _tokenInAmount Amount of input token to be zapped
    @param _token0 One Inch calldata for swapping the input token to token0 of the LP Pair
    @param _token1 One Inch calldata for swapping the input token to token1 of the LP Pair
    @param _type LP Pair type, whether uniswapV2, solidly volatile or solidly stable
    @param _router Rourter where "Add Liquidity" is to be called, to create LP Pair
    @param _pair Address of the output LP Pair token
    */
    function zapIn (address _inputToken, uint256 _tokenInAmount, bytes calldata _token0, bytes calldata _token1, WantType _type, address _router, address _pair) external {
        require(_tokenInAmount >= minimumAmount, 'Planet: Insignificant input amount');

        IERC20(_inputToken).safeTransferFrom(msg.sender, address(this), _tokenInAmount);
        _zapIn(_inputToken, _token0, _token1, _type, _router, _pair /** , _outputToken */);
        emit ZapIn(_inputToken, _tokenInAmount);
    }

    /**
    @notice Zaps out any LP Pair (including aggregated pairs) on Planet to any desired token via One Inch Router
    @param _pair Address of the input LP Pair token
    @param _withdrawAmount Amount of LP Pair token to zapped out
    @param _desiredToken Address of the desired output token
    @param _dataToken0 One Inch calldata for swapping token0 of the LP Pair to the desired output token
    @param _dataToken1 One Inch calldata for swapping token1 of the LP Pair to the desired output token
    @param _type LP Pair type, whether uniswapV2, solidly volatile or solidly stable
    */
    function zapOut(address _pair, uint256 _withdrawAmount, address _desiredToken, bytes calldata _dataToken0, bytes calldata _dataToken1, WantType _type) external {
        require(_withdrawAmount >= minimumAmount, 'Planet: Insignificant withdraw amount');

        IERC20(_pair).safeTransferFrom(msg.sender, address(this), _withdrawAmount);
        _removeLiquidity(_pair, _withdrawAmount, _type);

        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        address[] memory path = new address[](3);
        path[0] = pair.token0();
        path[1] = pair.token1();
        path[2] = _desiredToken;

        _approveTokenIfNeeded(path[0], address(oneInchRouter));
        _approveTokenIfNeeded(path[1], address(oneInchRouter));

        if (_desiredToken != path[0]) {
            _swapViaOneInch(path[0], _dataToken0);
        }

        if (_desiredToken != path[1]) {
            _swapViaOneInch(path[1], _dataToken1);
        }
    
        _returnAssets(path); // function _returnAssets also takes care of withdrawing WBNB and sending it to the user as BNB
        emit ZapOut(address(pair), _withdrawAmount);
    }

    // View function helpers for the app

    /**
    @notice Calculates amount of second input token given the amount of first input tokens while depositing into gammaUniProxy
    @param _pair Hypervisor Address
    @param _token Address of token to deposit
    @param _inputTokenDepositAmount Amount of token to deposit
    @return _otherTokenAmountMin Minimum amounts of the pair token to deposit
    @return _otherTokenAmountMax Maximum amounts of the pair token to deposit 
    */
    function getSecondTokenDepositAmount(
        address _pair,
        address _token,
        uint256 _inputTokenDepositAmount,
        address _router
        ) public view returns (uint256 _otherTokenAmountMin, uint256 _otherTokenAmountMax){

        (_otherTokenAmountMin, _otherTokenAmountMax) =  IGammaUniProxy(_router).getDepositAmount(_pair, _token, _inputTokenDepositAmount);
        
    }

    /**
    @notice Calculates minimum number of hypervisor tokens recieved depositing into gammaUniProxy
    @param _hypervisor Address of the hypervisor token
    @param _tokenA Address of token A of the hypervisor
    @param _amountADesired Desired amount of token A to be used to create the hypervisor
    @param _amountBDesired Desired amount of token B to be used to create the hypervisor
    @return liquidity Amount of hypervisor Tokens to be recieved when depositing
    */
    function quoteAddLiquidityGammaUniproxy(
        address _hypervisor,
        address _tokenA,
        uint _amountADesired,
        uint _amountBDesired
        ) external view returns (uint liquidity){
            (_amountADesired , _amountBDesired) = IUniswapV2Pair(_hypervisor).token0() == _tokenA ? (_amountADesired , _amountBDesired) : (_amountBDesired , _amountADesired);
            (uint256 baseLiquidity, uint256 baseAmount0, uint256 baseAmount1) = IHypervisor(_hypervisor).getBasePosition();
            (uint256 limitLiquidity, uint256 limitAmount0, uint256 limitAmount1) = IHypervisor(_hypervisor).getLimitPosition();

            uint256 liquidity0 = (_amountADesired * (baseLiquidity + limitLiquidity))/(baseAmount0 + limitAmount0);
            uint256 liquidity1 = (_amountBDesired * (baseLiquidity + limitLiquidity))/(baseAmount1 + limitAmount1);
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        }

    /**
    @notice Calculates minimum number of tokens recieved when removing liquidity from an hypervisor
    @param _hypervisor Address of the hypervisor token
    @param _tokenA Address of token A of the hypervisor
    @param _liquidity Amount of hypervisor Tokens desired to be removed
    @return amountA Amount of token A that will be recieved on removing liquidity
    @return amountB Amount of token B that will be recieved on removing liquidity
    */
    function quoteRemoveLiquidityGammaUniproxy(
        address _hypervisor,
        address _tokenA,
        uint _liquidity
        ) external view returns (uint amountA, uint amountB){
            (uint256 baseLiquidity, uint256 baseAmount0, uint256 baseAmount1) = IHypervisor(_hypervisor).getBasePosition();
            (uint256 limitLiquidity, uint256 limitAmount0, uint256 limitAmount1) = IHypervisor(_hypervisor).getLimitPosition();

            amountA = (_liquidity * (baseAmount0 + limitAmount0))/(baseLiquidity + limitLiquidity);
            amountB = (_liquidity * (baseAmount1 + limitAmount1))/(baseLiquidity + limitLiquidity);

            (amountA , amountB) = IUniswapV2Pair(_hypervisor).token0() == _tokenA ? (amountA , amountB) : (amountB , amountA);
        }



    /** 
    @notice Calculates ratio of input tokens for creating solidly stable pairs
    @dev Since solidly stable pairs can be inbalanced we need the proper ratio for our swap, we need to account both for price of the assets and the ratio of the pair. 
    @param _pair Address of the solidly stable LP Pair token
    @param _router Address of the solidly router associated with the solidly stable LP Pair
    @return ratio1to0 Ratio of Token1 to Token0
    */
    function quoteStableAddLiquidityRatio(ISolidlyPair _pair, address _router) external view returns (uint256 ratio1to0) {
            address tokenA = _pair.token0();
            address tokenB = _pair.token1();

            uint256 investment = IERC20(tokenA).balanceOf(address(_pair)) * 10 / 10000;
            uint out = _pair.getAmountOut(investment, tokenA);
            (uint amountA, uint amountB,) = ISolidlyRouter(_router).quoteAddLiquidity(tokenA, tokenB, _pair.stable(), investment, out);
                
            amountA = amountA * 1e18 / 10**IERC20Extended(tokenA).decimals();
            amountB = amountB * 1e18 / 10**IERC20Extended(tokenB).decimals();
            out = out * 1e18 / 10**IERC20Extended(tokenB).decimals();
            investment = investment * 1e18 / 10**IERC20Extended(tokenA).decimals();
                
            uint ratio = out * 1e18 / investment * amountA / amountB; 
                
            return 1e18 * 1e18 / (ratio + 1e18);
    }

    /**
    @notice Calculates minimum number of LP tokens recieved when creating an LP Pair
    @param _pair Address of the LP Pair token
    @param _tokenA Address of token A of the LP Pair
    @param _tokenB Address of token B of the LP Pair
    @param _amountADesired Desired amount of token A to be used to create the LP Pair
    @param _amountBDesired Desired amount of token B to be used to create the LP Pair
    @return amountA Actual amount of token A that will be used to create the LP Pair
    @return amountB Actual amount of token B that will be used to create the LP Pair
    @return liquidity Amount of LP Tokens to be recieved when adding liquidity
     */
    function quoteAddLiquidity(
        address _pair,
        address _tokenA,
        address _tokenB,
        uint _amountADesired,
        uint _amountBDesired
        ) external view returns (uint amountA, uint amountB, uint liquidity) {
        
        if (_pair == address(0)) {
            return (0,0,0);
        }

        (uint reserveA, uint reserveB) = getReserves(_pair, _tokenA, _tokenB);
        uint _totalSupply = IERC20(_pair).totalSupply();
        
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (_amountADesired, _amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - minimumAmount;
        } else {

            uint amountBOptimal = quoteLiquidity(_amountADesired, reserveA, reserveB);
            if (amountBOptimal <= _amountBDesired) {
                (amountA, amountB) = (_amountADesired, amountBOptimal);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            } else {
                uint amountAOptimal = quoteLiquidity(_amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, _amountBDesired);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            }
        }
    }

    /**
    @notice Calculates minimum number of tokens recieved when removing liquidity from an LP Pair
    @param _pair Address of the LP Pair token
    @param _tokenA Address of token A of the LP Pair
    @param _tokenB Address of token B of the LP Pair
    @param _liquidity Amount of LP Tokens desired to be removed
    @return amountA Amount of token A that will be recieved on removing liquidity
    @return amountB Amount of token B that will be recieved on removing liquidity

    */
    function quoteRemoveLiquidity(
        address _pair,
        address _tokenA,
        address _tokenB,
        uint _liquidity
        ) external view returns (uint amountA, uint amountB) {

        if (_pair == address(0)) {
            return (0,0);
        }

        (uint reserveA, uint reserveB) = getReserves(_pair, _tokenA, _tokenB);
        uint _totalSupply = IERC20(_pair).totalSupply();

        amountA = _liquidity * reserveA / _totalSupply; // using balances ensures pro-rata distribution
        amountB = _liquidity * reserveB / _totalSupply; // using balances ensures pro-rata distribution

    }

    // fetches and sorts the reserves for a pair
    function getReserves(address _pair, address _tokenA, address _tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(_tokenA, _tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(_pair).getReserves();
        (reserveA, reserveB) = _tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // internal functions

     // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PlanetLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PlanetLibrary: ZERO_ADDRESS');
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PlanetLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PlanetLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // provides allowance for the spender to access the token when allowance is not already given
    function _approveTokenIfNeeded(address _token, address _spender) private {
        if (IERC20(_token).allowance(address(this), _spender) == 0) {
            IERC20(_token).safeApprove(_spender, type(uint).max);
        }
    }
    // swaps tokens via One Inch router
    function _swap(address _inputToken, bytes calldata _token0, address _outputToken) private {
        address[] memory path;
        path = new address[](2);
        path[0] = _outputToken;
        path[1] = _inputToken;

        _swapViaOneInch(_inputToken, _token0);

        _returnAssets(path);
    }

    // Zaps any token into any LP Pair on Planet via One Inch Router
    function _zapIn(address _inputToken, bytes calldata _token0, bytes calldata _token1, WantType _type, address _router, address _pair) private {

        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        address[] memory path;
        path = new address[](3);
        path[0] = pair.token0();
        path[1] = pair.token1();
        path[2] = _inputToken;

        if (_inputToken != path[0]) {
            _swapViaOneInch(_inputToken, _token0);
        }

        if (_inputToken != path[1]) {
            _swapViaOneInch(_inputToken, _token1);
        }

        address approveToken = _router;
        if (_type == WantType.WANT_TYPE_GAMMA_HYPERVISOR){
            approveToken = _pair;
        }
        _approveTokenIfNeeded(path[0], address(approveToken));
        _approveTokenIfNeeded(path[1], address(approveToken));
        uint256 lp0Amt = IERC20(path[0]).balanceOf(address(this));
        uint256 lp1Amt = IERC20(path[1]).balanceOf(address(this));

        uint256[4] memory min;

        if (_type == WantType.WANT_TYPE_GAMMA_HYPERVISOR){
            (uint256 lp1AmtMin, uint256 lp1AmtMax) = getSecondTokenDepositAmount(_pair, path[0], lp0Amt, _router);
            
            if (lp1Amt >= lp1AmtMax){
                lp1Amt = lp1AmtMax;
            }
            else if (lp1Amt < lp1AmtMin){
                (,lp0Amt) = getSecondTokenDepositAmount(_pair, path[1], lp1Amt, _router);
            }
            
            IGammaUniProxy(_router).deposit(lp0Amt, lp1Amt, msg.sender, _pair, min);
        }
        else if (_type == WantType.WANT_TYPE_UNISWAP_V2) {
            IPlanetRouter(_router).addLiquidity(path[0], path[1], lp0Amt, lp1Amt, 1, 1, msg.sender, block.timestamp);
        } else {
            bool stable = _type == WantType.WANT_TYPE_SOLIDLY_STABLE ? true : false;
            ISolidlyRouter(_router).addLiquidity(path[0], path[1], stable,  lp0Amt, lp1Amt, 1, 1, msg.sender, block.timestamp);
        }  
        _returnAssets(path);   
    }

    // removes liquidity from the pair by burning LP pair tokens of the input address 
    function _removeLiquidity(address _pair, uint256 _withdrawAmount, WantType _type) private {
        uint256 amount0;
        uint256 amount1;

        uint256[4] memory min;
        if (_type == WantType.WANT_TYPE_GAMMA_HYPERVISOR){
            (amount0, amount1) = IHypervisor(_pair).withdraw(_withdrawAmount, address(this), address(this), min);
        }
        else {
            IERC20(_pair).safeTransfer(_pair, IERC20(_pair).balanceOf(address(this)));
            (amount0, amount1) = IUniswapV2Pair(_pair).burn(address(this));
        }

        require(amount0 >= minimumAmount, "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
        require(amount1 >= minimumAmount, "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
    }

    // Our main swap function call. We call the aggregator contract with our fed data. If we get an error we revert and return the error result. 
    function _swapViaOneInch(address _inputToken, bytes memory _callData) private {
        
        _approveTokenIfNeeded(_inputToken, address(oneInchRouter));

        (bool success, bytes memory retData) = oneInchRouter.call(_callData);

        propagateError(success, retData, "1inch");

        require(success == true, "calling 1inch got an error");
    }

    // Error reporting from our call to the aggrator contract when we try to swap. 
    function propagateError(
        bool success,
        bytes memory data,
        string memory errorMessage
        ) public pure {
        // Forward error message from call/delegatecall
        if (!success) {
            if (data.length == 0) revert(errorMessage);
            assembly {
                revert(add(32, data), mload(data))
            }
        }
    }

    // Returns any pending assets left with the contract after a swap, zapIn or ZapOut back to the user
    function _returnAssets (address[] memory _tokens) private {
        uint256 balance;
        for (uint256 i; i < _tokens.length; i++) {
            balance = IERC20(_tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                if (_tokens[i] == WBNB) {
                    IWBNB(WBNB).withdraw(balance);
                    (bool success,) = msg.sender.call{value: balance}(new bytes(0));
                    require(success, 'Planet: BNB transfer failed');
                    emit TokenReturned(_tokens[i], balance);
                } else {
                    IERC20(_tokens[i]).safeTransfer(msg.sender, balance);
                    emit TokenReturned(_tokens[i], balance);
                }
            }
        }
    }

    // enabling the contract to receive BNB
    receive() external payable {
        assert(msg.sender == WBNB);
    }

}