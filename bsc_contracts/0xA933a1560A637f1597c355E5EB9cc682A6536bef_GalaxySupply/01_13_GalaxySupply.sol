// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IERC4626.sol";
import "./interfaces/IERC20.sol";
import  "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IVenusProtocol.sol";
import "./interfaces/IGalaxyHolding.sol";
import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";

contract GalaxySupply is Ownable {
    using SafeERC20 for IERC20;
    mapping(address => bool) public allowedManagers;
    address allowedPairAddress = address(1);

    struct CallbackData {
        bool minting;
        address pool;
        address vault;
        address borrowedToken;
        uint256 amount;
    }

    modifier onlyManagers {
        require(allowedManagers[msg.sender] == true, "Only Managers");
        _;
    }

    function addManagers(address[] memory newManagers) public onlyOwner {
        for (uint i=0;i<newManagers.length;i++) {
            allowedManagers[newManagers[i]] = true;
        }
    }

    function removeManagers(address[] memory oldManagers) public onlyOwner {
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

    function supply(address token, address vault, uint256 amount) public onlyManagers {
        IERC20(token).approve(vault, amount);
        IVenusToken(vault).mint(amount);
    }

    function redeem(address vault, uint256 amount) public onlyManagers {
        IVenusToken(vault).redeem(amount);
    }

    function borrow(address vault, uint256 amount) public onlyManagers {
        IVenusToken(vault).borrow(amount);
    }

    function repayBorrow(address token, address vault, uint256 amount) public onlyManagers {
        IERC20(token).approve(vault, amount);
        IVenusToken(vault).repayBorrow(amount);
    }

    function claim(address unitroller) public onlyManagers {
       IVenusUnitroller(unitroller).claimVenus(address(this));
    }

    function enterMarkets(address unitroller, address[] calldata vTokens) public onlyManagers {
       IVenusUnitroller(unitroller).enterMarkets(vTokens);
    }

    function vaultDeposit(address token, address vaultToken, uint256 amount) public onlyManagers {
        IERC20(token).approve(vaultToken, amount);
        IERC4626(vaultToken).deposit(amount, address(this));
    }

    function redeemUnderlying(address vaultToken, uint256 amount) public onlyManagers {
        IERC4626(vaultToken).redeem(amount, address(this), address(this));
    }

    function takeLoan(address holdingContract, address vaultToken, uint256 amount) public onlyManagers {
        IGalaxyHolding(holdingContract).takeLoan(vaultToken, amount);
    }

    function loanPayment(address holdingContract, address vaultToken, address loanContract, uint256 amount) public onlyManagers {
        IERC20(vaultToken).approve(holdingContract, amount);
        IGalaxyHolding(holdingContract).loanPayment(vaultToken, loanContract, amount);
    }

    fallback() external {
        (address sender, 
         uint256 amount0, 
         uint256 amount1, 
         bytes memory data) = abi.decode(msg.data[4:], 
            (address, 
             uint256, 
             uint256, 
             bytes));
        _callback(sender, amount0, amount1, data);
    }

    function _callback(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes memory data
    ) internal {
        require(msg.sender == allowedPairAddress, "Not an allowed address");
        require(sender == address(this), "Not from this contract");
        CallbackData memory details = abi.decode(data, (CallbackData));
        uint256 borrowedAmount = amount0 > 0 ? amount0 : amount1;
        uint256 totalAmount = borrowedAmount + details.amount;
        uint256 fee = ((borrowedAmount * 3) / 997) + 1;
        uint256 repayAmount = borrowedAmount + fee;
        uint256 venusAmount = borrowedAmount + details.amount - fee;
        if (details.minting) {
            IERC20(details.borrowedToken).approve(details.vault, totalAmount);
            IVenusToken(details.vault).mint(venusAmount);
            IVenusToken(details.vault).borrow(borrowedAmount);
        } else {
            IERC20(details.borrowedToken).approve(details.vault, borrowedAmount);
            IVenusToken(details.vault).repayBorrow(borrowedAmount);
            IVenusToken(details.vault).redeem(details.amount);
        }
        IERC20(details.borrowedToken).safeTransfer(details.pool, repayAmount);
        allowedPairAddress = address(1);
    }

    function _setupFlash(
        bool minting,
        address pool, 
        address vault, 
        address borrowedToken, 
        uint256 loanAmount, 
        uint256 amount) internal {
            allowedPairAddress = pool;
            CallbackData memory callbackData;
            callbackData.minting = minting;
            callbackData.pool = pool;
            callbackData.vault = vault;
            callbackData.borrowedToken = borrowedToken;
            callbackData.amount = amount;
            bytes memory flash = abi.encode(callbackData);
            uint256 amount0Out = borrowedToken == IUniswapV2Pair(pool).token0() ? loanAmount : 0;
            uint256 amount1Out = borrowedToken == IUniswapV2Pair(pool).token1() ? loanAmount : 0;
            IUniswapV2Pair(pool).swap(
                amount0Out,
                amount1Out,
                address(this),
                flash
            );
    }

    function amplify(address pool, address vault, address borrowedToken, uint256 loanAmount, uint256 depositAmount) external onlyManagers {
        _setupFlash(true, pool, vault, borrowedToken, loanAmount, depositAmount);
    }

    function compress(address pool, address vault, address borrowedToken, uint256 loanAmount, uint256 redeemAmount) external onlyManagers {
        _setupFlash(false, pool, vault, borrowedToken, loanAmount, redeemAmount);
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