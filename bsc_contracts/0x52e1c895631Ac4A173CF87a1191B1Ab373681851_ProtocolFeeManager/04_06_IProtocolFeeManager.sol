// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolFeeManager {
    function setDefaultProtocolFee(uint256 _defaultProtocolFee) external;

    function setProtocolFeeForCollection(
        address _collection,
        uint256 _protocolFee
    ) external;

    function unsetProtocolFeeForCollection(address _collection) external;

    function protocolFeeForCollection(address _collection)
        external
        view
        returns (uint256);

    function defaultProtocolFee() external view returns (uint256);
}