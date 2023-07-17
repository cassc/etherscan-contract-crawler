// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import './CentaurLPToken.sol';
import './libraries/Initializable.sol';
import './libraries/SafeMath.sol';
import './libraries/CentaurMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/ICentaurFactory.sol';
import './interfaces/ICentaurPool.sol';
import './interfaces/ICentaurSettlement.sol';
import './interfaces/IOracle.sol';

contract CentaurPool is Initializable, CentaurLPToken {
    using SafeMath for uint;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public baseToken;
    uint public baseTokenDecimals;
    address public oracle;
    uint public oracleDecimals;

    uint public baseTokenTargetAmount;
    uint public baseTokenBalance;

    uint public liquidityParameter;

    bool public tradeEnabled;
    bool public depositEnabled;
    bool public withdrawEnabled;

    uint private unlocked;
    modifier lock() {
        require(unlocked == 1, 'CentaurSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier tradeAllowed() {
        require(tradeEnabled, "CentaurSwap: TRADE_NOT_ALLOWED");
        _;
    }

    modifier depositAllowed() {
        require(depositEnabled, "CentaurSwap: DEPOSIT_NOT_ALLOWED");
        _;
    }

    modifier withdrawAllowed() {
        require(withdrawEnabled, "CentaurSwap: WITHDRAW_NOT_ALLOWED");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == ICentaurFactory(factory).router(), 'CentaurSwap: ONLY_ROUTER_ALLOWED');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, 'CentaurSwap: ONLY_FACTORY_ALLOWED');
        _;
    }

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event AmountIn(address indexed sender, uint amount);
    event AmountOut(address indexed sender, uint amount, address indexed to);
    event EmergencyWithdraw(uint256 _timestamp, address indexed _token, uint256 _amount, address indexed _to);

    function init(address _factory, address _baseToken, address _oracle, uint _liquidityParameter) external initializer {
        factory = _factory;
        baseToken = _baseToken;
        baseTokenDecimals = IERC20(baseToken).decimals();
        oracle = _oracle;
        oracleDecimals = IOracle(oracle).decimals();

        tradeEnabled = false;
        depositEnabled = false;
        withdrawEnabled = false;

        liquidityParameter = _liquidityParameter;

        symbol = string(abi.encodePacked("CS-", IERC20(baseToken).symbol()));
        decimals = baseTokenDecimals;

        unlocked = 1;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CentaurSwap: TRANSFER_FAILED');
    }

    function mint(address to) external lock onlyRouter depositAllowed returns (uint liquidity) {
        uint balance = IERC20(baseToken).balanceOf(address(this));
        uint amount = balance.sub(baseTokenBalance);

        if (totalSupply == 0) {
            liquidity = amount.add(baseTokenTargetAmount);
        } else {
            liquidity = amount.mul(totalSupply).div(baseTokenTargetAmount);
        }

        require(liquidity > 0, 'CentaurSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        baseTokenBalance = baseTokenBalance.add(amount);
        baseTokenTargetAmount = baseTokenTargetAmount.add(amount);

        emit Mint(msg.sender, amount);
    }

    function burn(address to) external lock onlyRouter withdrawAllowed returns (uint amount) {
        uint liquidity = balanceOf[address(this)];

        amount = liquidity.mul(baseTokenTargetAmount).div(totalSupply);

        require(amount > 0, 'CentaurSwap: INSUFFICIENT_LIQUIDITY_BURNED');

        require(baseTokenBalance >= amount, 'CentaurSwap: INSUFFICIENT_LIQUIDITY');

        _burn(address(this), liquidity);
        _safeTransfer(baseToken, to, amount);

        baseTokenBalance = baseTokenBalance.sub(amount);
        baseTokenTargetAmount = baseTokenTargetAmount.sub(amount);

        emit Burn(msg.sender, amount, to);
    }

    function swapTo(address _sender, address _fromToken, uint _amountIn, uint _value, address _receiver) external lock onlyRouter tradeAllowed returns (uint maxAmount) {
        require(_fromToken != baseToken, 'CentaurSwap: INVALID_POOL');

        address pool = ICentaurFactory(factory).getPool(_fromToken);
        require(pool != address(0), 'CentaurSwap: POOL_NOT_FOUND');

        // Check if has pendingSettlement
        address settlement = ICentaurFactory(factory).settlement();
        require(!ICentaurSettlement(settlement).hasPendingSettlement(_sender, address(this)), 'CentaurSwap: PENDING_SETTLEMENT');
        
        // maxAmount because amount might be lesser during settlement. (If amount is more, excess is given back to pool)
        maxAmount = getAmountOutFromValue(_value);

        ICentaurSettlement.Settlement memory pendingSettlement = ICentaurSettlement.Settlement(
                pool,
                _amountIn,
                ICentaurPool(pool).baseTokenTargetAmount(),
                (ICentaurPool(pool).baseTokenBalance()).sub(_amountIn),
                ICentaurPool(pool).liquidityParameter(),
                address(this), 
                maxAmount,
                baseTokenTargetAmount,
                baseTokenBalance,
                liquidityParameter,
                _receiver,
                block.timestamp.add(ICentaurSettlement(settlement).settlementDuration())
            );

        // Subtract maxAmount from baseTokenBalance first, difference (if any) will be added back during settlement
        baseTokenBalance = baseTokenBalance.sub(maxAmount);

        // Add to pending settlement
        ICentaurSettlement(settlement).addSettlement(_sender, pendingSettlement);

        // Transfer amount to settlement for escrow
        _safeTransfer(baseToken, settlement, maxAmount);

        return maxAmount;
    }

    function swapFrom(address _sender) external lock onlyRouter tradeAllowed returns (uint amount, uint value) {
        uint balance = IERC20(baseToken).balanceOf(address(this));

        require(balance > baseTokenBalance, 'CentaurSwap: INSUFFICIENT_SWAP_AMOUNT');

        // Check if has pendingSettlement
        address settlement = ICentaurFactory(factory).settlement();
        require(!ICentaurSettlement(settlement).hasPendingSettlement(_sender, address(this)), 'CentaurSwap: PENDING_SETTLEMENT');

        amount = balance.sub(baseTokenBalance);
        value = getValueFromAmountIn(amount);

        baseTokenBalance = balance;

        emit AmountIn(_sender, amount);

        return (amount, value);
    }

    function swapSettle(address _sender) external lock returns (uint, address) {
        address settlement = ICentaurFactory(factory).settlement();
        ICentaurSettlement.Settlement memory pendingSettlement = ICentaurSettlement(settlement).getPendingSettlement(_sender, address(this));

        require (pendingSettlement.settlementTimestamp != 0, 'CentaurSwap: NO_PENDING_SETTLEMENT');
        require (pendingSettlement.tPool == address(this), 'CentaurSwap: WRONG_POOL_SETTLEMENT');
        require (block.timestamp >= pendingSettlement.settlementTimestamp, 'CentaurSwap: SETTLEMENT_STILL_PENDING');

        uint newfPoolOraclePrice = ICentaurPool(pendingSettlement.fPool).getOraclePrice();
        uint newtPoolOraclePrice = getOraclePrice();

        uint newValue = CentaurMath.getValueFromAmountIn(pendingSettlement.amountIn, newfPoolOraclePrice, ICentaurPool(pendingSettlement.fPool).baseTokenDecimals(), pendingSettlement.fPoolBaseTokenTargetAmount, pendingSettlement.fPoolBaseTokenBalance, pendingSettlement.fPoolLiquidityParameter);
        uint newAmount = CentaurMath.getAmountOutFromValue(newValue, newtPoolOraclePrice, baseTokenDecimals, pendingSettlement.tPoolBaseTokenTargetAmount, pendingSettlement.tPoolBaseTokenBalance, pendingSettlement.tPoolLiquidityParameter);

        uint poolFee = ICentaurFactory(factory).poolFee();
        address router = ICentaurFactory(factory).router();

        // Remove settlement and receive escrowed amount
        ICentaurSettlement(settlement).removeSettlement(_sender, pendingSettlement.fPool, pendingSettlement.tPool);

        if (newAmount > pendingSettlement.maxAmountOut) {

            uint fee = (pendingSettlement.maxAmountOut).mul(poolFee).div(100 ether);
            uint amountOut = pendingSettlement.maxAmountOut.sub(fee);

            if (msg.sender == router) {
                _safeTransfer(baseToken, router, amountOut);
            } else {
                _safeTransfer(baseToken, pendingSettlement.receiver, amountOut);
            }
            emit AmountOut(_sender, amountOut, pendingSettlement.receiver);

            baseTokenBalance = baseTokenBalance.add(fee);
            baseTokenTargetAmount = baseTokenTargetAmount.add(fee);

            return (amountOut, pendingSettlement.receiver);
        } else {
            uint fee = (newAmount).mul(poolFee).div(100 ether);
            uint amountOut = newAmount.sub(fee);

            if (msg.sender == router) {
                _safeTransfer(baseToken, router, amountOut);
            } else {
                _safeTransfer(baseToken, pendingSettlement.receiver, amountOut);
            }
            emit AmountOut(_sender, amountOut, pendingSettlement.receiver);

            // Difference added back to baseTokenBalance
            uint difference = (pendingSettlement.maxAmountOut).sub(amountOut);
            baseTokenBalance = baseTokenBalance.add(difference);

            // TX fee goes back into pool for liquidity providers
            baseTokenTargetAmount = baseTokenTargetAmount.add(difference);

            return (amountOut, pendingSettlement.receiver);
        }
    }

    function getOraclePrice() public view returns (uint price) {
        (, int answer,,,) = IOracle(oracle).latestRoundData();

        // Returns price in 18 decimals
        price = uint(answer).mul(10 ** uint(18).sub(oracleDecimals));
    }

    // Swap Exact Tokens For Tokens (getAmountOut)
    function getAmountOutFromValue(uint _value) public view returns (uint amount) {
        amount = CentaurMath.getAmountOutFromValue(_value, getOraclePrice(), baseTokenDecimals,  baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    
        require(baseTokenBalance > amount, "CentaurSwap: INSUFFICIENT_LIQUIDITY");
    }

    function getValueFromAmountIn(uint _amount) public view returns (uint value) {
        value = CentaurMath.getValueFromAmountIn(_amount, getOraclePrice(), baseTokenDecimals, baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    }

    // Swap Tokens For Exact Tokens (getAmountIn)
    function getAmountInFromValue(uint _value) public view returns (uint amount) {
        amount = CentaurMath.getAmountInFromValue(_value, getOraclePrice(), baseTokenDecimals,  baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    }

    function getValueFromAmountOut(uint _amount) public view returns (uint value) {
        require(baseTokenBalance > _amount, "CentaurSwap: INSUFFICIENT_LIQUIDITY");

        value = CentaurMath.getValueFromAmountOut(_amount, getOraclePrice(), baseTokenDecimals, baseTokenTargetAmount, baseTokenBalance, liquidityParameter);
    }

    // Helper functions
    function setFactory(address _factory) external onlyFactory {
        factory = _factory;
    }

    function setTradeEnabled(bool _tradeEnabled) external onlyFactory {
        tradeEnabled = _tradeEnabled;
    }

    function setDepositEnabled(bool _depositEnabled) external onlyFactory {
        depositEnabled = _depositEnabled;
    }

    function setWithdrawEnabled(bool _withdrawEnabled) external onlyFactory {
        withdrawEnabled = _withdrawEnabled;
    }

    function setLiquidityParameter(uint _liquidityParameter) external onlyFactory {
        liquidityParameter = _liquidityParameter;
    }

    function emergencyWithdraw(address _token, uint _amount, address _to) external onlyFactory {
        _safeTransfer(_token, _to, _amount);

        emit EmergencyWithdraw(block.timestamp, _token, _amount, _to);
    }
}