// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./util/Ownable.sol";
import "./util/ReentrancyGuard.sol";
import "./util/SafeERC20Upgradeable.sol";
import "./interface/INFTXVaultFactory.sol";
import "./interface/INFTXVault.sol";
import "./interface/IUniswapV2Router01.sol";
import "./token/IWETH.sol";
import "./NFTXInventoryStaking.sol";

contract NFTXUnstakingInventoryZap is Ownable, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    INFTXVaultFactory public vaultFactory;
    NFTXInventoryStaking public inventoryStaking;
    IUniswapV2Router01 public sushiRouter;
    IWETH public weth;

    event InventoryUnstaked(
        uint256 vaultId,
        uint256 xTokensUnstaked,
        uint256 numNftsRedeemed,
        address unstaker
    );

    function setVaultFactory(address addr) public onlyOwner {
        vaultFactory = INFTXVaultFactory(addr);
    }

    function setInventoryStaking(address addr) public onlyOwner {
        inventoryStaking = NFTXInventoryStaking(addr);
    }

    function setSushiRouterAndWeth(address sushiRouterAddr) public onlyOwner {
        sushiRouter = IUniswapV2Router01(sushiRouterAddr);
        weth = IWETH(sushiRouter.WETH());
    }

    /**
     * @param remainingPortionToUnstake Represents the ratio (in 1e18) of the remaining xTokens (left after claiming `numNfts`) balance of user to unstake
     * if remainingPortionToUnstake = 1e18 => unstake entire user's balance
     * if remainingPortionToUnstake = 0 => only unstake required xToken balance to claim `numNfts`, nothing extra
     */
    function unstakeInventory(
        uint256 vaultId,
        uint256 numNfts,
        uint256 remainingPortionToUnstake
    ) public payable {
        require(remainingPortionToUnstake <= 1e18);
        IERC20Upgradeable vToken = IERC20Upgradeable(
            vaultFactory.vault(vaultId)
        );
        IERC20Upgradeable xToken = IERC20Upgradeable(
            inventoryStaking.xTokenAddr(address(vToken))
        );

        uint256 reqVTokens = numNfts * 1e18;

        // calculate `xTokensToPull` to pull
        uint256 xTokensToPull;
        uint256 xTokenUserBal = xToken.balanceOf(msg.sender);
        if (remainingPortionToUnstake == 1e18) {
            xTokensToPull = xTokenUserBal;
        } else {
            uint256 shareValue = inventoryStaking.xTokenShareValue(vaultId); // vTokens per xToken in wei
            uint256 reqXTokens = (reqVTokens * 1e18) / shareValue;

            // Check for rounding error being 1 less that expected amount
            if ((reqXTokens * shareValue) / 1e18 < reqVTokens) {
                reqXTokens += 1;
            }

            // If the user doesn't have enough xTokens then we just want to pull the
            // balance of the user.
            if (xTokenUserBal < reqXTokens) {
                xTokensToPull = xTokenUserBal;
            }
            // If we have zero additional portion to unstake, then we only need to pull the required tokens
            else if (remainingPortionToUnstake == 0) {
                xTokensToPull = reqXTokens;
            }
            // Otherwise, calculate remaining xTokens to unstake using `remainingPortionToUnstake` ratio
            else {
                uint256 remainingXTokens = xToken.balanceOf(msg.sender) -
                    reqXTokens;
                xTokensToPull =
                    reqXTokens +
                    ((remainingXTokens * remainingPortionToUnstake) / 1e18);
            }
        }

        // pull xTokens then unstake for vTokens
        xToken.safeTransferFrom(msg.sender, address(this), xTokensToPull);

        // If our inventory staking contract has an allowance less that the amount we need
        // to pull, then we need to approve additional tokens.
        if (
            xToken.allowance(address(this), address(inventoryStaking)) <
            xTokensToPull
        ) {
            xToken.approve(address(inventoryStaking), type(uint256).max);
        }

        uint256 initialVTokenBal = vToken.balanceOf(address(this));
        // Burn our xTokens to pull in our vTokens
        inventoryStaking.withdraw(vaultId, xTokensToPull);
        uint256 vTokensReceived = vToken.balanceOf(address(this)) -
            initialVTokenBal;

        uint256 missingVToken;

        // If the amount of vTokens generated from our `inventoryStaking.withdraw` call
        // is not sufficient to fulfill the claim on the specified number of NFTs, then
        // we determine if we can claim some dust from the contract.
        if (vTokensReceived < reqVTokens) {
            // We can calculate the amount of vToken required by the contract to get
            // it from the withdrawal amount to the amount required based on the number
            // of NFTs.
            missingVToken = reqVTokens - vTokensReceived;

            /**
             * reqVTokens = 1e18
             * initialVTokenBal = 2
             * vToken.balanceOf(address(this)) = 1000000000000000001
             *
             * 1000000000000000000 - (1000000000000000001 - 2) = 1
             */
        }

        // This dust value has to be less that 100 to ensure we aren't just being rinsed
        // of dust.
        require(missingVToken < 100, "not enough vTokens");

        uint256 dustUsed;
        if (missingVToken > initialVTokenBal) {
            // If user has sufficient vTokens to account for missingVToken
            // then get it from them to this contract
            if (
                vToken.balanceOf(msg.sender) >= missingVToken &&
                vToken.allowance(msg.sender, address(this)) >= missingVToken
            ) {
                vToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    missingVToken
                );
            } else {
                // else we swap ETH from this contract to get `missingVToken`
                address[] memory path = new address[](2);
                path[0] = address(weth);
                path[1] = address(vToken);
                sushiRouter.swapETHForExactTokens{value: 1_000_000_000}(
                    missingVToken,
                    path,
                    address(this),
                    block.timestamp
                );
            }
        } else {
            dustUsed = missingVToken;
        }

        // reedem NFTs with vTokens, if requested
        if (numNfts > 0) {
            INFTXVault(address(vToken)).redeemTo(
                numNfts,
                new uint256[](0),
                msg.sender
            );
        }

        /**
         * How this fixes underflow error:
         * vToken.balanceOf(address(this)) = 1
         * initialVTokenBal = 2
         * dustUsed = missingVToken = 1
         * vTokenRemainder = 1 - (2 - 1) = 0
         */
        uint256 vTokenRemainder = vToken.balanceOf(address(this)) -
            (initialVTokenBal - dustUsed);

        // if vToken remainder more than dust then return to sender.
        // happens when `remainingPortionToUnstake` is non-zero
        if (vTokenRemainder > 100) {
            vToken.safeTransfer(msg.sender, vTokenRemainder);
        }

        emit InventoryUnstaked(vaultId, xTokensToPull, numNfts, msg.sender);
    }

    function maxNftsUsingXToken(
        uint256 vaultId,
        address staker,
        address slpToken
    ) public view returns (uint256 numNfts, bool shortByTinyAmount) {
        if (inventoryStaking.timelockUntil(vaultId, staker) > block.timestamp) {
            return (0, false);
        }
        address vTokenAddr = vaultFactory.vault(vaultId);
        address xTokenAddr = inventoryStaking.xTokenAddr(vTokenAddr);
        IERC20Upgradeable vToken = IERC20Upgradeable(vTokenAddr);
        IERC20Upgradeable xToken = IERC20Upgradeable(xTokenAddr);
        IERC20Upgradeable lpPair = IERC20Upgradeable(slpToken);

        uint256 xTokenBal = xToken.balanceOf(staker);
        uint256 shareValue = inventoryStaking.xTokenShareValue(vaultId);
        uint256 vTokensA = (xTokenBal * shareValue) / 1e18;
        uint256 vTokensB = ((xTokenBal * shareValue) / 1e18) + 99;

        uint256 vTokensIntA = vTokensA / 1e18;
        uint256 vTokensIntB = vTokensB / 1e18;

        if (vTokensIntB > vTokensIntA) {
            if (
                vToken.balanceOf(msg.sender) >= 99 &&
                vToken.allowance(msg.sender, address(this)) >= 99
            ) {
                return (vTokensIntB, true);
            } else if (lpPair.totalSupply() >= 10000) {
                return (vTokensIntB, true);
            } else if (vToken.balanceOf(address(this)) >= 99) {
                return (vTokensIntB, true);
            } else {
                return (vTokensIntA, false);
            }
        } else {
            return (vTokensIntA, false);
        }
    }

    receive() external payable {}

    function rescue(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = payable(msg.sender).call{
                value: address(this).balance
            }("");
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
        } else {
            IERC20Upgradeable(token).safeTransfer(
                msg.sender,
                IERC20Upgradeable(token).balanceOf(address(this))
            );
        }
    }
}