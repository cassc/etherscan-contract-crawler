/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT

// File: Arbitraje/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: Arbitraje/Bot de Arbitraje.sol




pragma solidity ^0.8.19;




interface IPancakeSwapRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

contract Arbitrage {
    address public pancakeSwapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Dirección del contrato inteligente de PancakeSwap Router
    address public tokenAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // Dirección del token a intercambiar
    address public dexAddress = 0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8; // Dirección del otro DEX donde el token es más barato
    IPancakeSwapRouter public pancakeSwapRouter = IPancakeSwapRouter(pancakeSwapRouterAddress); // Interfaz del contrato inteligente PancakeSwap Router
    address public owner;
    uint public numTrades;
    

constructor() {
    owner = msg.sender;
    dexAddress = 0x7DAe51BD3E3376B8c7c4900E9107f12Be3AF1bA8;
}
modifier onlyOwner() {
    require(msg.sender == owner, unicode"Solo el propietario puede llamar a esta función");
    _;
}
struct TradeHistory {
        uint timestamp;
        address tokenBought;
        address tokenSold;
        uint amountBought;
        uint amountSold;
        uint profit;
    }

    TradeHistory[] public tradeHistory;

    function addToTradeHistory(address _tokenBought, address _tokenSold, uint _amountBought, uint _amountSold, uint _profit) internal {
tradeHistory.push(TradeHistory(block.timestamp, _tokenBought, _tokenSold, _amountBought, _amountSold, _profit));
    }

    function getTradeHistoryLength() public view returns (uint) {
        return tradeHistory.length;
    }
    function getNumTradesSince(uint timestamp) public view returns (uint) {
    require(timestamp <= block.timestamp, "Invalid timestamp");
    uint trades = numTrades;
    // Recorremos el registro de operaciones y contamos solo las realizadas después del timestamp
    for (uint i = 0; i < tradeHistory.length; i++) {
        if (tradeHistory[i].timestamp >= timestamp) {
            trades++;
        }
    }
    return trades;
}

    
function startArbitrage(uint amountIn) external onlyOwner{
    address[] memory path = new address[](2);
    path[0] = tokenAddress;
    path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // dirección de WBNB en Binance Smart Chain
    uint[] memory amounts = pancakeSwapRouter.getAmountsOut(amountIn, path);
    uint amountOut = amounts[1];
    
    require(amountOut > 0, 'Amount out must be greater than 0');
    
    // Compra el token en el otro DEX
    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(dexAddress, address(this), amountIn);
    token.approve(address(pancakeSwapRouter), amountIn);
    
    // Intercambia el token por WBNB en PancakeSwap
    uint pancakeFee = amountIn / 100; // calcula el 1% de la cantidad de tokens a intercambiar
    uint amountInWithFee = amountIn - pancakeFee; // ajusta la cantidad de tokens para incluir la tarifa de PancakeSwap
    pancakeSwapRouter.swapExactTokensForTokens(amountInWithFee, amountOut, path, address(this), block.timestamp + 60);
    
    // Vende WBNB por el token en PancakeSwap
    path[0] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // dirección de WBNB en Binance Smart Chain
    path[1] = tokenAddress;
    uint[] memory amountsOut = pancakeSwapRouter.getAmountsOut(amountOut, path);
    pancakeSwapRouter.swapExactTokensForTokens(amountOut, amountsOut[1], path, dexAddress, block.timestamp + 60);
}
function getTokenAmount() public view returns (uint) {
    address[] memory path = new address[](2);
    path[0] = tokenAddress;
    path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // dirección de WBNB en Binance Smart Chain
    uint[] memory amounts = pancakeSwapRouter.getAmountsOut(1 ether, path); // Se asume que 1 BNB = 1 ether
    uint amountOut = amounts[1];
    return amountOut;
}
event TokensWithdrawn(address tokenAddress, uint amount);
function withdrawTokens(address _tokenAddress, uint _amount) external onlyOwner {
    require(_tokenAddress != address(0), "Token address cannot be zero");
    IERC20 token = IERC20(_tokenAddress);
    require(token.balanceOf(address(this)) >= _amount, "Insufficient balance");

    require(token.transfer(msg.sender, _amount), "Token transfer failed");

    emit TokensWithdrawn(_tokenAddress, _amount);
}



}