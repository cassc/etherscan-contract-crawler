/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/bearbull/bearBullV2.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

interface IPCSRouter {

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

}

interface IPancakeSwapFactory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);

}


contract BearBull is Ownable{

    //This contract allows users to short tokens listed on pancakeswap
    fallback() external payable {}
    receive() external payable {}

    constructor(IPCSRouter _pancakeSwapRouter){
        WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        token = IBEP20(0xCd033784B1ca29d2c58a424dE4508B924cB18474);
        pcsRouter = _pancakeSwapRouter;
        tokenAddress = 0xCd033784B1ca29d2c58a424dE4508B924cB18474;
    }

    // STRUCTS

    //short positions
    struct shortPosition{
        address trader;
        uint256 amount; //without decimals
        uint256 tolerance; //int, must divide by 100 to multiply
        uint256 liqPrice;
        uint256 startPrice;
        uint256 collateral;
        uint256 ethValue;
        uint256 shortNumber;
    }

    //lend positions
    struct lendingInfo{
        address lender;
        uint256 lendNumber;
        uint256 amount;
        uint256 duration;
        uint256 endTime;
    }

    //variables
    mapping(address => shortPosition) public shortPositions;
    IBEP20 public token;
    address public tokenAddress;
    IPCSRouter public pcsRouter;
    address public WBNB;
    lendingInfo[] public lendings;
    mapping(address => lendingInfo) lendMap; 
    uint256 public totalLent;
    uint256 public totalAvailable;
    mapping (address => uint256) public lenderShares;
    shortPosition[] public shorts;
    uint256 public tokensInShorts;

    //sub functions:

    //check how many tokens are available to short.
    function checkAvailable() public returns(uint256){
        uint256 available;
        for(uint256 i = 0; i < lendings.length; i++){
            if(lendings[i].endTime > block.timestamp + 3600){
                available += lendings[i].amount;
            }
        }
        totalAvailable = available - tokensInShorts;
        return available;
    }
    
    //check if a certain amount of tokens can be shorted.
    function canFulfill(uint256 amount) public view returns(bool){
        bool fulfillable = false;
        uint256 available;
        for(uint256 i = 0; i < lendings.length; i++){
            if(lendings[i].endTime > block.timestamp + 3600){
                available += lendings[i].amount;
                if(available >= amount*tokensInShorts){
                    fulfillable = true; 
                }
            }
        }
        return fulfillable;
    }

    //get collateral required, will return an amount of collateral required in wei.
    function getCollateral(uint256 amount, uint256 tolerance) public view returns (uint256){

        return (price() * amount * tolerance) / 100;

    }

    //get token price, returns value with decimal size.

    function price() private view returns (uint256) {

        uint256 amountIn = 10 ** token.decimals(); // 1 token
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WBNB);
        uint256[] memory amountsOut = pcsRouter.getAmountsOut(amountIn, path);

        return amountsOut[1];
    }

    function getPrice() public view returns (uint256) {
        uint256 currentPrice = price();
        return currentPrice;
    }

    //allow user to view price from BSCScan:
    function checkPrice() external view returns (uint256) {

        uint256 amountIn = 10 ** token.decimals(); // 1 token
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WBNB);
        uint256[] memory amountsOut = pcsRouter.getAmountsOut(amountIn, path);

        return amountsOut[1];
    }

    //get path from BNB to token:
    function getPathForETHToToken() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = tokenAddress;

        return path;
    }

    //get path from token to BNB:
    function getPathForTokenToETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[1] = WBNB;
        path[0] = tokenAddress;

        return path;
    }
    
    // MAIN FUNCTIONS

    //---------------------------------------------------------------------------------------------------\\
    
    //lend Tokens
    function lendTokens(uint256 amount, uint256 time) external {
        
        require(amount > 0, "Not enough tokens");
        require(time > 0, "Not long enough");

        bool success = token.transferFrom(msg.sender, address(this) , amount*10**token.decimals());

        require(success, "Token transfer failed.");

        totalLent += amount;
        uint256 lendTime = block.timestamp + (time * 3600);
        lenderShares[msg.sender] += amount;

        lendingInfo memory temp = lendingInfo({
            lender : msg.sender,
            lendNumber : lendings.length,
            amount : amount,
            duration : lendTime,
            endTime : block.timestamp + lendTime
        });

        lendings.push(temp);
        lendMap[msg.sender] = temp;

        emit TokensLent(msg.sender, amount, time);
    }

    //withdraw lent tokens
    function withdrawTokens() external {
        uint256 amount = lendMap[msg.sender].amount;
        require(amount > 0, "You must withdraw more than 0 tokens.");
        require(lendMap[msg.sender].endTime < block.timestamp, "Your withdraw date has not been met.");
        require(canFulfill(amount), "There are not enough tokens in the contract to withdraw.");
        

        token.approve(msg.sender, lendMap[msg.sender].amount*10**token.decimals());

        bool success = token.transferFrom(address(this), msg.sender , amount*10**token.decimals());

        require(success, "Token transfer failed.");

        totalLent -= amount;

        delete lendings[lendMap[msg.sender].lendNumber];
        delete lendMap[msg.sender];

        emit TokensWithdrawn(msg.sender, amount);
    }

    //Open Short
    function openShort(uint256 amount, uint256 riskTolerance) external payable {

        require(amount > 0, "Short position must be greater than zero");
        require(riskTolerance >= 25 && riskTolerance <= 50, "Risk tolerance must be between 25 and 50");
        uint256 collateralRequired = getCollateral(amount, riskTolerance);
        require(msg.value >= collateralRequired, "Insufficient collateral");
        
        uint256 decimals = token.decimals();
        bool fulfillable = canFulfill(amount);
        uint256 trueAmount = amount * 10**decimals;
        require(fulfillable, "Insufficient token balance in contract!");
        uint256 tokenPrice = price();

        address[] memory path = getPathForTokenToETH();

        bool success = token.approve(address(pcsRouter), trueAmount);
        require(success, "Token approval failed");

        uint256 deadline = block.timestamp + 100;

        uint256[] memory amounts = pcsRouter.swapExactTokensForETH(trueAmount, 0, path, address(this), deadline);

        uint256 shortNum = shorts.length;
        shortPosition memory temp = shortPosition({
            trader : msg.sender,
            amount : amount,
            tolerance : riskTolerance,
            liqPrice : liquidationPrice(tokenPrice, riskTolerance),
            startPrice : tokenPrice,
            collateral : msg.value,
            ethValue : amounts[1],
            shortNumber : shortNum
        });

        shortPositions[msg.sender] = temp;
        shorts.push(temp);
        tokensInShorts += temp.amount;
        emit ShortOpened (msg.sender, amount, tokenPrice, msg.value);
    }

    //close short
    function closeShort() external {

        shortPosition storage temp = shortPositions[msg.sender];

        require(temp.amount > 0, "No short position currently open.");

        uint256 currentPrice = price();
        uint256 buybackCost = currentPrice * temp.amount;
        uint256 toSend = 0;
        uint256 extraCollateral = 0;
        uint256 deadline = block.timestamp + 100;
        uint256 decimals = token.decimals();
        uint256[] memory amounts = pcsRouter.swapETHForExactTokens{value : buybackCost + (buybackCost * 10 / 100)}(temp.amount*10**decimals, getPathForETHToToken(), address(this), deadline);
    
        toSend = temp.ethValue + temp.collateral - amounts[0];
        
        if(toSend > 0){
            (bool success,) = msg.sender.call{value: toSend}("");
            require (success, "Failed to send back ETH.");
        }

        delete shortPositions[msg.sender];
        delete shorts[temp.shortNumber];
        tokensInShorts -= temp.amount;
        emit ShortClosed(msg.sender, temp.amount);
    }

    function closeShortByIndex(uint256 index) public onlyOwner returns (uint256){

        shortPosition storage temp = shorts[index];

        require(temp.amount > 0, "No short position currently open.");

        uint256 currentPrice = price();
        uint256 buybackCost = currentPrice * temp.amount;
        uint256 toSend = 0;
        uint256 extraCollateral = 0;
        uint256 deadline = block.timestamp + 100;
        uint256 decimals = token.decimals();
        uint256[] memory amounts = pcsRouter.swapETHForExactTokens{value : buybackCost + (buybackCost * 10 / 100)}(temp.amount*10**decimals, getPathForETHToToken(), address(this), deadline);
    
        toSend = temp.ethValue + temp.collateral - amounts[0];
        
        if(toSend > 0){
            (bool success,) = temp.trader.call{value: toSend}("");
            require (success, "Failed to send back ETH.");
        }

        delete shortPositions[temp.trader];
        delete shorts[temp.shortNumber];
        tokensInShorts -= temp.amount;
        emit ShortClosed(msg.sender, temp.amount);
    }

    //events:
    event ShortOpened(address indexed trader, uint256 amount, uint256 entryPrice, uint256 collateral);
    event ShortClosed(address indexed trader, uint256 amount);
    event TokensLent(address lender, uint256 amount, uint256 lendTime);
    event TokensDeposited(address indexed lender, uint256 amount);
    event TokensWithdrawn(address lender, uint256 amount);

    //Automating the closing of short positions

    //Create a must liquidate check function that checks if something must liquidate based on calculations of price

    function mustLiquidate(shortPosition memory _temp) public view returns (bool) {

        uint256 currentPrice = getPrice();
        shortPosition memory temp = _temp;

        if(temp.liqPrice >= currentPrice){
            return true;
        }
        else return false;

    }
    
    //CREATE A CALCULATE LIQUIDATION PRICE FUNCTION

    function liquidationPrice(uint256 currentPrice, uint256 riskTolerance) private pure returns (uint256) {

        uint256 liqPrice = currentPrice + (currentPrice * riskTolerance)/100;
        return liqPrice;

    }

    //Create a function that loops through all the shorts and finds the ones that must be liquidated, returns an array of index's for the shorts[].

    // function toLiquidate() public returns (uint256[] memory) {
        
    //     uint256 currentPrice = getPrice();
    //     uint256[] shortsToLiquidate;
    //     uint256 memory j = 0;

    //     for (uint256 i = 0; i < shorts.length; i++){
    //         shortPosition memory temp = shorts[i];

    //         if(mustLiquidate(temp)){
    //             closeShortByIndex(i);
                
    //             emit ShortClosed(temp.trader, temp.amount);
    //             shortsToLiquidate[j] = i;
    //         }
    //     }
    // }

    //Create a function that calls all of these functions and closes the shorts based on the array that is returned from the above function.
}