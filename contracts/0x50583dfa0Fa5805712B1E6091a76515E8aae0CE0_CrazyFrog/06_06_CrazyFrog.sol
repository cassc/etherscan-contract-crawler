// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);    
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract CrazyFrog is ERC20, Ownable {
	uint256 private _totalSupply = 5 * 10**14 * 10**18;		// Total Supply: 500,000,000,000,000

	bool private publicSale = false;
    mapping (address => bool) private whitelist;            // white list allowed to buy at private sale.

	IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    mapping (address => bool) private automatedMarketMakerPairs;

	constructor() ERC20("Crazy Frog", "CF") {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        setWhitelist();

        _mint(msg.sender, _totalSupply);
    }

    function setWhitelist() internal {
        whitelist[0x36497bEAd8F2F7aD88DbB3402AF4e67c8307E4A0] = true;
        whitelist[0x60d17E56d2c9672A466Bd2234fA39bF305DdBae0] = true;
        whitelist[0xFD6105ee2e9991E389397Db1c4c56F99D0cCDb48] = true;
        whitelist[0x16f5500c0A3aF2EC46DF268A0Cde0F58C49C3783] = true;
        whitelist[0xcf2366215c69eAf5eb60DBb3eFf67F5f34769ab7] = true;
        whitelist[0x79C35E7E3d4E123Ee80593268E79D7Dd8d125a43] = true;
        whitelist[0xCF0A5490453f11848Df1f6A545FDA730100dE270] = true;
        whitelist[0x59C22bd89D0D401e1C98B1Fa96A3dc318CbBe049] = true;
        whitelist[0xa6f30e1364e56EA7413cacE7e88d05Be9a277d1c] = true;
        whitelist[0xa9CfC25cEbAf8C46Ddf672F8D4BF1D68C96f1A52] = true;
        whitelist[0x3c4706829Bbb1189d7Baa5924397B6DE17fA5438] = true;
        whitelist[0xa625141E73AB1af1B57EFBbad9Ba9aB8813393e3] = true;
        whitelist[0x0F84b6FdBd02820A18018663fCd2C9584c03185d] = true;
        whitelist[0x3BfD635aDc7C1a491a1a63C7d38ED64198f7f620] = true;
    }

    function enablePublicSale() external onlyOwner() {
        publicSale = true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The uniswap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()) { // No owner transaction
	        // Check tradable
	        if (automatedMarketMakerPairs[from] && !publicSale) { // Allow white list only in public sale.
                require(whitelist[to], "No public sale.");
	        }
        }

        super._transfer(from, to, amount);
    }
}