// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev security contract
import "../secutiry/Administered.sol";
import "../secutiry/WhiteList.sol";

contract Withdraw is Administered {
    constructor() {}

    /// @dev withdraw tokens
    function withdrawOwner(uint256 amount) external payable onlyAdmin {
        require(
            payable(address(_msgSender())).send(amount),
            "Withdraw Owner: Failed to transfer token to Onwer"
        );
    }

    /// @dev withdraw tokens
    function withdrawTokenOnwer(
        address _token,
        uint256 _amount
    ) external onlyAdmin {
        require(
            IERC20(_token).transfer(_msgSender(), _amount),
            "Withdraw Token Onwer: Failed to transfer token to Onwer"
        );
    }
}