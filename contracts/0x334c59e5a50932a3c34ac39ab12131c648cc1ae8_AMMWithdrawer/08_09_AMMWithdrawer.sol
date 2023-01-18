// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {TokenAddresses} from "./TokenAddresses.sol";
import {AaveV2Ethereum} from "@aave-address-book/AaveV2Ethereum.sol";
import {AaveV2EthereumAMM} from "@aave-address-book/AaveV2EthereumAMM.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract AMMWithdrawer {
    using SafeERC20 for IERC20;

    /// Withdraw AMM tokens from Aave V2 Collector Contract
    function redeem() external {
        address[5] memory aAmmTokens = TokenAddresses.getaAMMTokens();
        address[5] memory tokens = TokenAddresses.getaAMMEquivalentTokens();

        uint256 length = aAmmTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            address aAmmToken = aAmmTokens[i];
            uint256 amount = IERC20(aAmmToken).balanceOf(address(this));

            if (amount == 0) {
                continue;
            }

            AaveV2EthereumAMM.POOL.withdraw(tokens[i], type(uint256).max, AaveV2Ethereum.COLLECTOR);
        }
    }
}