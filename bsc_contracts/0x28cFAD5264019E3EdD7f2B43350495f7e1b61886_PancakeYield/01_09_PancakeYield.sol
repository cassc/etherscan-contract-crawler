// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./interfaces/IPancakeFarm.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";

contract PancakeYield is Ownable {
    using SafeERC20 for IERC20;
    mapping(address => bool) public allowedManagers;

    receive() external payable {}

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

    function swapTokens(address router, address[] memory path, uint256[] memory amounts) external onlyManagers {      
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

    function swapForETH(address router,  address[] memory path, uint256[] memory amounts) external onlyManagers {
        require(IERC20(path[0]).balanceOf(address(this)) >= amounts[0], "Not enough path[0] in the contract");
        IERC20(path[0]).approve(address(router), amounts[0]);
        IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amounts[0],
            amounts[1],
            path,
            address(this),
            block.timestamp
        );
    }

    function cakePoolDeposit(address token, address pool, uint256 amount, uint256 lockDuration) external onlyManagers {
        IERC20(token).approve(pool, amount);
        ICakePool(pool).deposit(amount, lockDuration);
    }

    function cakePoolWithdraw(address pool, uint256 shares) external onlyManagers {
        ICakePool(pool).withdraw(shares);
    }
    
    function enableCakeBooster(address factory) external onlyManagers {
        IFarmBoosterProxyFactory(factory).createFarmBoosterProxy();
    }

    function boostDeposit(address proxy, address token, uint256 pid, uint256 tokenAmount) external onlyManagers {
        IERC20(token).approve(address(proxy), tokenAmount);
        ICakeBoost(proxy).deposit(pid, tokenAmount);
    }

    function boostWithdraw(address proxy, uint256 pid, uint256 tokenAmount) external onlyManagers {
        ICakeBoost(proxy).withdraw(pid, tokenAmount);
    }

    function boostActivate(address farmBooster, uint256 pid) external onlyManagers {
        IFarmBooster(farmBooster).activate(pid);
    }

    function boostDectivate(address farmBooster, uint256 pid) external onlyManagers {
        IFarmBooster(farmBooster).deactivate(pid);
    }

    function addLiquidity(address router, address token, uint256 tokenAmount, uint256 ethAmount) external onlyManagers {
        IERC20(token).approve(address(router), tokenAmount);
        IUniswapV2Router01(router).addLiquidityETH{ value: ethAmount }(token, tokenAmount, 0, 0, address(this), block.timestamp);
    }

    function withdrawToken(address token, uint256 amount) external onlyOwner {
        address to = this.owner();
        IERC20(token).transfer(to, amount);
    }
}