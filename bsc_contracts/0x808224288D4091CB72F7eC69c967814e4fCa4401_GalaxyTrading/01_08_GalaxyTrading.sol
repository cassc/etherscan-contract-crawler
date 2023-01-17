// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IERC4626.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IGalaxyHolding.sol";
import "./utils/Ownable.sol";

contract GalaxyTrading is Ownable {
    mapping(address => bool) public allowedTraders;

    modifier onlyTraders {
        require(allowedTraders[msg.sender] == true, "Only Traders");
        _;
    }

    function trade(address router, address[] memory path, uint256[] memory amounts) external onlyTraders {      
        require(IERC20(path[0]).balanceOf(address(this)) >= amounts[0], "Not enough path[0] in the contract");
        IERC20(path[0]).approve(address(router), amounts[0]);
        IUniswapV2Router01(router).swapExactTokensForTokens(
            amounts[0],
            amounts[1],
            path,
            address(this),
            block.timestamp
        );
    }

    function redeemUnderlying(address vaultToken, uint256 amount) public onlyTraders {
        IERC4626(vaultToken).redeem(amount, address(this), address(this));
    }

    function vaultDeposit(address token, address vaultToken, uint256 amount) public onlyTraders {
        IERC20(token).approve(vaultToken, amount);
        IERC4626(vaultToken).deposit(amount, address(this));
    }

    function takeLoan(address holdingContract, address vaultToken, uint256 amount) public onlyTraders {
        IGalaxyHolding(holdingContract).takeLoan(vaultToken, amount);
    }

    function loanPayment(address holdingContract, address vaultToken, address loanContract, uint256 amount) public onlyTraders {
        IERC20(vaultToken).approve(holdingContract, amount);
        IGalaxyHolding(holdingContract).loanPayment(vaultToken, loanContract, amount);
    }

    function addTraders(address[] memory newTrader) public onlyOwner {
        for (uint i=0;i<newTrader.length;i++) {
            allowedTraders[newTrader[i]] = true;
        }
    }

    function removeTraders(address[] memory oldTrader) public onlyOwner {
        for (uint i=0;i<oldTrader.length;i++) {
            delete allowedTraders[oldTrader[i]];
        }
    }

    function withdrawToken(address token, uint256 amount) public onlyOwner {
        address to = this.owner();
        IERC20(token).transfer(to, amount);
    }

    function migrateTokens(address[] memory tokens, address newContract) public onlyOwner {
        for (uint256 i=0;i<tokens.length;i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            IERC20(tokens[i]).transfer(newContract, balance);
        }
    }
}