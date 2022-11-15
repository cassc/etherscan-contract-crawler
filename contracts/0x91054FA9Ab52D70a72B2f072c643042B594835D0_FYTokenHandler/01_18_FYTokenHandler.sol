// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import "./ICollateralHandler.sol";

contract FYTokenHandler is ICollateralHandler {
    using SafeERC20 for IERC20;

    function handle(uint256 amount, address asset, bytes6 ilkId, ILadle ladle)
        external
        override
        returns (address newAsset, uint256 newAmount)
    {
        IFYToken fyToken = IFYToken(asset);
        newAsset = fyToken.underlying();

        // solhint-disable-next-line not-rely-on-time
        if (fyToken.maturity() > block.timestamp) {
            IPool pool = IPool(ladle.pools(ilkId));
            IERC20(asset).safeTransfer(address(pool), amount);
            newAmount = pool.sellFYToken(address(this), 0);
        } else {
            newAmount = fyToken.redeem(address(this), amount);
        }
    }

    function quote(uint256 amount, address asset, bytes6 ilkId, ILadle ladle)
        external
        view
        override
        returns (address newAsset, uint256 newAmount)
    {
        IFYToken fyToken = IFYToken(asset);
        newAsset = fyToken.underlying();

        // solhint-disable-next-line not-rely-on-time
        if (fyToken.maturity() > block.timestamp) {
            IPool pool = IPool(ladle.pools(ilkId));
            newAmount = pool.sellFYTokenPreview(uint128(amount));
        } else {
            // FYTokens are worth 1:1 after expiry
            newAmount = amount;
        }
    }
}