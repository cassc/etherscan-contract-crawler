//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC677Token is IERC20 {
    /// @dev transfer token to a contract address with additional data if the recipient is a contract.
    /// @param _receiver The address to transfer to.
    /// @param _amount The amount to be transferred.
    /// @param _data The extra data to be passed to the receiving contract.
    function transferAndCall(
        address _receiver,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bool success);
}