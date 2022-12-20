// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../security/Administered.sol";

contract Withdraw is Administered {
    /// @dev Allow the owner of the contract to withdraw
    function withdrawOwner(uint256 amount, address to)
        external
        payable
        onlyAdmin
    {
        require(
            payable(to).send(amount),
            "withdrawOwner: Failed to transfer token to fee contract"
        );
    }

    /// @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawTokenOnwer(
        address _token,
        uint256 _amount,
        address to
    ) external onlyAdmin {
        require(
            IERC20(_token).transfer(to, _amount),
            "withdrawTokenOnwer: Failed to transfer token to Onwer"
        );
    }
}