// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProxyRegistry.sol";
import "../../token/ERC20/IERC20.sol";
import "../../utils/Context.sol";

contract TokenTransferProxy is Context {
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(registry.contracts(_msgSender()));
        return IERC20(token).transferFrom(from, to, amount);
    }
}