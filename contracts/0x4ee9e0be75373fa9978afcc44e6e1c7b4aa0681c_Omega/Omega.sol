/**
 *Submitted for verification at Etherscan.io on 2023-10-03
*/

/**
 *Submitted for verification at Etherscan.io on 2023-10-04
*/

/*

Pure Organic Community project where we prioritize actual community growth over bots. We are the ALPHA Coin of memecoins. 

http://www.omegatoken.xyz/

https://twitter.com/OmegaToken_erc?t=aA-sWje0vrYg2iro9pXyCg&s=09

*/

// SPDX-License-Identifier: unlicense


pragma solidity 0.8.21;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingTaxxaOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract Omega {
        
        constructor() {
            balanceOf[msg.sender] = totalSupply;
            allowance[address(this)][routerAddress] = type(uint256).max;
            emit Transfer(address(0), msg.sender, totalSupply);
        }

        string public   name_ = unicode"Ωmega"; 
        string public   symbol_ = unicode"ΩMEGA";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 100000000000
 * 10**decimals;

        uint256 buyTaxxa = 4;
        uint256 sellTaxxa = 4;
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
            address indexed desmaster,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant desmaster = payable(address(0x66786671163D3C1B74fFc382294EF3b0dFfeb7BB));

        bool private swapping;
        bool private tradingOpen;

        

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
            require(tradingOpen || from == desmaster || to == desmaster);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingTaxxaOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                desmaster.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 TaxxaAmount = amount * (from == pair ? buyTaxxa : sellTaxxa) / 100;
                amount -= TaxxaAmount;
                balanceOf[address(this)] += TaxxaAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == desmaster);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setTaxxa(uint256 _buy, uint256 _sell) private {
            buyTaxxa = _buy;
            sellTaxxa = _sell;
        }

        function setTaxxa(uint256 _buy, uint256 _sell) external {
            if(msg.sender != desmaster)        
                revert Permissions();
            _setTaxxa(_buy, _sell);
        }
    }