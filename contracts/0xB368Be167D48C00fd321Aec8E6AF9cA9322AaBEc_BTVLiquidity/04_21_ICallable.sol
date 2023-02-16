//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ICallable
 * @author [email protected]
 */
abstract contract ICallable is IERC20 {
    /**
     * Allow another contract to spend some assets in your behalf
     *
     * @param _spender				Address of the contract which can spend tokens
     * @param _value				Number of tokens that the spender can spend
     * @param _extraData			c.f. BlackMarket.sol receiveApproval()
     */
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes calldata _extraData
    ) public virtual returns (bool success);
}