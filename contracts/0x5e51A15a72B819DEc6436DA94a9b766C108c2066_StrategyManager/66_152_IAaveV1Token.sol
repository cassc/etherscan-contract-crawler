// SPDX-License-Identifier:MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IAaveV1Token {
    function redeem(uint256 amount) external;

    function isTransferAllowed(address user, uint256 amount) external view returns (bool);

    function underlyingAssetAddress() external view returns (address);
}