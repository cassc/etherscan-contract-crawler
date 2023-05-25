// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, Receiver
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0x4fc35859.
 */
interface IERC20Receiver {
    /**
     * Handles the receipt of ERC20 tokens.
     * @param sender The initiator of the transfer.
     * @param from The address which transferred the tokens.
     * @param value The amount of tokens transferred.
     * @param data Optional additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`
     */
    function onERC20Received(
        address sender,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}