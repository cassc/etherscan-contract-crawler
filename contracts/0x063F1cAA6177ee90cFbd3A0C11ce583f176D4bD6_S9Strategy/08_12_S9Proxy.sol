import "../interfaces/IERC20.sol";
import "../interfaces/IRibbonVault.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IMinter.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract S9Proxy {
    address deployer;
    address user;
    address minter = 0x5B0655F938A72052c46d2e94D206ccB6FF625A3A;
    address rbn = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;

    constructor(address user_) {
        deployer = msg.sender;
        user = user_;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "onlyDeployer: Unauthorized");
        _;
    }

    function deposit(
        address vault,
        address inputToken,
        uint256 amount
    ) external onlyDeployer {
        IERC20(inputToken).approve(vault, amount);
        IRibbonVault(vault).deposit(amount);
    }

    function queueWithdraw(address vault, uint256 amount)
        external
        onlyDeployer
    {
        address gauge = IRibbonVault(vault).liquidityGauge();
        (uint256 heldByAccount, uint256 heldByVault) = IRibbonVault(vault)
            .shareBalances(address(this));
        uint256 balance = heldByAccount + heldByVault;
        if (amount > balance) {
            uint256 gaugeBalance = IERC20(gauge).balanceOf(address(this));
            if (gaugeBalance > 0) {
                uint256 withdrawAmt = gaugeBalance > amount - balance
                    ? amount - balance
                    : gaugeBalance;
                IGauge(gauge).withdraw(withdrawAmt);
                balance += withdrawAmt;
            }
        } else {
            balance = amount;
        }
        //max redeem done internally
        IRibbonVault(vault).initiateWithdraw(balance);
    }

    function withdraw(
        address vault,
        address vaultAsset,
        //in token
        uint256 requestAmtToken,
        uint256 instantAvaliable
    ) external onlyDeployer returns (uint256) {
        uint256 balance = _withdraw(
            vault,
            vaultAsset,
            requestAmtToken,
            instantAvaliable
        );
        IERC20(vaultAsset).transfer(deployer, balance);
        return balance;
    }

    function stake(address vault, uint256 shares) external onlyDeployer {
        IRibbonVault(vault).stake(shares);
    }

    function claim(address gauge, address to)
        external
        onlyDeployer
        returns (uint256)
    {
        IMinter(minter).mint(gauge);
        uint256 balance = IERC20(rbn).balanceOf(address(this));
        IERC20(rbn).transfer(to, balance);
        return balance;
    }

    function emergencyWithdraw(
        address vault,
        address vaultAsset,
        uint256 instantAvaliable
    ) external onlyDeployer {
        uint256 balance = _withdraw(
            vault,
            vaultAsset,
            2**256 - 1,
            instantAvaliable
        );
        IERC20(vaultAsset).transfer(user, balance);
    }

    function _withdraw(
        address vault,
        address vaultAsset,
        //in token
        uint256 requestAmtToken,
        uint256 instantAvaliable
    ) internal returns (uint256) {
        uint256 balance;
        //Prioritize withdrawing non yielding funds
        //withdraws vaultAsset that was previously initiateWithdraw
        IRibbonVault(vault).completeWithdraw();
        balance = IERC20(vaultAsset).balanceOf(address(this));
        //Withdraw from current deposit that has not been sent to vault
        if (balance < requestAmtToken && instantAvaliable > 0) {
            //withdraw the difference, up to the requested amount
            //will revert R32 if withdrawInstantly round is current round
            //will revert R33 if insufficient
            uint256 withdrawInstantAmt = instantAvaliable >
                requestAmtToken - balance
                ? requestAmtToken - balance
                : instantAvaliable;
            IRibbonVault(vault).withdrawInstantly(withdrawInstantAmt);
            balance = IERC20(vaultAsset).balanceOf(address(this));
        }
        return balance;
    }
}