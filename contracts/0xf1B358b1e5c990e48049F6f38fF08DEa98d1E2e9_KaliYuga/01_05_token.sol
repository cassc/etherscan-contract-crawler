// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract KaliYuga is ERC20 {
    uint256 supply;
    uint256 maxWallet;
    bool tradingOpen;
    address owner;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    constructor() ERC20("KaliYuga", "KaliYuga") {
        supply = 1 * 1e6 * 1e18; // 1 000 000 tokens, 18 decimal
        maxWallet = supply * 10 / 1000; // 1%
        owner = msg.sender;
        _mint(msg.sender, supply);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    }
    

    function setTrading(bool _state) public onlyOwner() {
        tradingOpen = _state;
    }

    function getTradingStatus() public view returns(bool) {
        return tradingOpen;
    }

    function setMaxWallet(uint256 _amount) public onlyOwner() {
        maxWallet = _amount;
    }

    function getMaxWallet() public view returns(uint) {
        return maxWallet;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override { 
        if (from != owner && to != owner) { 
            require(tradingOpen, "Trading not open yet");
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }
        }

        super._transfer(from, to, amount);

    }


}