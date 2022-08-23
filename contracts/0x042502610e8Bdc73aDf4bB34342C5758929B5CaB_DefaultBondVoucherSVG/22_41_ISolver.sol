// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISolver {

    event SetOperationPaused (
        address product,
        string operation,
        bool setPaused
    );


    function isSolver() external pure returns (bool);

    function setOperationPaused(address product_, string calldata operation_, bool setPaused_) external;

    function operationAllowed(string calldata operation_, bytes calldata data_) external returns (uint256);

    function operationVerify(string calldata operation_, bytes calldata data_) external returns (uint256);
    
}