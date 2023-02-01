// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./owner.sol";

contract AssetManagement is
    Owner
{
    using Address for address;
    using SafeERC20 for IERC20;

    /**
     * @dev Event emmitted when assets are withdrawn.
     */
    event Withdraw(
        address asset,
        uint256 amount
    );

    /**
     * @dev Withdraw Ether from this contract.
     */
	function withdrawEther_wEuX(
	    uint256 amount
    )
        external
        onlyOwner
    {
        (bool success, ) = msg.sender.call{value: amount}("");

        require(
            success,
            "RS:E0"
        );

        emit Withdraw(address(0), amount);
	}

    /**
     * @dev Withdraw tokens from this contract.
     */
	function withdrawToken_14u2(
	    address token,
        uint256 amount
    )
        external
        onlyOwner
    {
        require(
            token != address(0),
            "RS:E1"
        );

        IERC20(token).safeTransfer(msg.sender, amount);
        emit Withdraw(token, amount);
	}

    /**
     * @dev Manually set allowance for a given token & spender pair.
     * Allowances for this contract are managed via DexAggSwaps,
     * but any manual intervention is performed with this function.
     */
    function manuallySetAllowances(
        address spender,
        IERC20[] memory tokens,
        uint256[] memory values
    )
        external
        onlyOwner
    {
        require(
            spender != address(0),
            "RS:E1"
        );
        for (uint256 i; i < tokens.length;)
        {
            require(
                address(tokens[i]) != address(0),
                "RS:E1"
            );
            tokens[i].approve(spender, values[i]);

            // Gas optimization
            unchecked
            {
                ++i;
            }
        }
    }
}