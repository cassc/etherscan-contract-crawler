/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

pragma solidity ^0.8.0;

    interface IPancakeSwapRouter {
        function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
        function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
        function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
        function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    }

    interface IPancakeSwapFactory {
        function getPair(address tokenA, address tokenB) external view returns (address pair);
    }

    interface IBEP20 {
       
        function decimals() external view returns (uint8);
        
        function totalSupply() external view returns (uint256);

        function balanceOf(address account) external view returns (uint256);

        function transfer(address recipient, uint256 amount) external returns (bool);

        function allowance(address owner, address spender) external view returns (uint256);

        function approve(address spender, uint256 amount) external returns (bool);

        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

        event Transfer(address indexed from, address indexed to, uint256 value);

        event Approval(address indexed owner, address indexed spender, uint256 value);

        
    }

    contract BSCShorting {

        

        // Token interface for interacting with the BEP-20 token
        IBEP20 public token;
        IPancakeSwapRouter public pancakeSwapRouter;
        address public WBNB;
        mapping(address => uint256) public lenderShares;
        uint256 public totalLentTokens;
        address public tokenAddress;

        address[] public lenders;

        constructor(IBEP20 _token, IPancakeSwapRouter _pancakeSwapRouter, address _WBNB) {
            token = _token;
            pancakeSwapRouter = _pancakeSwapRouter;
            WBNB = _WBNB;
            tokenAddress = address(_token);
    }

        // Struct to store short position data
        struct ShortPosition {
            uint256 amount; // Amount of tokens shorted
            uint256 collateral; // BNB collateral deposited
            uint256 entryPrice; // Token price at the time of opening the short position
            uint256 riskTolerance;
        }

        struct LendingInfo {
        address lender;
        uint256 amount;
        uint256 duration;
        uint256 endTime;
        }

        LendingInfo[] public lendings;

        // Mapping to store the traders' short positions
        mapping(address => ShortPosition) public shortPositions;

     function getPathForETHToToken() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = tokenAddress;

        return path;
}

function getPathForTokenToETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[1] = WBNB;
        path[0] = tokenAddress;

        return path;
}


    
function lendTokens(uint256 amount, uint256 lendHours) external {
    require(amount > 0, "Lend amount must be greater than 0");

    // Transfer tokens from the lender to the contract
    bool success = token.transferFrom(msg.sender, address(this), amount);
    require(success, "Token transfer failed");

    // Update the lender's share and the total tokens lent
    lenderShares[msg.sender] += amount;
    totalLentTokens += amount;

    // Calculate lendTime in seconds
    uint256 lendTime = lendHours * 1 hours;

    // Update the lender's lend duration

    
    uint256 endTime = block.timestamp + lendTime;
    LendingInfo memory temp = LendingInfo({lender : msg.sender,
    amount: amount, 
    duration :lendTime, 
    endTime : endTime});

    lendings.push(temp);

    // Emit an event for tracking purposes
    emit TokensLent(msg.sender, amount, lendTime);
}


event TokensLent(address lender, uint256 amount, uint256 lendTime);


event TokensDeposited(address indexed lender, uint256 amount);
/**
     * @dev Open a short position for the trader.
     * @param amount The amount of tokens to short.
     */

function openShort(uint256 amount, uint256 riskTolerance) external payable {

    require(amount > 0, "Short amount must be greater than 0");
    require(riskTolerance >= 25 && riskTolerance <= 50, "Risk tolerance must be between 25% and 50%");

    uint256 tokenPrice = getTokenPrice(); // Replace with your chosen price oracle
    uint256 collateralRequired = (amount * tokenPrice * riskTolerance) / 100;

    require(msg.value >= collateralRequired, "Insufficient collateral");

    // Check if the contract has enough tokens
    uint256 contractTokenBalance = token.balanceOf(address(this));
    require(contractTokenBalance >= amount, "Not enough tokens in the contract");

    // Charge a 5% fee and distribute it among the lenders
    uint256 fee = (amount * 5) / 100;
    distributeFees(fee);

    // Approve the PancakeSwap Router to spend tokens on behalf of the contract
    bool success = token.approve(address(pancakeSwapRouter), amount - fee);
    require(success, "Token approval failed");

    // Sell the tokens for ETH (assuming WBNB as the intermediary) using swapExactTokensForETH
    address[] memory path = getPathForTokenToETH();
    uint256 deadline = block.timestamp + 300; // 5 minutes from now
    pancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount - fee, 0, path, address(this), deadline);

    // Update the trader's short position
    shortPositions[msg.sender] = ShortPosition(amount - fee, msg.value, tokenPrice, riskTolerance);

    // Emit an event for tracking purposes
    emit ShortOpened(msg.sender, amount - fee, tokenPrice, riskTolerance);
}


    function distributeFees(uint256 fee) private {
    for (uint256 i = 0; i < lenders.length; i++) {
        uint256 share = (lenderShares[lenders[i]] * fee) / totalLentTokens;
        token.transfer(lenders[i], share);
    }
}




    /**
     * @dev Close the trader's short position.
     */
    function closeShort() external {
    ShortPosition storage shortPosition = shortPositions[msg.sender];
    require(shortPosition.amount > 0, "No open short position");

    uint256 tokenPrice = getTokenPrice(); // Replace with your chosen price oracle

    // Calculate the cost to buy back tokens
    uint256 buyBackCost = shortPosition.amount * tokenPrice;

    uint256 remainingCollateral = 0;

    // Determine if the trader made a profit
    if (shortPosition.entryPrice > tokenPrice) {
        // Tax the profit by 5% and distribute it among the lenders
        uint256 profit = shortPosition.entryPrice - tokenPrice;
        uint256 tax = (profit * 5) / 100;
        distributeFees(tax);

        // Remaining collateral after buying back tokens and paying the tax
        remainingCollateral = shortPosition.collateral - (buyBackCost + tax);
    } else {
        // The trader didn't make a profit, use the remaining collateral to buy back tokens
        buyBackCost = shortPosition.collateral;
    }

    // Buy back tokens with the remaining collateral
    // Assuming pancakeSwapRouter.swapETHForExactTokens is used to buy back tokens
    uint256 deadline = block.timestamp + 300; // 5 minutes from now
    pancakeSwapRouter.swapETHForExactTokens{value: buyBackCost}(shortPosition.amount, getPathForETHToToken(), msg.sender, deadline);

    // Refund any remaining collateral to the trader
    if (remainingCollateral > 0) {
        (bool success,) = msg.sender.call{value: remainingCollateral}("");
        require(success, "Failed to send remaining collateral");
    }

    // Close the trader's short position
    delete shortPositions[msg.sender];

    // Emit an event for tracking purposes
    emit ShortClosed(msg.sender, shortPosition.amount, buyBackCost);
}

    function getTokenPrice() private view returns (uint256) {
        uint256 amountIn = 10 ** token.decimals(); // 1 token
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WBNB);

        uint256[] memory amountsOut = pancakeSwapRouter.getAmountsOut(amountIn, path);

        return amountsOut[1];
    }

    function price() external view returns (uint256) {
        uint256 amountIn = 10 ** token.decimals(); // 1 token
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WBNB);

        uint256[] memory amountsOut = pancakeSwapRouter.getAmountsOut(amountIn, path);

        return amountsOut[1];
    }


    event ShortOpened(address indexed trader, uint256 amount, uint256 entryPrice, uint256 collateral);
    event ShortClosed(address indexed trader, uint256 amount, uint256 remainingCollateral);
    


    }