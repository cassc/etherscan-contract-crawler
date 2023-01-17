// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IOracle} from "@yield-protocol/vault-v2/contracts/interfaces/IOracle.sol";

import "./ICollateralHandler.sol";
import "../dependencies/ICrabStrategy.sol";
import "../dependencies/IWETH9.sol";

contract CrabHandler is ICollateralHandler {
    using SafeERC20 for ICrabStrategy;

    IWETH9 public constant WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes6 public constant ETH_ID = "00";

    function handle(uint256 amount, address asset, bytes6, ILadle)
        external
        override
        returns (address newAsset, uint256 newAmount)
    {
        ICrabStrategy(asset).safeIncreaseAllowance(asset, amount);
        ICrabStrategy(asset).flashWithdraw(amount, type(uint256).max, 3000);
        newAmount = address(this).balance;
        WETH.deposit{value: newAmount}();
        newAsset = address(WETH);
    }

    function quote(uint256 amount, address, bytes6 ilkId, ILadle ladle)
        external
        view
        override
        returns (address newAsset, uint256 newAmount)
    {
        IOracle oracle = ladle.cauldron().spotOracles(ETH_ID, ilkId).oracle;

        (newAmount,) = oracle.peek(ilkId, ETH_ID, amount);
        newAsset = address(WETH);
    }
}