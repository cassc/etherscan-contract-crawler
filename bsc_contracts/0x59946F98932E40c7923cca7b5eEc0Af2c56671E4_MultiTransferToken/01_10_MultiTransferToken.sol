// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Simple multi transfer contract to help disperse airdrops efficiently
contract MultiTransferToken is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private fdToken;
    constructor(address tokenAddress) {
        fdToken = IERC20(tokenAddress);
    }

    /// @notice Send ERC20 tokens to multiple addresses using two arrays which includes the address and the amount.
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of token amounts to send
    function multiTransferToken(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external payable
    {
        for (uint8 i; i < _addresses.length; i++) {
            fdToken.transfer(_addresses[i], _amounts[i]);
        }
    }

    /// @notice Allows retrieval of any ERC20 token that was sent to the contract address
    /// @return success true if the transfer succeeded, false otherwise
    function rescueToken(address tokenAddress) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(msg.sender, ERC20(tokenAddress).balanceOf(address(this)));
    }
}