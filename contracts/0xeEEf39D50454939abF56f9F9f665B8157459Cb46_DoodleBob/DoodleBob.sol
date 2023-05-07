/**
 *Submitted for verification at Etherscan.io on 2023-05-06
*/

// DoodleBob - The SpongeBob killer

// Twitter:  https://twitter.com/doodlebobtoken
// Telegram:  https://t.me/DoodleBobTokenPortal
// Web:  https://doodlebobtoken.com/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract DoodleBob {
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    string public constant name = "DoodleBob";  
    string public constant symbol = "DOODLE";  
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 40_400_000_001 * 10**decimals;
    address public owner;

    uint256 buyTax = 3;
    uint256 sellTax = 5;
    uint256 constant swapAmount = totalSupply / 200;
    uint256 constant maxWallet = 2 * totalSupply / 100;

    bool tradingOpened = false;
    bool swapping;

    address immutable pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    constructor() {
        owner = msg.sender;
        pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), ETH);
        allowance[address(this)][routerAddress] = type(uint256).max;

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) external returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool){
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool){
        allowance[from][msg.sender] -= amount;        
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool){
        balanceOf[from] -= amount;

        bool renounced = owner == address(0);
        if(!renounced){
            if(from != owner)
                require(tradingOpened);
            if(to != pair && to != owner)
                require(balanceOf[to] + amount <= maxWallet);

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                payable(owner).transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 taxAmount = amount * (from == pair ? buyTax : sellTax) / 100;
                if(taxAmount > 0){
                    amount -= taxAmount;
                    balanceOf[address(this)] += taxAmount;
                    emit Transfer(from, address(this), taxAmount);
                }
            }
        }

        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function openTrading() external onlyOwner {
        tradingOpened = true;
    }

    function renounceOwnership() external onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    function setFees(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }
}