// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/ISwapAdapter.sol";

contract ZeroexSwapAdapter is ISwapAdapter, Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant VERSION = 1;

    mapping(address => bool) public routersList;

    event ConfiguredRoutersList(address router, bool olValue, bool newValue);

    /// @dev Configure routers list
    /// @param router Router address to enable
    function configureRoutersList(address router, bool value) external onlyOwner {
        emit ConfiguredRoutersList(router, routersList[router], value);
        routersList[router] = value;
    }

    function setRouterMaxAllowance(address asset, address router) external onlyOwner {
        IERC20Upgradeable(asset).safeApprove(router, 0);
        IERC20Upgradeable(asset).safeApprove(router, type(uint256).max);
    }

    /**
     * @notice swap
     * @param amountToSwap amountToSwap
     * @param swapBytesData swapBytesData
     * @return output amount
     **/
    function swap(address sellingAsset, address buyingAsset, uint256 amountToSwap, bytes memory swapBytesData)  external override returns (uint256) {

        (address approveRouter,,, bytes memory swapBytes) = abi.decode(swapBytesData, (address,address,address,bytes));

        require(routersList[approveRouter], "disabled router address");

        uint256 buyingAssetBalancePrior = IERC20Upgradeable(buyingAsset).balanceOf(address(this));

        IERC20Upgradeable(sellingAsset).safeTransferFrom(msg.sender, address(this), amountToSwap);

        // approve to appropriate router (Note: router is the part of swapBytes data. Do not take from the swap func arg. The function arg is given because for other swaps like 1inch

        (bool success, bytes memory data) = approveRouter.call(swapBytes);

        if(!success){
            assembly {
                let returndata_size := mload(data)
                revert(add(32, data), returndata_size)
            }
        }

        // check balance after swap
        uint256 buyingAssetBalance = IERC20Upgradeable(buyingAsset).balanceOf(address(this));
        uint256 receivedAmount = buyingAssetBalance - buyingAssetBalancePrior;

        IERC20Upgradeable(buyingAsset).safeTransfer(msg.sender, receivedAmount);

        return receivedAmount;
    }

    function sweep(address asset) external onlyOwner {
        uint256 balance = IERC20Upgradeable(asset).balanceOf(address(this));
        IERC20Upgradeable(asset).safeTransfer(owner(), balance);
    }
}