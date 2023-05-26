// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract LOCG is AccessControl, ERC20, Pausable, ERC20Burnable, ERC20Snapshot {
    using SafeERC20 for IERC20;

    string public constant NAME = "LOCGame";
    string public constant SYMBOL = "LOCG";
    uint256 public constant MAX_TOTAL_SUPPLY = 150_000_000 * 1e18;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");       // Whitelisted addresses can transfer token when paused

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }

    constructor (address daoMultiSig) ERC20(NAME, SYMBOL) {
        _setupRole(DEFAULT_ADMIN_ROLE, daoMultiSig);   // DEFAULT_ADMIN_ROLE can grant other roles
        _setupRole(WHITELISTED_ROLE, daoMultiSig);
        _mint(daoMultiSig, MAX_TOTAL_SUPPLY);
    }


    /**
     * @notice Triggers stopped state.
     * Requirements:
     * - The contract must not be paused.
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     * Requirements:
     * - The contract must be paused.
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @notice Creates a new snapshot and returns its snapshot id.
     */
    function snapshot() external onlyAdmin returns(uint256) {
        return _snapshot();
    }

    function withdrawERC20(IERC20 token) external onlyAdmin {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), balance);
    }

    function withdrawERC721(IERC721 token, uint256 id) external onlyAdmin {
        token.transferFrom(address(this), _msgSender(), id);
    }

    function withdrawERC1155(IERC1155 token, uint256 id, uint256 amount, bytes calldata data) external onlyAdmin {
        token.safeTransferFrom(address(this), _msgSender(), id, amount, data);
    }

    /**
     * @dev This function is overridden in both ERC20 and ERC20Snapshot, so we need to specify execution order here.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused() || hasRole(WHITELISTED_ROLE, _msgSender()) || hasRole(WHITELISTED_ROLE, from), "transfers paused");
    }
}