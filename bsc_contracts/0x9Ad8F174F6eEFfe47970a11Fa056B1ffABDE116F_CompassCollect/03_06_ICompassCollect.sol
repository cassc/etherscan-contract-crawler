// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0;

interface ICompassCollect {

    function recipient() external view returns (address payable);

    function useToken() external view returns (address);

    function setRecipient(address payable _recipient) external;

    function collect(address token, bytes32[] memory salts) external;

    function getBalance(address token, bytes32[] memory salts) external view returns (uint[] memory);

    function computeAddress(bytes32 salt) external view returns (address addr);
}