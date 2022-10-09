// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// solhint-disable func-name-mixedcase
interface IGelatoRelayBase {
    function userNonce(address _user) external view returns (uint256);

    function gelato() external view returns (address);

    function SPONSORED_CALL_TYPEHASH() external pure returns (bytes32);

    function SPONSORED_USER_AUTH_CALL_TYPEHASH()
        external
        pure
        returns (bytes32);
}