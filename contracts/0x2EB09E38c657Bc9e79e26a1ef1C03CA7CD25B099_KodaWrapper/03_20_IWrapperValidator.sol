// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IWrapperValidator {
    function underlyingToken() external view returns (address);

    function isValid(address collection, uint256 tokenId) external view returns (bool);
}