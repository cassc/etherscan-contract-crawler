//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITokensRescuer {
    /**
     * @dev withdraws an ETH token that accidentally ended up
     *      on this contract and cannot be used in any way.
     *      Can only be called by the current owner.
     * @param amount - a number of tokens to withdraw from this contract.
     * @param receiver - a wallet that will receive withdrawing tokens.
     */
    function rescueNativeToken(uint256 amount, address receiver) external;

    /**
     * @dev withdraws an ERC-20 token that accidentally ended up
     *      on this contract and cannot be used in any way.
     *      Can only be called by the current owner.
     * @param token - a number of tokens to withdraw from this contract.
     * @param amount - a number of tokens to withdraw from this contract.
     * @param receiver - a wallet that will receive withdrawing tokens.
     */
    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external;
}