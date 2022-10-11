// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AbstractDynaset.sol";

contract DynasetDydx is AbstractDynaset {
    using SafeERC20 for IERC20;

    constructor(
        address factoryContract,
        address dam,
        address controller_,
        string memory name,
        string memory symbol
    ) AbstractDynaset(factoryContract, dam, controller_, name, symbol) {
    }

    function depositFromDam(address token, uint256 amount) external {
        onlyDigitalAssetManager();
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "ERR_INSUFFICIENT_AMOUNT"
        );
        IERC20(token).safeTransferFrom(
            digitalAssetManager,
            address(this),
            amount
        );
        records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function withdrawToDam(address token, uint256 amount) external {
        onlyDigitalAssetManager();
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "ERR_INSUFFICIENT_AMOUNT"
        );
        IERC20(token).safeTransfer(digitalAssetManager, amount);
        records[token].balance = IERC20(token).balanceOf(address(this));
    }
}