// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AutoCompound is AccessControl {
    bytes32 public constant COMPOUNDER_ROLE = keccak256("COMPOUNDER_ROLE");

    address public tokenAddress;
    IUniswapV2Router02 public immutable uniswapV2Router;

    struct DistributeReward {
        address wallet;
        uint ethValue;
    }

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(COMPOUNDER_ROLE, msg.sender);
    }

    function compound(DistributeReward[] memory rewards) public onlyRole(COMPOUNDER_ROLE) payable {
        uint totalEth;
        for (uint i; i < rewards.length; i++) {
            totalEth += rewards[i].ethValue;
        }

        require(totalEth == msg.value, "Error: Invalid ether value");

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        IERC20 token = IERC20(tokenAddress);
        uint balance = token.balanceOf(address(this));

        for (uint i; i < rewards.length; i++) {
            token.transfer(rewards[i].wallet, balance * rewards[i].ethValue / totalEth);
        }
    }
}