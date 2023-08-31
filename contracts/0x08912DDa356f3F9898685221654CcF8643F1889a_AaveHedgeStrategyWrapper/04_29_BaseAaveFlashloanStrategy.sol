// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {BaseFlashloanStrategy} from "./BaseFlashloanStrategy.sol";
import {IAavePool} from "contracts/interfaces/ext/aave/IAavePool.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseAaveFlashloanStrategy is BaseFlashloanStrategy {
    using SafeERC20 for IERC20;

    IAavePool private immutable aavePool;

    constructor(IAavePool _aavePool) {
        aavePool = _aavePool;
    }

    function _takeFlashloan(address asset, uint256 amount, bytes memory data) internal override {
        aavePool.flashLoanSimple(address(this), asset, amount, data, 0);
    }

    // called by Aave pool
    function executeOperation(address asset, uint256 amount, uint256 premium, address _initiator, bytes calldata data)
        external
        returns (bool)
    {
        require(msg.sender == address(aavePool), "invalid flashloan caller");
        require(_initiator == address(this), "invalid flashloan initiator");

        uint256 amountOwed = amount + premium;

        _insideFlashloan(asset, amount, amountOwed, data);

        IERC20(asset).safeIncreaseAllowance(address(aavePool), amountOwed);

        return true;
    }
}