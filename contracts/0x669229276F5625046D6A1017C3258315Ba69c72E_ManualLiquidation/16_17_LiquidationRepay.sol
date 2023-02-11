// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISilo.sol";

/// @notice LiquidationHelper IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
/// see https://github.com/silo-finance/liquidation#readme for details how liquidation process should look like
abstract contract LiquidationRepay {

    error RepayFailed();

    function _repay(
        ISilo _silo,
        address _user,
        address[] calldata _assets,
        uint256[] calldata _shareAmountsToRepaid
    ) internal virtual {
        for (uint256 i = 0; i < _assets.length;) {
            if (_shareAmountsToRepaid[i] != 0) {
                _repayAsset(_silo, _user, _assets[i], _shareAmountsToRepaid[i]);
            }

            // we will never have that many assets to overflow
            unchecked { i++; }
        }
    }

    function _repayAsset(
        ISilo _silo,
        address _user,
        address _asset,
        uint256 _shareAmountToRepaid
    ) internal virtual {
        // Low level call needed to support non-standard `ERC20.approve` eg like `USDT.approve`
        // solhint-disable-next-line avoid-low-level-calls
        _asset.call(abi.encodeCall(IERC20.approve, (address(_silo), _shareAmountToRepaid)));
        _silo.repayFor(_asset, _user, _shareAmountToRepaid);

        // DEFLATIONARY TOKENS ARE NOT SUPPORTED
        // we are not using lower limits for swaps so we may not get enough tokens to do full repay
        // our assumption here is that `_shareAmountsToRepaid[i]` is total amount to repay the full debt
        // if after repay user has no debt in this asset, the swap is acceptable
        if (_silo.assetStorage(_asset).debtToken.balanceOf(_user) != 0) {
            revert RepayFailed();
        }
    }
}