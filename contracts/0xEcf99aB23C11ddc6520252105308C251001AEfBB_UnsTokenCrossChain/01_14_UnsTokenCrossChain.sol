// contracts/UnsTokenCrossChain.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UnsTokenCrossChain is ERC20Burnable, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant BLACKLIST_ROLE = keccak256("BLACKLIST_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event Bridge(address indexed src, uint256 amount, uint256 chainId);

    constructor() ERC20("UNS Token", "UNS") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function bridge(uint256 amount, uint256 chainId) public {
        _burn(_msgSender(), amount);
        emit Bridge(_msgSender(), amount, chainId);
    }
    
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
        require(!hasRole(BLACKLIST_ROLE, msg.sender), "Blacklisted");
    }

    /**
     * @notice Function to recover ERC20
     * Caller is assumed to be governance
     * @param token Address of token to be rescued
     * @param amount Amount of tokens
     */
    function recoverERC20(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "!zero");
        token.safeTransfer(_msgSender(), amount);
    }
}