// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./ITransferSelectorNFT.sol";

interface ILooksRare {
    /**
    * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool);

    function transferSelectorNFT() external view returns (ITransferSelectorNFT);
}