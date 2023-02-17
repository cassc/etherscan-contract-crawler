// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./interfaces/IPancakePool.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";

contract PancakeYield is Ownable {
    using SafeERC20 for IERC20;
    mapping(address => bool) public allowedManagers;

    modifier onlyManagers {
        require(allowedManagers[msg.sender] == true, "Only Managers");
        _;
    }

    function addManagers(address[] memory newManagers) external onlyOwner {
        for (uint i=0;i<newManagers.length;i++) {
            allowedManagers[newManagers[i]] = true;
        }
    }

    function removeManagers(address[] memory oldManagers) external onlyOwner {
        for (uint i=0;i<oldManagers.length;i++) {
            delete allowedManagers[oldManagers[i]];
        }
    }

    function trade(address router, address[] memory path, uint256[] memory amounts) external onlyManagers {      
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

    function deposit(address token, address pool, uint256 amount) external onlyManagers {
        IERC20(token).approve(pool, amount);
        IPancakePool(pool).deposit(amount);
    }

    function harvest(address pool, uint256 amount) external onlyManagers {
        IPancakePool(pool).withdraw(amount);
    }
   
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        address to = this.owner();
        IERC20(token).transfer(to, amount);
    }
}