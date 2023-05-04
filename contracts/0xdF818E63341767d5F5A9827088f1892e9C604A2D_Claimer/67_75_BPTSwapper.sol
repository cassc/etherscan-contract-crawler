// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/OracledAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

import './balancer/IBalancerBoostedPool.sol';
import './balancer/IBalancerPool.sol';
import './balancer/IBalancerVault.sol';

// solhint-disable avoid-low-level-calls

contract BPTSwapper is BaseAction, OracledAction, RelayedAction, TokenThresholdAction {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 95e3;

    // Internal constant used to exit balancer pools
    uint256 private constant EXACT_BPT_IN_FOR_TOKENS_OUT = 1;

    // Address of the token used in order to pay gas
    address public payingGasToken;

    // Balancer Vault reference - it cannot be changed
    address public immutable balancerVault;

    /**
     * @dev Emitted every time a paying gas token is set
     */
    event PayingGasTokenSet(address indexed payingGasToken);

    /**
     * @dev Creates a new BPT swapper action
     * @param _balancerVault Address of the Balancer Vault
     */
    constructor(address _balancerVault, address admin, address registry) BaseAction(admin, registry) {
        balancerVault = _balancerVault;
    }

    /**
     * @dev Sets a paying gas token
     * @param newPayingGasToken Address of the new token to be used to pay gas costs
     */
    function setPayingGasToken(address newPayingGasToken) external auth {
        require(newPayingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        payingGasToken = newPayingGasToken;
        emit PayingGasTokenSet(newPayingGasToken);
    }

    /**
     * @dev Executes the BPT swapper action for a token and amount pair
     * @param pool Address of the Balancer pool (token) to swap
     * @param amount Amount of BPTs to swap
     */
    function call(address pool, uint256 amount) external auth nonReentrant redeemGas(payingGasToken) {
        require(payingGasToken != address(0), 'CLAIMER_PAYING_GAS_TOKEN_ZERO');
        require(pool != address(0), 'BPT_SWAPPER_ADDRESS_ZERO');
        require(amount > 0, 'BPT_SWAPPER_AMOUNT_ZERO');
        _validateThreshold(pool, amount);

        smartVault.call(pool, abi.encodeWithSelector(IERC20.approve.selector, balancerVault, amount), 0, new bytes(0));
        smartVault.call(balancerVault, _buildSwapCall(pool, amount), 0, new bytes(0));
        emit Executed();
    }

    /**
     * @dev Builds the corresponding data to swap a BPT into its underlying tokens
     * @param pool Address of the Balancer pool (token) to swap
     * @param amount Amount of BPTs to swap
     */
    function _buildSwapCall(address pool, uint256 amount) private view returns (bytes memory) {
        try IBalancerBoostedPool(pool).getBptIndex() returns (uint256 bptIndex) {
            return _buildBoostedPoolSwap(pool, amount, bptIndex);
        } catch {
            return _buildNormalPoolExit(pool, amount);
        }
    }

    /**
     * @dev Exit normal pools using a exact BPT for tokens out. Note that there is no need to compute
     * minimum amounts since this is considered a proportional exit.
     * @param pool Address of the Balancer pool (token) to exit
     * @param amount Amount of BPTs to exit
     */
    function _buildNormalPoolExit(address pool, uint256 amount) private view returns (bytes memory) {
        // Fetch the list of tokens of the pool
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        (IERC20[] memory tokens, , ) = IBalancerVault(balancerVault).getPoolTokens(poolId);

        // Proportional exit
        IBalancerVault.ExitPoolRequest memory request = IBalancerVault.ExitPoolRequest({
            assets: tokens,
            minAmountsOut: new uint256[](tokens.length),
            userData: abi.encodePacked(EXACT_BPT_IN_FOR_TOKENS_OUT, amount),
            toInternalBalance: false
        });

        return
            abi.encodeWithSelector(
                IBalancerVault.exitPool.selector,
                poolId,
                address(smartVault),
                payable(address(smartVault)),
                request
            );
    }

    /**
     * @dev Exit boosted pools using a swap request in exchange for the first underlying token of the pool. The min
     * amount out is computed based on the current rate of the boosted pool.
     * @param pool Address of the Balancer pool (token) to swap
     * @param amount Amount of BPTs to swap
     * @param bptIndex Index of the BPT in the list of tokens tracked by the Balancer Vault
     */
    function _buildBoostedPoolSwap(address pool, uint256 amount, uint256 bptIndex) private view returns (bytes memory) {
        // Pick the first underlying token of the boosted pool
        bytes32 poolId = IBalancerPool(pool).getPoolId();
        (IERC20[] memory tokens, , ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        address underlying = address(bptIndex == 0 ? tokens[1] : tokens[0]);

        // Compute minimum amount out in the underlying token
        uint256 rate = IBalancerBoostedPool(pool).getRate();
        uint256 decimals = IERC20Metadata(underlying).decimals();
        uint256 minAmountOut = decimals <= 18 ? (rate / (10**(18 - decimals))) : (rate * (10**(decimals - 18)));

        // Swap from BPT to underlying token
        IBalancerVault.SingleSwap memory request = IBalancerVault.SingleSwap({
            poolId: IBalancerPool(pool).getPoolId(),
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: pool,
            assetOut: underlying,
            amount: amount,
            userData: new bytes(0)
        });

        // Build fund management object: smart vault is the sender and recipient
        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
            sender: address(smartVault),
            fromInternalBalance: false,
            recipient: payable(address(smartVault)),
            toInternalBalance: false
        });

        return abi.encodeWithSelector(IBalancerVault.swap.selector, request, funds, minAmountOut, block.timestamp);
    }

    function _getPrice(address base, address quote)
        internal
        view
        override(BaseAction, OracledAction)
        returns (uint256)
    {
        return OracledAction._getPrice(base, quote);
    }
}