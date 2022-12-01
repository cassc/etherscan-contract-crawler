// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/// @title L1Utils
/// @notice This is contract that Ribbon Lend references to retrieve the necessary information
contract L1Utils is Ownable {
    /// @notice The L1 bridge address
    address public immutable l1Bridge;

    /// @notice The l2 gas limit amount
    uint32 public l2GasLimit;

    /// @notice The correspondence between l1 and l2 ERC20 addresses
    mapping(address => address) public l1ToL2ERC20Address;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor
    /// @param _l1Bridge The L1 bridge address
    /// @param _l2GasLimit The l2 gas limit amount
    constructor(address _l1Bridge, uint32 _l2GasLimit) {
        l1Bridge = _l1Bridge;
        l2GasLimit = _l2GasLimit;
    }

    /*//////////////////////////////////////////////////////////////
                                UTILS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates l1 and corresponding l2 token addresses
    /// @param _l1ERC20 The l1 token address
    /// @param _l2ERC20 The l2 token address
    function updateL1ToL2ERC20Mapping(address _l1ERC20, address _l2ERC20) external onlyOwner {
        require(_l1ERC20 != address(0), "L1_ADDRESS_ZERO");
        require(_l2ERC20 != address(0), "L2_ADDRESS_ZERO");
        l1ToL2ERC20Address[_l1ERC20] = _l2ERC20;
    }

    /// @notice Updates the gas limit amount
    /// @param _l2GasLimit The new gas limit amount
    function updateL2GasLimit(uint32 _l2GasLimit) external onlyOwner {
        require(_l2GasLimit > 0, "ZERO_AMOUNT");
        l2GasLimit = _l2GasLimit;
    }
}