// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ICollateralHandler.sol";
import "../dependencies/IYearnVault.sol";

contract YearnHandler is ICollateralHandler {
    function handle(uint256, address asset, bytes6, ILadle)
        external
        override
        returns (address newAsset, uint256 newAmount)
    {
        newAmount = IYearnVault(asset).withdraw();
        newAsset = IYearnVault(asset).token();
    }

    function quote(uint256 amount, address asset, bytes6, ILadle)
        external
        view
        override
        returns (address newAsset, uint256 newAmount)
    {
        uint256 decimals = IERC20Metadata(asset).decimals();
        newAmount = (IYearnVault(asset).pricePerShare() * amount) / (10 ** decimals);
        newAsset = IYearnVault(asset).token();
    }
}