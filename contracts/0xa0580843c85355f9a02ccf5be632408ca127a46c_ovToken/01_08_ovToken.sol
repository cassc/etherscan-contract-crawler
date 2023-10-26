pragma solidity =0.8.21;

import './NameAsSymbolERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ovToken {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address[] public tokens; //list of tokens created using this contract

    uint256 public constant TOKEN_INITIAL_LIQUIDITY = 10000 ether;
    uint256 public constant ETH_INITIAL_LIQUIDITY = 0.05 ether;

    event TokenCreated(address indexed token, address indexed owner);

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function createTokenAndAddLiquidity(string calldata name, uint256 desiredTokenAmount) public payable returns (address) {
        NameAsSymbolERC20 T = new NameAsSymbolERC20{salt: keccak256('Open Value')}(name);
        address newToken = address(T);
        tokens.push(newToken);
        
        IERC20(newToken).approve(address(uniswapV2Router), TOKEN_INITIAL_LIQUIDITY);
        uniswapV2Router.addLiquidityETH{value: ETH_INITIAL_LIQUIDITY}(newToken, TOKEN_INITIAL_LIQUIDITY, 0, 0, address(0), block.timestamp + 15 minutes);

        uint256 remainingETH = msg.value - ETH_INITIAL_LIQUIDITY;

        if (desiredTokenAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = newToken;

            uint256 amountETHNeeded = uniswapV2Router.getAmountsIn(desiredTokenAmount, path)[0];
            require(remainingETH>amountETHNeeded);

            uint256[] memory swapamounts = uniswapV2Router.swapETHForExactTokens{value: amountETHNeeded}(desiredTokenAmount, path, msg.sender, block.timestamp + 15 minutes);
            remainingETH -= swapamounts[0]; //weth
        }

        if (remainingETH > 0) {
                payable(msg.sender).call{value: remainingETH}("");
        }
    
        emit TokenCreated(address(T), msg.sender);
        return newToken;
    }

    function getEstimatedETH(uint256 desiredTokenAmount) public pure returns (uint256) {
        require(desiredTokenAmount < TOKEN_INITIAL_LIQUIDITY, "Buy amount too large");
        uint256 amountInETH = desiredTokenAmount * ETH_INITIAL_LIQUIDITY * 1000 / ((TOKEN_INITIAL_LIQUIDITY - desiredTokenAmount) * 997); //fee
        uint256 totalEth = 0.05 ether + amountInETH + 1 gwei ;  //buffer
        return totalEth;
    }

    function getTokenCount() public view returns (uint) {
        return tokens.length;
    }
}