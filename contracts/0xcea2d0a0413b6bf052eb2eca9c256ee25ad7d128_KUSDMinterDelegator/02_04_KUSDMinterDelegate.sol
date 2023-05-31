pragma solidity ^0.5.16;

import "./Ownable.sol";

/**
 * @title KUSDMinterDelegate
 * @author Kine
 */
contract KUSDMinterDelegate is Ownable {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Implementation address
     */
    address public implementation;
}