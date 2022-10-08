// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface MarginPoolInterface {
    /* Getters */
    function addressBook() external view returns (address);

    function getStoredBalance(address _asset) external view returns (uint256);

    /* Controller-only functions */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) external;
}