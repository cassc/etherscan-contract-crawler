// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/math/SafeMath.sol";
import "aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";

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

interface ILendingPool {
    function flashLoan ( 
        address _receiver, 
        address[] memory _assets, 
        uint256[] memory _amounts, 
        uint256[] memory _modes, 
        address _onBehalfOf, 
        bytes memory _params, 
        uint16 _referralCode) external;
}

contract BlindBackrun is Ownable, FlashLoanSimpleReceiverBase {
    using SafeMath for uint256;
    uint256 uniswappyFee = 997;
    ILendingPool public lendingPool;
    address public immutable WETH_ADDRESS;

    constructor(address _wethAddress, address _addressProvider) 
        Ownable() 
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) 
    {
        WETH_ADDRESS = _wethAddress;
        lendingPool = ILendingPool(IPoolAddressesProvider(_addressProvider).getPool());
    }

    // Function to execute a flash loan
    function executeFlashLoan(
        address _asset,
        uint256 _amount,
        address firstPairAddress,
        address secondPairAddress,
        uint percentageToPayToCoinbase
    ) external onlyOwner {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = _asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 = no debt, 1 = stable, 2 = variable

        address onBehalfOf = address(this);
        bytes memory params = abi.encode(firstPairAddress, secondPairAddress, percentageToPayToCoinbase);
        uint16 referralCode = 0;

        lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
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
        // Ensure the loan is for the correct asset and is sent from the LendingPool
        require(msg.sender == address(lendingPool), "Invalid sender");
        require(IERC20(asset).balanceOf(address(this)) >= amount, "Did not receive loan");

        // Decode the params and execute the arbitrage
        (address firstPairAddress, address secondPairAddress, uint percentageToPayToCoinbase) = abi.decode(params, (address, address, uint));
        executeArbitrage(firstPairAddress, secondPairAddress, percentageToPayToCoinbase);

        // Calculate amount to repay, which is the loan amount plus the premium
        uint256 totalDebt = amount.add(premium);

        // Transfer funds back to repay the flash loan
        require(IERC20(asset).transferFrom(address(this), address(lendingPool), totalDebt), "Failed to repay loan");

        return true;
    }

    /// @notice Executes an arbitrage transaction between two Uniswap V2 pairs.
    /// @notice Pair addresses need to be computed off-chain.
    /// @dev Only the contract owner can call this function.
    /// @param firstPairAddress Address of the first Uniswap V2 pair.
    /// @param secondPairAddress Address of the second Uniswap V2 pair.
    function executeArbitrage(
        address firstPairAddress,
        address secondPairAddress,
        uint percentageToPayToCoinbase
    ) internal {
        uint256 balanceBefore = IERC20(WETH_ADDRESS).balanceOf(address(this));
        IUniswapV2Pair firstPair = IUniswapV2Pair(firstPairAddress);
        IUniswapV2Pair secondPair = IUniswapV2Pair(secondPairAddress);

        IPairReserves.PairReserves memory firstPairData = getPairData(firstPair);
        IPairReserves.PairReserves memory secondPairData = getPairData(secondPair);


        uint256 amountIn = getAmountIn(firstPairData, secondPairData);
        IERC20(WETH_ADDRESS).transfer(firstPairAddress, amountIn);
        
        uint256 firstPairAmountOut;
        uint256 finalAmountOut;
        if (firstPairData.isWETHZero == true){
            firstPairAmountOut = getAmountOut(amountIn, firstPairData.reserve0, firstPairData.reserve1);
            finalAmountOut = getAmountOut(firstPairAmountOut, secondPairData.reserve1, secondPairData.reserve0);

            firstPair.swap(0, firstPairAmountOut, secondPairAddress, "");
            secondPair.swap(finalAmountOut, 0, address(this), "");
        } else {
            firstPairAmountOut = getAmountOut(amountIn, firstPairData.reserve1, firstPairData.reserve0);
            finalAmountOut = getAmountOut(firstPairAmountOut, secondPairData.reserve0, secondPairData.reserve1);

            firstPair.swap(firstPairAmountOut, 0, secondPairAddress, "");          
            secondPair.swap(0, finalAmountOut, address(this), "");
        }
        
        uint256 balanceAfter = IERC20(WETH_ADDRESS).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "Arbitrage failed");
        uint profit = balanceAfter.sub(balanceBefore);
        uint profitToCoinbase = profit.mul(percentageToPayToCoinbase).div(100);
        IWETH(WETH_ADDRESS).withdraw(profitToCoinbase);
        block.coinbase.transfer(profitToCoinbase);
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
        
        uint256 amountIn = 
            numerator
            .mul(1000)
            .div(denominator);

        return amountIn;
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
        ) public returns (uint256){
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
    /// @param amountIn The input amount.
    /// @param reserveIn The reserve of the input token.
    /// @param reserveOut The reserve of the output token.
    /// @return amountOut The output amount.
    function getAmountOut(uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
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