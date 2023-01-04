// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IveListener {
    /**
     * @dev When a token weight is updated, this function is called if the contract is registered as observer.
     */
    function onTokenWeightUpdated(uint256 _tokenId) external;
}