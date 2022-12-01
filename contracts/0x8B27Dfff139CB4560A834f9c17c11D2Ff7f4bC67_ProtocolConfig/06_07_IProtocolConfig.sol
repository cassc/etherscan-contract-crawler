// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IProtocolConfig {
    function depositFee() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function treasury() external view returns (address);

    function withdrawSafeBoxFee() external view returns (uint256);

    function withdrawSafeBoxFeeWindow() external view returns (uint256);
}