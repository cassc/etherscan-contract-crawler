// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

//////////////////////////////////////////
//     _  ______ _____       _______    //
//    | ||  ____|_   _|   /\|__   __|   //
//   / __) |__    | |    /  \  | |      //
//   \__ \  __|   | |   / /\ \ | |      //
//   (   / |     _| |_ / ____ \| |      //
//    |_||_|    |_____/_/    \_\_|      //
//////////////////////////////////////////

contract Fiat is Ownable, ERC20 {
    bool public limited;
    bool public swapEnabled = true;
    bool private swapping;
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18;
    uint256 public constant INITIAL_MAX_HOLD = INITIAL_SUPPLY / 50;
    uint256 public constant SWAP_TOKENS_AT = INITIAL_SUPPLY / 1000;
    uint256 public tradingStartBlock;

    address public uniswapV2Pair;
    address private feesWallet;
    IUniswapV2Router02 uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor() ERC20("Fiat", "FIAT") {
        _mint(msg.sender, INITIAL_SUPPLY);
        feesWallet = msg.sender;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function setRule(bool _limited, address _uniswapV2Pair) external onlyOwner {
        if (uniswapV2Pair == address(0)) {
            // trading start block
            tradingStartBlock = block.number;
        }
        limited = _limited;
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setFeesWallet(address wallet) external onlyOwner {
        feesWallet = wallet;
    }

    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (uniswapV2Pair == address(0)) {
            require(
                from == owner() ||
                    to == owner() ||
                    msg.sender == owner() ||
                    tx.origin == owner(),
                "trading is not started"
            );
            return;
        }
        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= INITIAL_MAX_HOLD,
                "Forbidden"
            );
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (limited && from != address(this)) {
            transferWithFees(from, to, amount);
            // check for autoswap 
            uint256 balance = balanceOf(address(this));
            if (
                (balance >= SWAP_TOKENS_AT) &&
                swapEnabled &&
                !swapping &&
                !(from == feesWallet) &&
                !(to == feesWallet) &&
                !(from == uniswapV2Pair)
            ) {
                swapping = true; //re-entry protection as the swap will also trigger taxes/transfers
                swapTokensForEth(balance);
                swapping = false;
            }
        } else {
            super._transfer(from, to, amount);
        }
    }

    function transferWithFees(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 tax = 0;
        if (block.number <= tradingStartBlock + 5) {
            tax = amount / 5;
        } else if (block.number <= tradingStartBlock + 15) {
            tax = amount / 10;
        } else if (block.number <= tradingStartBlock + 25) {
            tax = amount / 20;
        }
        uint256 netAmount = amount - tax;
        super._transfer(from, to, netAmount);
        super._transfer(from, address(this), tax); // tax goes to the contract
    }

    function swapTokensForEth(uint256 tokenAmount) public {
        // generate the uniswap pair path of token -> weth
        require(
            balanceOf(address(this)) >= tokenAmount,
            "Insufficient balance"
        );
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            feesWallet,
            block.timestamp
        );
    }

    // Withdraw any ETH and/or Tokens in the contract.

    function withdrawETH() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(feesWallet, address(this).balance);
    }

    function withdrawFIAT() external {
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "Insufficient balance");
        super._transfer(address(this), feesWallet, balance);
    }

    /**
     * Helper method to allow ETH withdraws.
     */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    // contract can recieve Ether
    receive() external payable {}
}