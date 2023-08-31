// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../lib/openzeppelin/token/ERC20/IERC20.sol";
import "../lib/openzeppelin/access/Ownable.sol";
import "../lib/openzeppelin/utils/math/SafeMath.sol";
import "../lib/aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "../lib/aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "../lib/uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../lib/uniswap/v3-core/contracts/libraries/TickMath.sol";
import "../lib/uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IPairReserves {
    struct PairReserves {
        uint256 reserve0;
        uint256 reserve1;
        uint256 price;
        bool isWETHZero;
    }  
}

contract BlindBackrun is Ownable, FlashLoanSimpleReceiverBase {
    uint256 public amountIn; // This is a state variable
    using SafeMath for uint256;
    uint256 uniswappyFee = 997;
    address public immutable WETH_ADDRESS;

    struct ExecuteOperationData {
        address firstPairAddress;
        address secondPairAddress;
        uint256 percentageToPayToCoinbase;
        uint256 actualUniV3Fee;
        uint256 balanceBefore;
        IUniswapV2Pair firstPair;
        IUniswapV3Pool secondPair;
        IPairReserves.PairReserves firstPairData;
        IPairReserves.PairReserves secondPairData;
        uint256 amountToTrade;
        address tokenReceived;
        uint256 firstPairAmountOut;
        uint256 tokenReceivedBalance;
        int256 amountSpecified;
        uint256 balanceAfter;
        uint profit;
        uint profitToCoinbase;
        uint256 totalAmount;
    }

    constructor(address _addressProvider, address _wethAddress)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) 
    {
        WETH_ADDRESS = _wethAddress;
    }

    // Function to execute a flash loan
    function RequestFlashLoan(
        address firstPairAddress,
        address secondPairAddress,
        uint256 percentageToPayToCoinbase,
        uint256 actualUniV3Fee
    ) public {
        address receiverAddress = address(this);
        bytes memory params = abi.encode(firstPairAddress, secondPairAddress, percentageToPayToCoinbase, actualUniV3Fee); // encode input parameters from external script
        uint16 referralCode = 0;        

        IPairReserves.PairReserves memory firstPairData = getPairDataV2(IUniswapV2Pair(firstPairAddress));
        IPairReserves.PairReserves memory secondPairData = getPairDataV3(IUniswapV3Pool(secondPairAddress));

        getAmountIn(firstPairData, secondPairData, actualUniV3Fee); // This updates the state variable 'amountIn'

        POOL.flashLoanSimple(
            receiverAddress,
            WETH_ADDRESS,
            amountIn,
            params,
            referralCode
        );
    }

    // Override this function from FlashLoanSimpleReceiverBase to specify what happens when you receive the flash loan
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(initiator == address(this), "Unauthorized initiator");

    // Decode the parameters from the params field
    ExecuteOperationData memory data;
    (data.firstPairAddress, data.secondPairAddress, data.percentageToPayToCoinbase, data.actualUniV3Fee) = abi.decode(params, (address, address, uint256, uint256));

    require(asset == WETH_ADDRESS, "Asset not supported"); // Assuming you only support WETH as the borrowed asset
    require(IERC20(asset).balanceOf(address(this)) >= amount, "Did not receive loan"); 

    data.balanceBefore = IERC20(WETH_ADDRESS).balanceOf(address(this));
    
    data.firstPair = IUniswapV2Pair(data.firstPairAddress);
    data.secondPair = IUniswapV3Pool(data.secondPairAddress);

    data.firstPairData = getPairDataV2(data.firstPair);
    data.secondPairData = getPairDataV3(data.secondPair);

    data.amountToTrade = amount;
    
    if (data.firstPairData.isWETHZero == true){
        data.firstPairAmountOut = getAmountOut(data.firstPairData.reserve0, data.firstPairData.reserve1, data.amountToTrade);
        data.tokenReceived = data.firstPair.token1();

        data.firstPair.swap(0, data.firstPairAmountOut, data.secondPairAddress, "");
    } else {
        data.firstPairAmountOut = getAmountOut(data.firstPairData.reserve1, data.firstPairData.reserve0, data.amountToTrade);
        data.tokenReceived = data.firstPair.token0();

        data.firstPair.swap(data.firstPairAmountOut, 0, data.secondPairAddress, "");          
    }

    // Get balance of the token acquired from the first swap
    data.tokenReceivedBalance = IERC20(data.tokenReceived).balanceOf(address(this));
    
    // Swap tokens on the second Uniswap V3 pool
    data.amountSpecified = int256(data.tokenReceivedBalance); // use the balance from the first swap
    data.secondPair.swap(
        address(this), // recipient
        true, // zeroForOne
        data.amountSpecified, // amountSpecified
        0, // sqrtPriceLimitX96: no limit
        ""  // data: optional callback data
    );

    data.balanceAfter = IERC20(WETH_ADDRESS).balanceOf(address(this));
    require(data.balanceAfter > data.balanceBefore, "Arbitrage failed");
    data.profit = data.balanceAfter.sub(data.balanceBefore);
    data.profitToCoinbase = data.profit.mul(data.percentageToPayToCoinbase).div(100);
    IWETH(WETH_ADDRESS).withdraw(data.profitToCoinbase);
    block.coinbase.transfer(data.profitToCoinbase);

    // Calculate amount to repay, which is the loan amount plus the premium
    data.totalAmount = amount.add(premium);

    // Transfer funds back to repay the flash loan
    require(IERC20(asset).approve(address(POOL), data.totalAmount), "Failed to repay loan");

    return true;
}

    /// @notice Calculates the required input amount for the arbitrage transaction.
    /// @param firstPairData Struct containing data about the first Uniswap pair.
    /// @param secondPairData Struct containing data about the second Uniswap pair.
    /// @return amountIn, the optimal amount to trade to arbitrage two pairs.
    function getAmountIn(
        IPairReserves.PairReserves memory firstPairData, 
        IPairReserves.PairReserves memory secondPairData,
        uint256 actualUniV3Fee
    ) public returns (uint256) {
        uint256 numerator = getNumerator(firstPairData, secondPairData);
        uint256 denominator = getDenominator(firstPairData, secondPairData, actualUniV3Fee);
            
        uint256 calculatedAmountIn = numerator.mul(1000).div(denominator);
        
        amountIn = calculatedAmountIn; // Set the state variable to the calculated value

        return calculatedAmountIn;
    }
    
    function getNumerator(
        IPairReserves.PairReserves memory firstPairData, 
        IPairReserves.PairReserves memory secondPairData
    ) public view returns (uint256) {

        if (firstPairData.isWETHZero == true) {
            uint presqrt = 
                uniswappyFee
                    .mul(uniswappyFee)
                    .mul(firstPairData.reserve1)
                    .mul(secondPairData.reserve0)
                    .div(secondPairData.reserve1)
                    .div(firstPairData.reserve0);
            
            uint256 numerator = 
            (
                sqrt(presqrt)
                .sub(1e3)
            )            
            .mul(secondPairData.reserve1)
            .mul(firstPairData.reserve0);

            return numerator;
        } else {
            uint presqrt = 
                uniswappyFee
                    .mul(uniswappyFee)
                    .mul(firstPairData.reserve0)
                    .mul(secondPairData.reserve1)
                    .div(secondPairData.reserve0)
                    .div(firstPairData.reserve1);
            
            uint256 numerator = 
            (
                sqrt(presqrt)
                .sub(1e3)
            )            
            .mul(secondPairData.reserve0)
            .mul(firstPairData.reserve1);

            return numerator;
        }
    }

    function getDenominator(
        IPairReserves.PairReserves memory firstPairData, 
        IPairReserves.PairReserves memory secondPairData,
        uint256 actualUniV3Fee
    ) public view returns (uint256){

        // Convert _actualUniFee to a decimal
        uint256 _uniV3FeeProportion = 1000 * 1000 - actualUniV3Fee;
        uint256 uniV3FeeProportion = _uniV3FeeProportion / 1000;

        if (firstPairData.isWETHZero == true) {
            uint256 denominator = 
                (
                    uniV3FeeProportion
                    .mul(secondPairData.reserve1)
                    .mul(10000)
                )
                .add(
                    uniswappyFee
                    .mul(uniswappyFee)
                    .mul(firstPairData.reserve1)
                );
            return denominator;
        } else {
            uint256 denominator = 
                (
                    uniV3FeeProportion
                    .mul(secondPairData.reserve0)
                    .mul(1000)
                )
                .add(
                    uniswappyFee
                    .mul(uniswappyFee)
                    .mul(firstPairData.reserve0)
                );
            return denominator;
        }
    }

    /// @notice Retrieves price and reserve data for a given Uniswap pair. Also checks which token is WETH.
    /// @param pair The Uniswap pair to retrieve data for.
    /// @return A PairReserves struct containing price and reserve data for the given pair.
    function getPairDataV2(IUniswapV2Pair pair) public view returns (IPairReserves.PairReserves memory) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 price;

        bool isWETHZero = false;
        if (pair.token0() == WETH_ADDRESS) {
            price = reserve1.mul(1e18).div(reserve0);
            isWETHZero = true;
        } else {
            price = reserve0.mul(1e18).div(reserve1);
        }

        return IPairReserves.PairReserves(reserve0, reserve1, price, isWETHZero);
    }

    function getPairDataV3(IUniswapV3Pool pool) public view returns (IPairReserves.PairReserves memory) {
        (, int24 tick, , , , , ) = pool.slot0();
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        uint256 priceRatioX192 = uint256(sqrtRatioX96) * uint256(sqrtRatioX96);
        uint256 pricePerToken = priceRatioX192 >> 192;

        // Get the addresses of token0 and token1
        address token0Address = pool.token0();
        address token1Address = pool.token1();

        // Create contract instances for token0 and token1
        IERC20 token0 = IERC20(token0Address);
        IERC20 token1 = IERC20(token1Address);

        // Get the balances of token0 and token1 in the pool
        uint256 reserve0 = token0.balanceOf(address(pool));
        uint256 reserve1 = token1.balanceOf(address(pool));

        // Check if either reserve is 0
        if (reserve0 <= 0 || reserve1 <= 0) {
            return IPairReserves.PairReserves(0, 0, 0, false);
        }

        bool isWETHZero = false;
        if (token0Address == WETH_ADDRESS) {
            isWETHZero = true;
        }

        return IPairReserves.PairReserves(reserve0, reserve1, pricePerToken, isWETHZero);
    }  

    /// @notice Calculates the square root of a given number.
    /// @param x: The number to calculate the square root of.
    /// @return y: The square root of the given number.
    function sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = x.add(1).div(2);
        uint256 y = x;
        while (z < y) {
            y = z;
            z = ((x.div(z)).add(z)).div(2);
        }
        return y;
    }

    /// @notice Calculates theoutput amount for a given input amount and reserves.
    /// @param reserveIn The reserve of the input token.
    /// @param reserveOut The reserve of the output token.
    /// @param inputAmount The input amount.
    /// @return amountOut The output amount.
    function getAmountOut(
        uint reserveIn,
        uint reserveOut,
        uint inputAmount
    ) internal view returns (uint amountOut) {
        uint amountInWithFee = inputAmount.mul(uniswappyFee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
        return amountOut;
    }

    /// @notice Transfers all WETH held by the contract to the contract owner.
    /// @dev Only the contract owner can call this function.
    function withdrawWETHToOwner() external onlyOwner {
        uint256 balance = IERC20(WETH_ADDRESS).balanceOf(address(this));
        IERC20(WETH_ADDRESS).transfer(msg.sender, balance);
    }

    /// @notice Transfers all ETH held by the contract to the contract owner.
    /// @dev Only the contract owner can call this function.
    function withdrawETHToOwner() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Executes a call to another contract with the provided data and value.
    /// @dev Only the contract owner can call this function.
    /// @dev Reverted calls will result in a revert. 
    /// @param _to The address of the contract to call.
    /// @param _value The amount of Ether to send with the call.
    /// @param _data The calldata to send with the call.
    function call(
        address payable _to,
        uint256 _value, 
        bytes memory _data
    ) external onlyOwner {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "External call failed");
    }

    receive() external payable {}
}