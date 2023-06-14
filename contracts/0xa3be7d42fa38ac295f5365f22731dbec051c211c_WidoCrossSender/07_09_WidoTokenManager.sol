// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts-v4/access/Ownable.sol";
import "./interfaces/IWidoTokenManager.sol";

contract WidoTokenManager is IWidoTokenManager, Ownable {
    using SafeTransferLib for ERC20;

    /// @notice Transfers tokens or native tokens from the user
    /// @param user The address of the order user
    /// @param inputs Array of input objects, see OrderInput and Order
    function pullTokens(address user, IWidoRouter.OrderInput[] calldata inputs) external override onlyOwner {
        for (uint256 i = 0; i < inputs.length; i++) {
            IWidoRouter.OrderInput calldata input = inputs[i];

            if (input.tokenAddress == address(0)) {
                continue;
            }

            ERC20(input.tokenAddress).safeTransferFrom(user, owner(), input.amount);
        }
    }
}