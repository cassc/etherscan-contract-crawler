// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IHarvestCodeProvider } from "../interfaces/IHarvestCodeProvider.sol";
import { MultiCall } from "../../utils/MultiCall.sol";

contract TestHarvestCodeProvider is MultiCall {
    using SafeERC20 for ERC20;

    function testGetHarvestCodes(
        address _rewardToken,
        address _underlyingToken,
        address _harvestCodeProvider,
        uint256 _rewardTokenAmount
    ) external {
        executeCodes(
            IHarvestCodeProvider(_harvestCodeProvider).getHarvestCodes(
                payable(address(this)),
                _rewardToken,
                _underlyingToken,
                _rewardTokenAmount
            ),
            "harvest"
        );
    }

    function testGetAddLiquidityCodes(
        address _router,
        address _underlyingToken,
        address _harvestCodeProvider
    ) external {
        executeCodes(
            IHarvestCodeProvider(_harvestCodeProvider).getAddLiquidityCodes(
                _router,
                payable(address(this)),
                _underlyingToken
            ),
            "addLiquidity"
        );
    }

    function burnTokens(address _token) external {
        ERC20(_token).safeTransfer(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            ERC20(_token).balanceOf(address(this))
        );
    }
}