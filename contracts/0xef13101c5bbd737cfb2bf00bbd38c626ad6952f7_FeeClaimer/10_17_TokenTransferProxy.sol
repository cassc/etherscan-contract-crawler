// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ITokenTransferProxy.sol";

/**
 * @dev Allows owner of the contract to transfer tokens on behalf of user.
 * User will need to approve this contract to spend tokens on his/her behalf
 * on Paraswap platform
 */
contract TokenTransferProxy is Ownable, ITokenTransferProxy {
    using SafeERC20 for IERC20;
    using Address for address;

    /**
     * @dev Allows owner of the contract to transfer tokens on user's behalf
     * @dev Swapper contract will be the owner of this contract
     * @param token Address of the token
     * @param from Address from which tokens will be transferred
     * @param to Receipent address of the tokens
     * @param amount Amount of tokens to transfer
     */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override onlyOwner {
        // solhint-disable-next-line avoid-tx-origin
        require(from == tx.origin || from.isContract(), "Invalid from address");

        IERC20(token).safeTransferFrom(from, to, amount);
    }
}