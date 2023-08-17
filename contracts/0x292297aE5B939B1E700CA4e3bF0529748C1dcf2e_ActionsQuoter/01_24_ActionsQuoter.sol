// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./CrossLedgerVault.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @author YLDR <[email protected]>
contract ActionsQuoter {
    /// @dev Code is taken from openzeppelin Address.sol implementation
    /// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L223)
    /// function reverts with the same revert data
    function _revert(bytes memory returndata) private pure {
        assembly {
            let returndata_size := mload(returndata)
            revert(add(32, returndata), returndata_size)
        }
    }

    /// @dev Function always reverts, following cases are possible:
    /// 1. Amount is processable with acceptable slippage. Revert reason == abi.encode(true)
    /// 2. Amount is processable but too big for execution with acceptable slippage. Revert reason == abi.encode(false)
    /// 3. Amount is not processable due to other error. Revert reason == revert reason received during execution
    function quoteActionInternal(CrossLedgerVault vault, uint256 amount) external {
        bool isSuccessful;

        try vault.processAction(amount) {
            isSuccessful = true;
        } catch (bytes memory reason) {
            // Catch slippage error
            if (bytes4(reason) == CrossLedgerVault.SlippageTooBig.selector) {
                isSuccessful = false;
            } else {
                // some other error occured, it's not OK
                _revert(reason);
            }
        }

        // Revert with boolean result
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, isSuccessful)
            revert(ptr, 32)
        }
    }

    function quoteAction(CrossLedgerVault vault, uint256 amount) public returns (bool isSuccessful) {
        try this.quoteActionInternal(vault, amount) {}
        catch (bytes memory reason) {
            // If reason is not encoded boolean from quoteAction()
            if (reason.length != 32) {
                _revert(reason);
            }
            isSuccessful = abi.decode(reason, (bool));
        }
    }

    function calculateMaxExecutionAmount(CrossLedgerVault vault) external returns (uint256 maxAmount) {
        require(vault.isActionInProgress(), "No action is in progress");

        uint8 decimals = IERC20Metadata(address(vault.mainAsset())).decimals();
        uint256 amountIn = vault.currentAction().amountIn;

        // Check if we can process full amount
        if (quoteAction(vault, amountIn)) {
            return amountIn;
        }

        uint256 left = 1;
        uint256 right = amountIn;

        while ((right - left) > (10 ** decimals)) {
            uint256 mid = (left + right) / 2;
            bool isSuccessful = quoteAction(vault, mid);
            if (isSuccessful) {
                left = mid;
            } else {
                right = mid;
            }
        }

        return left;
    }
}