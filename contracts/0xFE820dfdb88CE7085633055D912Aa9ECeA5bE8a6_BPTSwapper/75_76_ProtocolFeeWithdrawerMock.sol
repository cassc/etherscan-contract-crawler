// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@mimic-fi/v2-helpers/contracts/utils/ERC20Helpers.sol';

import '../actions/claim/IProtocolFeeWithdrawer.sol';

contract ProtocolFeeWithdrawerMock is IProtocolFeeWithdrawer {
    function withdrawCollectedFees(address[] calldata tokens, uint256[] calldata amounts, address recipient)
        external
        override
    {
        require(tokens.length == amounts.length, 'WITHDRAWER_INVALID_INPUT_LEN');
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ERC20Helpers.balanceOf(tokens[i], address(this)) >= amounts[i], 'INVALID_WITHDRAWER_BALANCE');
            ERC20Helpers.transfer(tokens[i], recipient, amounts[i]);
        }
    }
}