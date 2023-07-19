pragma solidity 0.8.9;

import "./UniswapV2Library.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

contract FlashLoaner {
    address immutable factory;
    IUniswapV2Router02 immutable sushiRouter;

    // Define events
    event SwapAttempt(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amount);
    event ApprovalSet(address indexed token, address spender, uint256 amount);
    event AmountsCalculated(uint256 amountRequired, uint256 amountReceived);
    event ProfitTransferred(address indexed user, uint256 profit);
    event UpdatedMessages(string oldStr, string newStr);


    string public message;
    constructor (address _factory, address _sushiRouter) {
        factory = _factory; // Address of the Uniswap V2 factory contract
        sushiRouter = IUniswapV2Router02(_sushiRouter); // Address of the SushiSwap router contract
        message = "Hello World";
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata
    ) external {
        address[] memory path = new address[](2);
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;

        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();

        require(
            msg.sender == UniswapV2Library.pairFor(factory, token0, token1),
            "Unauthorized: caller is not a Uniswap pair"
        );
        require(
            _amount0 == 0 || _amount1 == 0,
            "One of the amounts must be zero"
        );

        path[0] = _amount0 == 0 ? token1 : token0;
        path[1] = _amount0 == 0 ? token0 : token1;
        
        emit SwapAttempt(_sender, path[0], path[1], amountToken);
        
        IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
        uint256 deadline = block.timestamp + 1 hours;
        token.approve(address(sushiRouter), amountToken);

        emit ApprovalSet(address(token), address(sushiRouter), amountToken);

        uint256 amountRequired = UniswapV2Library.getAmountsIn(
            factory,
            amountToken,
            path
        )[0];
        uint256 amountReceived = sushiRouter.swapExactTokensForTokens(
            amountToken,
            amountRequired,
            path,
            msg.sender,
            deadline
        )[1];

        emit AmountsCalculated(amountRequired, amountReceived);

        require(
            amountReceived > amountRequired,
            "Failed to profit from swap"
        );

        // YEAHH PROFIT
        uint256 profit = amountReceived - amountRequired;
        token.transfer(_sender, profit);

        // Emit ProfitTransferred event
        emit ProfitTransferred(_sender, profit);
    }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}