// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IRefuel {
    function depositNativeToken(uint256 destinationChainId, address _to) external payable;
}