// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC2309 standard as defined in the EIP.
 */
interface IERC2309 {
    
    /**
     * @dev Emitted when consecutive token ids in range ('fromTokenId') to ('toTokenId') are transferred from one account (`fromAddress`) to
     * another (`toAddress`).
     *
     * Note that `value` may be zero.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
}