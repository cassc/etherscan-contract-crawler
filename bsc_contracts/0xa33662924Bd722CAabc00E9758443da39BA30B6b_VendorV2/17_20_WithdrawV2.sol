// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../security/Administered.sol";

contract WithdrawV2 is Administered {

    /**
     * @dev Withdraws native tokens
     * @param _amount Amount to withdraw
     * @param _to Address to send the tokens to
     */
    function withdraw(
        uint256 _amount, 
        address _to
    ) external payable onlyAdmin returns (bool) {
        require(payable(_to).send(_amount), "Failed to withdraw contract fee");
        return true;
    }

    /**
     * @dev Withdraws tokens from the contract.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _to The address to send the tokens to.
     */
    function withdrawToken(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyAdmin returns (bool) {
        require(
            IERC20(_token).transfer(_to, _amount),
            "Failed to withdraw contract fee"
        );
        return true;
    }
}