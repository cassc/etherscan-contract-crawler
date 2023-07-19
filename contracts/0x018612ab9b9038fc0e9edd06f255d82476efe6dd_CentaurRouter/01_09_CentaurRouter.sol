// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import './interfaces/ICentaurFactory.sol';
import './interfaces/ICentaurPool.sol';
import './interfaces/ICentaurRouter.sol';
import "@openzeppelin/contracts/utils/Address.sol";

contract CentaurRouter is ICentaurRouter {
	using SafeMath for uint;

	address public override factory;
    address public immutable override WETH;
    bool public override onlyEOAEnabled;
    mapping(address => bool) public override whitelistContracts;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'CentaurSwap: EXPIRED');
        _;
    }

    modifier onlyEOA(address _address) {
        if (onlyEOAEnabled) {
            require((!Address.isContract(_address) || whitelistContracts[_address]), 'CentaurSwap: ONLY_EOA_ALLOWED');
        }
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'CentaurSwap: ONLY_FACTORY_ALLOWED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        onlyEOAEnabled = true;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address _baseToken,
        uint _amount,
        uint _minLiquidity
    ) internal view virtual returns (uint liquidity) {
		ICentaurPool pool = ICentaurPool(ICentaurFactory(factory).getPool(_baseToken));

        uint _totalSupply = pool.totalSupply();
        uint _baseTokenTargetAmount = pool.baseTokenTargetAmount();
        liquidity = _amount;

        if (_totalSupply == 0) {
            liquidity = _amount.add(_baseTokenTargetAmount);
        } else {
            liquidity = _amount.mul(_totalSupply).div(_baseTokenTargetAmount);
        }

    	require(liquidity > _minLiquidity, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');
    }

    function addLiquidity(
        address _baseToken,
        uint _amount,
        address _to,
        uint _minLiquidity,
        uint _deadline
    ) external virtual override ensure(_deadline) onlyEOA(msg.sender) returns (uint amount, uint liquidity) {
        address pool = ICentaurFactory(factory).getPool(_baseToken);
        require(pool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        (liquidity) = _addLiquidity(_baseToken, _amount, _minLiquidity);
        
        TransferHelper.safeTransferFrom(_baseToken, msg.sender, pool, _amount);
        liquidity = ICentaurPool(pool).mint(_to);
        require(liquidity > _minLiquidity, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');

        return (_amount, liquidity);
    }

    function addLiquidityETH(
        address _to,
        uint _minLiquidity,
        uint _deadline
    ) external virtual override payable ensure(_deadline) onlyEOA(msg.sender) returns (uint amount, uint liquidity) {
        address pool = ICentaurFactory(factory).getPool(WETH);
        require(pool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        (liquidity) = _addLiquidity(WETH, msg.value, _minLiquidity);

        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pool, msg.value));
        liquidity = ICentaurPool(pool).mint(_to);

        require(liquidity > _minLiquidity, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        
        return (msg.value, liquidity);
    }

    function removeLiquidity(
        address _baseToken,
        uint _liquidity,
        address _to,
        uint _minAmount,
        uint _deadline
    ) public virtual override ensure(_deadline) onlyEOA(msg.sender) returns (uint amount) {
        address pool = ICentaurFactory(factory).getPool(_baseToken);
        require(pool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        ICentaurPool(pool).transferFrom(msg.sender, pool, _liquidity); // send liquidity to pool
        amount = ICentaurPool(pool).burn(_to);
        require(amount > _minAmount, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');

        return amount;
    }

    function removeLiquidityETH(
        uint _liquidity,
        address _to,
        uint _minAmount,
        uint _deadline
    ) public virtual override ensure(_deadline) onlyEOA(msg.sender) returns (uint amount) {
        amount = removeLiquidity(
            WETH,
            _liquidity,
            address(this),
            _minAmount,
            _deadline
        );

        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(_to, amount);

        return amount;
    }

    function swapExactTokensForTokens(
        address _fromToken,
        uint _amountIn,
        address _toToken,
        uint _amountOutMin,
        address _to,
        uint _deadline
    ) external virtual override ensure(_deadline) onlyEOA(msg.sender) {
        require(getAmountOut(_fromToken, _toToken, _amountIn) >= _amountOutMin, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        
        (address inputTokenPool, address outputTokenPool) = validatePools(_fromToken, _toToken);

        TransferHelper.safeTransferFrom(_fromToken, msg.sender, inputTokenPool, _amountIn);

        (uint finalAmountIn, uint value) = ICentaurPool(inputTokenPool).swapFrom(msg.sender);
        ICentaurPool(outputTokenPool).swapTo(msg.sender, _fromToken, finalAmountIn, value, _to);
    }

    function swapExactETHForTokens(
        address _toToken,
        uint _amountOutMin,
        address _to,
        uint _deadline
    ) external virtual override payable ensure(_deadline) onlyEOA(msg.sender) {
        require(getAmountOut(WETH, _toToken, msg.value) >= _amountOutMin, 'CentaurSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        
        (address inputTokenPool, address outputTokenPool) = validatePools(WETH, _toToken);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(inputTokenPool, msg.value));
        // TransferHelper.safeTransferFrom(WETH, msg.sender, inputTokenPool, msg.value);

        (uint finalAmountIn, uint value) = ICentaurPool(inputTokenPool).swapFrom(msg.sender);
        ICentaurPool(outputTokenPool).swapTo(msg.sender, WETH, finalAmountIn, value, _to);
    }

    function swapTokensForExactTokens(
        address _fromToken,
        uint _amountInMax,
        address _toToken,
        uint _amountOut,
        address _to,
        uint _deadline
    ) external virtual override ensure(_deadline) onlyEOA(msg.sender) {
        uint amountIn = getAmountIn(_fromToken, _toToken, _amountOut);
        require(amountIn <= _amountInMax, 'CentaurSwap: EXCESSIVE_INPUT_AMOUNT');
        
        (address inputTokenPool, address outputTokenPool) = validatePools(_fromToken, _toToken);

        TransferHelper.safeTransferFrom(_fromToken, msg.sender, inputTokenPool, amountIn);

        (uint finalAmountIn, uint value) = ICentaurPool(inputTokenPool).swapFrom(msg.sender);
        ICentaurPool(outputTokenPool).swapTo(msg.sender, _fromToken, finalAmountIn, value, _to);
    }

    function swapETHForExactTokens(
        address _toToken,
        uint _amountOut,
        address _to,
        uint _deadline
    ) external virtual override payable ensure(_deadline) onlyEOA(msg.sender) {
        uint amountIn = getAmountIn(WETH, _toToken, _amountOut);
        require(amountIn <= msg.value, 'CentaurSwap: EXCESSIVE_INPUT_AMOUNT');
        
        (address inputTokenPool, address outputTokenPool) = validatePools(WETH, _toToken);

        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(inputTokenPool, amountIn));

        (uint finalAmountIn, uint value) = ICentaurPool(inputTokenPool).swapFrom(msg.sender);
        ICentaurPool(outputTokenPool).swapTo(msg.sender, WETH, finalAmountIn, value, _to);

        if (msg.value > amountIn) TransferHelper.safeTransferETH(msg.sender, msg.value - amountIn);
    }

    function swapSettle(address _sender, address _pool) external virtual override returns (uint amount, address receiver) {
        (amount, receiver) = ICentaurPool(_pool).swapSettle(_sender);
        address token = ICentaurPool(_pool).baseToken();
        if (token == WETH) {
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(receiver, amount);
        } else {
            TransferHelper.safeTransfer(token, receiver, amount);
        }
    }

    function swapSettleMultiple(address _sender, address[] memory _pools) external virtual override {
        for(uint i = 0; i < _pools.length; i++) {
            (uint amount, address receiver) = ICentaurPool(_pools[i]).swapSettle(_sender);
            address token = ICentaurPool(_pools[i]).baseToken();
            if (token == WETH) {
                IWETH(WETH).withdraw(amount);
                TransferHelper.safeTransferETH(receiver, amount);
            } else {
                TransferHelper.safeTransfer(token, receiver, amount);
            }
        }
    }

    function validatePools(address _fromToken, address _toToken) public view virtual override returns (address inputTokenPool, address outputTokenPool) {
        inputTokenPool = ICentaurFactory(factory).getPool(_fromToken);
        require(inputTokenPool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        outputTokenPool = ICentaurFactory(factory).getPool(_toToken);
        require(outputTokenPool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        return (inputTokenPool, outputTokenPool);
    } 

    function getAmountOut(
        address _fromToken,
        address _toToken,
        uint _amountIn
    ) public view virtual override returns (uint amountOut) {
        uint poolFee = ICentaurFactory(factory).poolFee();
        uint value = ICentaurPool(ICentaurFactory(factory).getPool(_fromToken)).getValueFromAmountIn(_amountIn);
        uint amountOutBeforeFees = ICentaurPool(ICentaurFactory(factory).getPool(_toToken)).getAmountOutFromValue(value);
        amountOut = (amountOutBeforeFees).mul(uint(100 ether).sub(poolFee)).div(100 ether);
    }

    function getAmountIn(
        address _fromToken,
        address _toToken,
        uint _amountOut
    ) public view virtual override returns (uint amountIn) {
        uint poolFee = ICentaurFactory(factory).poolFee();
        uint amountOut = _amountOut.mul(100 ether).div(uint(100 ether).sub(poolFee));
        uint value = ICentaurPool(ICentaurFactory(factory).getPool(_toToken)).getValueFromAmountOut(amountOut);
        amountIn = ICentaurPool(ICentaurFactory(factory).getPool(_fromToken)).getAmountInFromValue(value);
    }

    // Helper functions
    function setFactory(address _factory) external virtual override onlyFactory {
        factory = _factory;
    }

    function setOnlyEOAEnabled(bool _onlyEOAEnabled) external virtual override onlyFactory {
        onlyEOAEnabled = _onlyEOAEnabled;
    }

    function addContractToWhitelist(address _address) external virtual override onlyFactory {
        require(Address.isContract(_address), 'CentaurSwap: NOT_CONTRACT');
        whitelistContracts[_address] = true;
    }

    function removeContractFromWhitelist(address _address) external virtual override onlyFactory {
        whitelistContracts[_address] = false;
    }
}