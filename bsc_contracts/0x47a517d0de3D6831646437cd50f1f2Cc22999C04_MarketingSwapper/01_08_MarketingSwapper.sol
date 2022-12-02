//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./Governance.sol";
import "./IPancakeV2Router02.sol";

contract MarketingSwapper is Ownable, Governance {
    IERC20 public token;
    using SafeMath for uint256;
    address payable public marketingWallet;
    uint256 amountToSwap = 100_000 * 10**18;

    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;

    event SET_TOKEN(address token);

    constructor(IERC20 _token, address _wallet){
        token = _token;
        marketingWallet = payable(_wallet);
    }

    function setRouter(address _router) public onlyOwner {
        pancakeV2Router = IPancakeV2Router02(_router);
    }

    receive() external payable {}

    function setPair(address _pair) public onlyOwner {
        pancakeV2Pair = _pair;
    }

    function setWallet(address _address) public onlyOwner {
        marketingWallet = payable(_address);
    }

    function changeTokenAddress(address _token) public onlyOwner {
        token = IERC20(_token);
        emit SET_TOKEN(_token);
    }

    function checkSwapAction() public onlyGovernance {
        if (token.balanceOf(address(this)) > amountToSwap) {
            uint256 _marketingAmount = token.balanceOf(address(this));
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(_marketingAmount);
            uint256 newBalance = address(this).balance.sub(initialBalance);
            if (newBalance > 0) {
                marketingWallet.transfer(newBalance);
            }
        }
    }

    function withdrawToken() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(marketingWallet, balance);
    }

    function withdraw() public onlyOwner {
        uint256 bnbBalance = address(this).balance;
        marketingWallet.transfer(bnbBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = pancakeV2Router.WETH();

        token.approve(address(pancakeV2Router), tokenAmount);

        // make the swap
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}