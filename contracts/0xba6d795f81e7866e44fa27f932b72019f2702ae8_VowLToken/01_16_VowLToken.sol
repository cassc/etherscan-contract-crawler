// contracts/VowLToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VowLToken is ERC20Burnable, AccessControl {
    using SafeERC20 for IERC20;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    constructor() ERC20("VowL Token", "VOWL") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(
        address account, 
        uint256 amount
    ) public onlyRole(MINTER_ROLE) returns (bool) {
        _mint(account, amount);
        return true;
    }


    /**
     * @notice Function to recover ERC20
     * Caller is assumed to be governance
     * @param token Address of token to be rescued
     * @param amount Amount of tokens
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function recoverERC20(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "!zero");
        token.safeTransfer(_msgSender(), amount);
    }

}