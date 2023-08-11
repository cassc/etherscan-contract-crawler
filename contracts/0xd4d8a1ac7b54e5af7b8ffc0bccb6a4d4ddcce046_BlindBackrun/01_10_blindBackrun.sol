// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "../lib/openzeppelin/token/ERC20/IERC20.sol";
import "../lib/openzeppelin/access/Ownable.sol";
import "../lib/openzeppelin/utils/math/SafeMath.sol";
import "../lib/aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "../lib/aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";

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

interface IPairReserves{
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
        uint256 balanceBefore;
        IUniswapV2Pair firstPair;
        IUniswapV2Pair secondPair;
        IPairReserves.PairReserves firstPairData;
        IPairReserves.PairReserves secondPairData;
        uint256 amountToTrade;
        uint256 firstPairAmountOut;
        uint256 finalAmountOut;
        uint256 balanceAfter;
        uint256 profit;
        uint256 profitToCoinbase;
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
        uint percentageToPayToCoinbase
        ) public {
        address receiverAddress = address(this);
        bytes memory params = abi.encode(firstPairAddress, secondPairAddress, percentageToPayToCoinbase);
        uint16 referralCode = 0;

        IPairReserves.PairReserves memory firstPairData = getPairData(IUniswapV2Pair(firstPairAddress));
        IPairReserves.PairReserves memory secondPairData = getPairData(IUniswapV2Pair(secondPairAddress));

        getAmountIn(firstPairData, secondPairData); // This updates the state variable 'amountIn'

        POOL.flashLoanSimple(
            receiverAddress,
            WETH_ADDRESS,
            amountIn,
            params,
            referralCode
        );
    }

    /// @notice Executes an arbitrage transaction between two Uniswap V2 pairs.
    /// @notice Pair addresses need to be computed off-chain.
    /// @dev Only the contract owner can call this function.
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
    (data.firstPairAddress, data.secondPairAddress, data.percentageToPayToCoinbase) = abi.decode(params, (address, address, uint256));

    require(asset == WETH_ADDRESS, "Asset not supported"); // Assuming you only support WETH as the borrowed asset
    require(IERC20(asset).balanceOf(address(this)) >= amount, "Did not receive loan"); 

    data.balanceBefore = IERC20(WETH_ADDRESS).balanceOf(address(this));
    
    data.firstPair = IUniswapV2Pair(data.firstPairAddress);
    data.secondPair = IUniswapV2Pair(data.secondPairAddress);

    data.firstPairData = getPairData(data.firstPair);
    data.secondPairData = getPairData(data.secondPair);

    data.amountToTrade = amount;
    
    if (data.firstPairData.isWETHZero == true){
        data.firstPairAmountOut = getAmountOut(data.firstPairData.reserve0, data.firstPairData.reserve1, data.amountToTrade);
        data.finalAmountOut = getAmountOut(data.firstPairAmountOut, data.secondPairData.reserve1, data.secondPairData.reserve0);

        data.firstPair.swap(0, data.firstPairAmountOut, data.secondPairAddress, "");
        data.secondPair.swap(data.finalAmountOut, 0, address(this), "");
    } else {
        data.firstPairAmountOut = getAmountOut(data.firstPairData.reserve1, data.firstPairData.reserve0, data.amountToTrade);
        data.finalAmountOut = getAmountOut(data.firstPairAmountOut, data.secondPairData.reserve0, data.secondPairData.reserve1);

        data.firstPair.swap(data.firstPairAmountOut, 0, data.secondPairAddress, "");
        data.secondPair.swap(0, data.finalAmountOut, address(this), "");
    }

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
    /// @param firstPairData Struct containing data about the first Uniswap V2 pair.
    /// @param secondPairData Struct containing data about the second Uniswap V2 pair.
    /// @return amountIn, the optimal amount to trade to arbitrage two v2 pairs.
    function getAmountIn(
        IPairReserves.PairReserves memory firstPairData, 
        IPairReserves.PairReserves memory secondPairData
    ) public returns (uint256) {
        uint256 numerator = getNumerator(firstPairData, secondPairData);
        uint256 denominator = getDenominator(firstPairData, secondPairData);
        
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
            IPairReserves.PairReserves memory secondPairData
        ) public view returns (uint256){
        if (firstPairData.isWETHZero == true) {
            uint256 denominator = 
                (
                    uniswappyFee
                    .mul(secondPairData.reserve1)
                    .mul(1000)
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
                    uniswappyFee
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

    /// @notice Retrieves price and reserve data for a given Uniswap V2 pair. Also checks which token is WETH.
    /// @param pair The Uniswap V2 pair to retrieve data for.
    /// @return A PairReserves struct containing price and reserve data for the given pair.
    function getPairData(IUniswapV2Pair pair) private view returns (IPairReserves.PairReserves memory) {
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

    /// @notice Calculates the output amount for a given input amount and reserves.
    /// @param reserveIn The reserve of the input token.
    /// @param reserveOut The reserve of the output token.
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
    function call(address payable _to, uint256 _value, bytes memory _data) external onlyOwner {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "External call failed");
    }

    /// @notice Fallback function that allows the contract to receive Ether.
    receive() external payable {}
}