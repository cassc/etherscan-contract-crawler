//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IUniswapV2Router02.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IWETH {
    function withdraw(uint amount) external;
}

contract DENv2 is Ownable {

    using SafeMath for uint;

    // Fee Taken On Swaps (e.g., 15/10000 = 0.0015 = 0.15%)
    uint256 public systemFee      = 15;
    uint256 public referralFee    = 20;
    uint256 public feeDenominator = 10000;

    // Fee Recipient
    address public systemFeeReceiver;   //0x0aaA18c723B3e57df3988c4612d4CC7fAdD42a34 (Eclipse DAO Multisig)
    address public referralFeeReceiver; //0x091dD81C8B9347b30f1A4d5a88F92d6F2A42b059 (Useless Deployer)

    // Wrapped Native Coin
    // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 (Wrapped ETH)
    // 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (Wrapped BSC)
    // 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270 (Wrapped MATIC)
    // 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7 (Wrapped AVAX)
    // 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83 (Wrapped FTM)
    // 0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a (Wrapped ONE)
    // 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1 (Wrapped Arbitrum)
    address public WETH;

    // Create a struct to group local variables together to avoid stack too deep errors
    struct SwapVars {
        address token0;
        uint amountInput;
        uint amountOutput;
        uint reserve0;
        uint reserve1;
        uint reserveInput;
        uint reserveOutput;
    }

    constructor(address WETH_, address systemFeeReceiver_, address referralFeeReceiver_) {
        require(WETH_ != address(0), 'Zero Address');
        require(systemFeeReceiver_ != address(0), 'Zero Address');
        require(referralFeeReceiver_ != address(0), 'Zero Address');
        WETH = WETH_;
        systemFeeReceiver = systemFeeReceiver_;
        referralFeeReceiver = referralFeeReceiver_;
    }

    function setSystemFee(uint newSystemFee) external onlyOwner {
        require((newSystemFee + referralFee) <= 200, 'System fee with referral fee too high');
        systemFee = newSystemFee;
    }

    function setReferralFee(uint newReferralFee) external onlyOwner {
        require((newReferralFee + systemFee) <= 200, 'Referral fee with system fee too high');
        referralFee = newReferralFee;
    }

    function setSystemFeeRecipient(address newSystemFeeRecipient) external onlyOwner {
        require(newSystemFeeRecipient != address(0), 'Zero Address');
        systemFeeReceiver = newSystemFeeRecipient;
    }

    function setReferralFeeRecipient(address newReferralFeeRecipient) external onlyOwner {
        require(newReferralFeeRecipient != address(0), 'Zero Address');
        referralFeeReceiver = newReferralFeeRecipient;
    }

    function swapETHForToken(address DEX, address token, uint amountOutMin) external payable {
        // input validation
        require(DEX != address(0), 'Zero Address');
        require(token != address(0), 'Zero Address');
        require(msg.value > 0, 'Zero Value');

        // determine and collect fees
        uint _systemFeeAmount = getSystemFeeAmount(msg.value);
        uint _referralFeeAmount = getReferralFeeAmount(msg.value);
        _sendETH(systemFeeReceiver, _systemFeeAmount);
        _sendETH(referralFeeReceiver, _referralFeeAmount);

        // instantiate router
        IUniswapV2Router02 router = IUniswapV2Router02(DEX);

        // define swap path
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value - (_systemFeeAmount + _referralFeeAmount)
        } (amountOutMin, path, msg.sender, block.timestamp + 300);

        // save memory
        delete path;
    }

    function swapTokenForETH(address DEX, address token, uint amount, uint amountOutMin) external {
        require(DEX != address(0), 'Zero Address');
        require(token != address(0), 'Zero Address');
        require(amount > 0, 'Zero Value');

        // liquidity pool
        IPair pair = IPair(IUniswapV2Factory(IUniswapV2Router02(DEX).factory()).getPair(token, WETH));
        _transferIn(msg.sender, address(pair), token, amount);

        // handle swap logic
        (address input, address output) = (token, WETH);

        SwapVars memory vars;
        (vars.token0,) = sortTokens(input, output);
        (vars.reserve0, vars.reserve1,) = pair.getReserves();
        (vars.reserveInput, vars.reserveOutput) = input == vars.token0 ? (vars.reserve0, vars.reserve1) : (vars.reserve1, vars.reserve0);
        vars.amountInput = IERC20(input).balanceOf(address(pair)).sub(vars.reserveInput);
        vars.amountOutput = getAmountOut(vars.amountInput, vars.reserveInput, vars.reserveOutput);
        (uint amount0Out, uint amount1Out) = input == vars.token0 ? (uint(0), vars.amountOutput) : (vars.amountOutput, uint(0));

        // make the swap
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

        // check output amount
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);

        // take fee in bnb
        uint _systemFeeAmount = getSystemFeeAmount(amountOut);
        uint _referralFeeAmount = getReferralFeeAmount(amountOut);
        _sendETH(systemFeeReceiver, _systemFeeAmount);
        _sendETH(referralFeeReceiver, _referralFeeAmount);
        
        // send rest to sender
        _sendETH(msg.sender, amountOut - (_systemFeeAmount + _referralFeeAmount));
    }

    function swapTokenForToken(address DEX, address tokenIn, address tokenOut, uint amountIn, uint amountOutMin) external {
        require(DEX != address(0), 'Zero Address');
        require(tokenIn != address(0), 'Zero Address');
        require(tokenOut != address(0), 'Zero Address');
        require(amountIn > 0, 'Zero Value');

        // fetch fee and transfer in to receiver
        uint _systemFeeAmount = getSystemFeeAmount(amountIn);
        uint _referralFeeAmount = getReferralFeeAmount(amountIn);
        _transferIn(msg.sender, systemFeeReceiver, tokenIn, _systemFeeAmount);
        _transferIn(msg.sender, referralFeeReceiver, tokenIn, _referralFeeAmount);

        // transfer rest into liquidity pool
        IPair pair = IPair(IUniswapV2Factory(IUniswapV2Router02(DEX).factory()).getPair(tokenIn, tokenOut));
        _transferIn(
            msg.sender, 
            address(pair), 
            tokenIn,
            amountIn - (_systemFeeAmount + _referralFeeAmount)
        );

        // handle swap logic
        (address input, address output) = (tokenIn, tokenOut);

        SwapVars memory vars;
        (vars.token0,) = sortTokens(input, output);
        (vars.reserve0, vars.reserve1,) = pair.getReserves();
        (vars.reserveInput, vars.reserveOutput) = input == vars.token0 ? (vars.reserve0, vars.reserve1) : (vars.reserve1, vars.reserve0);
        vars.amountInput = IERC20(input).balanceOf(address(pair)).sub(vars.reserveInput);
        vars.amountOutput = getAmountOut(vars.amountInput, vars.reserveInput, vars.reserveOutput);
        (uint amount0Out, uint amount1Out) = input == vars.token0 ? (uint(0), vars.amountOutput) : (vars.amountOutput, uint(0));

        // make the swap
        uint before = IERC20(tokenOut).balanceOf(msg.sender);
        pair.swap(amount0Out, amount1Out, msg.sender, new bytes(0));
        uint received = IERC20(tokenOut).balanceOf(msg.sender).sub(before);

        // check output amount
        require(received >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9970); // hardcoded DEX fee estimate
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    function getSystemFeeAmount(uint amount) public view returns (uint) {
        return (amount * systemFee) / feeDenominator;
    }

    function getReferralFeeAmount(uint amount) public view returns (uint) {
        return (amount * referralFee) / feeDenominator;
    }

    function _sendETH(address receiver, uint amount) internal {
        (bool s,) = payable(receiver).call{value: amount}("");
        require(s, 'Failure On ETH Transfer');
    }

    function _transferIn(address fromUser, address toUser, address token, uint amount) internal returns (uint) {
        uint before = IERC20(token).balanceOf(toUser);
        bool s = IERC20(token).transferFrom(fromUser, toUser, amount);
        uint received = IERC20(token).balanceOf(toUser) - before;
        require(s && received > 0 && received <= amount, 'Error On Transfer From');
        return received;
    }

    receive() external payable {}
}